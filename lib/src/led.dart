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

/// Led error code
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

/// Converts the native error code [value] to [LedErrorCode].
LedErrorCode getLedErrorCode(int value) {
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

// led_t* dart_led_open(const char *path)
typedef _dart_led_open = Pointer<Void> Function(Pointer<Utf8> path);
typedef _LedOpen = Pointer<Void> Function(Pointer<Utf8> path);
final _nativeOpen = _peripheryLib
    .lookup<NativeFunction<_dart_led_open>>('dart_led_open')
    .asFunction<_LedOpen>();

// int dart_led_dispose(led_t *led)
typedef _dart_led_dispose = Int32 Function(Pointer<Void> handle);
typedef _LedDispose = int Function(Pointer<Void> handle);
final _nativeDispose = _peripheryLib
    .lookup<NativeFunction<_dart_led_dispose>>('dart_led_dispose')
    .asFunction<_LedDispose>();

// int dart_led_errno(led_t *led)
typedef _dart_led_errno = Int32 Function(Pointer<Void> handle);
typedef _LedErrno = int Function(Pointer<Void> handle);
final _nativeErrno = _peripheryLib
    .lookup<NativeFunction<_dart_led_errno>>('dart_led_errno')
    .asFunction<_LedErrno>();

// const char *dart_led_errmsg(led_t *led)
typedef _dart_led_errmsg = Pointer<Utf8> Function(Pointer<Void> handle);
typedef _LedErrmsg = Pointer<Utf8> Function(Pointer<Void> handle);
final _nativeErrmsg = _peripheryLib
    .lookup<NativeFunction<_dart_led_errmsg>>('dart_led_errmsg')
    .asFunction<_LedErrmsg>();

// int dart_led_write(led_t *gled, bool value)
typedef _dart_led_write = Int32 Function(Pointer<Void>, Int32 value);
typedef _LedWrite = int Function(Pointer<Void>, int value);
final _nativeWrite = _peripheryLib
    .lookup<NativeFunction<_dart_led_write>>('dart_led_write')
    .asFunction<_LedWrite>();

// int dart_led_read(led_t *led)
typedef _dart_led_read = Int32 Function(Pointer<Void>);
typedef _LedRead = int Function(Pointer<Void>);
final _nativeRead = _peripheryLib
    .lookup<NativeFunction<_dart_led_read>>('dart_led_read')
    .asFunction<_LedRead>();

// int dart_led_get_brightness(led_t *led)
typedef _dart_led_get_brightness = Int32 Function(Pointer<Void>);
typedef _LedGetBrightness = int Function(Pointer<Void>);
final _nativeBrightness = _peripheryLib
    .lookup<NativeFunction<_dart_led_get_brightness>>('dart_led_get_brightness')
    .asFunction<_LedGetBrightness>();

// int dart_led_set_brightness(led_t *led,int value)
typedef _dart_led_set_brightness = Int32 Function(Pointer<Void>, Int32 value);
typedef _LedSetBrightness = int Function(Pointer<Void>, int value);
final _nativeSetBrightness = _peripheryLib
    .lookup<NativeFunction<_dart_led_set_brightness>>('dart_led_set_brightness')
    .asFunction<_LedSetBrightness>();

// int dart_led_get_max_brightness(led_t *led)
typedef _dart_led_get_max_brightness = Int32 Function(Pointer<Void>);
typedef _LedGetMaxBrightness = int Function(Pointer<Void>);
final _nativeMaxBrightness = _peripheryLib
    .lookup<NativeFunction<_dart_led_get_max_brightness>>(
        'dart_led_get_max_brightness')
    .asFunction<_LedGetMaxBrightness>();

// char *dart_led_info(led_t *led)
typedef _dart_led_info = Pointer<Utf8> Function(Pointer<Void> handle);
typedef _LedInfo = Pointer<Utf8> Function(Pointer<Void> handle);
final _nativeInfo = _peripheryLib
    .lookup<NativeFunction<_dart_led_info>>('dart_led_info')
    .asFunction<_LedInfo>();

// char *dart_led_name(led_t *led)
typedef _dart_led_name = Pointer<Utf8> Function(Pointer<Void> handle);
typedef _LedName = Pointer<Utf8> Function(Pointer<Void> handle);
final _nativeName = _peripheryLib
    .lookup<NativeFunction<_dart_led_name>>('dart_led_name')
    .asFunction<_LedName>();

int _checkError(int value) {
  if (value < 0) {
    LedErrorCode errorCode = getLedErrorCode(value);
    throw LedException(errorCode, errorCode.toString());
  }
  return value;
}

String _getErrmsg(Pointer<Void> handle) {
  return Utf8.fromUtf8(_nativeErrmsg(handle));
}

// Led exception
class LedException implements Exception {
  final LedErrorCode errorCode;
  final String errorMsg;
  LedException(this.errorCode, this.errorMsg);
  LedException.errorCode(int code, Pointer<Void> handle)
      : errorCode = getLedErrorCode(code),
        errorMsg = _getErrmsg(handle);
  @override
  String toString() => errorMsg;
}

final DynamicLibrary _peripheryLib = getPeripheryLib();

/// LED wrapper functions for Linux userspace sysfs LEDs.
class Led {
  final String name;
  Pointer<Void> _ledHandle;
  bool _invalid = false;

  /// Open the sysfs LED with the specified name.
  ///
  /// 'ls /sys/class/leds/' to list all available leds.
  Led(this.name) {
    _ledHandle = _checkHandle(_nativeOpen(Utf8.toUtf8(name)));
  }

  void _checkStatus() {
    if (_invalid) {
      throw LedException(LedErrorCode.LED_ERROR_CLOSE,
          'Led interface has the status released.');
    }
  }

  Pointer<Void> _checkHandle(Pointer<Void> handle) {
    // handle 0 indicates an internal error
    if (handle.address == 0) {
      throw LedException(LedErrorCode.LED_ERROR_OPEN, "Error opening led");
    }
    return handle;
  }

  /// Sets the state of the led to [value].
  void write(bool value) {
    _checkStatus();
    _checkError(_nativeWrite(_ledHandle, value ? 1 : 0));
  }

  /// Reads the state of the led.
  bool read() {
    _checkStatus();
    int error = _nativeRead(_ledHandle);
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
    final Pointer<Utf8> ptr = _nativeInfo(_ledHandle);
    if (ptr.address == 0) {
      // throw an exception
      _checkError(getErrno());
      return "?";
    }
    String text = Utf8.fromUtf8(ptr);
    free(ptr);
    return text;
  }

  /// Returns the name of the led.
  String getLedName() {
    _checkStatus();
    final Pointer<Utf8> ptr = _nativeName(_ledHandle);
    if (ptr.address == 0) {
      // throw an exception
      _checkError(getErrno());
      return "?";
    }
    String name = Utf8.fromUtf8(ptr);
    free(ptr);
    return name;
  }
}
