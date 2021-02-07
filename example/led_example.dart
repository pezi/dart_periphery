// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

void main() {
  /// Nano Pi power led - see 'ls /sys/class/leds/'
  Led led = Led('nanopi:red:pwr');
  try {
    print("Led handle: " + led.getLedInfo());
    print("Led name: " + led.getLedName());
    print("Led brightness: " + led.getBrightness().toString());
    print("Led maximum brightness: " + led.getMaxBrightness().toString());
    bool inverse = !led.read();
    print("Original led status: " + (!inverse).toString());
    print("Toggle led");
    led.write(inverse);
    sleep(Duration(seconds: 5));
    inverse = !inverse;
    print("Toggle led");
    led.write(inverse);
    sleep(Duration(seconds: 5));
    print("Toggle led");
    inverse = !inverse;
    led.write(inverse);
    sleep(Duration(seconds: 5));
    print("Toggle led");
    led.write(!inverse);
  } finally {
    led.dispose();
  }
}
