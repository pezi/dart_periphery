// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/vsergeev/c-periphery/blob/master/docs/gpio.md
// https://github.com/vsergeev/c-periphery/blob/master/src/gpio.c
// https://github.com/vsergeev/c-periphery/blob/master/src/gpio.h
// https://github.com/dart-lang/samples/tree/master/ffi

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'isolate_api.dart';
import 'json.dart';
import 'library.dart';
import 'signature.dart';

/// Result codes of the [GPIO.poll].
enum GPIOpolling {
  /// Poll operation completed successfully with an event
  success,

  /// Poll operation timed out without an event
  timeout
}

/// Mapped native [GPIO] error codes with the same index, but different
/// leading sign.
enum GPIOerrorCode {
  /// Error code for not able to map the native C enum
  errorCodeNotMappable,

  ///  Invalid arguments
  gpioErrorArg,

  /// Opening GPIO
  gpioErrorOpen,

  /// Line name not found
  gpioErrorNotFound,

  /// Querying GPIO attributes
  gpioErrorQuery,

  /// Configuring GPIO attributes
  gpioErrorConfigure,

  /// Unsupported attribute or operation
  gpioErrorUnsupported,

  /// Invalid operation
  gpioErrorInvalidOperation,

  /// Reading/writing GPIO
  gpioErrorIO,

  /// Closing GPIO
  gpioErrorClose
}

/// [GPIO] input/output direction
enum GPIOdirection {
  /// Input direction
  gpioDirIn,

  /// Output direction, initialized to low
  gpioDirOut,

  /// Output direction, initialized to low
  gpioDirOutLow,

  /// Output direction, initialized to high
  gpioDirOutHigh
}

/// [GPIO] edge
enum GPIOedge {
  /// No interrupt edge
  gpioEdgeNone,

  /// Rising edge 0 -> 1
  gpioEdgeRising,

  /// Falling edge 1 -> 0
  gpioEdgeFalling,

  /// Both edges X -> !X
  gpioEdgeBoth
}

/// [GPIO] bias
enum GPIObias {
  /// Default line bias
  gpioBiasDefault,

  /// Pull-up resistor enabled
  gpioBiasPullUp,

  /// Pull-down resistor enabled
  gpioBiasPullDown,

  /// Disable line bias
  gpioBiasDisable,
}

/// [GPIO] drive
enum GPIOdrive {
  /// Default line drive (push-pull)
  gpioDriveDefault,

  /// Open drain output
  gpioDriveOpenDrain,

  /// Open source output
  gpioDriveOpenSource,
}

/// Result of the [GPIO.readEvent()].
class GPIOreadEvent {
  /// edge value
  final GPIOedge edge;
  // event time reported by Linux, in nanoseconds.
  final int nanoSeconds;

  GPIOreadEvent(this.edge, this.nanoSeconds);
}

/// Helper class for the static method [GPIO.pollMultiple].
///
/// [PollMultipleEvent.eventOccurred] will be populated with true for the
/// corresponding GPIO in the gpios array if an edge event occurred, or false
/// if none occurred. This class contains also the number [eventCounter] of
/// GPIOs for which an edge event occurred.
/// See for details [GPIO.pollMultiple]
class PollMultipleEvent {
  /// GPIO list monitored for edge events
  final List<GPIO> gpios;

  /// edge event occurred counter
  final int eventCounter;

  /// edge event result list
  final List<bool> eventOccurred;
  PollMultipleEvent(this.gpios, this.eventCounter, this.eventOccurred);

  /// Checks if the timeout has been reached.
  bool isTimeoutReached() {
    return eventCounter == 0 ? true : false;
  }

  /// Checks if an edge event occurred for a [gpio]
  bool hasEventOccurred(GPIO gpio) {
    var index = 0;
    for (var g in gpios) {
      if (g._gpioHandle == gpio._gpioHandle) {
        return eventOccurred[index];
      }
      ++index;
    }
    return false;
  }
}

