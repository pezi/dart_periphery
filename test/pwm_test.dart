// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

// https://github.com/vsergeev/c-periphery/blob/master/tests/test_pwm.c

double fabs(double x) => (x < 0) ? -x : x;

class TestException implements Exception {
  final String error;
  TestException(this.error);
  TestException.unexpected(PWMexception e)
      : error = 'Unexpected error code: ${e.errorCode}';
  @override
  String toString() => error;
}

void test(int chip, int channel) {
  // Open non-existent PWM chip
  try {
    PWM(9999, channel);
  } on PWMexception catch (e) {
    if (e.errorCode != PWMerrorCode.PWM_ERROR_OPEN) {
      throw TestException.unexpected(e);
    }
  }
  // Open non-existent PWM channel
  try {
    PWM(chip, 9999);
  } on PWMexception catch (e) {
    if (e.errorCode != PWMerrorCode.PWM_ERROR_OPEN) {
      throw TestException.unexpected(e);
    }
  }

  var pwm = PWM(chip, channel);

  // Check properties
  assert(pwm.getChip() == chip);
  assert(pwm.getChannel() == channel);

  // Initialize period and duty cycle
  pwm.setPeriod(5e-3);
  pwm.setDutyCycle(0);

  // Set period, check period, check period_ns, check frequency
  pwm.setPeriod(1e-3);
  assert(fabs(pwm.getPeriod() - 1e-3) < 1e-4);
  assert(fabs(pwm.getPeriodNs() - 1000000.0) < 1e-5);
  assert(fabs(pwm.getFrequency() - 1000) < 100);

  /*
    passert(pwm_set_period(pwm, 5e-4) == 0);
    passert(pwm_get_period(pwm, &period) == 0);
    passert(fabs(period - 5e-4) < 1e-5);
    passert(pwm_get_period_ns(pwm, &period_ns) == 0);
    passert(fabs(period_ns - 500000) < 1e4);
    passert(pwm_get_frequency(pwm, &frequency) == 0);
    passert(fabs(frequency - 2000) < 100);
    */
}
