// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/vsergeev/c-periphery/blob/master/docs/pwm.md
// https://github.com/vsergeev/c-periphery/blob/master/src/pwm.c
// https://github.com/vsergeev/c-periphery/blob/master/src/pwm.h
// https://github.com/dart-lang/samples/tree/master/ffi

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'signature.dart';

/// [PWM] error code
enum PWMerrorCode {
  /// Error code for not able to map the native C enum
  errorCodeNotMappable,

  ///  Invalid arguments */
  pwmErrorArg,

  /// Opening PWM
  pwmErrorOpen,

  ///  Querying PWM attributes
  pwmErrorQuery,

  /// Configuring PWM attributes
  pwmErrorConfigure,

  // Closing PWM
  pwmErrorClose
}

/// [PWM] polarity of the  output
enum Polarity { pwmPolarityNormal, pwmPolarityInversed }

// pwm_t *pwm_new(void);
final _nativePWMnew = voidPtrVOIDM('pwm_new');

// int pwm_close(pwm_t *pwm);
final _nativePWMclose = intVoidM('pwm_close');

// void pwm_free(pwm_t *pwm)
final _nativePWMfree = voidVoidM('pwm_free');

// int pwm_open(pwm_t *pwm, unsigned int chip, unsigned int channel);
final _nativePWMopen = intVoidIntIntM('pwm_open');

// int pwm_errno(pwm_t *pwm);
final _nativePWMerrno = intVoidM('pwm_errno');

// const char *pwm_errmsg(pwm_t *pwm);
final _nativePWMerrnMsg = utf8VoidM('pwm_errmsg');

// int pwm_tostring(pwm_t *led, char *str, size_t len);
final _nativePWMinfo = intVoidUtf8sizeTM('pwm_tostring');

// int pwm_enable(pwm_t *pwm);
final _nativePWMenable = intVoidM('pwm_enable');

// int pwm_disable(pwm_t *pwm);
final _nativePWMdisable = intVoidM('pwm_disable');

// unsigned int pwm_chip(pwm_t *pwm);
final _nativePWMchip = intVoidM('pwm_chip');

// unsigned int pwm_channel(pwm_t *pwm);
final _nativePWMchannel = intVoidM('pwm_chip');

// int pwm_get_period_ns(pwm_t *pwm, uint64_t *period_ns);
final _nativePWMgetPeriodNs = intVoidUint64PtrM('pwm_get_period_ns');

// int pwm_get_duty_cycle_ns(pwm_t *pwm, uint64_t *duty_cycle_ns);
final _nativePWMgetDutyCycleNs = intVoidUint64PtrM('pwm_get_duty_cycle_ns');

// int pwm_get_polarity(pwm_t *pwm, pwm_polarity_t *polarity);
final _nativePWMgetPolarity = intVoidInt32PtrM('pwm_get_polarity');

// int pwm_get_enabled(pwm_t *pwm, bool *enabled);
final _nativePWMgetEndabled = intVoidInt8PtrM('pwm_get_enabled');

// int pwm_get_period(pwm_t *pwm, double *period);
final _nativePWMgetPeriod = intVoidDoublePtrM('pwm_get_period');

// int pwm_get_duty_cycle(pwm_t *pwm, double *duty_cycle);
final _nativePWMgetDutyCycle = intVoidDoublePtrM('pwm_get_duty_cycle');

// int pwm_get_frequency(pwm_t *pwm, double *frequency);
final _nativePWMgetFrequency = intVoidDoublePtrM('pwm_get_frequency');

// int pwm_set_enabled(pwm_t *pwm, bool enabled);
final _nativePWMsetEnabled = intVoidBoolM('pwm_set_enabled');

// int pwm_set_period_ns(pwm_t *pwm, uint64_t period_ns);
final _nativePWMsetPeriodNs = intVoidUint64M('pwm_set_period_ns');

// int pwm_set_duty_cycle_ns(pwm_t *pwm, uint64_t duty_cycle_ns);
final _nativePWMsetDutyCycleNs = intVoidUint64M('pwm_set_duty_cycle_ns');

