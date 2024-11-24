import 'dart:io';
import 'package:dart_periphery/dart_periphery.dart';

enum Hat { nano, grove, grovePlus }

void usage() {
  print("Parameter: [nano|grove|grovePlus] anlogPIn");
}

(Hat hat, int pin) checkArgs(List<String> args) {
  if (args.length != 2) {
    usage();
    exit(0);
  }
  return (Hat.values.byName(args[0]), int.parse(args[0]));
}

const wait = 500;

void main(List<String> args) {
  var tupple = checkArgs(args);
  var pin = tupple.$2;
  switch (tupple.$1) {
    case Hat.nano:
      {
        var hat = NanoHatHub();
        print(hat.getFirmwareVersion());
        while (true) {
          print(hat.analogRead(pin));
          sleep(Duration(milliseconds: wait));
        }
      }
    case Hat.grovePlus:
      {
        var hat = NanoHatHub();
        print(hat.getFirmwareVersion());
        while (true) {
          print(hat.analogRead(pin));
          sleep(Duration(milliseconds: wait));
        }
      }
    case Hat.grove:
      var hat = GroveBaseHat();
      print(hat.getFirmware());
      print(hat.getName());

      while (true) {
        print(hat.readADCraw(pin));
        sleep(Duration(milliseconds: 100));
      }
  }
}
