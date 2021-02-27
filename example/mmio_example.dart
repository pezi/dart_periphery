// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

/// https://elinux.org/RPi_GPIO_Code_Samples

const int BCM2708_PERI_BASE = 0x3F000000; // Raspberry Pi 3
const int GPIO_BASE = BCM2708_PERI_BASE + 0x200000;
const int BLOCK_SIZE = 4 * 1024;

class MemMappedGPIO {
  MMIO mmio;
  MemMappedGPIO(this.mmio);

  // #define INP_GPIO(g) *(gpio+((g)/10)) &= ~(7<<(((g)%10)*3))
  void setPinInput(final int pin) {
    var offset = (pin ~/ 10) * 4;
    var value = mmio[offset];
    value &= (~(7 << (((pin) % 10) * 3)));
    mmio[offset] = value;
  }

  // #define OUT_GPIO(g) *(gpio+((g)/10)) |=  (1<<(((g)%10)*3))
  void setPinOutput(final int pin) {
    setPinInput(pin);
    var offset = (pin ~/ 10) * 4;
    var value = mmio[offset];
    value |= (1 << (((pin) % 10) * 3));
    mmio[offset] = value;
  }

  // #define GPIO_SET *(gpio+7) - sets   bits which are 1 ignores bits which are 0
  void setPinHigh(int pin) {
    mmio[7 * 4] = 1 << pin;
  }

  // #define GPIO_CLR *(gpio+10) - clears bits which are 1 ignores bits which are 0
  void setPinLow(int pin) {
    mmio[10 * 4] = 1 << pin;
  }

  // #define GET_GPIO(g) (*(gpio+13)&(1<<g)) - 0 if LOW, (1<<g) if HIGH
  int getPin(int pin) {
    return mmio[13 * 4] & (1 << pin);
  }
}

void main() {
  // Needs root rights and the GPIO_BASE must be correct!
  // var mmio = MMIO(GPIO_BASE, BLOCK_SIZE);
  var mmio = MMIO.advanced(0, BLOCK_SIZE, '/dev/gpiomem');
  var gpio = MemMappedGPIO(mmio);
  try {
    print(mmio.getMMIOinfo());
    var pin = 18;
    print('Led (pin=18) on');
    gpio.setPinOutput(pin);
    gpio.setPinHigh(pin);
    sleep(Duration(seconds: 10));
    gpio.setPinLow(pin);
    print('Led (pin=18) off');
  } finally {
    mmio.dispose();
  }
}
