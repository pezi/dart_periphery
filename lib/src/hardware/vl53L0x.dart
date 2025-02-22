// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Resources
// https://github.com/adafruit/Adafruit_CircuitPython_VL53L0X
// https://www.st.com/resource/en/datasheet/vl53l0x.pdf

import 'dart:io';

import 'package:dart_periphery/dart_periphery.dart';
import 'package:collection/collection.dart';
import 'dart:math' as math;

/// VL53L0X constants
enum VL53L0Xconst {
  sysRangeStart(0x00),
  systemThreshHigh(0x0C),
  systemThreshLow(0x0E),
  systemSequenceConfig(0x01),
  systemRangeConfig(0x09),
  systemIntermeasurementPeriod(0x04),
  systemInterruptConfigGpio(0x0A),
  gpioHvMuxActiveHigh(0x84),
  systemInterruptClear(0x0B),
  resultInterruptStatus(0x13),
  resultRangeStatus(0x14),
  resultCoreAmbientWindowEventsRtn(0xBC),
  resultCoreRangingTotalEventsRtn(0xC0),
  resultCoreAmbientWindowEventsRef(0xD0),
  resultCoreRangingTotalEventsRef(0xD4),
  resultPeakSignalRateRef(0xB6),
  algoPartToPartRangeOffsetMm(0x28),
  i2cSlaveDeviceAddress(0x8A),
  msrcConfigControl(0x60),
  preRangeConfigMinSnr(0x27),
  preRangeConfigValidPhaseLow(0x56),
  preRangeConfigValidPhaseHigh(0x57),
  preRangeMinCountRateRtnLimit(0x64),
  finalRangeConfigMinSnr(0x67),
  finalRangeConfigValidPhaseLow(0x47),
  finalRangeConfigValidPhaseHigh(0x48),
  finalRangeConfigMinCountRateRtnLimit(0x44),
  preRangeConfigSigmaThreshHi(0x61),
  preRangeConfigSigmaThreshLo(0x62),
  preRangeConfigVcselPeriod(0x50),
  preRangeConfigTimeoutMacropHi(0x51),
  preRangeConfigTimeoutMacropLo(0x52),
  systemHistogramBin(0x81),
  histogramConfigInitialPhaseSelect(0x33),
  histogramConfigReadoutCtrl(0x55),
  finalRangeConfigVcselPeriod(0x70),
  finalRangeConfigTimeoutMacropHi(0x71),
  finalRangeConfigTimeoutMacropLo(0x72),
  crosstalkCompensationPeakRateMcps(0x20),
  msrcConfigTimeoutMacrop(0x46),
  softResetGo2SoftResetN(0xBF),
  identificationModelId(0xC0),
  identificationRevisionId(0xC2),
  oscCalibrateVal(0xF8),
  globalConfigVcselWidth(0x32),
  globalConfigSpadEnablesRef0(0xB0),
  globalConfigSpadEnablesRef1(0xB1),
  globalConfigSpadEnablesRef2(0xB2),
  globalConfigSpadEnablesRef3(0xB3),
  globalConfigSpadEnablesRef4(0xB4),
  globalConfigSpadEnablesRef5(0xB5),
  globalConfigRefEnStartSelect(0xB6),
  dynamicSpadNumRequestedRefSpad(0x4E),
  dynamicSpadRefEnStartOffset(0x4F),
  powerManagementGo1PowerForce(0x80),
  vhvConfigPadSclSdaExtsupHv(0x89),
  algoPhasecalLim(0x30),
  algoPhasecalConfigTimeout(0x30),
  vcselPeriodPreRange(0),
  vcselPeriodFinalRange(1);

  final int value;
  const VL53L0Xconst(this.value);
}

/// Default address of the [VL53L0X] sensor.
const int vl53L0xDefaultI2Caddress = 0x29;