// int pwm_set_polarity(pwm_t *pwm, pwm_polarity_t polarity);
final _nativePWMsetPolarity = intVoidIntM('pwm_set_polarity');

// int pwm_set_period(pwm_t *pwm, double period);
final _nativePWMsetPeriod = intVoidDoubleM('pwm_set_period');

// int pwm_set_duty_cycle(pwm_t *pwm, double duty_cycle);
final _nativePWMsetCycle = intVoidDoubleM('pwm_set_duty_cycle');

// int pwm_set_frequency(pwm_t *pwm, double frequency);
final _nativePWMsetFrequency = intVoidDoubleM('pwm_set_frequency');

const bufferLen = 256;

int _checkError(int value) {
  if (value < 0) {
    var errorCode = PWM.getPWMerrorCode(value);
    throw PWMexception(errorCode, errorCode.toString());
  }
  return value;
}

String _getErrmsg(Pointer<Void> handle) {
  return _nativePWMerrnMsg(handle).toDartString();
}

/// [PWM] exception
class PWMexception implements Exception {
  final PWMerrorCode errorCode;
  final String errorMsg;
  PWMexception(this.errorCode, this.errorMsg);
  PWMexception.errorCode(int code, Pointer<Void> handle)
      : errorCode = PWM.getPWMerrorCode(code),
        errorMsg = _getErrmsg(handle);
  @override
  String toString() => errorMsg;
}

// final DynamicLibrary _peripheryLib = getPeripheryLib();

/// PWM wrapper functions for Linux userspace sysfs PWMs.
///
/// c-periphery [PCM](https://github.com/vsergeev/c-periphery/blob/master/docs/pwm.md) documentation.
class PWM {
  final int chip;
  final int channel;
  final Pointer<Void> _pwmHandle;
  bool _invalid = false;

  PWM(this.chip, this.channel) : _pwmHandle = _openPWM(chip, channel);

  void _checkStatus() {
    if (_invalid) {
      throw PWMexception(
          PWMerrorCode.pwmErrorClose, 'PWM interface has the status released.');
    }
  }

  static Pointer<Void> _openPWM(int chip, int channel) {
    var _pwmHandle = _nativePWMnew();
    if (_pwmHandle == nullptr) {
      return throw PWMexception(
          PWMerrorCode.pwmErrorOpen, 'Error opening PWM chip/channel');
    }
    _checkError(_nativePWMopen(_pwmHandle, chip, channel));

    return _pwmHandle;
  }

  /// Converts the native error code [value] to [PWMerrorCode].
  static PWMerrorCode getPWMerrorCode(int value) {
    // must be negative
    if (value >= 0) {
      return PWMerrorCode.errorCodeNotMappable;
    }
    value = -value;

    // check range
    if (value > PWMerrorCode.pwmErrorClose.index) {
      return PWMerrorCode.errorCodeNotMappable;
    }

    return PWMerrorCode.values[value];
  }

  /// Releases all interal native resoures.
  void dispose() {
    _checkStatus();
    _invalid = true;
    _checkError(_nativePWMclose(_pwmHandle));
    _nativePWMfree(_pwmHandle);
  }

  /// Enables the PWM output.
  void enable() {
    _checkStatus();
    _checkError(_nativePWMenable(_pwmHandle));
  }

  /// Disables the PWM output.
  void disable() {
    _checkStatus();
    _checkError(_nativePWMdisable(_pwmHandle));
  }

  /// Returns the libc errno of the last failure that occurred.
  int getErrno() {
    _checkStatus();
    return _nativePWMerrno(_pwmHandle);
  }

  /// Returns a string representation of the PWM handle.
  String getPWMinfo() {
    _checkStatus();
    var data = malloc<Int8>(bufferLen).cast<Utf8>();
    try {
      _checkError(_nativePWMinfo(_pwmHandle, data, bufferLen));
      return data.toDartString();
    } finally {
      malloc.free(data);
    }
  }

