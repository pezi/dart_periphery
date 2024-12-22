// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

import 'parse_cmd_line.dart';

const wait = 50;
const holdTime = 1000;

/// https://wiki.friendlyelec.com/wiki/index.php/BakeBit_-_Button
///
/// Usage: [nano|grove|grovePlus] buttonPin ledPin
void main(List<String> args) {
  String pinInfo = "Button pin";
  var tupple = checkArgs2Pins(args, "buttonPin", "ledPin");
  var buttonPin = tupple.$2;
  var ledPin = tupple.$3;
  var hat = tupple.$1;

  const holdTime = 1000; // Time to hold the button (in ms) to toggle LED

  bool ledState = false; // Tracks the current LED state
  var buttonPressedTime = 0; // Stores when the button was pressed
  bool buttonHeld = false; // Tracks if the button has been held long enough
  bool buttonState = false; // Current button state
  bool lastButtonState = false; // Previous button state

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

      while (true) {
        buttonState = button.read(); // Button is pressed when LOW

        if (buttonState && !lastButtonState) {
          // Button just pressed
          buttonPressedTime = DateTime.now().millisecondsSinceEpoch;
          buttonHeld = false;
        }

        if (!buttonState && lastButtonState) {
          // Button just released
          if (buttonHeld) {
            // Toggle the LED state if the button was held long enough
            ledState = !ledState;
            led.write(ledState);
          }
        }

        // Check if the button is still pressed and held long enough
        if (buttonState &&
            !buttonHeld &&
            (DateTime.now().millisecondsSinceEpoch - buttonPressedTime >=
                holdTime)) {
          buttonHeld = true; // Mark the button as held long enough
        }

        // Update the last button state
        lastButtonState = buttonState;
      }
  }
}
