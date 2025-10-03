// Copyright (c) 2022,2025 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/vsergeev/c-periphery/blob/master/docs/pwm.md
// https://github.com/vsergeev/c-periphery/blob/master/src/pwm.c
// https://github.com/vsergeev/c-periphery/blob/master/src/pwm.h
// https://github.com/dart-lang/samples/tree/master/ffi

import 'dart:ffi';
import 'package:dart_periphery/src/isolate_api.dart';
import 'package:dart_periphery/src/json.dart';
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
final _nativePWMchannel = intVoidM('pwm_channel');

// int pwm_get_period_ns(pwm_t *pwm, uint64_t *period_ns);
final _nativePWMgetPeriodNs = intVoidUint64PtrM('pwm_get_period_ns');

// int pwm_get_duty_cycle_ns(pwm_t *pwm, uint64_t *duty_cycle_ns);
final _nativePWMgetDutyCycleNs = intVoidUint64PtrM('pwm_get_duty_cycle_ns');

// int pwm_get_polarity(pwm_t *pwm, pwm_polarity_t *polarity);
final _nativePWMgetPolarity = intVoidInt32PtrM('pwm_get_polarity');

// int pwm_get_enabled(pwm_t *pwm, bool *enabled);
final _nativePWMgetEnabled = intVoidInt8PtrM('pwm_get_enabled');

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

/// PWM wrapper functions for Linux userspace sysfs PWMs.
///
/// Example usage:
/// ```dart
/// var pwm = PWM(0, 0);  // chip 0, channel 0
/// pwm.setFrequency(PWM.freq1kHz);  // 1kHz
/// pwm.setDutyCycle(PWM.dutyHalf);  // 50% duty cycle
/// pwm.enable();
/// // ... use PWM
/// pwm.dispose();
/// ```
///
/// c-periphery [PWM](https://github.com/vsergeev/c-periphery/blob/master/docs/pwm.md) documentation.
class PWM extends IsolateAPI {
  final int chip;
  final int channel;
  final bool isolate;
  late Pointer<Void> _pwmHandle;
  bool _invalid = false;

  /// Common PWM frequencies in Hz
  static const double freq1kHz = 1000.0;
  static const double freq10kHz = 10000.0;
  static const double freq100kHz = 100000.0;
  static const double freq1MHz = 1000000.0;

  /// Common duty cycles (0.0 to 1.0)
  static const double duty0Percent = 0.0;
  static const double duty25Percent = 0.25;
  static const double duty50Percent = 0.5;
  static const double duty75Percent = 0.75;
  static const double duty100Percent = 1.0;

  /// Alternative naming for duty cycles
  static const double dutyOff = 0.0;
  static const double dutyQuarter = 0.25;
  static const double dutyHalf = 0.5;
  static const double dutyThreeQuarters = 0.75;
  static const double dutyFull = 1.0;

  PWM(this.chip, this.channel)
      : _pwmHandle = _openPWM(chip, channel),
        isolate = false {
    if (chip < 0) {
      throw PWMexception(
          PWMerrorCode.pwmErrorArg, 'Chip number must be non-negative');
    }
    if (channel < 0) {
      throw PWMexception(
          PWMerrorCode.pwmErrorArg, 'Channel number must be non-negative');
    }
  }

  PWM.isolate(String json)
      : chip = jsonMap(json)['chip'] as int,
        channel = jsonMap(json)['channel'] as int,
        _pwmHandle = Pointer<Void>.fromAddress(jsonMap(json)['handle'] as int),
        isolate = true;

  void _checkStatus() {
    if (_invalid) {
      throw PWMexception(
          PWMerrorCode.pwmErrorClose, 'PWM interface has the status released.');
    }
  }

