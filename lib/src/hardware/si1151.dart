// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//import 'dart:io';

//import 'package:dart_periphery/src/hardware/utils/byte_buffer.dart';

//import '../../dart_periphery.dart';

// https://github.com/Seeed-Studio/Grove_Sunlight_Sensor
// https://github.com/Seeed-Studio/Seeed_Python_SI114X

enum Si115xReg {
  partId(0x00),
  revId(0x01),
  mfrId(0x02),
  info0(0x03),
  info1(0x04),
  hostin3(0x07),
  hostin2(0x08),
  hostin0(0x0A),
  command(0x0B),
  irqEnable(0x0F),
  response0(0x11),
  response1(0x10),
  irqStatus(0x12),
  hostout0(0x13),
  hostout1(0x14),
  hostout2(0x15);

  final int value;
  const Si115xReg(this.value);
}

enum Si115xCmd {
  resetCmdCtr(0x00),
  resetSw(0x01),
  force(0x11),
  pause(0x12),
  start(0x13),
  paramGet(0x40),
  paramSet(0x80);

  final int value;
  const Si115xCmd(this.value);
}

enum Si115xParam {
  i2cAddr(0x00),
  chanList(0x01),
  adcConfig0(0x02),
  adcSens0(0x03),
  adcPost0(0x04),
  measConfig0(0x05),
  adcConfig1(0x06),
  adcSens1(0x07),
  adcPost1(0x08),
  measConfig1(0x09),
  adcConfig2(0x0A),
  adcSens2(0x0B),
  adcPost2(0x0C),
  measConfig2(0x0D),
  adcConfig3(0x0E),
  adcSens3(0x0F),
  adcPost3(0x10),
  measConfig3(0x11),
  adcConfig4(0x12),
  adcSens4(0x13),
  adcPost4(0x14),
  measConfig4(0x15),
  adcConfig5(0x16),
  adcSens5(0x17),
  adcPost5(0x18),
  measConfig5(0x19),
  measRateH(0x1A),
  measRateL(0x1B),
  measCount0(0x1C),
  measCount1(0x1D),
  measCount2(0x1E),
  led1A(0x1F),
  led1B(0x20),
  led2A(0x21),
  led2B(0x22),
  led3A(0x23),
  led3B(0x24),
  threshold0H(0x25),
  threshold0L(0x26),
  threshold1H(0x27),
  threshold1L(0x28),
  threshold2H(0x29),
  threshold2L(0x2A),
  burst(0x2B);

  final int value;
  const Si115xParam(this.value);
}

/// [SI1151] exception
class SI1151exception implements Exception {
  final String errorMsg;
  @override
  String toString() => errorMsg;

  SI1151exception(this.errorMsg);
}
