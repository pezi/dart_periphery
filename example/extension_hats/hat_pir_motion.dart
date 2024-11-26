// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

import 'parse_cmd_line.dart';

const wait = 200;

/// https://wiki.seeedstudio.com/Grove-PIR_Motion_Sensor/
///
/// Usage: [nano|grove|grovePlus] pirMotionPin ledPin
void main(List<String> args) {
  String pinInfo = "Magenetic switch pin";
  var tupple = checkArgs2Pins(args, "pirMotionPin", "ledPin");
  var magnetPin = tupple.$2;
  var ledPin = tupple.$3;
  switch (tupple.$1) {
    case Hat.nano:
      var hat = NanoHatHub();
      print("Firmeware ${hat.getFirmwareVersion()}");
      print("$pinInfo: $magnetPin");
      print("Led pin: $ledPin");

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
      print("$pinInfo: $magnetPin");
      print("Led pin: $ledPin");

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
      print("$pinInfo: $magnetPin");
      print("Led pin: $ledPin");
      var pirMotion = GPIO(magnetPin, GPIOdirection.gpioDirIn);
      var led = GPIO(ledPin, GPIOdirection.gpioDirOut);
      led.write(false);

      var old = false;
      while (true) {
        var value = pirMotion.read();
        if (value != old) {
          led.write(value);
          if (value == true) {
            print("Motion detected");
          } else {
            print("Watching...");
          }
        }
        sleep(Duration(milliseconds: wait));
        old = value;
      }
  }
}
