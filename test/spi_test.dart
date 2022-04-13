// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

// https://github.com/vsergeev/c-periphery/blob/master/tests/test_spi.c

import 'package:dart_periphery/dart_periphery.dart';
import 'util.dart';
import 'dart:io';
import 'package:collection/collection.dart';

void testArguments(int bus, int chip) {
  // Invalid mode
  // ppassert(spi_open(spi, device, 4, 1e6) == SPI_ERROR_ARG);
  // ppassert(spi_open_advanced(spi, device, 0, 1e6, LSB_FIRST+1, 8, 0) == SPI_ERROR_ARG);
  //
  // Due the usage of enums this invald parameter can not be mapped
}

void testOpenConfigClose(int bus, int chip) {
  var spi = SPI(bus, chip, SPImode.mode0, 100000);
  try {
    var isolate = SPI.isolate(spi.toJson());
    passert(spi.path == isolate.path);
    passert(spi.bitOrder == isolate.bitOrder);
    passert(spi.bitsPerWord == isolate.bitsPerWord);
    passert(spi.bus == isolate.bus);
    passert(spi.chip == isolate.chip);
    passert(spi.extraFlags == isolate.extraFlags);
    passert(spi.maxSpeed == isolate.maxSpeed);
    passert(spi.getHandle() == isolate.getHandle());

    passert(spi.bitOrder == BitOrder.msbFirst);
    passert(spi.bitsPerWord == 8);

    // Not going to try different bit order or bits per word, because not all
    //  SPI controllers support them

    for (var mode in SPImode.values) {
      spi.setSPImode(mode);
      passert(spi.getSPImode() == mode);
    }
    spi.setSPImode(SPImode.mode0);

    // Try 100KHz, 500KHz, 1MHz
    for (var f in [100e3, 500e3, 1e6]) {
      spi.setSPImaxSpeed(f.toInt());
      passert(spi.getSPImaxSpeed() == f.toInt());
    }
  } finally {
    spi.dispose();
  }
}

void testLoopback(int bus, int chip) {
  var spi = SPI(bus, chip, SPImode.mode0, 100000);
  try {
    Function eq = const ListEquality().equals;
    var data = <int>[for (int i = 0; i < 32; ++i) i];
    passert(eq(spi.transfer(data, false), data) == true);
  } finally {
    spi.dispose();
  }
}

void testInteractive(int bus, int chip) {
  var buf = [0x55, 0xaa, 0x0f, 0xf0];
  var spi = SPI(bus, chip, SPImode.mode0, 100000);
  try {
    print('Starting interactive test. Get out your logic analyzer, buddy!');
    print('Press enter to continue...');
    pressKey();
    print('SPI description: ${spi.getSPIinfo()}');
    print('SPI description looks OK? y/n');
    pressKeyYes();
    for (var mode in SPImode.values) {
      spi.setSPImode(mode);
      print('Press enter to start transfer...');
      pressKey();
      spi.transfer(buf, true);
      print('SPI data 0x55, 0xaa, 0x0f, 0xf');
      print('SPI transfer speed <= 100KHz, mode ${mode.index} occurred? y/n');
      pressKeyYes();
    }
    spi.setSPImode(SPImode.mode0);
    for (var f in [500e3, 1e6]) {
      spi.setSPImaxSpeed(f.toInt());
      print('Press enter to start transfer...');
      pressKey();
      spi.transfer(buf, true);
      print('SPI data 0x55, 0xaa, 0x0f, 0xf');
      print('SPI transfer speed <= ${f.toInt()}Hz, mode 0 occurred? y/n');
      pressKeyYes();
    }
  } finally {
    spi.dispose();
  }
}

void main(List<String> argv) {
  if (argv.length != 2) {
    print('Usage: dart spi_test.dart <bus> <chip>');
    print('Hint /dev/spidev[bus].[chip] e.g. /dev/spidev0.0');
    print('[1/4] Arguments test: No requirements.');
    print('[2/4] Open/close test: SPI device should be real.');
    print(
        '[3/4] Loopback test: SPI MISO and MOSI should be connected with a wire.');
    print(
        '[4/4] Interactive test: SPI MOSI, CLK, CS should be observed with an oscilloscope or logic analyzer.');
    print('Hint: for Raspberry Pi 3, enable SPI0 with:');
    print('   \$ echo "dtparam=spi=on" | sudo tee -a /boot/config.txt');
    print('   \$ sudo reboot');
    print(
        'Use pins SPI0 MOSI (header pin 19), SPI0 MISO (header pin 21), SPI0 SCLK (header pin 23),');
    print('connect a loopback between MOSI and MISO, and run this test with:');
    print('    dart spi_test.dart 0 0');
    exit(1);
  }

  var bus = int.parse(argv[0]);
  var chip = int.parse(argv[1]);

  testArguments(bus, chip);
  print('Arguments test passed.');
  testOpenConfigClose(bus, chip);
  print('Open/close test passed.');
  testLoopback(bus, chip);
  print('Loopback test passed.');
  testInteractive(bus, chip);
  print('Interactive test passed.');

  print('All tests passed!\n');
}