/* Configuration structure for gpio_open_*advanced() functions
typedef struct gpio_config {
    gpio_direction_t direction;
    gpio_edge_t edge;
    gpio_bias_t bias;
    gpio_drive_t drive;
    bool inverted;
    const char *label; 
} gpio_config_t;
*/

final class _GPIOconfig extends Struct {
  @Int32()
  external int direction;
  @Int32()
  external int edge;
  @Int32()
  external int bias;
  @Int32()
  external int drive;
  @Int32() // this a bool value, but inside a struct 3 padding bytes are added for a 32-bit alignment
  external int inverted;
  external Pointer<Utf8> label;
}

/// Configuration class for [GPIO.advanced] and [GPIO.nameAdvanced].
class GPIOconfig {
  GPIOdirection direction;
  GPIOedge edge;
  GPIObias bias;
  GPIOdrive drive;
  bool inverted;
  // GPIO name
  String label;
  GPIOconfig(this.direction, this.edge, this.bias, this.drive, this.inverted,
      this.label);
  GPIOconfig.defaultValues()
      : direction = GPIOdirection.gpioDirIn,
        edge = GPIOedge.gpioEdgeNone,
        bias = GPIObias.gpioBiasDefault,
        drive = GPIOdrive.gpioDriveDefault,
        inverted = false,
        label = '';
  Pointer<_GPIOconfig> _toNative() {
    var cfg = malloc<_GPIOconfig>(1);
    cfg.ref.direction = direction.index;
    cfg.ref.edge = edge.index;
    cfg.ref.bias = bias.index;
    cfg.ref.drive = drive.index;
    cfg.ref.inverted = inverted ? 1 : 0;
    cfg.ref.label = label.toNativeUtf8();
    return cfg;
  }
}

/// [GPIO] exception
class GPIOexception implements Exception {
  final GPIOerrorCode errorCode;
  final String errorMsg;
  GPIOexception(this.errorCode, this.errorMsg);
  GPIOexception.errorCode(int code, Pointer<Void> handle)
      : errorCode = GPIO.getGPIOerrorCode(code),
        errorMsg = _getErrmsg(handle);
  @override
  String toString() => errorMsg;
}

final DynamicLibrary _peripheryLib = loadPeripheryLib();

// gpio_t *gpio_new(void);
final _nativeGPIOnew = voidPtrVOIDM('gpio_new');

// int gpio_close(led_t *led);
final _nativeGPIOclose = intVoidM('gpio_close');

//  void gpio_free(gpio_t *i2c);
final _nativeGPIOfree = voidVoidM('gpio_free');

// int gpio_errno(gpio_t *i2c);
final _nativeGPIOerrno = intVoidM('gpio_errno');

// const char *gpio_errmsg(gpio_t *i2c);
final _nativeGPIOerrnMsg = utf8VoidM('gpio_errmsg');

// int gpio_tostring(gpio_t *gpio, char *str, size_t len);
final _nativeGPIOinfo = intVoidUtf8sizeTM('gpio_tostring');

// int gpio_fd(gpio_t *gpio);
final _nativeGPIOfd = intVoidM('gpio_fd');

// int gpio_chip_fd(gpio_t *gpio);
final _nativeGPIOchipFd = intVoidM('gpio_chip_fd');

// unsigned int gpio_line(gpio_t *gpio);
final _nativeGPIOline = intVoidM('gpio_line');

// int gpio_name(gpio_t *gpio, char *str, size_t len);
final _nativeGPIOname = intVoidUtf8sizeTM('gpio_name');

// int gpio_label(gpio_t *gpio, char *str, size_t len);
final _nativeGPIOlabel = intVoidUtf8sizeTM('gpio_label');

// int gpio_chip_name(gpio_t *gpio, char *str, size_t len);
final _nativeGPIOchipName = intVoidUtf8sizeTM('gpio_chip_name');

// int gpio_chip_label(gpio_t *gpio, char *str, size_t len);
final _nativeGPIOchipLabel = intVoidUtf8sizeTM('gpio_chip_label');

// int gpio_set_direction(gpio_t *gpio, gpio_direction_t direction);
final _nativeGPIOsetDirection = intVoidIntM('gpio_set_direction');

