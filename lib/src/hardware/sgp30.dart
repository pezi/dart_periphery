// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://wiki.seeedstudio.com/Grove-VOC_and_eCO2_Gas_Sensor-SGP30/
// https://github.com/mattjlewis/diozero/blob/master/diozero-core/src/main/java/com/diozero/devices/SGP30.java
// https://github.com/adafruit/Adafruit_SGP30
// https://github.com/Seeed-Studio/SGP30_Gas_Sensor
// https://github.com/Sensirion/embedded-sgp/tree/master/sgp30

import 'dart:io';
import '../i2c.dart';
import 'utils/byte_buffer.dart';

const int productType = 0;
const int i2cAddress = 0x58;

// command and constants for reading the serial ID
const int cmdGetSerialId = 0x3682;
const int cmdGetSerialIdWords = 3;
const int cmdGetSerialDelayMs = 1;

// command and constants for reading the featureset version
const int cmdGetFeatureSet = 0x202f;
const int cmdGetFeatureSetWords = 1;
const int cmdGetFeatureSetDelayMs = 10;

// command and constants for on-chip self-test
const int cmdMeasureTest = 0x2032;
const int cmdMeasureTestWords = 1;
const int cmdMeasureTestTestDelayMs = 220;
const int cmdMeasureTestOk = 0xd400;

// command and constants for IAQ init
const int cmdIaqInit = 0x2003;
const int cmdIaqInitDelayMs = 10;

// command and constants for IAQ measure
const int cmdIaqMeasure = 0x2008;
const int cmdIaqMeasureWords = 2;
const int cmdIaqMeasureDelayMs = 12;

// command and constants for getting IAQ baseline
const int cmdGetIaqBaseline = 0x2015;
const int cmdGetIaqBaselineWords = 2;
const int cmdGetIaqBaselineDelayMs = 10;

// command and constants for setting IAQ baseline
const int cmdSetIaqBaseline = 0x201e;
const int cmdSetIaqDelayMs = 10;

// command and constants for raw measure
const int cmdRawMeasure = 0x2050;
const int cmdRawMeasureWords = 2;
const int cmdRawMeasureDelayMs = 25;

// command and constants for setting absolute humidity
const int cmdSetAbsoluteHumidity = 0x2061;
const int cmdSetAbsoluteDelayMs = 10;

// command and constants for getting TVOC inceptive baseline
const int cmdGetTVOCinceptiveBaseline = 0x20b3;
const int cmdGetTVOCinceptiveBaselineWords = 1;
const int cmdGetTVOCinceptiveBaselineDelayMs = 10;

// command and constants for setting TVOC baseline
const int cmdSetTVOCbaseline = 0x2077;
const int cmdSetTVOCbaselineDelayMs = 10;

/// [SGP30] exception
class SGP30excpetion implements Exception {
  SGP30excpetion(this.errorMsg);
  final String errorMsg;
  @override
  String toString() => errorMsg;
}

/// Set of internal [SGP30] features
class FeatureSetVersion {
  final int productType;
  final int productVersion;
  FeatureSetVersion(int prodType, int prodVersion)
      : productType = (prodType >> 12) & 0xF,
        productVersion = prodVersion & 0xFF;
  @override
  String toString() =>
      'FeatureSetVersion [productType=0x${productType.toRadixString(16)}, productVersion=0x${productVersion.toRadixString(16)}]';
}

/// [SGP30] raw data container for H<sub>2</sub> and Ethanol
class RawMeasurement {
  final int h2;
  final int ethanol;
  RawMeasurement(this.h2, this.ethanol);
  @override
  String toString() => 'RawMeasurement [h2=$h2, ethanol=$ethanol]';
}

/// [SGP30] measured data: co2Equivalent and totalVOC sensor.
class SGP30result {
  int co2Equivalent;
  // Total Volatile Organic Compounds
  int totalVOC;

  SGP30result(this.co2Equivalent, this.totalVOC);
  @override
  String toString() =>
      'SGP30result [CO2 Equivalent=$co2Equivalent, Total VOC=$totalVOC]';

  /// Returns a [SGP30result] object as a JSON string. [fractionDigits] controls the number of fraction digits.
  String toJSON([int fractionDigits = 2]) {
    return '{"co2Equivalent":"${co2Equivalent.toStringAsFixed(fractionDigits)}","totalVOC":"${totalVOC.toStringAsFixed(fractionDigits)}"';
  }
}