// Format: (LSByte * 2^MSByte) + 1
int _decodeTimeout(int val) {
  return ((val & 0xFF) * math.pow(2.0, ((val & 0xFF00) >> 8)) + 1).toInt();
}

/// Format: (LSByte * 2^MSByte) + 1
int _encodeTimeout(int timeoutMclks) {
  timeoutMclks = timeoutMclks & 0xFFFF;
  int lsByte = 0;
  int msByte = 0;

  if (timeoutMclks > 0) {
    lsByte = timeoutMclks - 1;
    while (lsByte > 255) {
      lsByte >>= 1;
      msByte++;
    }
    return ((msByte << 8) | (lsByte & 0xFF)) & 0xFFFF;
  }
  return 0;
}

/// Converts timeout in MCLKs to microseconds.
int _timeoutMclksToMicroseconds(int timeoutPeriodMclks, int vcselPeriodPclks) {
  int macroPeriodNs = ((2304 * vcselPeriodPclks * 1655) + 500) ~/ 1000;
  return ((timeoutPeriodMclks * macroPeriodNs) + (macroPeriodNs ~/ 2)) ~/ 1000;
}

/// Converts timeout in microseconds to MCLKs.
int _timeoutMicrosecondsToMclks(int timeoutPeriodUs, int vcselPeriodPclks) {
  int macroPeriodNs = ((2304 * vcselPeriodPclks * 1655) + 500) ~/ 1000;
  return ((timeoutPeriodUs * 1000) + (macroPeriodNs ~/ 2)) ~/ macroPeriodNs;
}

/// [VL53L0X] exception
class VL53L0Xexception implements Exception {
  VL53L0Xexception(this.errorMsg);
  final String errorMsg;
  @override
  String toString() => errorMsg;
}

class VL53L0X {
  final I2C i2c;
  final int i2cAddress;
  final int timeout;
  int _stop = 0;
  int _configControl = 0;
  bool _continuousMode = false;
  int _spadCount = 0;
  bool _spadIsAperture = false;
  int _firstSpadToEnable = 0;
  int _spadsEnabled = 0;
  int _measurementTimingBudgetUs = 0;
  int _range = 0;
  bool _dataReady = false;

  // i2c helper

  /// Reads an 8-bit unsigned integer from a register address.
  int readU8reg(int reg) {
    return i2c.readByteReg(vl53L0xDefaultI2Caddress, reg);
  }

  /// Reads an 8-bit unsigned integer from a [VL53L0Xconst], representing a
  /// register address.
  int readU8(VL53L0Xconst c) {
    return i2c.readByteReg(vl53L0xDefaultI2Caddress, c.value);
  }

  /// Reads a 16-bit unsigned integer from a [VL53L0Xconst], representing a
  /// register address.
  int readU16(VL53L0Xconst c) {
    var buf = i2c.readBytesReg(vl53L0xDefaultI2Caddress, c.value, 2);
    return (buf[0] << 8) | buf[1];
  }

  /// Reads a 16-bit unsigned integer from a register address.
  int readU16reg(int reg) {
    var buf = i2c.readBytesReg(vl53L0xDefaultI2Caddress, reg, 2);
    return (buf[0] << 8) | buf[1];
  }

  /// Writes an 8-bit unsigned integer to a [VL53L0Xconst], representing a
  /// register address.
  void writeU8(VL53L0Xconst c, int v) {
    i2c.writeByteReg(vl53L0xDefaultI2Caddress, c.value, v);
  }

  /// Writes an 8-bit unsigned integer to a register address.
  void writeU8reg(int reg, int v) {
    i2c.writeByteReg(vl53L0xDefaultI2Caddress, reg, v);
  }

  /// Writes a 16-bit unsigned integer to a [VL53L0Xconst], representing a
  /// register address.
  void writeU16(VL53L0Xconst c, int val) {
    var buf = List<int>.filled(2, 0);
    buf[0] = (val >> 8) & 0xFF;
    buf[1] = val & 0xFF;
    i2c.writeBytesReg(vl53L0xDefaultI2Caddress, c.value, buf);
  }

