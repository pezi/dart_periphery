// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://wiki.seeedstudio.com/Grove-Gesture_v1.0/
// https://github.com/Seeed-Studio/Gesture_PAJ7620/
// https://github.com/DexterInd/GrovePi/blob/master/Software/Python/grove_gesture_sensor/grove_gesture_sensor.py

import 'dart:io';
import '../i2c.dart';

const int GESTURE_REACTION_TIME = 500;
const int GESTURE_QUIT_TIME = 1000;

enum Bank { BANK0, BANK1 }

const int PAJ7620_ADDR_BASE = 0x00;

// REGISTER BANK SELECT
const int PAJ7620_REGITER_BANK_SEL = (PAJ7620_ADDR_BASE + 0xEF); //W

// DEVICE ID
const int PAJ7620_ID = 0x73;

// REGISTER BANK 0
const int PAJ7620_ADDR_SUSPEND_CMD = (PAJ7620_ADDR_BASE + 0x3); //W
const int PAJ7620_ADDR_GES_PS_DET_MASK_0 = (PAJ7620_ADDR_BASE + 0x41); //RW
const int PAJ7620_ADDR_GES_PS_DET_MASK_1 = (PAJ7620_ADDR_BASE + 0x42); //RW
const int PAJ7620_ADDR_GES_PS_DET_FLAG_0 = (PAJ7620_ADDR_BASE + 0x43); //R
const int PAJ7620_ADDR_GES_PS_DET_FLAG_1 = (PAJ7620_ADDR_BASE + 0x44); //R
const int PAJ7620_ADDR_STATE_INDICATOR = (PAJ7620_ADDR_BASE + 0x45); //R
const int PAJ7620_ADDR_PS_HIGH_THRESHOLD = (PAJ7620_ADDR_BASE + 0x69); //RW
const int PAJ7620_ADDR_PS_LOW_THRESHOLD = (PAJ7620_ADDR_BASE + 0x6A); //RW
const int PAJ7620_ADDR_PS_APPROACH_STATE = (PAJ7620_ADDR_BASE + 0x6B); //R
const int PAJ7620_ADDR_PS_RAW_DATA = (PAJ7620_ADDR_BASE + 0x6C); //R

// REGISTER BANK 1
const int PAJ7620_ADDR_PS_GAIN = (PAJ7620_ADDR_BASE + 0x44); //RW
const int PAJ7620_ADDR_IDLE_S1_STEP_0 = (PAJ7620_ADDR_BASE + 0x67); //RW
const int PAJ7620_ADDR_IDLE_S1_STEP_1 = (PAJ7620_ADDR_BASE + 0x68); //RW
const int PAJ7620_ADDR_IDLE_S2_STEP_0 = (PAJ7620_ADDR_BASE + 0x69); //RW
const int PAJ7620_ADDR_IDLE_S2_STEP_1 = (PAJ7620_ADDR_BASE + 0x6A); //RW
const int PAJ7620_ADDR_OP_TO_S1_STEP_0 = (PAJ7620_ADDR_BASE + 0x6B); //RW
const int PAJ7620_ADDR_OP_TO_S1_STEP_1 = (PAJ7620_ADDR_BASE + 0x6C); //RW
const int PAJ7620_ADDR_OP_TO_S2_STEP_0 = (PAJ7620_ADDR_BASE + 0x6D); //RW
const int PAJ7620_ADDR_OP_TO_S2_STEP_1 = (PAJ7620_ADDR_BASE + 0x6E); //RW
const int PAJ7620_ADDR_OPERATION_ENABLE = (PAJ7620_ADDR_BASE + 0x72); //RW

//PAJ7620_REGITER_BANK_SEL
const int PAJ7620_BANK0 = 0;
const int PAJ7620_BANK1 = 1;

//PAJ7620_ADDR_SUSPEND_CMD
const int PAJ7620_I2C_WAKEUP = 1;
const int PAJ7620_I2C_SUSPEND = 0;

//PAJ7620_ADDR_OPERATION_ENABLE
const int PAJ7620_ENABLE = 1;
const int PAJ7620_DISABLE = 0;