/// Sensirion eCO2 gas sensor, an air quality detection sensor.
///
/// See for more
/// * [SGP30 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_sgp30.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/sgp30.dart)
/// * [Datasheet](https://www.mouser.in/datasheet/2/682/Sensirion_Gas_Sensors_SGP30_Datasheet-1511334.pdf)
/// * This implementation is derived from project [DIOZero](https://github.com/mattjlewis/diozero/blob/master/diozero-core/src/main/java/com/diozero/devices/SGP30.java)
class SGP30 {
  final I2C i2c;
  bool _isInitialized = false;

  /// Creates a SGP30 sensor instance that uses the [i2c] bus.
  SGP30(this.i2c, [bool init = true]) {
    if (init) {
      iaqInit();
      measureIaq();
      _isInitialized = true;
    }
  }

  /// Checks if the sensor is initialized for measurement.
  bool isInitialized() {
    return _isInitialized;
  }

  List<int> _command(int command, int responseLength, int delayMs) {
    return _commandData(command, responseLength, delayMs, const <int>[]);
  }

  List<int> _commandData(
      int command, int responseLength, int delayMs, List<int> data) {
    var buffer = <int>[];

    buffer.add(command >> 8);
    buffer.add(command & 0xff);

    if (data.isNotEmpty) {
      for (var v in data) {
        buffer.add(v >> 8);
        buffer.add(v & 0xff);
      }
      buffer.add(crc8(data));
    }

    i2c.writeBytes(i2cAddress, buffer);

    sleep(Duration(milliseconds: delayMs));

    if (responseLength == 0) {
      return const <int>[];
    }

    var read = i2c.readBytes(i2cAddress, 3 * responseLength);

    if (!checkCRC(read)) {
      throw SGP30excpetion('CRC8 mismatch!');
    }

    var result = <int>[];
    for (var i = 0; i < 3 * responseLength; i += 3) {
      result.add(((read[i] & 0xff) << 8) | read[i + 1] & 0xff);
    }

    return result;
  }

  /// Returns the sensor serial ID.
  int getSerialId() {
    var response =
        _command(cmdGetSerialId, cmdGetSerialIdWords, cmdGetSerialDelayMs);

    return (response[0] << 32) | (response[1] << 16) | response[2];
  }

  /// Returns the internal features.
  FeatureSetVersion getFeatureSetVersion() {
    var result = _command(
        cmdGetFeatureSet, cmdGetFeatureSetWords, cmdGetFeatureSetDelayMs);
    return FeatureSetVersion(result[0], result[1]);
  }

  /// Initializes the sensor for measurement.
  void iaqInit() {
    if (!_isInitialized) {
      _command(cmdIaqInit, 0, cmdIaqInitDelayMs);
      _isInitialized = true;
    }
  }

  /// Returns the baseline as an int value.
  int getTvocInceptiveBaseline() {
    return _command(
            cmdGetTVOCinceptiveBaseline,
            cmdGetTVOCinceptiveBaselineWords,
            cmdGetTVOCinceptiveBaselineDelayMs)[0] &
        0xffff;
  }

  /// Returns the baseline.
  SGP30result getIaqBaseline() {
    var result = _command(
        cmdGetIaqBaseline, cmdGetIaqBaselineWords, cmdGetIaqBaselineDelayMs);
    return SGP30result(result[0], result[1]);
  }

  /// Sets the baseline of the sensor.
  void setIaqBaseline(SGP30result baseline) {
    _commandData(cmdSetIaqBaseline, 0, cmdSetIaqDelayMs,
        [baseline.totalVOC, baseline.co2Equivalent]);
  }

  /// Sets the absolute humidity for internal humidity compensation.
  void setHumidityCompensation(int humidity) {
    // Can only be set after iaq_init, can also be set between measurements
    _commandData(cmdSetAbsoluteHumidity, 0, cmdSetAbsoluteDelayMs, [humidity]);
  }

  /// Returns the co2Equivalent and totalVOC measurement.
  SGP30result measureIaq() {
    var result =
        _command(cmdIaqMeasure, cmdIaqMeasureWords, cmdIaqMeasureDelayMs);
    return SGP30result(result[0], result[1]);
  }

  /// Returns the H<sub>2</sub> and Ethanol measurement.
  RawMeasurement measureRaw() {
    var result =
        _command(cmdRawMeasure, cmdRawMeasureWords, cmdRawMeasureDelayMs);
    return RawMeasurement(result[0], result[1]);
  }

  /// Performs an internal test. DO NOT call this method after
  /// [SGP30.iaqInit] because this test resets the sensor initialization!
  ///
  /// To use this method create [SGP30] with the optional paramter
  /// init = false
  void measureTest() {
    var data = _command(
        cmdMeasureTest, cmdMeasureTestWords, cmdMeasureTestTestDelayMs);
    print(data[0] == cmdMeasureTestOk);
  }
}
