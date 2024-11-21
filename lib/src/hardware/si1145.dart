// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//import 'dart:io';

import 'dart:io';

import '../../dart_periphery.dart';

// Resources:
// https://www.seeedstudio.com/Grove-Sunlight-Sensor.html
// https://github.com/Seeed-Studio/Grove_Sunlight_Sensor
// https://github.com/Seeed-Studio/Seeed_Python_SI114X/blob/master/seeed_si114x.py#L235

const si1145DefaultI2Caddress = 0x60;

abstract class IntEnum {
  int getValue();
}

enum SI1145reg implements IntEnum {
  partId(0x00),
  revId(0x01),
  seqId(0x02),
  intCfg(0x03),
  irqEnable(0x04),
  irqMode1(0x05),
  irqMode2(0x06),
  hwKey(0x07),
  measRate0(0x08),
  measRate1(0x09),
  psRate(0x0A),
  psLed21(0x0F),
  psLed3(0x10),
  ucoeff0(0x13),
  ucoeff1(0x14),
  ucoeff2(0x15),
  ucoeff3(0x16),
  wr(0x17),
  command(0x18),
  response(0x20),
  irqStatus(0x21),
  alsVisData0(0x22),
  alsVisData1(0x23),
  alsIrData0(0x24),
  alsIrData1(0x25),
  ps1Data0(0x26),
  ps1Data1(0x27),
  ps2Data0(0x28),
  ps2Data1(0x29),
  ps3Data0(0x2A),
  ps3Data1(0x2B),
  auxData0Uvindex0(0x2C),
  auxData1Uvindex1(0x2D),
  rd(0x2E),
  chipStat(0x30);

  final int value;
  const SI1145reg(this.value);

  @override
  int getValue() {
    return value;
  }
}

enum SI1145cmd implements IntEnum {
  nop(0x00),
  reset(0x01),
  busaddr(0x02),
  psForce(0x05),
  alsForce(0x06),
  psalsForce(0x07),
  psPause(0x09),
  alsPause(0x0A),
  psalsPause(0x0B),
  psAuto(0x0D),
  alsAuto(0x0E),
  psalsAuto(0x0F),
  query(0x80),
  set(0xA0);

  final int value;
  const SI1145cmd(this.value);

  @override
  int getValue() {
    return value;
  }
}

enum SI1145param implements IntEnum {
  i2caddr(0x00),
  chlist(0x01),
  psled12Select(0x02),
  psled3Select(0x03),
  psEncoding(0x05),
  alsEncoding(0x06),
  ps1Adcmux(0x07),
  ps2Adcmux(0x08),
  ps3Adcmux(0x09),
  psAdcCounter(0x0A),
  psAdcGain(0x0B),
  psAdcMisc(0x0C),
  alsIrAdcmux(0x0E),
  auxAdcmux(0x0F),
  alsVisAdcCounter(0x10),
  alsVisAdcGain(0x11),
  alsVisAdcMisc(0x12),
  ledRec(0x1C),
  alsIrAdcCounter(0x1D),
  alsIrAdcGain(0x1E),
  alsIrAdcMisc(0x1F);

  final int value;
  const SI1145param(this.value);

  @override
  int getValue() {
    return value;
  }
}

enum SI1145chlist {
  enps1(0x01),
  enps2(0x02),
  enps3(0x04),
  enalsvis(0x10),
  enalsir(0x20),
  enaux(0x40),
  enuv(0x80);

  final int value;
  const SI1145chlist(this.value);
}

enum SI1145LedCurrent implements IntEnum {
  cur5ma(0x01),
  cur11ma(0x02),
  cur22ma(0x03),
  cur45ma(0x04);

  final int value;
  const SI1145LedCurrent(this.value);

  @override
  int getValue() {
    return value;
  }
}

enum SI1145adcmux implements IntEnum {
  smallIr(0x00),
  visiable(0x02),
  largeIr(0x03),
  no(0x06),
  gnd(0x25),
  temperature(0x65),
  vdd(0x75);

  final int value;
  const SI1145adcmux(this.value);

  @override
  int getValue() {
    return value;
  }
}

enum Si1145ledSel implements IntEnum {
  ps1None(0x00),
  ps1Led1(0x01),
  ps1Led2(0x02),
  ps1Led3(0x04),
  ps2None(0x00),
  ps2Led1(0x10),
  ps2Led2(0x20),
  ps2Led3(0x40);

  final int value;
  const Si1145ledSel(this.value);

  @override
  int getValue() {
    return value;
  }
}

enum SI1145adcGain implements IntEnum {
  div1(0x00),
  div2(0x01),
  div4(0x02),
  div8(0x03),
  div16(0x04),
  div32(0x05);

  final int value;
  const SI1145adcGain(this.value);

  @override
  int getValue() {
    return value;
  }
}

enum SI1145adcCounter implements IntEnum {
  adcclk1(0x00),
  adcclk7(0x01),
  adcclk15(0x02),
  adcclk31(0x03),
  adcclk63(0x04),
  adcclk127(0x05),
  adcclk255(0x06),
  adcclk511(0x07);

  final int value;
  const SI1145adcCounter(this.value);

  @override
  int getValue() {
    return value;
  }
}

enum SI1145adcMisc implements IntEnum {
  lowrange(0x00),
  highrange(0x20),
  adcNormalproximity(0x00),
  adcRawadc(0x04);

  final int value;
  const SI1145adcMisc(this.value);

  @override
  int getValue() {
    return value;
  }
}

enum SI1145irqen implements IntEnum {
  als(0x01),
  ps1(0x04),
  ps2(0x08),
  ps3(0x10);

  final int value;
  const SI1145irqen(this.value);