  /// Writes a list of tuples (register,value).
  void writeRegList(List<(int, int)> data) {
    for (var pair in data) {
      i2c.writeByteReg(vl53L0xDefaultI2Caddress, pair.$1, pair.$2);
    }
  }

  /// Modifies an 8-bit unsigned integer from a [VL53L0Xconst] using a
  /// function and returns the register's value before modification.
  int modifyReg(VL53L0Xconst c, int Function(int value) modify) {
    var result = readU8reg(c.value);
    writeU8(c, modify(result));
    return result;
  }

  /// Modifies an 8-bit unsigned integer from a [reg] using a
  /// function and returns the register's value before modification.
  int modifyRegAddress(int reg, int Function(int value) modify) {
    var result = readU8reg(reg);
    writeU8reg(reg, modify(result));
    return result;
  }

  // VL53L0X Time of Flight Distance Sensor
  VL53L0X(this.i2c,
      [this.timeout = 0, this.i2cAddress = ds1307DefaultI2Caddress]) {
    // Check identification registers for expected values
    if (!ListEquality().equals(
        i2c.readBytesReg(vl53L0xDefaultI2Caddress, 0xC0, 3),
        [0xEE, 0xAA, 0x10])) {
      throw VL53L0Xexception("VL53L0X not found");
    }
    // Initialize access to the sensor.  This is based on the logic from:
    // https://github.com/pololu/vl53l0x-arduino/blob/master/VL53L0X.cpp
    // Set I2C standard mode.
    writeRegList([(0x88, 0x00), (0x80, 0x01), (0xFF, 0x01), (0x00, 0x00)]);

    _stop = readU8reg(0x91);
    writeRegList([(0x00, 0x01), (0xFF, 0x00), (0x80, 0x00)]);

    // disable SIGNAL_RATE_MSRC (bit 1) and SIGNAL_RATE_PRE_RANGE (bit 4)
    // limit checks
    _configControl =
        modifyReg(VL53L0Xconst.msrcConfigControl, (value) => value | 0x12);

    // set final range signal rate limit to 0.25 MCPS (million counts per second)
    setSignalRateLimit(0.25);
    writeU8(VL53L0Xconst.systemSequenceConfig, 0xFF);

    _setSpad();

    var refSpadMap = i2c.readBytesReg(vl53L0xDefaultI2Caddress,
        VL53L0Xconst.globalConfigSpadEnablesRef0.value, 6);

    // VL53L0Xconst.
    // VL53L0Xconst.globalConfigRefEnStartSelect
    writeRegList([
      (0xFF, 0x01),
      (VL53L0Xconst.dynamicSpadRefEnStartOffset.value, 0x00),
      (VL53L0Xconst.dynamicSpadNumRequestedRefSpad.value, 0x2C),
      (0xFF, 0x00),
      (VL53L0Xconst.globalConfigRefEnStartSelect.value, 0xB4)
    ]);

    _firstSpadToEnable = _spadIsAperture ? 12 : 0;

    for (var i = 0; i < 48; ++i) {
      if (i < _firstSpadToEnable || _spadsEnabled == _spadCount) {
        // This bit is lower than the first one that should be enabled,
        // or (reference_spad_count) bits have already been enabled, so
        // zero this bit.
        refSpadMap[i ~/ 8] &= ~(1 << (i % 8));
      } else if ((refSpadMap[i ~/ 8] >> (i % 8)) & 0x1 > 0) {
        _spadsEnabled += 1;
      }
    }

    i2c.writeBytesReg(vl53L0xDefaultI2Caddress,
        VL53L0Xconst.globalConfigSpadEnablesRef0.value, refSpadMap);

    writeRegList([
      (0xFF, 0x01),
      (0x00, 0x00),
      (0xFF, 0x00),
      (0x09, 0x00),
      (0x10, 0x00),
      (0x11, 0x00),
      (0x24, 0x01),
      (0x25, 0xFF),
      (0x75, 0x00),
      (0xFF, 0x01),
      (0x4E, 0x2C),
      (0x48, 0x00),
      (0x30, 0x20),
      (0xFF, 0x00),
      (0x30, 0x09),
      (0x54, 0x00),
      (0x31, 0x04),
      (0x32, 0x03),
      (0x40, 0x83),
      (0x46, 0x25),
      (0x60, 0x00),
      (0x27, 0x00),
      (0x50, 0x06),
      (0x51, 0x00),
      (0x52, 0x96),
      (0x56, 0x08),
      (0x57, 0x30),
      (0x61, 0x00),
      (0x62, 0x00),
      (0x64, 0x00),
      (0x65, 0x00),
      (0x66, 0xA0),
      (0xFF, 0x01),
      (0x22, 0x32),
      (0x47, 0x14),
      (0x49, 0xFF),
      (0x4A, 0x00),
      (0xFF, 0x00),
      (0x7A, 0x0A),
      (0x7B, 0x00),
      (0x78, 0x21),
      (0xFF, 0x01),
      (0x23, 0x34),
      (0x42, 0x00),
      (0x44, 0xFF),
      (0x45, 0x26),
      (0x46, 0x05),
      (0x40, 0x40),
      (0x0E, 0x06),
      (0x20, 0x1A),
      (0x43, 0x40),
      (0xFF, 0x00),
      (0x34, 0x03),
      (0x35, 0x44),
      (0xFF, 0x01),
      (0x31, 0x04),
      (0x4B, 0x09),
      (0x4C, 0x05),
      (0x4D, 0x04),
      (0xFF, 0x00),
      (0x44, 0x00),
      (0x45, 0x20),
      (0x47, 0x08),
      (0x48, 0x28),
      (0x67, 0x00),
      (0x70, 0x04),
      (0x71, 0x01),
      (0x72, 0xFE),
      (0x76, 0x00),
      (0x77, 0x00),
      (0xFF, 0x01),
      (0x0D, 0x01),
      (0xFF, 0x00),
      (0x80, 0x01),
      (0x01, 0xF8),
      (0xFF, 0x01),
      (0x8E, 0x01),
      (0x00, 0x01),
      (0xFF, 0x00),
      (0x80, 0x00)
    ]);

    writeU8(VL53L0Xconst.systemInterruptConfigGpio, 0x04);
    modifyReg(VL53L0Xconst.gpioHvMuxActiveHigh, (value) => value & ~0x10);
    writeU8(VL53L0Xconst.systemInterruptClear, 0x01);

    _measurementTimingBudgetUs = getMeasurementTimingBudget();
    writeU8(VL53L0Xconst.systemSequenceConfig, 0xE8);

    setMeasurementTimingBudget(_measurementTimingBudgetUs);
    writeU8(VL53L0Xconst.systemSequenceConfig, 0x01);
    _performSingleRefCalibration(0x40);
    writeU8(VL53L0Xconst.systemSequenceConfig, 0x02);
    _performSingleRefCalibration(0x00);

    // restore the previous sequence Config
    writeU8(VL53L0Xconst.systemSequenceConfig, 0xE8);
  }

