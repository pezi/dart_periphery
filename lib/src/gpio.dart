// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/vsergeev/c-periphery/blob/master/docs/gpio.md
// https://github.com/vsergeev/c-periphery/blob/master/src/gpio.c
// https://github.com/vsergeev/c-periphery/blob/master/src/gpio.h
// https://github.com/dart-lang/samples/tree/master/ffi

import 'dart:ffi';
import 'library.dart';
import 'package:ffi/ffi.dart';
import 'signature.dart';

enum _GPIOproperties {
  DIRECTION,
  EDGE,
  BIAS,
  DRIVE,
  INVERTED,
  GPIO_LINE,
  GPIO_FD,
  GPIO_CHIP_FD
}

enum _GPIOtextProperty {
  GPIO_NAME,
  GPIO_LABEL,
  GPIO_CHIP_NAME,
  GPIO_CHIP_LABEL,
  GPIO_INFO
}

/// Result codes of the [GPIO.poll()].
enum GPIOpolling { SUCCESS, TIMEOUT }

/// Mapped native GPIO error codes with the same index, but different leading sign.
enum GPIOerrorCode {
  /// Error code for not able to map the native C enum
  ERROR_CODE_NOT_MAPPABLE,

  ///  Invalid arguments
  GPIO_ERROR_ARG,

  /// Opening GPIO
  GPIO_ERROR_OPEN,

  /// Line name not found
  GPIO_ERROR_NOT_FOUND,

  /// Querying GPIO attributes
  GPIO_ERROR_QUERY,

  /// Configuring GPIO attributes
  GPIO_ERROR_CONFIGURE,

  /// Unsupported attribute or operation
  GPIO_ERROR_UNSUPPORTED,

  /// Invalid operation
  GPIO_ERROR_INVALID_OPERATION,

  /// Reading/writing GPIO
  GPIO_ERROR_IO,

  /// Closing GPIO
  GPIO_ERROR_CLOSE,
}

/// GPIO input/output direction
enum GPIOdirection {
  ///  Input
  GPIO_DIR_IN,

  /// Output, initialized to low
  GPIO_DIR_OUT,

  /// output, initialized to low
  GPIO_DIR_OUT_LOW,

  /// output, initialized to high
  GPIO_DIR_OUT_HIGH
}

/// GPIO edge
enum GPIOedge {
  /// No interrupt edge
  GPIO_EDGE_NONE,

  /// Rising edge 0 -> 1
  GPIO_EDGE_RISING,

  /// Falling edge 1 -> 0
  GPIO_EDGE_FALLING,

  /// Both edges X -> !X
  GPIO_EDGE_BOTH
}

/// GPIO bias
enum GPIObias {
  /// Default line bias
  GPIO_BIAS_DEFAULT,

  /// Pull-up
  GPIO_BIAS_PULL_UP,

  /// Pull-down *
  GPIO_BIAS_PULL_DOWN,

  /// Disable line bias
  GPIO_BIAS_DISABLE,
}

/// GPIO drive
enum GPIOdrive {
  /// Default line drive (push-pull)
  GPIO_DRIVE_DEFAULT,

  /// Open drain
  GPIO_DRIVE_OPEN_DRAIN,

  ///  Open source
  GPIO_DRIVE_OPEN_SOURCE,
}

// map native struct
//
// typedef struct read_event
// {
//     int error_code;
//     gpio_edge_t edge;
//     uint64_t timestamp;
// } read_event_t;

class _ReadEvent extends Struct {
  @Int32()
  int error_code;
  @Int32()
  int edge;
  @Int32()
  int timestamp;
  factory _ReadEvent.allocate() => allocate<_ReadEvent>().ref;
}

/// Result of the [GPIO.readEvent()].
class GPIOreadEvent {
  /// edge value
  final GPIOedge edge;
  // event time reported by Linux, in nanoseconds.
  final int nanoSeconds;
  GPIOreadEvent(_ReadEvent event)
      : edge = GPIOedge.values[event.edge],
        nanoSeconds = event.timestamp;
}

/// Helper class for [GPIO.pollMultiple].
///
/// [PollMultipleEvent.eventOccured] will be populated with true for the
/// corresponding GPIO in the gpios array if an edge event occurred, or false if none occurred.
/// Returns the number eventCounter of GPIOs for which an edge event occurred.
/// See for details [GPIO.pollMultiple]
class PollMultipleEvent {
  final List<GPIO> gpios;
  final int eventCounter;
  final List<bool> eventOccured;
  PollMultipleEvent(this.gpios, this.eventCounter, this.eventOccured);

