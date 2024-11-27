// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:dart_periphery/dart_periphery.dart';

import 'parse_cmd_line.dart';

const wait = 500;

/// https://wiki.seeedstudio.com/Grove-Light_Sensor/
///
/// Usage: [nano|grove|grovePlus] analogPin
void main(List<String> args) {
  var tupple = checkArgs(args, "analogPin");
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
        sleep(Duration(milliseconds: wait));
      }
  }
}