// int gpio_set_edge(gpio_t *gpio, gpio_edge_t edge);
final _nativeGPIOsetEdge = intVoidIntM('gpio_set_edge');

// int gpio_set_bias(gpio_t *gpio, gpio_bias_t bias);
final _nativeGPIOsetBias = intVoidIntM('gpio_set_bias');

// int gpio_set_drive(gpio_t *gpio, gpio_drive_t drive);
final _nativeGPIOsetDrive = intVoidIntM('gpio_set_drive');

// int gpio_set_inverted(gpio_t *gpio, bool inverted);
final _nativeGPIOsetInverted = intVoidBoolM('gpio_set_inverted');

// int gpio_get_direction(gpio_t *gpio, gpio_direction_t *direction);
final _nativeGPIOgetDirection = intVoidInt32PtrM('gpio_get_direction');

// int gpio_get_edge(gpio_t *gpio, gpio_edge_t *edge);
final _nativeGPIOgetEdge = intVoidInt32PtrM('gpio_get_edge');

// int gpio_get_bias(gpio_t *gpio, gpio_bias_t *bias);
final _nativeGPIOgetBias = intVoidInt32PtrM('gpio_get_bias');

// int gpio_get_drive(gpio_t *gpio, gpio_drive_t *drive);
final _nativeGPIOgetDrive = intVoidInt32PtrM('gpio_get_drive');

// int gpio_get_inverted(gpio_t *gpio, bool *inverted);
final _nativeGPIOgetInverted = intVoidInt8PtrM('gpio_get_inverted');

// int gpio_open(gpio_t *gpio, const char *path, unsigned int line, gpio_direction_t direction);
// ignore: camel_case_types
typedef _gpioOpen = Int32 Function(
    Pointer<Void> handle, Pointer<Utf8> path, Int32 line, Int32 direction);
typedef _GPIOopen = int Function(
    Pointer<Void> handle, Pointer<Utf8> path, int line, int direction);
final _nativeGPIOopen = _peripheryLib
    .lookup<NativeFunction<_gpioOpen>>('gpio_open')
    .asFunction<_GPIOopen>();

// int gpio_open_name(gpio_t *gpio, const char *path, const char *name, gpio_direction_t direction);
// ignore: camel_case_types
typedef _gpioOpenName = Int32 Function(Pointer<Void> handle, Pointer<Utf8> path,
    Pointer<Utf8> name, Int32 direction);
typedef _GPIOopenName = int Function(Pointer<Void> handle, Pointer<Utf8> path,
    Pointer<Utf8> name, int direction);
final _nativeGPIOopenName = _peripheryLib
    .lookup<NativeFunction<_gpioOpenName>>('gpio_open_name')
    .asFunction<_GPIOopenName>();

// int open_advanced(gpio_t *gpio, const char *path, unsigned int line, const gpio_config_t *config);
// ignore: camel_case_types
typedef _gpioOpenAdvanced = Int32 Function(Pointer<Void> handle,
    Pointer<Utf8> path, Int32 line, Pointer<_GPIOconfig> config);
typedef _GPIOopenAdvanced = int Function(Pointer<Void> handle,
    Pointer<Utf8> path, int line, Pointer<_GPIOconfig> config);
final _nativeGPIOopenAdvanced = _peripheryLib
    .lookup<NativeFunction<_gpioOpenAdvanced>>('gpio_open_advanced')
    .asFunction<_GPIOopenAdvanced>();

// int gpio_open_sysfs(gpio_t *gpio, unsigned int line, gpio_direction_t direction)
// ignore: camel_case_types
typedef _gpioOpenSysfs = Int32 Function(
    Pointer<Void> handle, Int32 line, Int32 direction);
typedef _GPIOopenSysfs = int Function(
    Pointer<Void> handle, int line, int direction);
final _nativeGPIOopenSysfs = _peripheryLib
    .lookup<NativeFunction<_gpioOpenSysfs>>('gpio_open_sysfs')
    .asFunction<_GPIOopenSysfs>();

