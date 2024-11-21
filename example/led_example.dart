// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

// On-board led status change demo.
void main() {
  /// Nano Pi power led - see 'ls /sys/class/leds/'
  var led = Led('nanopi:red:pwr');
  try {
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}\n");
    print('Led handle: ${led.getLedInfo()}');
    print('Led name: ${led.getLedName()}');
    print('Led brightness: ${led.getBrightness()}');
    print('Led maximum brightness: ${led.getMaxBrightness()}');
    var inverse = !led.read();
    print('Original led status: ${(!inverse)}');
    print('Toggle led');
    led.write(inverse);
    sleep(Duration(seconds: 5));
    inverse = !inverse;
    print('Toggle led');
    led.write(inverse);
    sleep(Duration(seconds: 5));
    print('Toggle led');
    inverse = !inverse;
    led.write(inverse);
    sleep(Duration(seconds: 5));
    print('Toggle led');
    led.write(!inverse);
  } finally {
    led.dispose();
  }
}