  /// Checks if the timeout is reached.
  bool isTimeoutReached() {
    return eventCounter == 0 ? true : false;
  }

  /// Checks if an edge event occured for a [gpio]
  bool hasEventOccured(GPIO gpio) {
    var index = 0;
    for (var g in gpios) {
      if (g._gpioHandle == gpio._gpioHandle) {
        return eventOccured[index];
      }
      ++index;
    }
    return false;
  }
}

// map native struct
//
// typedef struct poll_multiple
// {
//    int error_code;
//    bool *ready;
// } poll_multiple_t;
//
class _PoolMultiple extends Struct {
  @Int32()
  int result;
  Pointer<Int8> ready;
}

/// Configuration class for [GPIO.advanced()] and [GPIO.nameAdvanced()].
class GPIOconfig {
  GPIOdirection direction;
  GPIOedge edge;
  GPIObias bias;
  GPIOdrive drive;
  bool inverted;
  // GPIO name,
  String label;
  GPIOconfig()
      : direction = GPIOdirection.GPIO_DIR_IN,
        edge = GPIOedge.GPIO_EDGE_NONE,
        bias = GPIObias.GPIO_BIAS_DEFAULT,
        drive = GPIOdrive.GPIO_DRIVE_DEFAULT,
        inverted = false,
        label = '';
}

/// GPIO exception
class GPIOexception implements Exception {
  final GPIOerrorCode errorCode;
  final String errorMsg;
  GPIOexception(this.errorCode, this.errorMsg);
  GPIOexception.errorCode(int code, Pointer<Void> handle)
      : errorCode = getGPIOerrorCode(code),
        errorMsg = _getErrmsg(handle);
  @override
  String toString() => errorMsg;
}

/// Converts the native error code [value] to [GPIOerrorCode].
GPIOerrorCode getGPIOerrorCode(int value) {
  // must be negative
  if (value >= 0) {
    return GPIOerrorCode.ERROR_CODE_NOT_MAPPABLE;
  }
  value = -value;

  // check range
  if (value > GPIOerrorCode.GPIO_ERROR_CLOSE.index) {
    return GPIOerrorCode.ERROR_CODE_NOT_MAPPABLE;
  }

  return GPIOerrorCode.values[value];
}

final DynamicLibrary _peripheryLib = getPeripheryLib();

// gpio_t *dart_gpio_open(const char *path, int line, int direction)
typedef _dart_gpio_open = Pointer<Void> Function(
    Pointer<Utf8> path, Int32 line, Int32 direction);
typedef _GPIOopen = Pointer<Void> Function(
    Pointer<Utf8> path, int line, int direction);
final _nativeOpen = _peripheryLib
    .lookup<NativeFunction<_dart_gpio_open>>('dart_gpio_open')
    .asFunction<_GPIOopen>();

// gpio_t *dart_gpio_open_advanced(const char *path, int line, int direction, int edge, int bias, int drive, int inverted, const char *label)
typedef _dart_gpio_open_advanced = Pointer<Void> Function(
    Pointer<Utf8> path,
    Int32 line,
    Int32 direction,
    Int32 edge,
    Int32 bias,
    Int32 drive,
    Int32 inverted,
    Pointer<Utf8> label);
typedef _GPIOopenAdvanced = Pointer<Void> Function(
    Pointer<Utf8> path,
    int line,
    int direction,
    int edge,
    int bias,
    int drive,
    int inverted,
    Pointer<Utf8> label);
final _nativeOpenAdvanced = _peripheryLib
    .lookup<NativeFunction<_dart_gpio_open_advanced>>('dart_gpio_open_advanced')
    .asFunction<_GPIOopenAdvanced>();

// gpio_t *dart_gpio_open_name_advanced(const char *path, const char *name, int direction, int edge, int bias, int drive, int inverted, const char *label)
typedef _dart_gpio_open_name_advanced = Pointer<Void> Function(
    Pointer<Utf8> path,
    Pointer<Utf8> name,
    Int32 direction,
    Int32 edge,
    Int32 bias,
    Int32 drive,
    Int32 inverted,
    Pointer<Utf8> label);