  // Get reference SPAD count and type, returned as a 2-tuple of
  // count and boolean is_aperture.  Based on code from:
  //  https://github.com/pololu/vl53l0x-arduino/blob/master/VL53L0X.cpp
  void _setSpad() {
    writeRegList([(0x80, 0x01), (0xFF, 0x01), (0x00, 0x00), (0xFF, 0x06)]);

    modifyRegAddress(0x83, (value) => value | 0x04);

    writeRegList(
        [(0xFF, 0x07), (0x81, 0x01), (0x80, 0x01), (0x94, 0x6B), (0x83, 0x00)]);

    var start = DateTime.now().millisecondsSinceEpoch;
    while (readU8reg(0x83) == 0x00) {
      if (timeout > 0 &&
          (DateTime.now().millisecondsSinceEpoch - start) >= timeout) {
        throw VL53L0Xexception("Timeout waiting for VL53L0X!");
      }
    }

    writeU8reg(0x83, 0x01);

    var tmp = readU8reg(0x92);
    _spadCount = tmp & 0x7F;
    _spadIsAperture = ((tmp >> 7) & 0x01) == 1;
    writeRegList([(0x81, 0x00), (0xFF, 0x06)]);

    modifyRegAddress(0x83, (value) => value & ~0x04);
    writeRegList([(0xFF, 0x01), (0x00, 0x01), (0xFF, 0x00), (0x80, 0x00)]);
  }

