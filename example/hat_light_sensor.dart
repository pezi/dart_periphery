import 'dart:io';
import 'package:dart_periphery/dart_periphery.dart';

void main() {
  var hat = GroveBaseHat();
  print(hat.getFirmware());
  print(hat.getName());
  while (true) {
    print(hat.readADCraw(0));
    sleep(Duration(milliseconds: 500));
  }
}
