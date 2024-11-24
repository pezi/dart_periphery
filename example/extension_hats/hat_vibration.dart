// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'package:dart_periphery/src/hardware/extension_hat.dart';
import 'dart:io';

import 'parse_cmd_line.dart';

const wait = 150;

/// https://wiki.seeedstudio.com/Grove-Vibration_Sensor_SW-420/

///
/// Usage: [nano|grove|grovePlus] magentPin ledPin
void main(List<String> args) {
  var tupple = checkArgs2Pins(args);
  var magnetPin = tupple.$2;
  var ledPin = tupple.$3;
  switch (tupple.$1) {
    case Hat.nano:
      var hat = NanoHatHub();
      print("Firmeware ${hat.getFirmwareVersion()}");
      print("Magnet digial pin: $magnetPin");
      print("Led digial pin: $ledPin");

      var old = DigitalValue.high;
      while (true) {
        var value = hat.digitalRead(magnetPin);
        print(value);
        if (value != old) {
          hat.digitalWrite(ledPin, value.negate());
        }
        sleep(Duration(milliseconds: wait));
        old = value;
      }

    case Hat.grovePlus:
      var hat = GrovePiPlusHat();
      print("Firmeware ${hat.getFirmwareVersion()}");
      print("Magnet digial pin: $magnetPin");
      print("Led digial pin: $ledPin");

      var old = DigitalValue.high;
      while (true) {
        var value = hat.digitalRead(magnetPin);
        print(value);
        if (value != old) {
          hat.digitalWrite(ledPin, value.negate());
        }
        sleep(Duration(milliseconds: wait));
        old = value;
      }
    case Hat.grove:
      var hat = GroveBaseHat();
      print("Firmeware ${hat.getFirmware()}");
      print("Extension hat ${hat.getName()}");
      print("Magnet digial pin: $magnetPin");
      print("Led digial pin: $ledPin");
      var magnet = GPIO(magnetPin, GPIOdirection.gpioDirIn);
      var led = GPIO(ledPin, GPIOdirection.gpioDirOut);

      var old = true;
      while (true) {
        var value = magnet.read();
        print(value);
        if (value != old) {
          led.write(!value);
        }
        sleep(Duration(milliseconds: wait));
        old = value;
      }
  }
}