  double getSignalRateLimit() {
    return readU16(VL53L0Xconst.finalRangeConfigMinCountRateRtnLimit) /
        (1 << 7);
  }

  void setSignalRateLimit(double value) {
    writeU16(VL53L0Xconst.finalRangeConfigMinCountRateRtnLimit,
        (value * (1 << 7)).toInt());
  }

  // ** refiew until here **

  void _performSingleRefCalibration(int vhvInitByte) {
    writeU8(VL53L0Xconst.sysRangeStart, 0x01 | vhvInitByte & 0xFF);
    var start = DateTime.now().millisecondsSinceEpoch;
    while ((readU8(VL53L0Xconst.resultInterruptStatus) & 0x07) == 0) {
      if (timeout > 0 &&
          (DateTime.now().millisecondsSinceEpoch - start) >= timeout) {
        throw VL53L0Xexception("Timeout waiting for VL53L0X!");
      }
    }
    writeU8(VL53L0Xconst.systemInterruptClear, 0x01);
    writeU8(VL53L0Xconst.sysRangeStart, 0x00);
  }

  int _getVcselPulsePeriod(VL53L0Xconst vcselPeriodType) {
    if (vcselPeriodType == VL53L0Xconst.vcselPeriodPreRange) {
      var val = readU8(VL53L0Xconst.preRangeConfigVcselPeriod);
      return (((val) + 1) & 0xFF) << 1;
    } else if (vcselPeriodType == VL53L0Xconst.vcselPeriodFinalRange) {
      var val = readU8(VL53L0Xconst.finalRangeConfigVcselPeriod);
      return (((val) + 1) & 0xFF) << 1;
    }
    return 255;
  }

  (bool, bool, bool, bool, bool) _getSequenceStepEnables() {
    var sequenceConfig = readU8(VL53L0Xconst.systemSequenceConfig);
    var tcc = (sequenceConfig >> 4) & 0x1 > 0;
    var dss = (sequenceConfig >> 3) & 0x1 > 0;
    var msrc = (sequenceConfig >> 2) & 0x1 > 0;
    var preRange = (sequenceConfig >> 6) & 0x1 > 0;
    var finalRange = (sequenceConfig >> 7) & 0x1 > 0;
    return (tcc, dss, msrc, preRange, finalRange);
  }

  // based on get_sequence_step_timeout() from ST API but modified by
  // pololu here:
  //   https://github.com/pololu/vl53l0x-arduino/blob/master/VL53L0X.cpp
  (int, int, int, int, int) _getSequenceStepTimeouts(bool preRange) {
    var preRangeVcselPeriodPclks =
        _getVcselPulsePeriod(VL53L0Xconst.vcselPeriodPreRange);
    var msrcDssTccMclks =
        (readU8(VL53L0Xconst.msrcConfigTimeoutMacrop) + 1) & 0xFF;
    var msrcDssTccUs =
        _timeoutMclksToMicroseconds(msrcDssTccMclks, preRangeVcselPeriodPclks);
    var preRangeMclks =
        _decodeTimeout(readU16(VL53L0Xconst.preRangeConfigTimeoutMacropHi));
    var preRangeUs =
        _timeoutMclksToMicroseconds(preRangeMclks, preRangeVcselPeriodPclks);

    var finalRangeVcselPeriodPclks =
        _getVcselPulsePeriod(VL53L0Xconst.vcselPeriodFinalRange);
    var finalRangeMclks =
        _decodeTimeout(readU16(VL53L0Xconst.finalRangeConfigTimeoutMacropHi));
    if (preRange) {
      finalRangeMclks -= preRangeMclks;
    }
    var finalRangeUs = _timeoutMclksToMicroseconds(
        finalRangeMclks, finalRangeVcselPeriodPclks);
    return (
      msrcDssTccUs,
      preRangeUs,
      finalRangeUs,
      finalRangeVcselPeriodPclks,
      preRangeMclks,
    );
  }

