// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

import 'parse_cmd_line.dart';

const wait = 150;

/// https://wiki.seeedstudio.com/Grove-Magnetic_Switch/
///
/// Usage: [nano|grove|grovePlus] vibrationPin ledPin
void main(List<String> args) {
  var tupple = checkArgs2Pins(args, "magenetPin", "ledPin");
  var magnetPin = tupple.$2;
  var ledPin = tupple.$3;
  switch (tupple.$1) {
    case Hat.nano:
      var hat = NanoHatHub();
      print("Firmeware ${hat.getFirmwareVersion()}");
      print("Magnet digital pin IN: $magnetPin");
      print("Led digital pin OUT: $ledPin");

      hat.pinMode(magnetPin, PinMode.input);
      hat.pinMode(ledPin, PinMode.output);

      var old = DigitalValue.low;
      while (true) {
        var value = hat.digitalRead(magnetPin);
        print(value);
        if (value != old) {
          hat.digitalWrite(ledPin, value);
        }
        sleep(Duration(milliseconds: wait));
        old = value;
      }

    case Hat.grovePlus:
      var hat = GrovePiPlusHat();
      print("Firmeware ${hat.getFirmwareVersion()}");
      print("Magnet digial pin IN: $magnetPin");
      print("Led digital pin OUT: $ledPin");

      hat.pinMode(magnetPin, PinMode.input);
      hat.pinMode(ledPin, PinMode.output);

      var old = DigitalValue.low;
      while (true) {
        var value = hat.digitalRead(magnetPin);
        print(value);
        if (value != old) {
          hat.digitalWrite(ledPin, value);
        }
        sleep(Duration(milliseconds: wait));
        old = value;
      }

    case Hat.grove:
      var hat = GroveBaseHat();
      print("Firmeware ${hat.getFirmware()}");
      print("Extension hat ${hat.getName()}");
      print("Magnet digital pin IN: $magnetPin");
      print("Led digital pin OUT: $ledPin");
      var magnet = GPIO(magnetPin, GPIOdirection.gpioDirIn);
      var led = GPIO(ledPin, GPIOdirection.gpioDirOut);
      led.write(false);

      var old = false;
      while (true) {
        var value = magnet.read();
        print(value);
        if (value != old) {
          led.write(value);
        }
        sleep(Duration(milliseconds: wait));
        old = value;
      }
  }
}