  bool _getBoolValue(intVoidInt8PtrF f) {
    _checkStatus();
    var data = malloc<Int8>(1);
    try {
      _checkError(f(_pwmHandle, data));
      return data[0] != 0;
    } finally {
      malloc.free(data);
    }
  }

  int _getInt64Value(intVoidUint64PtrF f) {
    _checkStatus();
    var data = malloc<Uint64>(1);
    try {
      _checkError(f(_pwmHandle, data));
      return data[0].toInt();
    } finally {
      malloc.free(data);
    }
  }

  int _getInt32Value(intVoidInt32PtrF f) {
    _checkStatus();
    var data = malloc<Int32>(1);
    try {
      _checkError(f(_pwmHandle, data));
      return data[0];
    } finally {
      malloc.free(data);
    }
  }

  double _getDoubleValue(intVoidDoublePtrF f) {
    _checkStatus();
    var data = malloc<Double>(1);
    try {
      _checkError(f(_pwmHandle, data));
      return data[0];
    } finally {
      malloc.free(data);
    }
  }

  /// Gets the period in nanoseconds of the PWM.
  int getPeriodNs() {
    return _getInt64Value(_nativePWMgetPeriodNs);
  }

  // Gets the output state of the PWM.
  bool getEnabled() {
    return _getBoolValue(_nativePWMgetEndabled);
  }

  /// Sets the period in [nanoseconds] of the PWM.
  void setPeriodNs(int nanoseconds) {
    _checkError(_nativePWMsetPeriodNs(_pwmHandle, nanoseconds));
  }

  /// Sets the output state of the PWM.
  void setEnabled(bool flag) {
    _checkError(_nativePWMsetEnabled(_pwmHandle, flag == true ? 1 : 0));
  }

  /// Gets the duty cycle in nanoseconds of the PWM.
  int getDutyCycleNs() {
    return _getInt64Value(_nativePWMgetDutyCycleNs);
  }

  /// Sets the duty cycle in [nanoseconds] of the PWM.
  void setDutyCycleNs(int nanoseconds) {
    _checkError(_nativePWMsetDutyCycleNs(_pwmHandle, nanoseconds));
  }

  /// Gets the period in seconds of the PWM.
  double getPeriod() {
    return _getDoubleValue(_nativePWMgetPeriod);
  }

  /// Sets the period in [seconds] of the PWM.
  void setPeriod(double seconds) {
    _checkError(_nativePWMsetPeriod(_pwmHandle, seconds));
  }

  /// Gets the duty cycle as a ratio between 0.0 to 1.0 in second of the PWM.
  double getDutyCycle() {
    return _getDoubleValue(_nativePWMgetDutyCycle);
  }

  /// Sets the [dutyCycle] as a ratio between 0.0 to 1.0 in second of the PWM.
  void setDutyCycle(double dutyCycle) {
    _checkError(_nativePWMsetCycle(_pwmHandle, dutyCycle));
  }

  /// Gets the frequency in Hz of the PWM.
  double getFrequency() {
    return _getDoubleValue(_nativePWMgetFrequency);
  }

  /// Sets the [frequency] in Hz of the PWM.
  void setFrequency(double frequency) {
    _checkError(_nativePWMsetFrequency(_pwmHandle, frequency));
  }

  /// Returns the polarity of the PWM.
  Polarity getPolarity() {
    switch (_getInt32Value(_nativePWMgetPolarity)) {
      case 0:
        return Polarity.pwmPolarityNormal;
      case 1:
        return Polarity.pwmPolarityInversed;
      default:
        throw PWMexception(PWMerrorCode.pwmErrorQuery, 'Unkown polarity');
    }
  }

  /// Sets the output [polarity] of the PWM.
  void setPolarity(Polarity polarity) {
    _checkError(_nativePWMsetPolarity(_pwmHandle, polarity.index));
  }

  /// Return the chip number of the PWM handle.
  int getChip() {
    return _nativePWMchip(_pwmHandle);
  }

  /// Returns the channel number of the PWM handle.
  int getChannel() {
    return _nativePWMchannel(_pwmHandle);
  }
}