//ADC, delete
const int REG_ADDR_RESULT = 0x00;
const int REG_ADDR_ALERT = 0x01;
const int REG_ADDR_CONFIG = 0x02;
const int REG_ADDR_LIMITL = 0x03;
const int REG_ADDR_LIMITH = 0x04;
const int REG_ADDR_HYST = 0x05;
const int REG_ADDR_CONVL = 0x06;
const int REG_ADDR_CONVH = 0x07;

const int GES_RIGHT_FLAG = 1 << 0;
const int GES_LEFT_FLAG = 1 << 1;
const int GES_UP_FLAG = 1 << 2;
const int GES_DOWN_FLAG = 1 << 3;
const int GES_FORWARD_FLAG = 1 << 4;
const int GES_BACKWARD_FLAG = 1 << 5;
const int GES_CLOCKWISE_FLAG = 1 << 6;
const int GES_COUNT_CLOCKWISE_FLAG = 1 << 7;
const int GES_WAVE_FLAG = 1 << 0;

/// [GestureSensorException] exception
class GestureSensorException implements Exception {
  final String errorMsg;
  @override
  String toString() => errorMsg;

  GestureSensorException(this.errorMsg);
}

/// [Gesture] directions
enum Gesture {
  NOTHING,
  FORWARD,
  FORWARD_BACKWARD,
  BACKWARD,
  BACKWARD_FORWARD,
  RIGHT,
  RIGHT_LEFT,
  LEFT,
  LEFT_RIGHT,
  UP,
  UP_DOWN,
  DOWN,
  DOWN_UP,
  CLOCKWISE,
  ANTI_CLOCKWISE,
  WAVE
}

// Initial register state
var initRegisterArray = <int>[
  0xEF00,
  0x3229,
  0x3301,
  0x3400,
  0x3501,
  0x3600,
  0x3707,
  0x3817,
  0x3906,
  0x3A12,
  0x3F00,
  0x4002,
  0x41FF,
  0x4201,
  0x462D,
  0x470F,
  0x483C,
  0x4900,
  0x4A1E,
  0x4B00,
  0x4C20,
  0x4D00,
  0x4E1A,
  0x4F14,
  0x5000,
  0x5110,
  0x5200,
  0x5C02,
  0x5D00,
  0x5E10,
  0x5F3F,
  0x6027,
  0x6128,
  0x6200,
  0x6303,
  0x64F7,
  0x6503,
  0x66D9,
  0x6703,
  0x6801,
  0x69C8,
  0x6A40,
  0x6D04,
  0x6E00,
  0x6F00,
  0x7080,
  0x7100,
  0x7200,
  0x7300,
  0x74F0,
  0x7500,
  0x8042,
  0x8144,
  0x8204,
  0x8320,
  0x8420,
  0x8500,
  0x8610,
  0x8700,
  0x8805,
  0x8918,
  0x8A10,
  0x8B01,
  0x8C37,
  0x8D00,
  0x8EF0,
  0x8F81,
  0x9006,
  0x9106,
  0x921E,
  0x930D,
  0x940A,
  0x950A,
  0x960C,
  0x9705,
  0x980A,
  0x9941,
  0x9A14,
  0x9B0A,
  0x9C3F,
  0x9D33,
  0x9EAE,
  0x9FF9,
  0xA048,
  0xA113,
  0xA210,
  0xA308,
  0xA430,
  0xA519,
  0xA610,
  0xA708,
  0xA824,
  0xA904,
  0xAA1E,
  0xAB1E,
  0xCC19,
  0xCD0B,
  0xCE13,
  0xCF64,
  0xD021,
  0xD10F,
  0xD288,
  0xE001,
  0xE104,
  0xE241,
  0xE3D6,
  0xE400,
  0xE50C,
  0xE60A,
  0xE700,
  0xE800,
  0xE900,
  0xEE07,
  0xEF01,
  0x001E,
  0x011E,
  0x020F,
  0x0310,
  0x0402,
  0x0500,
  0x06B0,
  0x0704,
  0x080D,
  0x090E,
  0x0A9C,
  0x0B04,
  0x0C05,
  0x0D0F,
  0x0E02,
  0x0F12,
  0x1002,
  0x1102,
  0x1200,
  0x1301,
  0x1405,
  0x1507,
  0x1605,
  0x1707,
  0x1801,
  0x1904,
  0x1A05,
  0x1B0C,
  0x1C2A,
  0x1D01,
  0x1E00,
  0x2100,
  0x2200,
  0x2300,
  0x2501,
  0x2600,
  0x2739,
  0x287F,
  0x2908,
  0x3003,
  0x3100,
  0x321A,
  0x331A,
  0x3407,
  0x3507,
  0x3601,
  0x37FF,
  0x3836,
  0x3907,
  0x3A00,
  0x3EFF,
  0x3F00,
  0x4077,
  0x4140,
  0x4200,
  0x4330,
  0x44A0,
  0x455C,
  0x4600,
  0x4700,
  0x4858,
  0x4A1E,
  0x4B1E,
  0x4C00,
  0x4D00,
  0x4EA0,
  0x4F80,
  0x5000,
  0x5100,
  0x5200,
  0x5300,
  0x5400,
  0x5780,
  0x5910,
  0x5A08,
  0x5B94,
  0x5CE8,
  0x5D08,
  0x5E3D,
  0x5F99,
  0x6045,
  0x6140,
  0x632D,
  0x6402,
  0x6596,
  0x6600,
  0x6797,
  0x6801,
  0x69CD,
  0x6A01,
  0x6BB0,
  0x6C04,
  0x6D2C,
  0x6E01,
  0x6F32,
  0x7100,
  0x7201,
  0x7335,
  0x7400,
  0x7533,
  0x7631,
  0x7701,
  0x7C84,
  0x7D03,
  0x7E01
];

