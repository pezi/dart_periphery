// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

// https://github.com/vsergeev/c-periphery/blob/master/tests/test_led.c

import 'package:dart_periphery/dart_periphery.dart';
import 'util.dart';
import 'dart:io';

void test_arguments() {
  print(
      'test_arguments() - No real argument validation needed in the LED wrapper');
}

void test_loopback() {
  print('Starting test');
}

void test_open_config_close(String device) {
  // Open non-existent LED
  try {
    Led('nonexistent');
  } on LedException catch (e) {
    if (e.errorCode != LedErrorCode.LED_ERROR_OPEN) {
      rethrow;
    }
  }

  // Open legitimate LED
  var led = Led(device);
  try {
    // Check properties
    assert(led.getLedName() == device);

    var max_brightness = led.getMaxBrightness();
    // Check max brightness
    assert(max_brightness > 0);

    try {
      led.setBrightness(max_brightness + 1);
    } on LedException catch (e) {
      if (e.errorCode != LedErrorCode.LED_ERROR_ARG) {
        rethrow;
      }
    }

    // Write false, read false, check brightness is zero
    led.write(false);
    sleep(Duration(seconds: 1));
    assert(led.read() == false);
    assert(led.getBrightness() == 0);

    // Set brightness to 1, check brightness
    led.setBrightness(1);
    sleep(Duration(seconds: 1));
    assert(led.getBrightness() >= 1);

    // Set brightness to 0, check brightness
    led.setBrightness(0);
    sleep(Duration(seconds: 1));
    assert(led.getBrightness() == 0);
  } finally {
    led.dispose();
  }
}

void test_interactive(String device) {
  var led = Led(device);
  try {
    print('Starting interactive test.');
    print('Press enter to continue...');
    pressKey();

    print('LED description: ${led.getLedInfo()}');
    print('LED description looks OK? y/n');
    assert(pressKeyYes());

    // Turn LED off
    led.write(false);
    print('LED is off? y/n');
    assert(pressKeyYes());

    // Turn LED on
    led.write(true);
    print('LED is on? y/n');
    assert(pressKeyYes());

    // Turn LED off
    led.write(false);
    print('LED is off? y/n');
    assert(pressKeyYes());

    // Turn LED on
    led.write(true);
    print('LED is on? y/n');
    assert(pressKeyYes());
  } finally {
    led.dispose();
  }
}

void main(List<String> argv) {
  if (argv.isEmpty) {
    print('Usage led_test.dart <LED name>');
    print('[1/4] Arguments test: No requirements.');
    print('[2/4] Open/close test: LED should be real.');
    print('[3/4] Loopback test: No test.');
    print('[4/4] Interactive test: LED should be observed.\n');
    print('Hint: for Raspberry Pi 3, disable triggers for led1:');
    print('    \$ echo none > /sys/class/leds/led1/trigger');
    print('Observe led1 (red power LED), and run this test:');
    print('    led_test.dart led1\n');
    exit(1);
  }

  var device = argv[0];

  test_arguments();
  print('Arguments test passed.');
  test_open_config_close(device);
  print('Open/close test passed.');
  test_loopback();
  print('Loopback test passed.');
  test_interactive(device);
  print('Interactive test passed.');
  print('All tests passed!\n');
}
