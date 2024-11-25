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
  var tupple = checkArgs2Pins(args);
  var buttonPin = tupple.$2;
  var ledPin = tupple.$3;
  switch (tupple.$1) {
    case Hat.nano:
      var hat = NanoHatHub();
      print("Firmeware ${hat.getFirmwareVersion()}");
      print("Button digital pin IN: $buttonPin");
      print("Led digial pin OUT: $ledPin");

      hat.pinMode(buttonPin, PinMode.input);
      hat.pinMode(ledPin, PinMode.output);
      hat.digitalWrite(ledPin, DigitalValue.low);

      // BakeBit button: button is not pressed the module will output high otherwise it will output low.
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
      print("Button digital pin IN: $buttonPin");
      print("Led digial pin OUT: $ledPin");

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

    case Hat.grove:
      var hat = GroveBaseHat();
      print("Firmeware ${hat.getFirmware()}");
      print("Extension hat ${hat.getName()}");
      print("Button digital pin IN: $buttonPin");
      print("Led digial pin OUT: $ledPin");

      var magnet = GPIO(buttonPin, GPIOdirection.gpioDirIn);
      var led = GPIO(ledPin, GPIOdirection.gpioDirOut);
      led.write(false);

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