// int gpio_open_name_advanced(gpio_t *gpio, const char *path, const char *name, const gpio_config_t *config);
// ignore: camel_case_types
typedef _gpioOpenNameAdvanced = Int32 Function(Pointer<Void> handle,
    Pointer<Utf8> path, Pointer<Utf8> name, Pointer<_GPIOconfig> config);
typedef _GPIOopenNameAdvanced = int Function(Pointer<Void> handle,
    Pointer<Utf8> path, Pointer<Utf8> name, Pointer<_GPIOconfig> config);
final _nativeGPIOopenNameAdvanced = _peripheryLib
    .lookup<NativeFunction<_gpioOpenNameAdvanced>>('gpio_open_name_advanced')
    .asFunction<_GPIOopenNameAdvanced>();

// int gpio_write(gpio_t *gpio, bool value)
final _nativeGPIOwrite = intVoidIntM('gpio_write');

// int gpio_read(gpio_t *gpio, bool *value);
final _nativeGPIOread = intVoidInt8PtrM('gpio_read');

// int gpio_read_event(gpio_t *gpio, gpio_edge_t *edge, uint64_t *timestamp);
// ignore: camel_case_types
typedef _gpioReadEvent = Int32 Function(
    Pointer<Void>, Pointer<Int32> edge, Pointer<Uint64> timeoutMillis);
typedef _GPIOreadEvent = int Function(
    Pointer<Void>, Pointer<Int32> edge, Pointer<Uint64> timeoutMillis);
final _nativeGPIOReadEvent = _peripheryLib
    .lookup<NativeFunction<_gpioReadEvent>>('gpio_read_event')
    .asFunction<_GPIOreadEvent>();

// int gpio_poll(gpio_t *gpio, int timeout_ms);
final _nativeGPIOpoll = intVoidIntM('gpio_poll');

// int gpio_poll_multiple(gpio_t **gpios, size_t count, int timeout_ms, bool *gpios_ready);
// ignore: camel_case_types
typedef _gpioMultiplePoll = Int32 Function(Pointer<Pointer<Void>> gpios,
    IntPtr count, Int32 timoutMillis, Pointer<Int8>);
typedef _GPIOmultiplePoll = int Function(
    Pointer<Pointer<Void>> gpios, int count, int timeoutMillis, Pointer<Int8>);
final _nativeGPIOmultiplePoll = _peripheryLib
    .lookup<NativeFunction<_gpioMultiplePoll>>('gpio_poll_multiple')
    .asFunction<_GPIOmultiplePoll>();

String _getErrmsg(Pointer<Void> handle) {
  return _nativeGPIOerrnMsg(handle).toDartString();
}

const bufferLen = 256;
const openError = 'gpio_new() failed';

int _checkError(int value) {
  if (value < 0) {
    throw GPIOexception(
        GPIO.getGPIOerrorCode(value), GPIO.getGPIOerrorCode(value).toString());
  }
  return value;
}

/// GPIO wrapper functions for Linux userspace character device gpio-cdev
/// and sysfs GPIOs.
///
/// Character device GPIOs were introduced in Linux kernel version 4.8. If the
/// toolchain used to compile c-periphery contains Linux kernel headers
/// older than 4.8 (i.e. linux/gpio.h is missing), then only legacy
/// sysfs GPIOs will be supported.
///
/// c-periphery [GPIO](https://github.com/vsergeev/c-periphery/blob/master/docs/gpio.md)
///  documentation.
class GPIO extends IsolateAPI {
  static String _gpioBasePath = '/dev/gpiochip';

  /// GPIO chip device path e.g. /dev/gpiochip0
  final String path;

  /// GPIO chip number, e.g. 0 for /dev/gpiochip0
  final int chip;

  /// GPIO line number, is -1 if  [GPIO.name] is used
  final int line;

  /// input/output GPIO direction
  final GPIOdirection direction;

  /// GPIO name, is empty if [GPIO.line] is used
  final String name;
  late Pointer<Void> _gpioHandle;
  List<Pointer> _freeList = [];

