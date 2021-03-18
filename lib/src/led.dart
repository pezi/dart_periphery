// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/vsergeev/c-periphery/blob/master/docs/led.md
// https://github.com/vsergeev/c-periphery/blob/master/src/led.c
// https://github.com/vsergeev/c-periphery/blob/master/src/led.h
// https://github.com/dart-lang/samples/tree/master/ffi

import 'dart:ffi';
import 'library.dart';
import 'package:ffi/ffi.dart';
import 'signature.dart';

/// [Led] error code
enum LedErrorCode {
  /// Error code for not able to map the native C enum
  ERROR_CODE_NOT_MAPPABLE,

  ///  Invalid arguments */
  LED_ERROR_ARG,

  /// Opening LED
  LED_ERROR_OPEN,

  ///  Querying LED attributes
  LED_ERROR_QUERY,

  /// Reading/writing LED brightness
  LED_ERROR_IO,

  /// Closing LED
  LED_ERROR_CLOSE,
}

// led_t* dart_led_open(const char *path)
typedef _dart_led_open = Pointer<Void> Function(Pointer<Utf8> path);
typedef _LedOpen = Pointer<Void> Function(Pointer<Utf8> path);
final _nativeOpen = _peripheryLib
    .lookup<NativeFunction<_dart_led_open>>('dart_led_open')
    .asFunction<_LedOpen>();

// int dart_led_dispose(led_t *led)
final _nativeDispose = intVoidM('dart_led_dispose');

// int dart_led_errno(led_t *led)
final _nativeErrno = intVoidM('dart_led_errno');

// const char *dart_led_errmsg(led_t *led)
final _nativeErrmsg = utf8VoidM('dart_led_errmsg');

// int dart_led_write(led_t *gled, bool value)
final _nativeWrite = intVoidIntM('dart_led_write');

// int dart_led_read(led_t *led)
final _nativeRead = intVoidM('dart_led_read');

// int dart_led_get_brightness(led_t *led)
final _nativeBrightness = intVoidM('dart_led_get_brightness');

// int dart_led_set_brightness(led_t *led,int value)
final _nativeSetBrightness = intVoidIntM('dart_led_set_brightness');

// int dart_led_get_max_brightness(led_t *led)
final _nativeMaxBrightness = intVoidM('dart_led_get_max_brightness');

// char *dart_led_info(led_t *led)
final _nativeInfo = utf8VoidM('dart_led_info');

// char *dart_led_name(led_t *led)
final _nativeName = utf8VoidM('dart_led_name');

int _checkError(int value) {
  if (value < 0) {
    var errorCode = Led.getLedErrorCode(value);
    throw LedException(errorCode, errorCode.toString());
  }
  return value;
}

String _getErrmsg(Pointer<Void> handle) {
  return _nativeErrmsg(handle).toDartString();
}

/// [Led] exception
class LedException implements Exception {
  final LedErrorCode errorCode;
  final String errorMsg;
  LedException(this.errorCode, this.errorMsg);
  LedException.errorCode(int code, Pointer<Void> handle)
      : errorCode = Led.getLedErrorCode(code),
        errorMsg = _getErrmsg(handle);
  @override
  String toString() => errorMsg;
}

final DynamicLibrary _peripheryLib = getPeripheryLib();

Pointer<Void> _checkHandle(Pointer<Void> handle) {
  // handle 0 indicates an internal error
  if (handle.address == 0) {
    throw LedException(LedErrorCode.LED_ERROR_OPEN, 'Error opening led');
  }
  return handle;
}

/// LED wrapper functions for Linux userspace sysfs LEDs.
class Led {
  final String name;
  final Pointer<Void> _ledHandle;
  bool _invalid = false;

  /// Open the sysfs LED with the specified name.
  ///
  /// 'ls /sys/class/leds/' to list all available leds.
  Led(this.name) : _ledHandle = _checkHandle(_nativeOpen(name.toNativeUtf8()));

  void _checkStatus() {
    if (_invalid) {
      throw LedException(LedErrorCode.LED_ERROR_CLOSE,
          'Led interface has the status released.');
    }
  }

  /// Converts the native error code [value] to [LedErrorCode].
  static LedErrorCode getLedErrorCode(int value) {
    // must be negative
    if (value >= 0) {
      return LedErrorCode.ERROR_CODE_NOT_MAPPABLE;
    }
    value = -value;

    // check range
    if (value > LedErrorCode.LED_ERROR_CLOSE.index) {
      return LedErrorCode.ERROR_CODE_NOT_MAPPABLE;
    }

    return LedErrorCode.values[value];
  }

  /// Sets the state of the led to [value].
  void write(bool value) {
    _checkStatus();
    _checkError(_nativeWrite(_ledHandle, value ? 1 : 0));
  }

  /// Reads the state of the led.
  bool read() {
    _checkStatus();
    var error = _nativeRead(_ledHandle);
    _checkError(error);
    return error == 0 ? false : true;
  }

  /// Releases all interal native resoures.
  void dispose() {
    _checkStatus();
    _invalid = true;
    _checkError(_nativeDispose(_ledHandle));
  }

  /// Returns the libc errno of the last failure that occurred.
  int getErrno() {
    _checkStatus();
    return _nativeErrno(_ledHandle);
  }

  /// Returns the brightness of the led.
  int getBrightness() {
    _checkStatus();
    return _checkError(_nativeBrightness(_ledHandle));
  }

  /// Returns the maximum possible brightness of the led.
  int getMaxBrightness() {
    _checkStatus();
    return _checkError(_nativeMaxBrightness(_ledHandle));
  }

  /// Sets the brightness of the led to [value].
  void setBrightness(int value) {
    _checkStatus();
    _checkError(_nativeSetBrightness(_ledHandle, value));
  }

  /// Returns a string representation of the led handle.
  String getLedInfo() {
    _checkStatus();
    final ptr = _nativeInfo(_ledHandle);
    if (ptr.address == 0) {
      // throw an exception
      _checkError(getErrno());
      return '?';
    }
    var text = ptr.toDartString();
    malloc.free(ptr);
    return text;
  }

  /// Returns the name of the led.
  String getLedName() {
    _checkStatus();
    final ptr = _nativeName(_ledHandle);
    if (ptr.address == 0) {
      // throw an exception
      _checkError(getErrno());
      return '?';
    }
    var name = ptr.toDartString();
    malloc.free(ptr);
    return name;
  }
}
