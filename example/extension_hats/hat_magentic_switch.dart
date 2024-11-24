// https://wiki.seeedstudio.com/Grove-Magnetic_Switch/

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

import 'parse_cmd_line.dart';

const wait = 150;

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
      while (true) {
        var old = DigitalValue.low;
        while (true) {
          var value = hat.digitalRead(magnetPin);
          print(value);
          if (value != old) {
            hat.digitalWrite(ledPin, value);
          }
          sleep(Duration(milliseconds: 150));
          old = value;
        }
      }
    case Hat.grovePlus:
      break;
    case Hat.grove:
      var hat = GroveBaseHat();
      print("Firmeware ${hat.getFirmware()}");
      print("Extension hat ${hat.getName()}");
      print("Magnet digial pin: $magnetPin");
      print("Led digial pin: $ledPin");
      var magnet = GPIO(magnetPin, GPIOdirection.gpioDirIn);
      var led = GPIO(ledPin, GPIOdirection.gpioDirOut);

      var old = false;
      while (true) {
        var value = magnet.read();
        print(value);
        if (value != old) {
          led.write(value);
        }
        sleep(Duration(milliseconds: 150));
        old = value;
      }
  }
}