  bool _invalid = false;

  /// Converts a [GPIO] to a JSON string. See constructor [isolate] for details.
  @override
  String toJson() {
    return '{"class":"GPIO","path":"$path","chip":$chip,"line":$line,"direction":${direction.index},"name":"$name","handle":${_gpioHandle.address}}';
  }

  /// Sets an alternative [chipBasePath], default value is '/dev/gpiochip'
  static void setBaseGPIOpath(String chipBasePath) {
    _gpioBasePath = chipBasePath;
  }

  /// Converts the native error code [value] to [GPIOerrorCode].
  static GPIOerrorCode getGPIOerrorCode(int value) {
    // must be negative
    if (value >= 0) {
      return GPIOerrorCode.errorCodeNotMappable;
    }
    value = -value;

    // check range
    if (value > GPIOerrorCode.gpioErrorClose.index) {
      return GPIOerrorCode.errorCodeNotMappable;
    }

    return GPIOerrorCode.values[value];
  }

  void _checkStatus() {
    if (_invalid) {
      throw GPIOexception(GPIOerrorCode.gpioErrorInvalidOperation,
          'GPIO line has the status released!');
    }
  }

  /// Returns the libc errno of the last failure that occurred.
  int getErrno() {
    _checkStatus();
    return _nativeGPIOerrno(_gpioHandle);
  }

  /// Opens the character device GPIO with the specified GPIO [line] and
  /// [direction] at the default character device GPIO with the [chip] number.
  /// The default chip number is 0, with the path /dev/gpiochip0.
  ///
  /// Use [GPIO.setBaseGPIOpath] to change the default character device path.
  GPIO(this.line, this.direction, [this.chip = 0])
      : path = _gpioBasePath + chip.toString(),
        name = '' {
    var tuple = _openGPIO(_gpioBasePath + chip.toString(), line, direction);
    _gpioHandle = tuple.$1;
    _freeList = tuple.$2;
  }

  static (Pointer<Void>, List<Pointer>) _openGPIO(
      String path, int line, GPIOdirection direction) {
    var gpioHandle = _nativeGPIOnew();
    if (gpioHandle == nullptr) {
      return throw GPIOexception(GPIOerrorCode.gpioErrorOpen, openError);
    }
    var nativePath = path.toNativeUtf8();
    try {
      _checkError(
          _nativeGPIOopen(gpioHandle, nativePath, line, direction.index));
    } catch (_) {
      _nativeGPIOfree(gpioHandle);
      malloc.free(nativePath);
      rethrow;
    }
    return (gpioHandle, [nativePath]);
  }

  /// Opens the character device GPIO with the specified GPIO [name] and
  /// [direction] at the default character device GPIO with the [chip] number.
  /// The default chip number is 0, with the path /dev/gpiochip0.
  ///
  /// Use [GPIO.setBaseGPIOpath] to change the default character device path.
  GPIO.name(this.name, this.direction, [this.chip = 0])
      : path = _gpioBasePath + chip.toString(),
        line = -1 {
    var tuple = _openNameGPIO(_gpioBasePath + chip.toString(), name, direction);
    _gpioHandle = tuple.$1;
    _freeList = tuple.$2;
  }

  static (Pointer<Void>, List<Pointer>) _openNameGPIO(
      String path, String name, GPIOdirection direction) {
    var gpioHandle = _nativeGPIOnew();
    if (gpioHandle == nullptr) {
      return throw GPIOexception(GPIOerrorCode.gpioErrorOpen, openError);
    }
    var nativePath = path.toNativeUtf8();
    var nativeName = name.toNativeUtf8();
    try {
      _checkError(_nativeGPIOopenName(
          gpioHandle, nativePath, nativeName, direction.index));
    } catch (_) {
      _nativeGPIOfree(gpioHandle);
      malloc.free(nativePath);
      malloc.free(nativeName);
      rethrow;
    }
    return (gpioHandle, [nativePath, nativeName]);
  }