typedef _GPIOopenNameAdvanced = Pointer<Void> Function(
    Pointer<Utf8> path,
    Pointer<Utf8> name,
    int direction,
    int edge,
    int bias,
    int drive,
    int inverted,
    Pointer<Utf8> label);
final _nativeOpenNameAdvanced = _peripheryLib
    .lookup<NativeFunction<_dart_gpio_open_name_advanced>>(
        'dart_gpio_open_name_advanced')
    .asFunction<_GPIOopenNameAdvanced>();

// gpio_t *dart_gpio_open_name(const char *path, const char *name, int direction)
typedef _dart_gpio_open_name = Pointer<Void> Function(
    Pointer<Utf8> path, Pointer<Utf8> name, Int32 direction);
typedef _GPIOopenName = Pointer<Void> Function(
    Pointer<Utf8> path, Pointer<Utf8> name, int direction);
final _nativeOpenName = _peripheryLib
    .lookup<NativeFunction<_dart_gpio_open_name>>('dart_gpio_open_name')
    .asFunction<_GPIOopenName>();

// gpio_t *dart_gpio_open_sysfs(int line, int direction)
typedef _dart_gpio_open_sysfs = Pointer<Void> Function(
    Pointer<Utf8> path, Int32 line, Int32 direction);
typedef _GPIOopenSysfs = Pointer<Void> Function(
    Pointer<Utf8> path, int line, int direction);
final _nativeOpenSysfs = _peripheryLib
    .lookup<NativeFunction<_dart_gpio_open_sysfs>>('dart_gpio_open_sysfs')
    .asFunction<_GPIOopenSysfs>();

// int dart_gpio_write(gpio_t *gpio, bool value)
final _nativeWrite = intVoidIntM('dart_gpio_write');

// int dart_gpio_read(gpio_t *gpio)
final _nativeRead = intVoidM('dart_gpio_read');

// int dart_gpio_dispose(gpio_t *gpio)
final _nativeDispose = intVoidM('dart_gpio_dispose');

// int dart_gpio_errno(gpio_t *gpio);
final _nativeErrno = intVoidM('dart_gpio_errno');

// const char *dart_gpio_errmsg(gpio_t *gpio)
final _nativeErrmsg = utf8VoidM('dart_gpio_errmsg');

// int dart_gpio_get_property(gpio_t *gpio, GPIOproperty_t property));
final _nativeGetGPIOproperty = intVoidIntM('dart_gpio_get_property');

// int dart_gpio_set_property(gpio_t *gpio, GPIOproperty_t property, int value)
typedef _dart_gpio_set_property = Int32 Function(
    Pointer<Void>, Int32 gpioProperty, Int32 value);
typedef _GPIOsetProperty = int Function(
    Pointer<Void>, int gpioProperty, int value);
final _nativeSetGPIOproperty = _peripheryLib
    .lookup<NativeFunction<_dart_gpio_set_property>>('dart_gpio_set_property')
    .asFunction<_GPIOsetProperty>();

// read_event_t *dart_gpio_read_event(gpio_t *gpio, int timeout_ms)
typedef _dart_gpio_read_event = Pointer<_ReadEvent> Function(
    Pointer<Void>, Int32 timeoutMillis);
typedef _GPIOreadEvent = Pointer<_ReadEvent> Function(
    Pointer<Void>, int timeoutMillis);
final _nativeReadEvent = _peripheryLib
    .lookup<NativeFunction<_dart_gpio_read_event>>('dart_gpio_read_event')
    .asFunction<_GPIOreadEvent>();

// int dart_gpio_poll(gpio_t *gpio, int timeout_ms)
final _nativePoll = intVoidIntM('dart_gpio_poll');

// poll_multiple_t *dart_gpio_poll_multiple(gpio_t **gpios, size_t count, int timeout_ms)
typedef _dart_gpio_multiple_poll = Pointer<_PoolMultiple> Function(
    Pointer<Pointer<Void>> gpios, Int32 count, Int32 timoutMillis);
typedef _GPIOmultiplePoll = Pointer<_PoolMultiple> Function(
    Pointer<Pointer<Void>> gpios, int count, int timeoutMillis);
final _nativeMultiplePoll = _peripheryLib
    .lookup<NativeFunction<_dart_gpio_multiple_poll>>('dart_gpio_multiple_poll')
    .asFunction<_GPIOmultiplePoll>();

