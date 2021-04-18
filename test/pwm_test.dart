// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';
import 'util.dart';

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

void test_arguments() {}

void test_loopback() {}

void test_interactive(int chip, int channel) {
  var pwm = PWM(chip, channel);
  try {
    print('Starting interactive test. Get out your logic analyzer, buddy!');
    print('Press enter to continue...');
    pressKey();

    // Set initial parameters and enable PWM
    pwm.setDutyCycle(0);
    pwm.setFrequency(1e3);
    pwm.setPolarity(Polarity.PWM_POLARITY_NORMAL);
    pwm.setEnabled(true);
    print('PWM description: ${pwm.getPWMinfo()}');
    print('PWM description looks OK? y/n');
    pressKeyYes();

    // Set 1 kHz frequency, 0.25 duty cycle
    pwm.setFrequency(1e3);
    pwm.setDutyCycle(0.25);
    print('Frequency is 1 kHz, duty cycle is 25%? y/n');
    pressKeyYes();

    /* Set 1 kHz frequency, 0.50 duty cycle */
    pwm.setFrequency(1e3);
    pwm.setDutyCycle(0.50);
    print('Frequency is 1 kHz, duty cycle is 50%? y/n');
    pressKeyYes();

    // Set 2 kHz frequency, 0.25 duty cycle
    pwm.setFrequency(2e3);
    pwm.setDutyCycle(0.25);
    print('Frequency is 2 kHz, duty cycle is 25%? y/n');
    pressKeyYes();

    // Set 2 kHz frequency, 0.50 duty cycle
    pwm.setFrequency(2e3);
    pwm.setDutyCycle(0.50);
    print('Frequency is 2 kHz, duty cycle is 50%? y/n');
    pressKeyYes();

    pwm.setDutyCycle(0);
    pwm.setEnabled(true);
  } finally {
    pwm.dispose();
  }
}

void test_open_config_close(int chip, int channel) {
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
  try {
    // Check properties
    passert(pwm.getChip() == chip);
    passert(pwm.getChannel() == channel);

    // Initialize period and duty cycle
    pwm.setPeriod(5e-3);
    pwm.setDutyCycle(0);

    // Set period, check period, check period_ns, check frequency
    pwm.setPeriod(1e-3);
    passert(fabs(pwm.getPeriod() - 1e-3) < 1e-4);
    passert(fabs(pwm.getPeriodNs() - 1000000.0) < 1e-5);
    passert(fabs(pwm.getFrequency() - 1000) < 100);
    pwm.setPeriod(5e-4);
    passert(fabs(pwm.getPeriod() - 5e-4) < 1e-5);
    passert(fabs(pwm.getPeriodNs() - 500000.0) < 1e-4);
    passert(fabs(pwm.getFrequency() - 2000) < 100);

    // Set frequency, check frequency, check period, check period_ns
    pwm.setFrequency(1000);
    passert(fabs(pwm.getFrequency() - 1000) < 100);
    passert(fabs(pwm.getPeriod() - 1e-3) < 1e-4);
    passert(fabs(pwm.getPeriodNs() - 1000000.0) < 1e5);

    pwm.setFrequency(2000);
    passert(fabs(pwm.getFrequency() - 2000) < 100);
    passert(fabs(pwm.getPeriod() - 5e-4) < 1e-5);
    passert(fabs(pwm.getPeriodNs() - 500000) < 1e4);

    // Set period_ns, check period_ns, check period, check frequency
    pwm.setPeriodNs(1000000);
    passert(fabs(pwm.getPeriodNs() - 1000000) < 1e5);
    passert(fabs(pwm.getPeriod() - 1e-3) < 1e-4);
    passert(fabs(pwm.getFrequency() - 1000) < 100);

    pwm.setPeriodNs(500000);
    passert(fabs(pwm.getPeriodNs() - 500000) < 1e4);
    passert(fabs(pwm.getPeriod() - 5e-4) < 1e-5);
    passert(fabs(pwm.getFrequency() - 2000) < 100);

    pwm.setPeriodNs(1000000);

    // Set duty cycle, check duty cycle, check duty_cycle_ns
    pwm.setDutyCycle(0.25);
    passert(fabs(pwm.getDutyCycle() - 0.25) < 1e-3);
    passert(fabs(pwm.getDutyCycleNs() - 250000) < 1e4);

    pwm.setDutyCycle(0.50);
    passert(fabs(pwm.getDutyCycle() - 0.50) < 1e-3);
    passert(fabs(pwm.getDutyCycleNs() - 500000) < 1e4);

    pwm.setDutyCycle(0.75);
    passert(fabs(pwm.getDutyCycle() - 0.75) < 1e-3);
    passert(fabs(pwm.getDutyCycleNs() - 750000) < 1e4);

    // Set duty_cycle_ns, check duty_cycle_ns, check duty_cycle
    pwm.setDutyCycleNs(250000);
    passert(fabs(pwm.getDutyCycleNs() - 250000) < 1e4);
    passert(fabs(pwm.getDutyCycle() - 0.25) < 1e-3);

    pwm.setDutyCycleNs(500000);
    passert(fabs(pwm.getDutyCycleNs() - 500000) < 1e4);
    passert(fabs(pwm.getDutyCycle() - 0.50) < 1e-3);

    pwm.setDutyCycleNs(750000);
    passert(fabs(pwm.getDutyCycleNs() - 750000) < 1e4);
    passert(fabs(pwm.getDutyCycle() - 0.75) < 1e-3);

    // Set polarity, check polarity
    pwm.setPolarity(Polarity.PWM_POLARITY_NORMAL);
    passert(pwm.getPolarity() == Polarity.PWM_POLARITY_NORMAL);

    pwm.setPolarity(Polarity.PWM_POLARITY_INVERSED);
    passert(pwm.getPolarity() == Polarity.PWM_POLARITY_INVERSED);

    // Set enabled, check enabled
    pwm.setEnabled(true);
    passert(pwm.getEnabled() == true);

    pwm.setEnabled(false);
    passert(pwm.getEnabled() == false);

    // passert(pwm.setPolarity(pwm, 123) == PWM_ERROR_ARG);
    // can not mapped

    pwm.setPeriodNs(1000000);
  } finally {
    pwm.dispose();
  }
}

void main(List<String> argv) {
  if (argv.length != 2) {
    print('Usage: dart pwm_test <PWM chip> <PWM channel>');
    print('[1/4] Arguments test: No requirements.');
    print('[2/4] Open/close test: PWM channel should be real.');
    print('[3/4] Loopback test: No test.');
    print(
        '[4/4] Interactive test: PWM channel should be observed with an oscilloscope or logic analyzer.');
    print('Hint: for Raspberry Pi 3, enable PWM0 and PWM1 with:');
    print(
        '   \$ echo \"dtoverlay=pwm-2chan,pin=18,func=2,pin2=13,func2=4\" | sudo tee -a /boot/config.txt');
    print('   \$ sudo reboot');
    print('Monitor GPIO 18 (header pin 12), and run this test with:');
    print('    dart pwm_test 0 0');
    print('or, monitor GPIO 13 (header pin 33), and run this test with:');
    print('    dart pwm_test 0 1');
    exit(1);
  }

  var chip = int.parse(argv[0]);
  var channel = int.parse(argv[1]);

  test_arguments();
  print('Arguments test passed.');
  test_open_config_close(chip, channel);
  print('Open/close test passed.');
  test_loopback();
  print('Loopback test passed.');
  test_interactive(chip, channel);
  print('Interactive test passed.');
  print('All tests passed!\n');
}