  /// Opens the character device GPIO with the specified GPIO [line] and
  /// configuration [config] at the default character device GPIO with
  /// the [chip] number. The default chip number is 0, with the
  /// path /dev/gpiochip0.
  ///
  /// Use [GPIO.setBaseGPIOpath] to change the default character device path.
  GPIO.advanced(this.line, GPIOconfig config, [this.chip = 0])
      : path = _gpioBasePath + chip.toString(),
        name = '',
        direction = config.direction {
    var tuple =
        _openAdvancedGPIO(_gpioBasePath + chip.toString(), line, config);
    _gpioHandle = tuple.$1;
    _freeList = tuple.$2;
  }

  static (Pointer<Void>, List<Pointer>) _openAdvancedGPIO(
      String path, int line, GPIOconfig config) {
    var gpioHandle = _nativeGPIOnew();
    if (gpioHandle == nullptr) {
      return throw GPIOexception(GPIOerrorCode.gpioErrorOpen, openError);
    }
    var nativePath = path.toNativeUtf8();
    var nativeConfig = config._toNative();
    try {
      _checkError(
        _nativeGPIOopenAdvanced(gpioHandle, nativePath, line, nativeConfig),
      );
    } catch (_) {
      _nativeGPIOfree(gpioHandle);
      malloc.free(nativeConfig.ref.label);
      malloc.free(nativeConfig);
      malloc.free(nativePath);
      rethrow;
    }
    return (gpioHandle, [nativeConfig.ref.label, nativeConfig, nativePath]);
  }

  /// Opens the character device GPIO with the specified GPIO [name] and the
  /// configuration [config] at the default character device GPIO with
  /// the [chip] number. The default chip number is 0, with the
  /// path `/dev/gpiochip0`.
  ///
  /// Use [GPIO.setBaseGPIOpath] to change the default character device path.
  GPIO.nameAdvanced(this.name, GPIOconfig config, [this.chip = 0])
      : path = _gpioBasePath + chip.toString(),
        line = -1,
        direction = config.direction {
    var tuple =
        _openNameAdvancedGPIO(_gpioBasePath + chip.toString(), name, config);
    _gpioHandle = tuple.$1;
    _freeList = tuple.$2;
  }
  static (Pointer<Void>, List<Pointer>) _openNameAdvancedGPIO(
      String path, String name, GPIOconfig config) {
    var gpioHandle = _nativeGPIOnew();
    if (gpioHandle == nullptr) {
      return throw GPIOexception(GPIOerrorCode.gpioErrorOpen, openError);
    }
    var nativePath = path.toNativeUtf8();
    var nativeName = name.toNativeUtf8();
    var nativeConfig = config._toNative();
    try {
      _checkError(_nativeGPIOopenNameAdvanced(
          gpioHandle, nativePath, nativeName, nativeConfig));
    } catch (_) {
      _nativeGPIOfree(gpioHandle);
      malloc.free(nativeConfig.ref.label);
      malloc.free(nativeConfig);
      malloc.free(nativePath);
      malloc.free(nativeName);
      rethrow;
    }
    return (
      gpioHandle,
      [nativeConfig.ref.label, nativeConfig, nativePath, nativeName]
    );
  }

  /// Opens the sysfs GPIO with the specified [line] and [direction].
  GPIO.sysfs(this.line, this.direction)
      : chip = -1,
        path = '',
        name = '',
        _gpioHandle = _openSysfsGPIO(line, direction);

  /// Duplicates an existing [GPIO] from a JSON string. This special constructor
  /// is used to transfer an existing [GPIO] to an isolate.
  GPIO.isolate(String json)
      : chip = jsonMap(json)['chip'] as int,
        line = jsonMap(json)['line'] as int,
        name = jsonMap(json)['name'] as String,
        path = jsonMap(json)['path'] as String,
        direction = GPIOdirection.values[jsonMap(json)['direction'] as int],
        _gpioHandle = Pointer<Void>.fromAddress(jsonMap(json)['handle'] as int);

