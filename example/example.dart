// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

void main() {
  GPIOconfig config = GPIOconfig();
  config.direction = GPIOdirection.GPIO_DIR_OUT;

  print("GPIO test");
  GPIO gpio = GPIO(18, GPIOdirection.GPIO_DIR_OUT);
  GPIO gpio2 = GPIO(16, GPIOdirection.GPIO_DIR_OUT);
  GPIO gpio3 = GPIO.advanced(5, config);

  print("GPIO info: " + gpio.getGPIOinfo());

  print("GPIO native file handle: " + gpio.getGPIOfd().toString());
  print("GPIO chip name: " + gpio.getGPIOchipName());
  print("GPIO chip label: " + gpio.getGPIOchipLabel());
  print("GPIO chip name: " + gpio.getGPIOchipName());
  print("CPIO chip label: " + gpio.getGPIOchipLabel());

  for (int i = 0; i < 10; ++i) {
    gpio.write(true);
    gpio2.write(true);
    gpio3.write(true);
    sleep(Duration(milliseconds: 200));
    gpio.write(false);
    gpio2.write(false);
    gpio3.write(false);
    sleep(Duration(milliseconds: 200));
  }

  gpio.dispose();
  gpio2.dispose();
  gpio3.dispose();
}
