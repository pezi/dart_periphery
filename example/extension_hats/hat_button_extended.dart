// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

import 'parse_cmd_line.dart';

const wait = 50;
const holdTime = 1000;

/// https://wiki.friendlyelec.com/wiki/index.php/BakeBit_-_Button
///
/// Usage: [gpio|nano|grove|grovePlus] buttonPin ledPin
void main(List<String> args) {
  String pinInfo = "Button pin";
  var tuple = checkArgs2Pins(false, args, "buttonPin", "ledPin");
  var buttonPin = tuple.$2;
  var ledPin = tuple.$3;
  var hat = tuple.$1;

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

      while (true) {
        buttonState = hat.digitalRead(buttonPin) ==
            DigitalValue.high; // Button is pressed when LOW

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
            hat.digitalWrite(
                ledPin, ledState ? DigitalValue.high : DigitalValue.low);
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

    case Hat.grovePlus:
      var hat = GrovePiPlusHat();
      print("Firmeware ${hat.getFirmwareVersion()}");
      print("$pinInfo: $buttonPin");
      print("Led pin: $ledPin");

      hat.pinMode(buttonPin, PinMode.input);
      hat.pinMode(ledPin, PinMode.output);
      hat.digitalWrite(ledPin, DigitalValue.low);
      while (true) {
        buttonState = hat.digitalRead(buttonPin) ==
            DigitalValue.high; // Button is pressed when LOW

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
            hat.digitalWrite(
                ledPin, ledState ? DigitalValue.high : DigitalValue.low);
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