// char *dart_gpio_get_text_property(gpio_t *gpio, GPIOtextProperty_t property)
final _nativeGetTextProperty = utf8VoidIntM('dart_gpio_get_text_property');

String _getErrmsg(Pointer<Void> handle) {
  return Utf8.fromUtf8(_nativeErrmsg(handle));
}

int _checkError(int value) {
  if (value < 0) {
    var errorCode = getGPIOerrorCode(value);
    throw GPIOexception(errorCode, errorCode.toString());
  }
  return value;
}

/// GPIO wrapper functions for Linux userspace character device gpio-cdev and sysfs GPIOs.
///
/// Character device GPIOs were introduced in Linux kernel version 4.8. If the toolchain used to compiled
/// c-periphery contains Linux kernel headers older than 4.8 (i.e. linux/gpio.h is missing), then only legacy
/// sysfs GPIOs will be supported.
class GPIO {
  static String _gpioBasePath = '/dev/gpiochip';

  /// GPIO chip device path e.g. /dev/gpiochip0
  final String path;

  /// GPIO chip number, e.g. 0 for /dev/gpiochip0
  final int chip;

  /// GPIO line number, is -1 if  [GPIO.name] is used
  final int line;

  /// input/ouput GPIO direction
  final GPIOdirection direction;

  /// GPIO name, is empty if [GPIO.line] is used
  final String name;
  Pointer<Void> _gpioHandle;
  bool _invalid = false;

  /// Sets an alternative [chipBasePath], default value is '/dev/gpiochip'
  static void setBaseGPIOpath(String chipBasePath) {
    _gpioBasePath = chipBasePath;
  }

  Pointer<Void> _checkHandle(Pointer<Void> handle) {
    // handle 0 indicates an internal error
    if (handle.address == 0) {
      throw GPIOexception(GPIOerrorCode.GPIO_ERROR_OPEN, 'Error opening GPIO');
    }
    return handle;
  }

  void _checkStatus() {
    if (_invalid) {
      throw GPIOexception(GPIOerrorCode.GPIO_ERROR_INVALID_OPERATION,
          'GPIO line has the status released!');
    }
  }

  /// Returns the libc errno of the last failure that occurred.
  int getErrno() {
    _checkStatus();
    return _nativeErrno(_gpioHandle);
  }

  /// Opens the character device GPIO with the specified GPIO [line] and [direction] at
  /// the default character device GPIO with the [chip] number. The default
  /// chip number is 0, with the path /dev/gpiochip0.
  ///
  /// Use [GPIO.setBaseGPIOpath] to change the default character device path.
  GPIO(this.line, this.direction, [this.chip = 0])
      : path = _gpioBasePath + chip.toString(),
        name = '' {
    _gpioHandle =
        _checkHandle(_nativeOpen(Utf8.toUtf8(path), line, direction.index));
  }

  /// Opens the character device GPIO with the specified GPIO [name] and [direction] at the default character
  /// device GPIO with the [chip] number. The default chip number is 0, with the path /dev/gpiochip0. Use [GPIO.setBaseGPIOpath]
  /// to change the default character device path.
  GPIO.name(this.name, this.direction, [this.chip = 0])
      : path = _gpioBasePath + chip.toString(),
        line = -1 {
    _gpioHandle = _checkHandle(
        _nativeOpenName(Utf8.toUtf8(path), Utf8.toUtf8(name), direction.index));
  }

  /// Opens the character device GPIO with the specified GPIO [line] and configuration [config] at the default character
  /// device GPIO with the [chip] number. The default chip numer is 0, with the path /dev/gpiochip0. Use [GPIO.setBaseGPIOpath]
  /// to change the default character device path.
  GPIO.advanced(this.line, GPIOconfig config, [this.chip = 0])
      : path = _gpioBasePath + chip.toString(),
        name = '',
        direction = config.direction {
    _gpioHandle = _checkHandle(_nativeOpenAdvanced(
        Utf8.toUtf8(path),
        line,
        config.direction.index,
        config.edge.index,
        config.bias.index,
        config.drive.index,
        config.inverted ? 1 : 0,
        Utf8.toUtf8(config.label)));
  }

