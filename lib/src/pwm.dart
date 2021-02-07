// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/vsergeev/c-periphery/blob/master/docs/pwm.md
// https://github.com/vsergeev/c-periphery/blob/master/src/pwm.c
// https://github.com/vsergeev/c-periphery/blob/master/src/pwm.h
// https://github.com/dart-lang/samples/tree/master/ffi

import 'dart:ffi';
import 'library.dart';
import 'package:ffi/ffi.dart';

/// PWM error code
enum PWMerrorCode {
  /// Error code for not able to map the native C enum
  ERROR_CODE_NOT_MAPPABLE,

  ///  Invalid arguments */
  PWM_ERROR_ARG,

  /// Opening PWM
  PWM_ERROR_OPEN,

  ///  Querying PWM attributes
  PWM_ERROR_QUERY,

  /// Configuring PWM attributes
  PWM_ERROR_CONFIGURE,

  // Closing PWM
  PWM_ERROR_CLOSE
}

/// Converts the native error code [value] to [PWMerrorCode].
PWMerrorCode getPWMerrorCode(int value) {
  // must be negative
  if (value >= 0) {
    return PWMerrorCode.ERROR_CODE_NOT_MAPPABLE;
  }
  value = -value;

  // check range
  if (value > PWMerrorCode.PWM_ERROR_CLOSE.index) {
    return PWMerrorCode.ERROR_CODE_NOT_MAPPABLE;
  }

  return PWMerrorCode.values[value];
}

/// Polarity of the PWM output.
enum Polarity { PWM_POLARITY_NORMAL, PWM_POLARITY_INVERSED }

enum _PWMpropertyEnum {
  PERIOD_NS,
  DUTY_CYCLE_NS,
  PERIOD,
  DUTY_CYCLE,
  FREQUENCY,
  POLARITY,
  CHIP,
  CHANNEL
}

// PWMproperty_t *dart_pwm_get_property(pwm_t *pwm,PWMpropertyEnum_t prop)
typedef _dart_pwm_get_property = Pointer<Void> Function(
    Pointer<Void> handle, Int32 prop);
typedef _PWMgetProperty = Pointer<Void> Function(
    Pointer<Void> handle, int prop);
final _nativeGetProperty = _peripheryLib
    .lookup<NativeFunction<_dart_pwm_get_property>>('dart_pwm_get_property')
    .asFunction<_PWMgetProperty>();

// int dart_pwm_get_property(pwm_t *pwm,PWMpropertyEnum_t prop,PWMproperty_t *data)
typedef _dart_pwm_set_property = Int32 Function(
    Pointer<Void> handle, Int32 prop, Pointer<Void> value);
typedef _PWMsetProperty = int Function(
    Pointer<Void> handle, int prop, Pointer<Void> value);
final _nativeSetProperty = _peripheryLib
    .lookup<NativeFunction<_dart_pwm_set_property>>('dart_pwm_set_property')
    .asFunction<_PWMsetProperty>();

// int pwm_open(pwm_t *pwm, unsigned int chip, unsigned int channel);
typedef _dart_pwm_open = Pointer<Void> Function(Int32 chip, Int32 channel);
typedef _PWMopen = Pointer<Void> Function(int chip, int channel);
final _nativeOpen = _peripheryLib
    .lookup<NativeFunction<_dart_pwm_open>>('dart_pwm_open')
    .asFunction<_PWMopen>();

// int dart_pwm_dispose(pwm_t *pwm)
typedef _dart_pwm_dispose = Int32 Function(Pointer<Void> handle);
typedef _PWMdispose = int Function(Pointer<Void> handle);
final _nativeDispose = _peripheryLib
    .lookup<NativeFunction<_dart_pwm_dispose>>('dart_pwm_dispose')
    .asFunction<_PWMdispose>();

// int pwm_errno(pwm_t *pwm);
typedef _dart_pwm_errno = Int32 Function(Pointer<Void> handle);
typedef _PWMerrno = int Function(Pointer<Void> handle);
final _nativeErrno = _peripheryLib
    .lookup<NativeFunction<_dart_pwm_errno>>('dart_pwm_errno')
    .asFunction<_PWMerrno>();

// const char *pwm_errmsg(pwm_t *pwm);
typedef _dart_pwm_errmsg = Pointer<Utf8> Function(Pointer<Void> handle);
typedef _PWMerrmsg = Pointer<Utf8> Function(Pointer<Void> handle);
final _nativeErrmsg = _peripheryLib
    .lookup<NativeFunction<_dart_pwm_errmsg>>('dart_pwm_errmsg')
    .asFunction<_PWMerrmsg>();

