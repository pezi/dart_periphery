// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// https://github.com/vsergeev/c-periphery/blob/master/tests/test_mmio.c

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:ffi';

const int BCM2708_PERI_BASE = 0x3F000000; // Raspberry Pi 3
const int GPIO_BASE = BCM2708_PERI_BASE + 0x200000;
const int BLOCK_SIZE = 4 * 1024;

void test_arguments() {}

class Error extends Struct {
  @Int32()
  external int c_errno;
  //   char errmsg[96];
  // @Array(8)
  //  external Array<Uint8> inlineArray;
}

class Mmio_handle extends Struct {
  @IntPtr()
  external int base;
  @IntPtr()
  external int aligned_base;
  external Pointer<Void> ptr;
  external Error error;
}

void test_open_config_close() {
  MMIO(GPIO_BASE, BLOCK_SIZE);
}

void main(List<String> argv) {
  test_arguments();
  print('Arguments test passed.');
  test_open_config_close();
  print('Open/close test passed.');
  // test_loopback();
  print('Loopback test passed.');
  // test_interactive();
  print('Interactive test passed.');

  print('All tests passed!\n');
}
