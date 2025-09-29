// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*
  https://github.com/adafruit/Adafruit_CircuitPython_VEML7700/blob/main/adafruit_veml7700.py
  https://github.com/iavorvel/MyLD2410/blob/master/src/MyLD2410.cpp
  https://github.com/csRon/HLK-LD2410B
  https://github.com/aakash30jan/Radar-24GHz-HLK-LD2410B
  https://github.com/aakash30jan/Radar-24GHz-HLK-LD2410B/blob/main/radar_handler.py
*/

import 'package:dart_periphery/dart_periphery.dart';

enum TargetState {
  noTarget,
  movingTarget,
  staticTarget,
  bothTargets,
  unknown,
}

final List<int> commandHeader = [0xFD, 0xFC, 0xFB, 0xFA];
final List<int> commandTail = [0x04, 0x03, 0x02, 0x01];
final List<int> reportHeader = [0xF4, 0xF3, 0xF2, 0xF1];
final List<int> reportTail = [0xF8, 0xF7, 0xF6, 0xF5];

class LD2410B {
  final Serial serial;
  final List<int> readingsBuffer = [];
  final bool engineeringMode;
  final bool debug;

  LD2410B(this.serial, [this.engineeringMode = false, this.debug = false]);

  void sendCommand(List<int> command, List<int> param) {
    int frameLen = command.length + param.length;

    var data = <int>[];
    data.addAll(commandHeader);
    data.add(frameLen & 0xff);
    data.add(frameLen >> 8);
    data.addAll(commandTail);
    serial.write(data);

    // serial.read(len, timeout)
  }
}