  @override
  int getValue() {
    return value;
  }
}

/// [SI1145] exception
class SI1145exception implements Exception {
  final String errorMsg;
  @override
  String toString() => errorMsg;

  SI1145exception(this.errorMsg);
}

/// [SI1145] measured data: visible, IR and UV part of the sunlight.
class SI1145result {
  /// visible
  final int visible;
  final int ir;
  final int uv;

  @override
  String toString() => 'SI1145result [visible=$visible, ir=$ir, uv=$uv]';

  String toJSON() {
    return '{"visible":"$visible","ir","$ir","uv","$uv"}';
  }

  SI1145result(this.visible, this.ir, this.uv);
}

/// SiLabs  sensor for temperature, pressure and
/// humidity (BME280 only).
///
/// See for more
/// * [BM280 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_bme280.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/bme280.dart)
/// * [Datasheet](https://cdn-shop.adafruit.com/datasheets/BST-BME280_DS001-10.pdf)
class SI1145 {
  final I2C i2c;
  final int i2cAddress;

  /// Creates a SI1145 sensor instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  SI1145(this.i2c, [this.i2cAddress = si1145DefaultI2Caddress]) {
    init();
  }

  void writeByte(SI1145reg reg, int byte) {
    i2c.writeByteReg(i2cAddress, reg.value, byte);
  }

  void writeEnum(SI1145reg reg, IntEnum byte) {
    i2c.writeByteReg(i2cAddress, reg.value, byte.getValue());
  }

  int readWord(IntEnum reg) {
    var v = i2c.readBytesReg(i2cAddress, reg.getValue(), 2);
    return (v[0] & 0xff) | (v[1] & 0xff) << 8;
  }

  int readByte(SI1145reg reg) {
    return i2c.readByteReg(i2cAddress, reg.value);
  }

  int writeParam(IntEnum register, int value) {
    // write Value into PARAMWR reg first
    writeByte(SI1145reg.wr, value);
    writeByte(SI1145reg.command, register.getValue() | SI1145cmd.set.value);
    // SI1145 writes value out to PARAM_RD,read and confirm its right
    return readByte(SI1145reg.rd);
  }

  int writeParamEnum(IntEnum register, IntEnum value) {
    return writeParam(register, value.getValue());
  }

  void reset() {
    writeByte(SI1145reg.measRate0, 0);
    writeByte(SI1145reg.measRate1, 0);
    writeByte(SI1145reg.irqEnable, 0);
    writeByte(SI1145reg.irqMode1, 0);
    writeByte(SI1145reg.irqMode2, 0);
    writeByte(SI1145reg.intCfg, 0);
    writeByte(SI1145reg.irqStatus, 0xFF);
    writeEnum(SI1145reg.command, SI1145cmd.reset);
    sleep(Duration(microseconds: 100));
    writeByte(SI1145reg.hwKey, 0x17);
    sleep(Duration(microseconds: 100));
  }

  void deInit() {
    // ENABLE UV reading
    // these reg must be set to the fixed value
    writeByte(SI1145reg.ucoeff0, 0x29);
    writeByte(SI1145reg.ucoeff1, 0x89);
    writeByte(SI1145reg.ucoeff2, 0x02);
    writeByte(SI1145reg.ucoeff3, 0x00);
    writeParam(
        SI1145param.chlist,
        SI1145chlist.enuv.value |
            SI1145chlist.enalsir.value |
            SI1145chlist.enalsvis.value |
            SI1145chlist.enps1.value);

    // set LED1 CURRENT(22.4mA)(It is a normal value for many LED
    writeParamEnum(SI1145param.ps1Adcmux, SI1145adcmux.largeIr);
    writeByte(SI1145reg.psLed21, SI1145LedCurrent.cur22ma.value);
    writeParamEnum(SI1145param.psled12Select, Si1145ledSel.ps1Led1);

    // PS ADC SETTING
    writeParamEnum(SI1145param.psAdcGain, SI1145adcGain.div1);
    writeParamEnum(SI1145param.psAdcCounter, SI1145adcCounter.adcclk511);
    writeParam(SI1145param.psAdcMisc,
        SI1145adcMisc.highrange.value | SI1145adcMisc.adcRawadc.value);

    // VIS ADC SETTING
    writeParamEnum(SI1145param.alsVisAdcGain, SI1145adcGain.div1);
    writeParamEnum(SI1145param.alsVisAdcCounter, SI1145adcCounter.adcclk511);
    writeParamEnum(SI1145param.alsVisAdcMisc, SI1145adcMisc.highrange);

    // IR ADC SETTING
    writeParamEnum(SI1145param.alsIrAdcGain, SI1145adcGain.div1);
    writeParamEnum(SI1145param.alsIrAdcCounter, SI1145adcCounter.adcclk511);
    writeParamEnum(SI1145param.alsIrAdcMisc, SI1145adcMisc.highrange);

    // interrupt enable
    writeByte(SI1145reg.intCfg, 1);
    writeEnum(SI1145reg.irqEnable, SI1145irqen.als);

    // auto run
    writeByte(SI1145reg.measRate0, 0xFF);
    writeEnum(SI1145reg.command, SI1145cmd.psalsAuto);
  }

  void init() {
    if (readByte(SI1145reg.partId) != 0x45) {
      throw SI1145exception("Sensor init failed");
    }
    reset();
    deInit();
  }

  int getVisible() {
    return readWord(SI1145reg.alsVisData0);
  }

  int getIr() {
    return readWord(SI1145reg.alsIrData0);
  }

  int getUV() {
    return readWord(SI1145reg.auxData0Uvindex0);
  }

  SI1145result getValues() {
    return SI1145result(getVisible(), getIr(), getUV());
  }
}
