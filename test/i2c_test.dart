// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

// https://github.com/vsergeev/c-periphery/blob/master/tests/test_i2c.c

import 'package:dart_periphery/dart_periphery.dart';
import 'util.dart';
import 'dart:io';

void test_arguments() {
  /* No real argument validation needed in the i2c wrapper */
}

void test_open_config_close(int i2cNum) {
  try {
    I2C(99999);
  } on I2Cexception catch (e) {
    if (e.errorCode != I2CerrorCode.I2C_ERROR_OPEN) {
      rethrow;
    }
  }
  var validBus = I2C(i2cNum);
  validBus.dispose();
}

void test_loopback() {
  print(
      'No general way to do a loopback test for I2C without a real component, skipping...');
}

void test_interactive(int i2cNum) {
  var msg = [0xaa, 0xbb, 0xcc, 0xdd];
  var i2c = I2C(i2cNum);
  try {
    print('Starting interactive test. Get out your logic analyzer, buddy!');
    print('Press enter to continue...');
    pressKey();
    print('I2C description: ${i2c.getI2Cinfo()}');
    print('I2C description looks OK? y/n');
    pressKeyYes();
    print('Press enter to start transfer...');
    pressKey();
    try {
      i2c.writeBytes(0x7a, msg);
    } on I2Cexception catch (e) {
      assert(i2c.getErrno() == ERNO.EREMOTEIO.index ||
          i2c.getErrno() == ERNO.ENXIO.index);
      assert(e.errorCode == I2CerrorCode.I2C_ERROR_TRANSFER);
    }
    print('I2C transfer occurred? y/n');
    pressKeyYes();
  } finally {
    i2c.dispose();
  }
}

void main(List<String> argv) {
  if (argv.length != 1) {
    print(' "Usage: dart i2c_test.dart <bus>');

    print('[1/4] Arguments test: No requirements.');
    print('[2/4] Open/close test: I2C device should be real.');
    print('[3/4] Loopback test: No test.\.');
    print(
        '[4/4] Interactive test: I2C bus should be observed with an oscilloscope or logic analyzer.');
    print('Hint: for Raspberry Pi 3, enable I2C1 with:');
    print('   \$ echo "dtparam=i2c_arm=on" | sudo tee -a /boot/config.txt');
    print('   \$ sudo reboot');
    print('Use pins I2C1 SDA (header pin 2) and I2C1 SCL (header pin 3)');
    print('and run this test with:');
    print('    dart i2c_test.dart 1');
    exit(1);
  }

  var i2cNum = int.parse(argv[0]);

  test_arguments();
  print('Arguments test passed.');
  test_open_config_close(i2cNum);
  print('Open/close test passed.');
  test_loopback();
  print('Loopback test passed.');
  test_interactive(i2cNum);
  print('Interactive test passed.');

  print('All tests passed!\n');
}
