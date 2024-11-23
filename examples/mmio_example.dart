// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

/// https://elinux.org/RPi_GPIO_Code_Samples

const int bcm2708PeriBase = 0x3F000000; // Raspberry Pi 3
const int gpioBase = bcm2708PeriBase + 0x200000;
const int blockSize = 4 * 1024;

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
  // Needs root rights and the gpioBase must be correct!
  // var mmio = MMIO(gpioBase, blockSize);
  var mmio = MMIO.advanced(0, blockSize, '/dev/gpiomem');
  var gpio = MemMappedGPIO(mmio);
  try {
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print("MMIO demo");
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
