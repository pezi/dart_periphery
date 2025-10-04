// Copyright (c) 2022,2025 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/vsergeev/c-periphery/blob/master/docs/led.md
// https://github.com/vsergeev/c-periphery/blob/master/src/led.c
// https://github.com/vsergeev/c-periphery/blob/master/src/led.h
// https://github.com/dart-lang/samples/tree/master/ffi

import 'dart:ffi';

import 'package:dart_periphery/dart_periphery.dart';
import 'package:ffi/ffi.dart';

import 'json.dart';
import 'signature.dart';

/// [Led] error code
enum LedErrorCode {
  /// Error code for not able to map the native C enum
  errorCodeNotMappable,

  ///  Invalid arguments */
  ledErrorArg,

  /// Opening LED
  ledErrorOpen,

  ///  Querying LED attributes
  ledErrorQuery,

  /// Reading/writing LED brightness
  ledErrorIO,

  /// Closing LED
  ledErrorClose,
}

// led_t *led_new(void);
final _nativeLedNew = voidPtrVOIDM('led_new');

//int led_open(led_t *led, const char *name);
final _nativeLedOpen = voidVoidUtf8M('led_open');

// int led_close(led_t *led);
final _nativeLedClose = intVoidM('led_close');

//  void led_free(led_t *led);
final _nativeLedFree = voidVoidM('led_free');

// int led_errno(led_t *led);
final _nativeLedErrno = intVoidM('led_errno');

// const char *led_errmsg(led_t *led);
final _nativeLedErrMsg = utf8VoidM('led_errmsg');

// int led_write(led_t *led, bool value);
final _nativeLedWrite = intVoidBoolM('led_write');

// int led_read(led_t *led, bool *value);
final _nativeLedRead = intVoidInt8PtrM('led_read');

// int led_tostring(led_t *led, char *str, size_t len);
final _nativeLedInfo = intVoidUtf8sizeTM('led_tostring');

// int led_name(led_t *led, char *str, size_t len);
final _nativeLedName = intVoidUtf8sizeTM('led_name');

// led_get_brightness(led_t *led, unsigned int *brightness);
final _nativeLedGetBrightness = intVoidInt32PtrM('led_get_brightness');

// led_get_max_brightness(led_t *led, unsigned int *brightness);
final _nativeLedGetMaxBrightness = intVoidInt32PtrM('led_get_max_brightness');

// int led_set_brightness(led_t *led, unsigned int brightness);
final _nativeLedSetBrightness = intVoidIntM('led_set_brightness');

const bufferLen = 256;

int _checkError(int value) {
  if (value < 0) {
    var errorCode = Led.getLedErrorCode(value);
    throw LedException(errorCode, errorCode.toString());
  }
  return value;
}

String _getErrMsg(Pointer<Void> handle) {
  return _nativeLedErrMsg(handle).toDartString();
}

/// [Led] exception
class LedException implements Exception {
  final LedErrorCode errorCode;
  final String errorMsg;
  LedException(this.errorCode, this.errorMsg);
  LedException.errorCode(int code, Pointer<Void> handle)
      : errorCode = Led.getLedErrorCode(code),
        errorMsg = _getErrMsg(handle);
  @override
  String toString() => errorMsg;
}

/// LED wrapper functions for Linux userspace sysfs LEDs.
class Led extends IsolateAPI {
  final String name;
  late Pointer<Void> _ledHandle;
  Pointer<Utf8>? _nativeName;
  bool _invalid = false;
  final bool isolate;

  /// Open the sysfs LED with the specified name.
  ///
  /// 'ls /sys/class/leds/' to list all available leds.
  /// c-periphery [Led](https://github.com/vsergeev/c-periphery/blob/master/docs/led.md)
  /// documentation.
  Led(this.name) : isolate = false {
    var tuple = _openLed(name);
    _ledHandle = tuple.$1;
    _nativeName = tuple.$2;
  }

  /// Duplicates an existing [Led] from a JSON string. This special constructor
  /// is used to transfer an existing [Led] to another isolate.
  Led.isolate(String json)
      : name = jsonMap(json)['name'] as String,
        _ledHandle = Pointer<Void>.fromAddress(jsonMap(json)['handle'] as int),
        isolate = true;

