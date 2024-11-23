import 'dart:io';
import 'package:dart_periphery/dart_periphery.dart';

void main() {
  var hat = NanoHatHub();

  print(hat.getFirmwareVersion());
  while (true) {
    print(hat.analogRead(0));
    sleep(Duration(milliseconds: 100));
  }
}