  static Pointer<Void> _openSysfsGPIO(int line, GPIOdirection direction) {
    var gpioHandle = _nativeGPIOnew();
    if (gpioHandle == nullptr) {
      return throw GPIOexception(
          GPIOerrorCode.gpioErrorOpen, 'Error opening GPIO interface');
    }
    _checkError(_nativeGPIOopenSysfs(gpioHandle, line, direction.index));
    return gpioHandle;
  }

  /// Polls multiple GPIOs for an edge event configured with [GPIO.setGPIOedge].
  /// For character device GPIOs, the edge event should be consumed with
  /// [GPIO.readEvent]. For sysfs GPIOs, the edge event should be consumed
  /// with [GPIO.read]. [timeoutMillis] can be positive for a timeout
  /// in milliseconds, zero for a non-blocking poll, or
  /// negative for a blocking poll. Returns a [PollMultipleEvent()]
  static PollMultipleEvent pollMultiple(List<GPIO> gpios, int timeoutMillis) {
    final ptr = malloc<Pointer<Void>>(gpios.length);
    final result = malloc<Int8>(gpios.length);
    try {
      var index = 0;
      for (var g in gpios) {
        g._checkStatus();
        ptr[index++] = g._gpioHandle;
      }
      _checkError(
          _nativeGPIOmultiplePoll(ptr, gpios.length, timeoutMillis, result));

      var list = List<bool>.filled(gpios.length, false);
      var counter = 0;
      for (var i = 0; i < gpios.length; ++i) {
        list[i] = result[i] == 1 ? true : false;
        if (list[i]) {
          ++counter;
        }
      }
      return PollMultipleEvent(gpios, counter, list);
    } finally {
      malloc.free(ptr);
      malloc.free(result);
    }
  }

  /// Sets the state of the GPIO to [value].
  void write(bool value) {
    _checkStatus();
    _checkError(_nativeGPIOwrite(_gpioHandle, value ? 1 : 0));
  }

  /// Reads the state of the GPIO line.
  bool read() {
    return _getBoolValue(_nativeGPIOread);
  }

  /// Polls a GPIO for the edge event configured with [GPIO.setGPIOedge].
  /// For character device GPIOs, the edge event should be consumed
  /// with [readEvent].
  /// For sysfs GPIOs, the edge event should be consumed with [GPIO.read].
  GPIOpolling poll(int timeoutMillis) {
    _checkStatus();
    return _checkError(_nativeGPIOpoll(_gpioHandle, timeoutMillis)) == 1
        ? GPIOpolling.success
        : GPIOpolling.timeout;
  }

  /// Reads the edge event that occurred with the GPIO.
  /// This method is intended for use with character device GPIOs and is
  /// unsupported by sysfs GPIOs.
  GPIOreadEvent readEvent() {
    _checkStatus();
    var edge = malloc<Int32>(1);
    var time = malloc<Uint64>(1);
    try {
      _checkError(_nativeGPIOReadEvent(_gpioHandle, edge, time));
      return GPIOreadEvent(GPIOedge.values[edge.value], time.value);
    } finally {
      malloc.free(edge);
      malloc.free(time);
    }
  }

  /// Returns the address of the internal handle.
  @override
  int getHandle() {
    return _gpioHandle.address;
  }

  /// Releases all internal native resources.
  void dispose() {
    _checkStatus();
    _invalid = true;
    try {
      _checkError(_nativeGPIOclose(_gpioHandle));
    } finally {
      _nativeGPIOfree(_gpioHandle);
      for (var p in _freeList) {
        malloc.free(p);
      }
    }
  }

  int _getInt32Value(intVoidInt32PtrF f) {
    _checkStatus();
    var data = malloc<Int32>(1);
    try {
      _checkError(f(_gpioHandle, data));
      return data[0];
    } finally {
      malloc.free(data);
    }
  }

  bool _getBoolValue(intVoidInt8PtrF f) {
    _checkStatus();
    var data = malloc<Int8>(1);
    try {
      _checkError(f(_gpioHandle, data));
      return data[0] != 0;
    } finally {
      malloc.free(data);
    }
  }