  // The measurement timing budget in microseconds
  int getMeasurementTimingBudget() {
    var budgetUs = 1910 + 960;
    var (bool tcc, bool dss, bool msrc, bool preRange, bool finalRange) =
        _getSequenceStepEnables();

    var stepTimeouts = _getSequenceStepTimeouts(preRange);
    var msrcDssTccUs = stepTimeouts.$1;
    var preRangeUs = stepTimeouts.$2;
    var finalRangeUs = stepTimeouts.$3;

    if (tcc) {
      budgetUs += msrcDssTccUs + 590;
    }
    if (dss) {
      budgetUs += 2 * (msrcDssTccUs + 690);
    } else if (msrc) {
      budgetUs += msrcDssTccUs + 660;
    }
    if (preRange) {
      budgetUs += preRangeUs + 660;
    }
    if (finalRange) {
      budgetUs += finalRangeUs + 550;
    }
    // _measurementTimingBudgetUs = budgetUs;
    return budgetUs;
  }

  void setMeasurementTimingBudget(int budgetUs) {
    var usedBudgetUs = 1320 + 960;
    var (bool tcc, bool dss, bool msrc, bool preRange, bool finalRange) =
        _getSequenceStepEnables();
    var stepTimeouts = _getSequenceStepTimeouts(preRange);
    var msrcDssTccUs = stepTimeouts.$1;
    var preRangeUs = stepTimeouts.$2;
    var finalRangeVcselPeriodPclks = stepTimeouts.$4;
    var preRangeMclks = stepTimeouts.$5;

    if (tcc) {
      usedBudgetUs += msrcDssTccUs + 590;
    }
    if (dss) {
      usedBudgetUs += 2 * (msrcDssTccUs + 690);
    } else if (msrc) {
      usedBudgetUs += msrcDssTccUs + 660;
    }
    if (preRange) {
      usedBudgetUs += preRangeUs + 660;
    }
    if (finalRange) {
      usedBudgetUs += 550;

      // Note that the final range timeout is determined by the timing
      // budget and the sum of all other timeouts within the sequence.
      // If there is no room for the final range timeout, then an error
      // will be set. Otherwise, the remaining time will be applied to
      // the final range.
      if (usedBudgetUs > budgetUs) {
        throw VL53L0Xexception("Requested timeout too big.");
      }
      var finalRangeTimeoutUs = budgetUs - usedBudgetUs;
      var finalRangeTimeoutMclks = _timeoutMicrosecondsToMclks(
          finalRangeTimeoutUs, finalRangeVcselPeriodPclks);
      if (preRange) {
        finalRangeTimeoutMclks += preRangeMclks;
      }
      writeU16(VL53L0Xconst.finalRangeConfigTimeoutMacropHi,
          _encodeTimeout(finalRangeTimeoutMclks));
      _measurementTimingBudgetUs = budgetUs;
    }
  }