/// PixArt PAJ7620U2 chip, can recognize 9 basic gestures.
///
/// See for more
/// * [PAJ7620U2 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_gesture_sensor.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/gesture_sensor.dart)
/// * [Datasheet](file:///C:/Users/pezi/AppData/Local/Temp/PAJ7620U2_GDS-R1.0_29032016_41002AEN-1.pdf)
/// * This code bases on [grove_gesture_sensor.py](https://github.com/Seeed-Studio/grove.py/blob/master/grove/grove_gesture_sensor.py)
class GestureSensor {
  final I2C i2c;
  int gestureReactionTime;
  int gestureQuitTime;

  /// Creates a PAJ7620U2 sensor instance that uses [i2c] bus
  /// with the optional parameter [gestureReactionTime] and [gestureQuitTime].
  GestureSensor(this.i2c,
      [this.gestureReactionTime = GESTURE_REACTION_TIME,
      this.gestureQuitTime = GESTURE_QUIT_TIME]) {
    var data0 = 0;

    // At the first access Raspbery PI 3 runs into a timeout - sensor is still sleeping
    try {
      data0 = i2c.readByteReg(PAJ7620_ID, 0);
    } on I2Cexception catch (e) {
      if (e.errorCode == I2CerrorCode.I2C_ERROR_TRANSFER) {
        sleep(Duration(milliseconds: 10));
        // sensor should be up at this point!
        data0 = i2c.readByteReg(PAJ7620_ID, 0);
      }
    }

    var data1 = i2c.readByteReg(PAJ7620_ID, 1);

    if ((data0 != 0x20) || (data1 != 0x76)) {
      throw GestureSensorException(
          'Bad init data 0x${data0.toRadixString(16)}  != 0x20 and 0x${data1.toRadixString(16)} != 0x76');
    }

    _paj7620SelectBank(Bank.BANK0);

    for (var v in initRegisterArray) {
      i2c.writeByteReg(PAJ7620_ID, v >> 8, v & 0xff);
    }

    _paj7620SelectBank(Bank.BANK1);
    i2c.writeByteReg(PAJ7620_ID, 0x65, 0x12);
    _paj7620SelectBank(Bank.BANK0);
  }

  void _paj7620SelectBank(Bank bank) {
    i2c.writeByteReg(PAJ7620_ID, PAJ7620_REGITER_BANK_SEL,
        bank == Bank.BANK0 ? PAJ7620_BANK0 : PAJ7620_BANK1);
  }

