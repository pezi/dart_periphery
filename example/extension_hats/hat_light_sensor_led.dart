// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:dart_periphery/dart_periphery.dart';

import 'parse_cmd_line.dart';

const wait = 500;
const treshold = 100;

/// https://wiki.seeedstudio.com/Grove-Light_Sensor/
///
/// In this demo, the LED turns on when the value of the light sensor falls
/// below a certain threshold.
///
/// Usage: [nano|grove|grovePlus] analogPin
void main(List<String> args) {
  String pinInfo = "Analog pin";
  var tupple = checkArgs2Pins(args, "analogPin", "ledPin");
  var analogPin = tupple.$2;
  var ledPin = tupple.$3;

  switch (tupple.$1) {
    case Hat.nano:
      {
        var hat = NanoHatHub();
        print(hat.getFirmwareVersion());
        hat.pinMode(ledPin, PinMode.output);
        print("$pinInfo: $analogPin");
        print("Led pin: $ledPin");

        hat.digitalWrite(ledPin, DigitalValue.low);
        bool ledStatus = false;

        while (true) {
          var value = hat.analogRead(analogPin);
          if (value < treshold) {
            if (!ledStatus) {
              ledStatus = true;
              hat.digitalWrite(ledPin, DigitalValue.high);
            }
          } else {
            if (ledStatus) {
              ledStatus = false;
              hat.digitalWrite(ledPin, DigitalValue.low);
            }
          }
          sleep(Duration(milliseconds: wait));
        }
      }
    case Hat.grovePlus:
      {
        var hat = NanoHatHub();
        print(hat.getFirmwareVersion());
        hat.pinMode(ledPin, PinMode.output);
        print("$pinInfo: $analogPin");
        print("Led pin: $ledPin");

        hat.digitalWrite(ledPin, DigitalValue.low);
        bool ledStatus = false;

        while (true) {
          var value = hat.analogRead(analogPin);
          if (value < treshold) {
            if (!ledStatus) {
              ledStatus = true;
              hat.digitalWrite(ledPin, DigitalValue.high);
            }
          } else {
            if (ledStatus) {
              ledStatus = false;
              hat.digitalWrite(ledPin, DigitalValue.low);
            }
          }
          sleep(Duration(milliseconds: wait));
        }
      }
    case Hat.grove:
      var hat = GroveBaseHat();
      print(hat.getFirmware());
      print(hat.getName());
      print("$pinInfo: $analogPin");
      print("Led pin: $ledPin");

      var led = GPIO(ledPin, GPIOdirection.gpioDirOut);
      led.write(false);

      bool ledStatus = false;

      while (true) {
        var value = hat.readADCraw(analogPin);
        if (value < treshold) {
          if (!ledStatus) {
            ledStatus = true;
            led.write(true);
          }
        } else {
          if (ledStatus) {
            ledStatus = false;
            led.write(false);
          }
        }
        sleep(Duration(milliseconds: wait));
      }
  }
}