  // Perform a single reading of the range for an object in front of the
  // sensor, but without return the distance.
  // Adapted from readRangeSingleMillimeters in pololu code at:
  // https://github.com/pololu/vl53l0x-arduino/blob/master/VL53L0X.cpp
  void doRangeMeasurement() {
    writeRegList([
      (0x80, 0x01),
      (0xFF, 0x01),
      (0x00, 0x00),
      (0x91, _stop),
      (0x00, 0x01),
      (0xFF, 0x00),
      (0x80, 0x00),
      (VL53L0Xconst.sysRangeStart.value, 0x01)
    ]);
    var start = DateTime.now().millisecondsSinceEpoch;
    while ((readU8(VL53L0Xconst.sysRangeStart) & 0x01) > 0) {
      if (timeout > 0 &&
          (DateTime.now().millisecondsSinceEpoch - start) >= timeout) {
        throw VL53L0Xexception("Timeout waiting for VL53L0X!");
      }
    }
  }

  // Check if data is available from the sensor. If true a call to .range
  // will return quickly. If false, calls to .range will wait for the sensor's
  // next reading to be available
  bool isDataReady() {
    if (!_dataReady) {
      _dataReady = readU8(VL53L0Xconst.resultInterruptStatus) & 0x07 != 0;
    }
    return _dataReady;
  }

  // Return a range reading in millimeters.
  //    Note: Avoid calling this directly. If you do single mode, you need
  //    to call `do_range_measurement` first. Or your program will stuck or
  //    timeout occurred.
  int readRange() {
    var start = DateTime.now().millisecondsSinceEpoch;
    while (!isDataReady()) {
      if (timeout > 0 &&
          (DateTime.now().millisecondsSinceEpoch - start) >= timeout) {
        throw VL53L0Xexception("Timeout waiting for VL53L0X!");
      }
    }
    // assumptions: Linearity Corrective Gain is 1000 (default)
    //fractional ranging is not enabled
    var rangeMM = readU16reg(VL53L0Xconst.resultRangeStatus.value + 10);
    writeU8(VL53L0Xconst.systemInterruptClear, 0x01);
    _dataReady = false;
    return rangeMM;
  }

  double getDistance() {
    return _range / 10;
  }

  int getRange() {
    if (!_continuousMode) {
      doRangeMeasurement();
    }
    return readRange();
  }

  // Perform a continuous reading of the range for an object in front of
  // the sensor.
  //
  // Adapted from startContinuous in pololu code at:
  // https://github.com/pololu/vl53l0x-arduino/blob/master/VL53L0X.cpp
  void startContinuous() {
    writeRegList([
      (0x80, 0x01),
      (0xFF, 0x01),
      (0x00, 0x00),
      (0x91, _stop),
      (0x00, 0x01),
      (0xFF, 0x00),
      (0x80, 0x00),
      (VL53L0Xconst.sysRangeStart.value, 0x02),
    ]);
    var start = DateTime.now().millisecondsSinceEpoch;
    while ((readU8(VL53L0Xconst.sysRangeStart) & 0x01) > 0) {
      if (timeout > 0 &&
          (DateTime.now().millisecondsSinceEpoch - start) >= timeout) {
        throw VL53L0Xexception("Timeout waiting for VL53L0X!");
      }
    }
    _continuousMode = true;
  }

  // ** refiew until here **

  // Perform a continuous reading of the range for an object in front of
  // the sensor.
  //
  // Adapted from startContinuous in pololu code at:
  // https://github.com/pololu/vl53l0x-arduino/blob/master/VL53L0X.cpp
  void stopContinuous() {
    writeRegList([
      (VL53L0Xconst.sysRangeStart.value, 0x01),
      (0xFF, 0x01),
      (0x00, 0x00),
      (0x91, 0x00),
      (0x00, 0x01),
      (0xFF, 0x00),
    ]);
    _continuousMode = false;
    doRangeMeasurement();
  }
}

void main() {
  var i2c = I2C(1);
  var v = VL53L0X(i2c);
  while (true) {
    print(v.getRange());
    sleep(Duration(seconds: 1));
  }
}
