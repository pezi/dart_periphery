// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:dart_periphery/dart_periphery.dart';
import 'package:dart_periphery/src/hardware/air530.dart';

/// GPS Sensor
///
/// [GPS Sensor](https://www.seeedstudio.com/SeeedGrove-GPS-Air530-p-4584.html)
///
void main() {
  // RasperyPi (for Armbian use e.g. /dev/ttyS1)
  var s = Serial('/dev/serial0', Baudrate.b9600);
  try {
    while (true) {
      var event = s.read(512, 1000);
      final gps = NmeaParser.parse(event.toString());
      print(gps);
      sleep(Duration(seconds: 5));
    }
  } finally {
    s.dispose();
  }
}