/// int pwm_enable(pwm_t *pwm);
typedef _dart_pwm_enable = Int32 Function(Pointer<Void> handle);
typedef _PWMenable = int Function(Pointer<Void> handle);
final _nativeEnable = _peripheryLib
    .lookup<NativeFunction<_dart_pwm_enable>>('dart_pwm_enable')
    .asFunction<_PWMenable>();

/// int pwm_disable(pwm_t *pwm)
typedef _dart_pwm_disable = Int32 Function(Pointer<Void> handle);
typedef _PWMdisable = int Function(Pointer<Void> handle);
final _nativeDisable = _peripheryLib
    .lookup<NativeFunction<_dart_pwm_disable>>('dart_pwm_disable')
    .asFunction<_PWMdisable>();

// char *dart_pwm_info(pwm_t *led)
typedef _dart_pwm_info = Pointer<Utf8> Function(Pointer<Void> handle);
typedef _PWMinfo = Pointer<Utf8> Function(Pointer<Void> handle);
final _nativeInfo = _peripheryLib
    .lookup<NativeFunction<_dart_pwm_info>>('dart_pwm_info')
    .asFunction<_PWMinfo>();

int _checkError(int value) {
  if (value < 0) {
    PWMerrorCode errorCode = getPWMerrorCode(value);
    throw PWMexception(errorCode, errorCode.toString());
  }
  return value;
}

String _getErrmsg(Pointer<Void> handle) {
  return Utf8.fromUtf8(_nativeErrmsg(handle));
}

// PWM exception
class PWMexception implements Exception {
  final PWMerrorCode errorCode;
  final String errorMsg;
  PWMexception(this.errorCode, this.errorMsg);
  PWMexception.errorCode(int code, Pointer<Void> handle)
      : errorCode = getPWMerrorCode(code),
        errorMsg = _getErrmsg(handle);
  @override
  String toString() => errorMsg;
}

final DynamicLibrary _peripheryLib = getPeripheryLib();

// PWM wrapper functions for Linux userspace sysfs PWMs.
class PWM {
  final int chip;
  final int channel;
  Pointer<Void> _pwmHandle;
  bool _invalid = false;

  PWM(this.chip, this.channel) {
    _pwmHandle = _checkHandle(_nativeOpen(chip, channel));
  }

  void _checkStatus() {
    if (_invalid) {
      throw PWMexception(PWMerrorCode.PWM_ERROR_CLOSE,
          'PWM interface has the status released.');
    }
  }

  Pointer<Void> _checkHandle(Pointer<Void> handle) {
    // handle 0 indicates an internal error
    if (handle.address == 0) {
      throw PWMexception(
          PWMerrorCode.PWM_ERROR_OPEN, 'Error opening PWM chip/channel');
    }
    return handle;
  }

  /// Releases all interal native resoures.
  void dispose() {
    _checkStatus();
    _invalid = true;
    _checkError(_nativeDispose(_pwmHandle));
  }

  /// Enables the PWM output.
  void enable() {
    _checkStatus();
    _invalid = true;
    _checkError(_nativeEnable(_pwmHandle));
  }

  /// Disables the PWM output.
  void disables() {
    _checkStatus();
    _invalid = true;
    _checkError(_nativeDisable(_pwmHandle));
  }

  /// Returns the libc errno of the last failure that occurred.
  int getErrno() {
    _checkStatus();
    return _nativeErrno(_pwmHandle);
  }

  /// Returns a string representation of the PWM handle.
  String getLedInfo() {
    _checkStatus();
    final Pointer<Utf8> ptr = _nativeInfo(_pwmHandle);
    if (ptr.address == 0) {
      // throw an exception
      _checkError(getErrno());
      return "?";
    }
    String text = Utf8.fromUtf8(ptr);
    free(ptr);
    return text;
  }

  /// Gets the period in nanoseconds of the PWM.
  int getPeriodNs() {
    _checkStatus();
    final Pointer<Int64> ptr =
        _nativeGetProperty(_pwmHandle, _PWMpropertyEnum.PERIOD_NS.index)
            as Pointer<Int64>;
    try {
      return _checkError(ptr.value);
      ;
    } finally {
      free(ptr);
    }
  }

  /// Sets the period in [nanoseconds] of the PWM.
  void setPeriodNs(int nanoseconds) {
    _checkStatus();
    Pointer<Int64> ptr = allocate<Int64>(count: 1);
    ptr.value = nanoseconds;
    _checkError(_nativeSetProperty(
        _pwmHandle, _PWMpropertyEnum.PERIOD_NS.index, ptr as Pointer<Void>));
  }

  /// Gets the duty cycle in nanoseconds of the PWM.
  int getDutyCylceNs() {
    _checkStatus();
    final Pointer<Int64> ptr =
        _nativeGetProperty(_pwmHandle, _PWMpropertyEnum.DUTY_CYCLE_NS.index)
            as Pointer<Int64>;
    try {
      return _checkError(ptr.value);
    } finally {
      free(ptr);
    }
  }

