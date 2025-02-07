// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:dart_periphery/dart_periphery.dart';

bool confirm() {
  while (true) {
    stdout.write("Do you want to continue? (yes/no): ");
    String? input = stdin.readLineSync()?.trim().toLowerCase();

    if (input == 'yes' || input == 'y') {
      return true;
    } else if (input == 'no' || input == 'n') {
      return false;
    } else {
      print("Invalid input. Please enter 'yes' or 'no'.");
    }
  }
}

/// DS1307 real time clock
///
/// https://wiki.seeedstudio.com/Grove-RTC
///
/// Hint: Be aware that many DS1307 modules in circulation operate
/// exclusively at 5V.
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(1);
  try {
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print('I2C info: ${i2c.getI2Cinfo()}');
    print("DS1307 real time clock");

    var rtc = DS1307(i2c, true);
    print("Get current RTC date and time");
    print(rtc.getDateTime());

    print("Set RTC to current sytem time?");
    if (!confirm()) {
      return;
    }
    var now = DateTime.now();
    print(now);
    rtc.setDateTime(now);
    print("Get current RTC date and time");
    print(rtc.getDateTime());
    if (rtc.isDS2131) {
      print("RTC on board temperature sensor: ${rtc.getTemperature()}");
    }

    print("Set system time to RTC time? ROOT rights needed!");
    if (!confirm()) {
      return;
    }
    if (!setLinuxLocalTime(rtc.getDateTime())) {
      print("Failed to set system time. Are you running as root?");
    } else {
      print("System time successfully set!");
    }
  } finally {
    i2c.dispose();
  }
}