  static Pointer<Void> _openPWM(int chip, int channel) {
    var pwmHandle = _nativePWMnew();
    if (pwmHandle == nullptr) {
      return throw PWMexception(
          PWMerrorCode.pwmErrorOpen, 'Error opening PWM chip/channel');
    }
    try {
      _checkError(_nativePWMopen(pwmHandle, chip, channel));
    } catch (e) {
      _nativePWMfree(pwmHandle);
      rethrow;
    }
    return pwmHandle;
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

  @override
  String toJson() {
    return '{"class":"PWM","chip":$chip,"channel":$channel,"handle":${_pwmHandle.address}}';
  }

  /// Releases all internal native resources.
  void dispose() {
    _checkStatus();
    _invalid = true;
    try {
      _checkError(_nativePWMclose(_pwmHandle));
    } finally {
      _nativePWMfree(_pwmHandle);
    }
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
    _checkStatus();
    return _getInt64Value(_nativePWMgetPeriodNs);
  }

  // Gets the output state of the PWM.
  bool getEnabled() {
    _checkStatus();
    return _getBoolValue(_nativePWMgetEnabled);
  }

  /// Sets the period in [nanoseconds] of the PWM.
  void setPeriodNs(int nanoseconds) {
    _checkStatus();
    _checkError(_nativePWMsetPeriodNs(_pwmHandle, nanoseconds));
  }

  /// Sets the output state of the PWM.
  void setEnabled(bool flag) {
    _checkStatus();
    _checkError(_nativePWMsetEnabled(_pwmHandle, flag == true ? 1 : 0));
  }

  /// Gets the duty cycle in nanoseconds of the PWM.
  int getDutyCycleNs() {
    _checkStatus();
    return _getInt64Value(_nativePWMgetDutyCycleNs);
  }

  /// Sets the duty cycle in [nanoseconds] of the PWM.
  void setDutyCycleNs(int nanoseconds) {
    _checkStatus();
    _checkError(_nativePWMsetDutyCycleNs(_pwmHandle, nanoseconds));
  }

  /// Gets the period in seconds of the PWM.
  double getPeriod() {
    _checkStatus();
    return _getDoubleValue(_nativePWMgetPeriod);
  }

  /// Sets the period in [seconds] of the PWM.
  void setPeriod(double seconds) {
    _checkStatus();
    _checkError(_nativePWMsetPeriod(_pwmHandle, seconds));
  }

  /// Gets the duty cycle as a ratio between 0.0 to 1.0 in second of the PWM.
  double getDutyCycle() {
    _checkStatus();
    return _getDoubleValue(_nativePWMgetDutyCycle);
  }

  /// Sets the [dutyCycle] as a ratio between 0.0 to 1.0 in second of the PWM.
  void setDutyCycle(double dutyCycle) {
    if (dutyCycle < 0.0 || dutyCycle > 1.0) {
      throw PWMexception(
          PWMerrorCode.pwmErrorArg, 'Duty cycle must be between 0.0 and 1.0');
    }
    _checkStatus();
    _checkError(_nativePWMsetCycle(_pwmHandle, dutyCycle));
  }

  /// Gets the frequency in Hz of the PWM.
  double getFrequency() {
    _checkStatus();
    return _getDoubleValue(_nativePWMgetFrequency);
  }

  /// Sets the [frequency] in Hz of the PWM.
  void setFrequency(double frequency) {
    if (frequency <= 0) {
      throw PWMexception(
          PWMerrorCode.pwmErrorArg, 'Frequency must be positive');
    }
    _checkStatus();
    _checkError(_nativePWMsetFrequency(_pwmHandle, frequency));
  }

  /// Returns the polarity of the PWM.
  Polarity getPolarity() {
    _checkStatus();
    switch (_getInt32Value(_nativePWMgetPolarity)) {
      case 0:
        return Polarity.pwmPolarityNormal;
      case 1:
        return Polarity.pwmPolarityInversed;
      default:
        throw PWMexception(PWMerrorCode.pwmErrorQuery, 'Unknown polarity');
    }
  }

  /// Sets the output [polarity] of the PWM.
  void setPolarity(Polarity polarity) {
    _checkStatus();
    _checkError(_nativePWMsetPolarity(_pwmHandle, polarity.index));
  }

  /// Sets duty cycle as a percentage (0-100)
  void setDutyCyclePercent(double percent) {
    if (percent < 0.0 || percent > 100.0) {
      throw PWMexception(
          PWMerrorCode.pwmErrorArg, 'Percentage must be between 0 and 100');
    }
    setDutyCycle(percent / 100.0);
  }

  /// Gets duty cycle as a percentage (0-100)
  double getDutyCyclePercent() {
    return getDutyCycle() * 100.0;
  }

  /// Sets frequency in kHz
  void setFrequencyKHz(double frequencyKHz) {
    setFrequency(frequencyKHz * 1000.0);
  }

  /// Return the chip number of the PWM handle.
  int getChip() {
    _checkStatus();
    return _nativePWMchip(_pwmHandle);
  }

  /// Returns the channel number of the PWM handle.
  int getChannel() {
    _checkStatus();
    return _nativePWMchannel(_pwmHandle);
  }

  @override
  IsolateAPI fromJson(String json) {
    return PWM.isolate(json);
  }

  @override
  int getHandle() {
    return _pwmHandle.address;
  }

  /// Gets frequency in kHz
  double getFrequencyKHz() {
    return getFrequency() / 1000.0;
  }

  /// Gets frequency in MHz
  double getFrequencyMHz() {
    return getFrequency() / 1000000.0;
  }

  /// Sets frequency in MHz
  void setFrequencyMHz(double frequencyMHz) {
    setFrequency(frequencyMHz * 1000000.0);
  }

  @override
  void setHandle(int handle) {
    _pwmHandle = Pointer<Void>.fromAddress(handle);
  }

  @override
  bool isIsolate() {
    return isolate;
  }
}