  /// Opens the character device GPIO with the specified GPIO [name] and the configuration [config] at the default character
  /// device GPIO with the [chip] number. The default chip numer is 0, with the path /dev/gpiochip0. Use [GPIO.setBaseGPIOpath]
  /// to change the default character device path.
  GPIO.nameAdvanced(this.name, GPIOconfig config, [this.chip = 0])
      : path = _gpioBasePath + chip.toString(),
        line = -1,
        direction = config.direction {
    _gpioHandle = _checkHandle(_nativeOpenNameAdvanced(
        Utf8.toUtf8(path),
        Utf8.toUtf8(name),
        config.direction.index,
        config.edge.index,
        config.bias.index,
        config.drive.index,
        config.inverted ? 1 : 0,
        Utf8.toUtf8(config.label)));
  }

  /// Opens the sysfs GPIO with the specified [line] and [direction].
  GPIO.sysfs(this.line, this.direction)
      : chip = -1,
        path = '',
        name = '' {
    _gpioHandle = _checkHandle(
        _nativeOpenSysfs(Utf8.toUtf8(path), line, direction.index));
  }

  /// Polls multiple GPIOs for an edge event configured with [GPIO.setGPIOedge].
  /// For character device GPIOs, the edge event should be consumed with [GPIO.readEvent]. For sysfs GPIOs,
  /// the edge event should be consumed with [GPIO.read].
  /// [timeoutMillis] can be positive for a timeout in milliseconds, zero for a non-blocking poll, or
  /// negative for a blocking poll. Returns a [PollMultipleEvent()]
  static PollMultipleEvent pollMultiple(List<GPIO> gpios, int timeoutMillis) {
    final ptr = allocate<Pointer<Void>>(count: gpios.length);
    var index = 0;
    for (var g in gpios) {
      g._checkStatus();
      ptr.elementAt(index++).value = g._gpioHandle;
    }
    var result = _nativeMultiplePoll(ptr, gpios.length, timeoutMillis);
    try {
      _checkError(result.ref.result);
      var list = <bool>[];
      for (var i = 0; i < gpios.length; ++i) {
        list.add(result.ref.ready.elementAt(index).value == 1 ? true : false);
      }
      return PollMultipleEvent(gpios, result.ref.result, list);
    } finally {
      free(ptr);
      if (result.ref.ready.address != 0) {
        free(result.ref.ready);
      }
      free(result);
    }
  }

  /// Sets the state of the GPIO to [value].
  void write(bool value) {
    _checkStatus();
    _checkError(_nativeWrite(_gpioHandle, value ? 1 : 0));
  }

  /// Reads the state of the GPIO line.
  bool read() {
    _checkStatus();
    var error = _nativeRead(_gpioHandle);
    _checkError(error);
    return error == 0 ? false : true;
  }

  /// Polls a GPIO for the edge event configured with [GPIO.setGPIOedge].
  /// For character device GPIOs, the edge event should be consumed with gpio_read_event().
  /// For sysfs GPIOs, the edge event should be consumed with [GPIO.read].
  GPIOpolling poll(int timeoutMillis) {
    _checkStatus();
    var error = _nativePoll(_gpioHandle, timeoutMillis);
    _checkError(error);
    return error == 0 ? GPIOpolling.SUCCESS : GPIOpolling.TIMEOUT;
  }

  /// Reads the edge event that occurred with the GPIO.
  /// This method is intended for use with character device GPIOs and is unsupported by sysfs GPIOs.
  GPIOreadEvent readEvent(int timeoutMillis) {
    _checkStatus();
    var event = _nativeReadEvent(_gpioHandle, timeoutMillis);
    try {
      _checkError(event.ref.error_code);
      var result = GPIOreadEvent(event.ref);
      return result;
    } finally {
      free(event);
    }
  }

  /// Releases all interal native resoures.
  void dispose() {
    _checkStatus();
    _invalid = true;
    _checkError(_nativeDispose(_gpioHandle));
  }

  /// Returns the property direction of the GPIO.
  GPIOdirection getGPIOdirection() {
    _checkStatus();
    return GPIOdirection.values[_checkError(
        _nativeGetGPIOproperty(_gpioHandle, _GPIOproperties.DIRECTION.index))];
  }

  /// Returns the property edge of the GPIO.
  GPIOedge getGPIOedge() {
    _checkStatus();
    return GPIOedge.values[_checkError(
        _nativeGetGPIOproperty(_gpioHandle, _GPIOproperties.EDGE.index))];
  }

