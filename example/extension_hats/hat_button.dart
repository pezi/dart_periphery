// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

import 'parse_cmd_line.dart';

const wait = 150;

/// https://wiki.friendlyelec.com/wiki/index.php/BakeBit_-_Button
///
/// Usage: [nano|grove|grovePlus] buttonPin ledPin
void main(List<String> args) {
  String pinInfo = "Button pin";
  var tupple = checkArgs2Pins(args, "buttonPin", "ledPin");
  var buttonPin = tupple.$2;
  var ledPin = tupple.$3;
  var hat = tupple.$1;
  switch (hat) {
    case Hat.nano:
      var hat = NanoHatHub();
      print("Firmeware ${hat.getFirmwareVersion()}");
      print("$pinInfo: $buttonPin");
      print("Led pin: $ledPin");

      hat.pinMode(buttonPin, PinMode.input);
      hat.pinMode(ledPin, PinMode.output);
      hat.digitalWrite(ledPin, DigitalValue.low);

      // BakeBit button: button is not pressed the module will output high
      // otherwise it will output low.
      var old = DigitalValue.high;
      while (true) {
        var value = hat.digitalRead(buttonPin);
        print(value);
        if (value != old) {
          hat.digitalWrite(ledPin, value.invert());
        }
        sleep(Duration(milliseconds: wait));
        old = value;
      }

    case Hat.grovePlus:
      var hat = GrovePiPlusHat();
      print("Firmeware ${hat.getFirmwareVersion()}");
      print("$pinInfo: $buttonPin");
      print("Led pin: $ledPin");

      hat.pinMode(buttonPin, PinMode.input);
      hat.pinMode(ledPin, PinMode.output);
      hat.digitalWrite(ledPin, DigitalValue.low);

      var old = DigitalValue.high;
      while (true) {
        var value = hat.digitalRead(buttonPin);
        print(value);
        if (value != old) {
          hat.digitalWrite(ledPin, value.invert());
        }
        sleep(Duration(milliseconds: wait));
        old = value;
      }

    case Hat.gpio:
    case Hat.grove:
      if (hat == Hat.grove) {
        var hat = GroveBaseHat();
        print("Firmeware ${hat.getFirmware()}");
        print("Extension hat ${hat.getName()}");
      }
      print("$pinInfo: $buttonPin");
      print("Led pin: $ledPin");

      var button = GPIO(buttonPin, GPIOdirection.gpioDirIn);
      var led = GPIO(ledPin, GPIOdirection.gpioDirOut);
      led.write(false);

      var old = true;
      while (true) {
        var value = button.read();
        print(value);
        if (value != old) {
          led.write(!value);
        }
        sleep(Duration(milliseconds: wait));
        old = value;
      }
  }
}