  /// Sets the duty cycle in [nanoseconds] of the PWM.
  void setDutyCylcNs(int nanoseconds) {
    _checkStatus();
    Pointer<Int64> ptr = allocate<Int64>(count: 1);
    ptr.value = nanoseconds;
    _checkError(_nativeSetProperty(_pwmHandle,
        _PWMpropertyEnum.DUTY_CYCLE_NS.index, ptr as Pointer<Void>));
  }

  /// Gets the period in seconds of the PWM.
  double getPeriod() {
    _checkStatus();
    final Pointer<Double> ptr =
        _nativeGetProperty(_pwmHandle, _PWMpropertyEnum.PERIOD.index)
            as Pointer<Double>;
    try {
      _checkError(ptr.value.toInt());
      return ptr.value;
    } finally {
      free(ptr);
    }
  }

  /// Sets the period in [seconds] of the PWM.
  void setPeriod(double seconds) {
    _checkStatus();
    Pointer<Double> ptr = allocate<Double>(count: 1);
    ptr.value = seconds;
    _checkError(_nativeSetProperty(
        _pwmHandle, _PWMpropertyEnum.PERIOD.index, ptr as Pointer<Void>));
  }

  /// Gets the duty cycle as a ratio between 0.0 to 1.0 in second of the PWM.
  double getDutyCylce() {
    _checkStatus();
    final Pointer<Double> ptr =
        _nativeGetProperty(_pwmHandle, _PWMpropertyEnum.DUTY_CYCLE.index)
            as Pointer<Double>;
    try {
      _checkError(ptr.value.toInt());
      return ptr.value;
    } finally {
      free(ptr);
    }
  }

  /// Sets the [dutyCycle] as a ratio between 0.0 to 1.0 in second of the PWM.
  void setDutyCylce(double dutyCycle) {
    _checkStatus();
    Pointer<Double> ptr = allocate<Double>(count: 1);
    ptr.value = dutyCycle;
    _checkError(_nativeSetProperty(
        _pwmHandle, _PWMpropertyEnum.DUTY_CYCLE.index, ptr as Pointer<Void>));
  }

  /// Gets the frequency in Hz of the PWM.
  double getFrequency() {
    _checkStatus();
    final Pointer<Double> ptr =
        _nativeGetProperty(_pwmHandle, _PWMpropertyEnum.FREQUENCY.index)
            as Pointer<Double>;
    try {
      _checkError(ptr.value.toInt());
      return ptr.value;
    } finally {
      free(ptr);
    }
  }

  /// Sets the [frequency] in Hz of the PWM.
  void setFrequency(double frequency) {
    _checkStatus();
    Pointer<Double> ptr = allocate<Double>(count: 1);
    ptr.value = frequency;
    _checkError(_nativeSetProperty(
        _pwmHandle, _PWMpropertyEnum.FREQUENCY.index, ptr as Pointer<Void>));
  }

  /// Returns the polarity of the PWM.
  Polarity getPolarity() {
    _checkStatus();
    final Pointer<Int32> ptr =
        _nativeGetProperty(_pwmHandle, _PWMpropertyEnum.POLARITY.index)
            as Pointer<Int32>;
    try {
      _checkError(ptr.value);
      switch (ptr.value) {
        case 0:
          return Polarity.PWM_POLARITY_NORMAL;
        case 1:
          return Polarity.PWM_POLARITY_INVERSED;
        default:
          throw PWMexception(PWMerrorCode.PWM_ERROR_QUERY, "Unkown polarity");
      }
    } finally {
      free(ptr);
    }
  }

  /// Sets the output [polarity] of the PWM.
  void setPolarity(Polarity polarity) {
    _checkStatus();
    Pointer<Int32> ptr = allocate<Int32>(count: 1);
    ptr.value = polarity.index;
    _checkError(_nativeSetProperty(
        _pwmHandle, _PWMpropertyEnum.POLARITY.index, ptr as Pointer<Void>));
  }

  /// Return the chip number of the PWM handle.
  int getChip() {
    _checkStatus();
    final Pointer<Int32> ptr =
        _nativeGetProperty(_pwmHandle, _PWMpropertyEnum.CHIP.index)
            as Pointer<Int32>;
    try {
      return _checkError(ptr.value);
    } finally {
      free(ptr);
    }
  }

  /// Returns the channel number of the PWM handle.
  int getChannel() {
    _checkStatus();
    final Pointer<Int32> ptr =
        _nativeGetProperty(_pwmHandle, _PWMpropertyEnum.CHANNEL.index)
            as Pointer<Int32>;
    try {
      return _checkError(ptr.value);
    } finally {
      free(ptr);
    }
  }
}