  /// Returns the actual detected gesture.
  Gesture getGesture() {
    var gesture = Gesture.NOTHING;
    switch (i2c.readByteReg(PAJ7620_ID, 0x43)) {
      case GES_RIGHT_FLAG:
        sleep(Duration(milliseconds: gestureReactionTime));
        var data = i2c.readByteReg(PAJ7620_ID, 0x43);
        if (data == GES_LEFT_FLAG) {
          gesture = Gesture.RIGHT_LEFT;
        } else if (data == GES_FORWARD_FLAG) {
          sleep(Duration(milliseconds: gestureQuitTime));
          gesture = Gesture.FORWARD;
        } else if (data == GES_BACKWARD_FLAG) {
          sleep(Duration(milliseconds: gestureQuitTime));
          gesture = Gesture.BACKWARD;
        } else {
          gesture = Gesture.RIGHT;
        }
        return gesture;
      case GES_LEFT_FLAG:
        sleep(Duration(milliseconds: gestureReactionTime));
        var data = i2c.readByteReg(PAJ7620_ID, 0x43);
        if (data == GES_RIGHT_FLAG) {
          gesture = Gesture.LEFT_RIGHT;
        } else if (data == GES_FORWARD_FLAG) {
          sleep(Duration(milliseconds: gestureQuitTime));
          gesture = Gesture.FORWARD;
        } else if (data == GES_BACKWARD_FLAG) {
          sleep(Duration(milliseconds: gestureQuitTime));
          gesture = Gesture.BACKWARD;
        } else {
          gesture = Gesture.LEFT;
        }
        return gesture;
      case GES_UP_FLAG:
        sleep(Duration(milliseconds: gestureReactionTime));
        var data = i2c.readByteReg(PAJ7620_ID, 0x43);
        if (data == GES_DOWN_FLAG) {
          gesture = Gesture.UP_DOWN;
        } else if (data == GES_FORWARD_FLAG) {
          sleep(Duration(milliseconds: gestureQuitTime));
          gesture = Gesture.FORWARD;
        } else if (data == GES_BACKWARD_FLAG) {
          sleep(Duration(milliseconds: gestureQuitTime));
          gesture = Gesture.BACKWARD;
        } else {
          gesture = Gesture.UP;
        }
        return gesture;
      case GES_DOWN_FLAG:
        sleep(Duration(milliseconds: gestureReactionTime));
        var data = i2c.readByteReg(PAJ7620_ID, 0x43);
        if (data == GES_UP_FLAG) {
          gesture = Gesture.DOWN_UP;
        } else if (data == GES_FORWARD_FLAG) {
          sleep(Duration(milliseconds: gestureQuitTime));
          gesture = Gesture.FORWARD;
        } else if (data == GES_BACKWARD_FLAG) {
          sleep(Duration(milliseconds: gestureQuitTime));
          gesture = Gesture.BACKWARD;
        } else {
          gesture = Gesture.DOWN;
        }
        return gesture;
      case GES_FORWARD_FLAG:
        sleep(Duration(milliseconds: gestureReactionTime));
        var data = i2c.readByteReg(PAJ7620_ID, 0x43);
        if (data == GES_BACKWARD_FLAG) {
          gesture = Gesture.FORWARD_BACKWARD;
        } else {
          gesture = Gesture.FORWARD;
        }
        sleep(Duration(milliseconds: gestureQuitTime));
        return gesture;
      case GES_BACKWARD_FLAG:
        sleep(Duration(milliseconds: gestureReactionTime));
        var data = i2c.readByteReg(PAJ7620_ID, 0x43);
        if (data == GES_FORWARD_FLAG) {
          gesture = Gesture.BACKWARD_FORWARD;
        } else {
          gesture = Gesture.BACKWARD;
        }
        sleep(Duration(milliseconds: gestureQuitTime));
        return gesture;
      case GES_CLOCKWISE_FLAG:
        return Gesture.CLOCKWISE;
      case GES_COUNT_CLOCKWISE_FLAG:
        return Gesture.ANTI_CLOCKWISE;
      default:
        var data = i2c.readByteReg(PAJ7620_ID, 0x44);
        if (data == GES_WAVE_FLAG) {
          Gesture.WAVE;
        } else {
          return Gesture.NOTHING;
        }
        break;
    }
    return Gesture.NOTHING;
  }
}