  /// Returns the property direction of the GPIO.
  GPIOdirection getGPIOdirection() {
    return GPIOdirection.values[_getInt32Value(_nativeGPIOgetDirection)];
  }

  /// Returns the property edge of the GPIO.
  GPIOedge getGPIOedge() {
    return GPIOedge.values[_getInt32Value(_nativeGPIOgetEdge)];
  }

  /// Returns the property bias of the GPIO.
  GPIObias getGPIObias() {
    return GPIObias.values[_getInt32Value(_nativeGPIOgetBias)];
  }

  /// Returns the property drive of the GPIO.
  GPIOdrive getGPIOdrive() {
    return GPIOdrive.values[_getInt32Value(_nativeGPIOgetDrive)];
  }

  /// Returns if the GPIO line is inverted,
  bool getGPIOinverted() {
    return _getBoolValue(_nativeGPIOgetInverted);
  }

  /// Sets the [direction] of the GPIO.
  void setGPIOdirection(GPIOdirection direction) {
    _checkStatus();
    _checkError(_nativeGPIOsetDirection(_gpioHandle, direction.index));
  }

  /// Sets the [edge] of the GPIO.
  void setGPIOedge(GPIOedge edge) {
    _checkStatus();
    _checkError(_nativeGPIOsetEdge(_gpioHandle, edge.index));
  }

  /// Sets the [bias] of the GPIO.
  void setGPIObias(GPIObias bias) {
    _checkStatus();
    _checkError(_nativeGPIOsetBias(_gpioHandle, bias.index));
  }

  /// Sets the [drive] of the GPIO.
  void setGPIOdrive(GPIOdrive drive) {
    _checkStatus();
    _checkError(_nativeGPIOsetDrive(_gpioHandle, drive.index));
  }

  /// Inverts the GPIO line.
  void setGPIOinverted(bool inverted) {
    _checkStatus();
    _checkError(_nativeGPIOsetInverted(_gpioHandle, inverted == true ? 1 : 0));
  }

  /// Returns the line of the GPIO handle was opened with.
  int getLine() {
    _checkStatus();
    return _nativeGPIOline(_gpioHandle);
  }

  /// Returns the native line file descriptor of the GPIO handle.
  int getGPIOfd() {
    _checkStatus();
    return _nativeGPIOfd(_gpioHandle);
  }

  /// Returns the GPIO chip file descriptor of the GPIO handle.
  /// This method is intended for use with character device GPIOs and is
  /// unsupported by sysfs GPIOs.
  int getGPIOchipFD() {
    _checkStatus();
    return _nativeGPIOchipFd(_gpioHandle);
  }

  /// Returns the line name of the GPIO.
  /// This method is intended for use with character device GPIOs and always
  /// returns the empty string for sysfs GPIOs.
  String getGPIOname() {
    return _getString(_nativeGPIOname);
  }

  /// Returns the line consumer label of the GPIO.
  /// This method is intended for use with character device GPIOs and always
  /// returns the empty string for sysfs GPIOs.
  String getGPIOlabel() {
    return _getString(_nativeGPIOlabel);
  }

  /// Returns the label of the GPIO chip associated with the GPIO.
  String getGPIOchipName() {
    return _getString(_nativeGPIOchipName);
  }

  /// Returns the label of the GPIO chip associated with the GPIO.
  String getGPIOchipLabel() {
    return _getString(_nativeGPIOchipLabel);
  }

  String _getString(intVoidUtf8IntF f) {
    _checkStatus();
    var data = malloc<Int8>(bufferLen).cast<Utf8>();
    try {
      _checkError(f(_gpioHandle, data, bufferLen));
      return data.toDartString();
    } finally {
      malloc.free(data);
    }
  }

  /// Returns a string representation of the native GPIO handle.
  String getGPIOinfo() {
    return _getString(_nativeGPIOinfo);
  }

  @override
  IsolateAPI fromJson(String json) {
    return GPIO.isolate(json);
  }

  @override
  void setHandle(int handle) {
    _gpioHandle = Pointer<Void>.fromAddress(handle);
  }
}
