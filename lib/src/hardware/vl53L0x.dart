// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Resources
// https://github.com/adafruit/Adafruit_CircuitPython_VL53L0X
//

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:math' as math;

/// VL53L0X constants
enum VL53L0Xconst {
  sysrangeStart(0x00),
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
double _decodeTimeout(int val) {
  return (val & 0xFF).toDouble() * math.pow(2.0, ((val & 0xFF00) >> 8)) + 1;
}

/// Format: (LSByte * 2^MSByte) + 1
int _encodeTimeout(double timeoutMclks) {
  int t = timeoutMclks.toInt() & 0xFFFF;
  int lsByte = 0;
  int msByte = 0;

  if (t > 0) {
    lsByte = t - 1;
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

class VL53L0X {
  final I2C i2c;
  final int i2cAddress;

  VL53L0X(this.i2c, [this.i2cAddress = ds1307DefaultI2Caddress]) {
    /*
        # Check identification registers for expected values.
        # From section 3.2 of the datasheet.
        if (
            self._read_u8(0xC0) != 0xEE
            or self._read_u8(0xC1) != 0xAA
            or self._read_u8(0xC2) != 0x10
        ):
            raise RuntimeError(
                "Failed to find expected ID register values. Check wiring!"
            )*/
  }
}