  /// Returns the property bias of the GPIO.
  GPIObias getGPIObias() {
    _checkStatus();
    return GPIObias.values[_checkError(
        _nativeGetGPIOproperty(_gpioHandle, _GPIOproperties.BIAS.index))];
  }

  /// Returns the property drive of the GPIO.
  GPIOdrive getGPIOdrive() {
    _checkStatus();
    return GPIOdrive.values[_checkError(
        _nativeGetGPIOproperty(_gpioHandle, _GPIOproperties.DRIVE.index))];
  }

  /// Returns if the GPIO line is inverted,
  bool isInverted() {
    _checkStatus();
    return _checkError(_nativeGetGPIOproperty(
                _gpioHandle, _GPIOproperties.INVERTED.index)) ==
            1
        ? true
        : false;
  }

  /// Sets the [direction] of the GPIO.
  void setGPIOdirection(GPIOdirection direction) {
    _checkStatus();
    _checkError(_nativeSetGPIOproperty(
        _gpioHandle, _GPIOproperties.DIRECTION.index, direction.index));
  }

  /// Sets the [edge] of the GPIO.
  void setGPIOedge(GPIOedge edge) {
    _checkStatus();
    _checkError(_nativeSetGPIOproperty(
        _gpioHandle, _GPIOproperties.EDGE.index, edge.index));
  }

  /// Sets the [bias] of the GPIO.
  void setGPIObias(GPIObias bias) {
    _checkStatus();
    _checkError(_nativeSetGPIOproperty(
        _gpioHandle, _GPIOproperties.BIAS.index, bias.index));
  }

  /// Sets the [drive] of the GPIO.
  void setGPIOdrive(GPIOdrive drive) {
    _checkStatus();
    _checkError(_nativeSetGPIOproperty(
        _gpioHandle, _GPIOproperties.DRIVE.index, drive.index));
  }

  /// Inverts the GPIO line.
  void setInverted(bool inverted) {
    _checkStatus();
    _nativeSetGPIOproperty(
        _gpioHandle, _GPIOproperties.INVERTED.index, inverted == true ? 1 : 0);
  }

  /// Returns the line the GPIO handle was opened with.
  int getLine() {
    _checkStatus();
    return _checkError(
        _nativeGetGPIOproperty(_gpioHandle, _GPIOproperties.GPIO_LINE.index));
  }

  /// Returns the native line file descriptor of the GPIO handle.
  int getGPIOfd() {
    _checkStatus();
    return _checkError(
        _nativeGetGPIOproperty(_gpioHandle, _GPIOproperties.GPIO_FD.index));
  }

  /// Returns the GPIO chip file descriptor of the GPIO handle.
  /// This method is intended for use with character device GPIOs and is unsupported by sysfs GPIOs.
  int getGPIOchipFD() {
    _checkStatus();
    return _checkError(_nativeGetGPIOproperty(
        _gpioHandle, _GPIOproperties.GPIO_CHIP_FD.index));
  }

  String _getTextProperty(_GPIOtextProperty prop) {
    _checkStatus();
    final ptr = _nativeGetTextProperty(_gpioHandle, prop.index);
    if (ptr.address == 0) {
      // throw an exception
      _checkError(getErrno());
      return '?';
    }
    var text = Utf8.fromUtf8(ptr);
    free(ptr);
    return text;
  }

  /// Returns the line name of the GPIO.
  /// This method is intended for use with character device GPIOs and always returns the empty string for sysfs GPIOs.
  String getGPIOname() {
    return _getTextProperty(_GPIOtextProperty.GPIO_NAME);
  }

  /// Returns the line consumer label of the GPIO.
  /// This method is intended for use with character device GPIOs and always returns the empty string for sysfs GPIOs.
  String getGPIOlabel() {
    return _getTextProperty(_GPIOtextProperty.GPIO_LABEL);
  }

  /// Returns the label of the GPIO chip associated with the GPIO.
  String getGPIOchipName() {
    return _getTextProperty(_GPIOtextProperty.GPIO_CHIP_NAME);
  }

  /// Returns the label of the GPIO chip associated with the GPIO.
  String getGPIOchipLabel() {
    return _getTextProperty(_GPIOtextProperty.GPIO_CHIP_LABEL);
  }

  /// Returns a string representation of the native GPIO handle.
  String getGPIOinfo() {
    return _getTextProperty(_GPIOtextProperty.GPIO_INFO);
  }
}
