// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Guards the Dart mappings of the native c-periphery structs gpio_config_t
// and spi_msg_t against layout drift - see https://github.com/pezi/dart_periphery/issues/55
//
// This test needs no GPIO hardware and no native library:
// dart test test/native_struct_layout_test.dart

import 'dart:ffi';

import 'package:dart_periphery/src/gpio.dart';
import 'package:dart_periphery/src/spi.dart';
import 'package:test/test.dart';

void main() {
  test('gpio_config_t size matches c-periphery', () {
    final is64bit = sizeOf<IntPtr>() == 8;
    final (current, legacy) = gpioConfigNativeSizes();
    // c-periphery >= v2.5.0: 6 x 4 bytes, bool + padding, pointer
    expect(current, is64bit ? 40 : 32);
    // c-periphery < v2.5.0: 4 x 4 bytes, bool + padding, pointer
    expect(legacy, is64bit ? 32 : 24);
  });

  test('spi_msg_t size matches c-periphery', () {
    final is64bit = sizeOf<IntPtr>() == 8;
    // 2 pointers, size_t, bool + padding, uint16_t, uint8_t + padding
    expect(spiMsgNativeSize(), is64bit ? 32 : 20);
  });
}
