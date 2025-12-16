// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*
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

/// Engineering mode data containing energy values for each distance gate
class EngineeringData {
  final int maxMovingDistanceGate;
  final int maxStaticDistanceGate;
  final List<int>
      movingEnergyGates; // Energy values for each moving distance gate
  final List<int>
      staticEnergyGates; // Energy values for each static distance gate

  const EngineeringData({
    required this.maxMovingDistanceGate,
    required this.maxStaticDistanceGate,
    required this.movingEnergyGates,
    required this.staticEnergyGates,
  });

  @override
  String toString() {
    return 'EngineeringData(maxMovingDistanceGate: $maxMovingDistanceGate, '
        'maxStaticDistanceGate: $maxStaticDistanceGate, '
        'movingEnergyGates: $movingEnergyGates, '
        'staticEnergyGates: $staticEnergyGates)';
  }
}

class RadarReading {
  final DateTime timestamp;
  final TargetState targetState;
  final int movingTargetDistance;
  final int movingTargetEnergy;
  final int staticTargetDistance;
  final int staticTargetEnergy;
  final int detectionDistance;
  final EngineeringData? engineeringData;

  RadarReading({
    required this.targetState,
    required this.movingTargetDistance,
    required this.movingTargetEnergy,
    required this.staticTargetDistance,
    required this.staticTargetEnergy,
    required this.detectionDistance,
    this.engineeringData,
  }) : timestamp = DateTime.now();

  /// Check if the radar reading contains valid data
  bool isValid() {
    return (0 <= detectionDistance &&
            detectionDistance <= 600) && // Max 6m detection range
        (-100 <= movingTargetEnergy && movingTargetEnergy <= 100) &&
        (-100 <= staticTargetEnergy && staticTargetEnergy <= 100) &&
        (targetState != TargetState.unknown);
  }

  @override
  String toString() {
    return 'RadarReading(timestamp: $timestamp, '
        'targetState: $targetState, '
        'movingTargetDistance: $movingTargetDistance, '
        'movingTargetEnergy: $movingTargetEnergy, '
        'staticTargetDistance: $staticTargetDistance, '
        'staticTargetEnergy: $staticTargetEnergy, '
        'detectionDistance: $detectionDistance, '
        'engineeringData: $engineeringData)';
  }
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