  /// Converts a [Led] to a JSON string. See constructor [isolate] for details.
  @override
  String toJson() {
    return '{"class":"Led","name":"$name","handle":${_ledHandle.address}}';
  }

  void _checkStatus() {
    if (_invalid) {
      throw LedException(
          LedErrorCode.ledErrorClose, 'Led interface has the status released.');
    }
  }

  static (Pointer<Void>, Pointer<Utf8>) _openLed(String name) {
    var ledHandle = _nativeLedNew();
    if (ledHandle == nullptr) {
      return throw LedException(LedErrorCode.ledErrorOpen, 'led_new() failed');
    }
    var nativeName = name.toNativeUtf8();
    try {
      _checkError(_nativeLedOpen(ledHandle, nativeName));
    } catch (_) {
      _nativeLedFree(ledHandle);
      malloc.free(nativeName);
      rethrow;
    }
    return (ledHandle, nativeName);
  }

  /// Converts the native error code [value] to [LedErrorCode].
  static LedErrorCode getLedErrorCode(int value) {
    // must be negative
    if (value >= 0) {
      return LedErrorCode.errorCodeNotMappable;
    }

    value = -value;

    // check range
    if (value > LedErrorCode.ledErrorClose.index) {
      return LedErrorCode.errorCodeNotMappable;
    }

    return LedErrorCode.values[value];
  }

  /// Sets the state of the led to [value].
  void write(bool value) {
    _checkStatus();
    _checkError(_nativeLedWrite(_ledHandle, value ? 1 : 0));
  }

  /// Reads the state of the led.
  bool read() {
    _checkStatus();
    var data = malloc<Int8>(1);
    try {
      _checkError(_nativeLedRead(_ledHandle, data));
      return data[0] == 0 ? false : true;
    } finally {
      malloc.free(data);
    }
  }

  /// Releases all internal native resources.
  void dispose() {
    _checkStatus();
    _invalid = true;
    try {
      _checkError(_nativeLedClose(_ledHandle));
    } finally {
      _nativeLedFree(_ledHandle);
      if (_nativeName != null) {
        malloc.free(_nativeName!);
      }
    }
  }

  /// Returns the libc errno of the last failure that occurred.
  int getErrno() {
    _checkStatus();
    return _nativeLedErrno(_ledHandle);
  }

  /// Returns the brightness of the led.
  int getBrightness() {
    _checkStatus();
    var data = malloc<Int32>(1);
    try {
      _checkError(_nativeLedGetBrightness(_ledHandle, data));
      return data[0];
    } finally {
      malloc.free(data);
    }
  }

  /// Returns the maximum possible brightness of the led.
  int getMaxBrightness() {
    _checkStatus();
    var data = malloc<Int32>(1);
    try {
      _checkError(_nativeLedGetMaxBrightness(_ledHandle, data));
      return data[0];
    } finally {
      malloc.free(data);
    }
  }

  /// Sets the brightness of the led to [value].
  void setBrightness(int value) {
    _checkStatus();
    _checkError(_nativeLedSetBrightness(_ledHandle, value));
  }

  /// Returns a string representation of the led handle.
  String getLedInfo() {
    _checkStatus();
    var data = malloc<Int8>(bufferLen).cast<Utf8>();
    try {
      _checkError(_nativeLedInfo(_ledHandle, data, bufferLen));
      return data.toDartString();
    } finally {
      malloc.free(data);
    }
  }

  /// Returns the name of the led.
  String getLedName() {
    _checkStatus();
    var data = malloc<Int8>(bufferLen).cast<Utf8>();
    try {
      _checkError(_nativeLedName(_ledHandle, data, bufferLen));
      return data.toDartString();
    } finally {
      malloc.free(data);
    }
  }

  @override
  IsolateAPI fromJson(String json) {
    return Led.isolate(json);
  }

  /// Set the address of the internal handle.
  @override
  void setHandle(int handle) {
    _ledHandle = Pointer<Void>.fromAddress(handle);
  }

  @override
  bool isIsolate() {
    return isolate;
  }

  @override
  int getHandle() {
    return _ledHandle.address;
  }
}
