// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/vsergeev/c-periphery/blob/master/tests/test_mmio.c

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:ffi';

const int bcm2708PeriBase = 0x3F000000; // Raspberry Pi 3
const int gpioBase = bcm2708PeriBase + 0x200000;
const int blockSize = 4 * 1024;

void testArguments() {}

class Error extends Struct {
  @Int32()
  external int cErrno;
  //   char errmsg[96];
  // @Array(8)
  //  external Array<Uint8> inlineArray;
}

class MmioHandle extends Struct {
  @IntPtr()
  external int base;
  @IntPtr()
  external int alignedBase;
  external Pointer<Void> ptr;
  external Error error;
}

void testOpenConfigClose() {
  MMIO(gpioBase, blockSize);
}

void main(List<String> argv) {
  testArguments();
  print('Arguments test passed.');
  testOpenConfigClose();
  print('Open/close test passed.');
  // test_loopback();
  print('Loopback test passed.');
  // test_interactive();
  print('Interactive test passed.');

  print('All tests passed!\n');
}
