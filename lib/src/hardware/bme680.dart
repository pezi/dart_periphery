// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:io';
import 'dart:math';

import '../i2c.dart';
import 'bosch.dart';
import 'utils/byte_buffer.dart';

// Resources:
// BME680 sensor for temperature, humidity, pressure and gas sensor
//
// This code bases on the diozero project - Thanks to Matthew Lewis!
// https://github.com/mattjlewis/diozero/blob/master/diozero-core/src/main/java/com/diozero/devices/BME680.java
// https://cdn-shop.adafruit.com/product-files/3660/BME680.pdf

/// Default I2C address of the BME680 sensor
const int bme680DefaultI2Caddress = 0x76;

/// Alternative I2C address of the BME680 sensor
const int bme680AlternativeI2Caddress = 0x77;

/// Chip vendor for the BME680
const String chipVendor = 'Bosch';

/// Chip name for the BME680
const String chipName = 'BME680';

/// Chip ID for the BME680
const int chipIdBme680 = 0x61;

/// Minimum pressure in hPa the sensor can measure.
const double minPressurehPa = 300;

/// Maximum pressure in hPa the sensor can measure.
const double maxPressurehPa = 1100;

/// Minimum humidity in percentage the sensor can measure.
const double minHumidityPercent = 0;

/// Maximum humidity in percentage the sensor can measure.
const double maxHumidityPercent = 100;

/// Minimum humidity in percentage the sensor can measure.
const double minGasPercent = 10;

/// Maximum humidity in percentage the sensor can measure.
const double maxGasPercent = 95;

/// Maximum power consumption in micro-amperes when measuring temperature.
const double maxPowerConsumptionTempUA = 350;

/// Maximum power consumption in micro-amperes when measuring pressure.
const double maxPowerConsumptionPressureUA = 714;

/// Maximum power consumption in micro-amperes when measuring pressure.
const double maxPowerConsumptionHumidityUA = 340;

/// Maximum power consumption in micro-amperes when measuring volatile gases.
const double maxPowerConsumptionGasUA = 13; // 12f

/// Maximum frequency of the measurements.
const double maxFreqHz = 181;

/// Minimum frequency of the measurements.
const double minFreqHz = 23.1;

const int sensorReadRetryCounter = 10;

/// [BME680] power modes
enum PowerMode { sleep, forced }

int oversampMulti2int(OversamplingMultiplier v) {
  return int.parse(v.toString().substring(1));
}

/// [BME680] IIR filter size
enum FilterSize { none, size1, size3, size7, size15, size31, size63, size127 }

/// [BME680] gas heater profile
enum HeaterProfile {
  profile0,
  profile1,
  profile2,
  profile3,
  profile4,
  profile5,
  profile6,
  profile7,
  profile8,
  profile9
}

// Gas heater duration.
const int minHeaterDuration = 1;
const int maxHeaterDuration = 4032;

// Registers
const int chipIdAddress = 0xD0;
const int softRestAddress = 0xe0;

// Sensor configuration registers
const int configHearerControlAddress = 0x70;
const int configOdrRunGasNbcAddress = 0x71;
const int configOsHaddress = 0x72;
// ignore: constant_identifier_names
const int configT_PmodeAddress = 0x74;
const int configODRfilterAddress = 0x75;

// field_x related defines
const int field0Address = 0x1d;
const int fieldLength = 15;
const int fieldAddressOffset = 17;

// Heater settings
const int resistanceHeat0Address = 0x5a;
const int gasWait0Address = 0x64;

// Commands
const int softResetCommand = 0xb6;

// BME680 coefficients related defines
const int coefficientAddress1Len = 25;
const int coefficientAddress2Len = 16;

// Coefficient's address
const int coeffizientAddress1 = 0x89;
const int coeffizientAddress2 = 0xe1;

// Other coefficient's address
const int resistanceHeatValueAddress = 0x00;
const int resistanceHeatRangeAddress = 0x02;
const int rangeSwitchingErrorAddress = 0x04;
const int sensorConfigStartAddress = 0x5A;
const int gasConfigStartAddress = 0x64;

// Mask definitions
final int gasMeasureMask = '0b00110000'.bin();
final int nbconversionMask = '0b00001111'.bin();
final int filterMask = '0b00011100'.bin();
final int oversamplingTemperatureMask = '0b11100000'.bin();
final int oversamplingPressureMask = '0b00011100'.bin();
final int oversamplingHumidityMask = '0b00000111'.bin();
final int heaterControlMask = '0b00001000'.bin();
final int runGasMask = '0b00010000'.bin();
final int modeMask = '0b00000011'.bin();
final int resistanceHeatRangeMask = '0b00110000'.bin();
final int rangeSwitchingErrorMask = '0b11110000'.bin();
final int newDataMask = '0b10000000'.bin();
final int gasIndexMask = '0b00001111'.bin();
final int gasRangeMask = '0b00001111'.bin();
final int gasmValidMask = '0b00100000'.bin();
final int heatStableMask = '0b00010000'.bin();
final int memPageMask = '0b00010000'.bin();
final int spiRDmask = '0b10000000'.bin();
final int spiWRmask = '0b01111111'.bin();
final int bitH1dataMask = '0b00001111'.bin();

// Bit position definitions for sensor settings
const int gasMeasurePosition = 4;
const int nbconversionPosition = 0;
const int filterPosition = 2;
const int oversamplingTemperaturePosition = 5;
const int oversamplingPressurePosition = 2;
const int oversamplingHumidityPosition = 0;
const int heaterControlPosition = 3;
const int runGasPosition = 4;
const int modePostion = 0;

// Array Index to Field data mapping for Calibration Data
const int t2LSBregister = 1;
const int t2MSBregister = 2;
const int t3Register = 3;
const int p1LSBregister = 5;
const int p1MSBregister = 6;
const int p2LSBregister = 7;
const int p2MSBregister = 8;
const int p3Register = 9;
const int p4LSBregister = 11;
const int p4MSBregister = 12;
const int p5LSBregister = 13;
const int p5MSBregister = 14;
const int p7Register = 15;
const int p6Register = 16;
const int p8LSBregister = 19;
const int p8MSBregister = 20;
const int p9LSBregister = 21;
const int p9MSBregister = 22;
const int p10Register = 23;
const int h2MSBregister = 25;
const int h2LSBregister = 26;
const int h1LSBregister = 26;
const int h1MSBregister = 27;
const int h3Register = 28;
const int h4Register = 29;
const int h5Register = 30;
const int h6Register = 31;
const int h7Register = 32;
const int t1LSBregister = 33;
const int t1MSBregister = 34;
const int gh2LSBregister = 35;
const int gh2MSBregister = 36;
const int gh1Register = 37;
const int gh3Register = 38;

// This max value is used to provide precedence to multiplication or division
// in pressure compensation equation to achieve least loss of precision and
// avoiding overflows.
// i.e Comparing value, BME680_MAX_OVERFLOW_VAL = INT32_C(1 << 30)
// Other code has this at (1 << 31)
const int maxOverflowVal = 0x40000000;

const int humidityRegisterShiftValue = 4;
const int resetPeriodMilliseconds = 10;
const int pollPeriodMilliseconds = 10;

// Look up tables for the possible gas range values
const List<int> gasRangeLookupTable1 = [
  2147483647,
  2147483647,
  2147483647,
  2147483647,
  2147483647,
  2126008810,
  2147483647,
  2130303777,
  2147483647,
  2147483647,
  2143188679,
  2136746228,
  2147483647,
  2126008810,
  2147483647,
  2147483647
];

const List<int> gasRangeLookupTable2 = [
  4096000000,
  2048000000,
  1024000000,
  512000000,
  255744255,
  127110228,
  64000000,
  32258064,
  16016016,
  8000000,
  4000000,
  2000000,
  1000000,
  500000,
  250000,
  125000
];

const int dataGasBurnIn = 50;

/// [BME680] exception
class BME680exception implements Exception {
  final String errorMsg;
  @override
  String toString() => errorMsg;

  BME680exception(this.errorMsg);
}

class Calibration {
  List<int> temperature = List<int>.filled(3, 0);
  List<int> pressure = List<int>.filled(10, 0);
  List<int> humidity = List<int>.filled(7, 0);
  List<int> gasHeater = List<int>.filled(3, 0);

  /// Heater resistance range
  int resistanceHeaterRange = 0;

  /// Heater resistance value = 0;
  int resistanceHeaterValue = 0;

  /// Switching error range
  int rangeSwitchingError = 0;
}

class GasSettings {
  // Variable to store nb conversion
  // nb_conv is used to select heater set-points of the sensor. Values 0-9
  HeaterProfile heaterProfile = HeaterProfile.profile0;
  // Variable to store heater control
  bool heaterEnabled = false;
  // Run gas enable value
  bool gasMeasurementsEnabled = false;
  // Store duration profile
  int heaterDuration = 0;
}

class SensorSettings {
  /// Humidity oversampling
  OversamplingMultiplier oversamplingHumidity = OversamplingMultiplier.x0;

  /// Temperature oversampling
  OversamplingMultiplier oversamplingTemperature = OversamplingMultiplier.x0;

  /// Pressure oversampling
  OversamplingMultiplier oversamplingPressure = OversamplingMultiplier.x0;

  /// Filter coefficient
  FilterSize filter = FilterSize.none;
}

/// [BME680] measured data: temperature, pressure, humidity and IAQ sensor.
class BME680result {
  /// Temperature in degree celsius
  final double temperature;

  /// Pressure in hPa ( hectopascal)
  final double pressure;

  /// % relative humidity
  final double humidity;

  /// Gas resistance in Ohms
  final double gasResistance;

  /// Indoor air quality score index 0-500
  final double airQualityScore;
  // Is the heater temperature stable?
  final bool isHeaterTempStable;

  /// Is the gas measurement valid?
  final bool isGasMeasurementValid;

  /// index of the heater profile used
  final int gasMeasurementIndex;

  /// measurement index, to track order
  int measureIndex;

  BME680result(
      this.temperature,
      this.pressure,
      this.humidity,
      this.gasResistance,
      this.airQualityScore,
      this.isHeaterTempStable,
      this.isGasMeasurementValid,
      this.gasMeasurementIndex,
      this.measureIndex);

  @override
  String toString() =>
      'BME680result [temperature=$temperature, pressure=$pressure, humidity=$humidity,gasResistance=$gasResistance,airQualityScore=$airQualityScore]';

  String _toJSONbase([int fractionDigits = 2]) {
    return '{"temperature":"${temperature.toStringAsFixed(fractionDigits)}","pressure":"${pressure.toStringAsFixed(fractionDigits)}","humidity":"${humidity.toStringAsFixed(fractionDigits)},"airQualityScore":${airQualityScore.toStringAsFixed(fractionDigits)}"';
  }

  /// Returns a [BME680result] as a JSON string with only temperature, pressure,
  /// humidity and airQualityScore, if the optional parameter [allVars] is
  /// false, true returns all variables. [fractionDigits] controls the number
  /// of fraction digits.
  String toJSON([int fractionDigits = 2, bool allVars = false]) {
    if (allVars == false) {
      return '${_toJSONbase(fractionDigits)}}';
    } else {
      return '${_toJSONbase(fractionDigits)},"gasResistance":"${gasResistance.toStringAsFixed(fractionDigits)}","isHeaterTempStable":"$isHeaterTempStable","gasResistance":"$gasResistance","isGasMeasurementValid":"$isGasMeasurementValid","gasMeasurementIndex":"$gasMeasurementIndex","measureIndex":"$measureIndex"}';
    }
  }
}

/// Bosch BME680 sensor for temperature, humidity, pressure and gas sensor
/// ([IAQ](https://en.wikipedia.org/wiki/Indoor_air_quality)
///  Indoor air quality).
///
/// IAQ is in an index that can have values between 0 and 500 with
/// resolution of 1 to indicate or quantify the quality of the air available
/// in the surrounding.
///
/// See for more
/// * [BM680 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_bme680.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/bme680.dart)
/// * [Datasheet](https://cdn-shop.adafruit.com/product-files/3660/BME680.pdf)
/// * This implementation is derived from project [DIOZero](https://github.com/mattjlewis/diozero/blob/master/diozero-core/src/main/java/com/diozero/devices/BME680.java)
class BME680 {
  final I2C i2c;
  final int i2cAddress;
  int _temperatureFine = 0;
  int _chipId = 0;
  // ! Ambient temperature in Degree C
  int _ambientTemperature = 0;
  // ! Sensor calibration data
  final Calibration _calibration = Calibration();
  // ! Sensor settings
  final SensorSettings _sensorSettings = SensorSettings();
  // ! Gas Sensor settings
  final GasSettings _gasSettings = GasSettings();
  // ! Sensor power modes
  PowerMode _powerMode = PowerMode.sleep;
  bool _heaterTempStable = false;
  bool _gasMeasurementValid = false;
  // The index of the heater profile used
  int _gasMeasurementIndex = -1;
  // Measurement index to track order
  int _measureIndex = -1;
  // Temperature in degree celsius x100
  double _temperature = 0;
  // Pressure in Pascal
  double _pressure = 0;
  // Humidity in % relative humidity x1000
  double _humidity = 0;
  // Gas resistance in Ohms
  double _gasResistance = 0;
  // Indoor air quality score index
  double _airQualityScore = 0;

  final ListQueue<int> _gasResistanceData = ListQueue(dataGasBurnIn);
  int _offsetTemperature = 0;

  /// Creates a BME680 sensor instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  ///
  /// Default [bme680DefaultI2Caddress] = 0x76, [bme680AlternativeI2Caddress] = 0x77
  BME680(this.i2c, [this.i2cAddress = bme680DefaultI2Caddress]) {
    _initialize();
  }

  /// Returns the internal chip ID.
  int getChipId() => _chipId;

  void _initialize() {
    for (var i = 0; i < dataGasBurnIn; i++) {
      _gasResistanceData.add(0);
    }
    _chipId = i2c.readByteReg(i2cAddress, chipIdAddress);
    if (_chipId != chipIdBme680) {
      throw BME680exception('$chipVendor $chipName not found.');
    }
    softReset();
    setPowerMode(PowerMode.sleep);

    _getCalibrationData();

    // It is highly recommended to set first osrs_h<2:0> followed by
    // osrs_t<2:0> and osrs_p<2:0> in one write command (see Section 3.3).
    setHumidityOversample(OversamplingMultiplier.x2); // 0x72
    setTemperatureOversample(OversamplingMultiplier.x4); // 0x74
    setPressureOversampling(OversamplingMultiplier.x8); // 0x74

    setFilter(FilterSize.size3);

    // setHeaterEnabled(true);
    setGasMeasurementEnabled(true);

    setTemperatureOffset(0);

    getValues();
  }

  /// Returns the temperature oversampling.
  OversamplingMultiplier getTemperatureOversample() {
    return OversamplingMultiplier.values[
        (i2c.readByteReg(i2cAddress, configT_PmodeAddress) &
                oversamplingTemperatureMask) >>
            oversamplingTemperaturePosition];
  }

  /// Sets the temperature oversampling to [value].
  ///
  /// A higher oversampling value means more stable
  /// sensor readings, with less noise and jitter.
  /// However each step of oversampling adds about 2ms to the latency, causing a
  /// slower response time to fast transients.
  void setTemperatureOversample(OversamplingMultiplier value) {
    _setRegByte(configT_PmodeAddress, oversamplingTemperatureMask,
        oversamplingTemperaturePosition, value.index);
    _sensorSettings.oversamplingTemperature = value;
  }

  /// Returns the humidity oversampling.
  OversamplingMultiplier getHumidityOversample() {
    return OversamplingMultiplier.values[
        (i2c.readByteReg(i2cAddress, configOsHaddress) &
                oversamplingHumidityMask) >>
            oversamplingHumidityPosition];
  }

  /// Sets the humidity oversampling to [value].
  ///
  ///  A higher oversampling value means more stable
  /// sensor readings, with less noise and jitter.
  /// However each step of oversampling adds about 2ms to the latency, causing a
  /// slower response time to fast transients.
  void setHumidityOversample(final OversamplingMultiplier value) {
    _setRegByte(configOsHaddress, oversamplingHumidityMask,
        oversamplingHumidityPosition, value.index);

    _sensorSettings.oversamplingHumidity = value;
  }

  /// Sets the pressure oversampling to [value].
  ///
  /// A higher oversampling value means more stable
  /// sensor readings, with less noise and jitter.
  /// However each step of oversampling adds about 2ms to the latency,
  /// causing a slower response time to fast transients.
  void setPressureOversampling(final OversamplingMultiplier value) {
    _setRegByte(configT_PmodeAddress, oversamplingPressureMask,
        oversamplingPressurePosition, value.index);

    _sensorSettings.oversamplingPressure = value;
  }

  /// Returns the pressure oversampling.
  OversamplingMultiplier getPressureOversampling() {
    return OversamplingMultiplier.values[
        (i2c.readByteReg(i2cAddress, configT_PmodeAddress) &
                oversamplingPressureMask) >>
            oversamplingPressurePosition];
  }

  /// Returns the IIR filter size.
  FilterSize getFilter() {
    return FilterSize.values[
        (i2c.readByteReg(i2cAddress, configODRfilterAddress) & filterMask) >>
            filterPosition];
  }

  /// Sets the IIR [filter] size.
  ///
  /// Optionally remove short term fluctuations from the temperature and pressure
  /// readings, increasing their resolution but reducing their bandwidth.
  /// Enabling the IIR filter does not slow down the time a reading takes,
  /// but will slow down the BME680s response to changes in temperature and
  /// pressure.
  ///
  /// When the IIR filter is enabled, the temperature and pressure resolution is
  /// effectively 20bit. When it is disabled, it is 16bit + oversampling-1 bits.
  void setFilter(final FilterSize filter) {
    _setRegByte(
        configODRfilterAddress, filterMask, filterPosition, filter.index);

    _sensorSettings.filter = filter;
  }

  /// [gasMeasurementsEnabled] enables/disables the gas sensor.
  void setGasMeasurementEnabled(final bool gasMeasurementsEnabled) {
    // The gas conversions are started only in appropriate mode if run_gas = '1'
    _setRegByte(configOdrRunGasNbcAddress, runGasMask, runGasPosition,
        gasMeasurementsEnabled ? 1 : 0);

    _gasSettings.gasMeasurementsEnabled = gasMeasurementsEnabled;
  }

  /// Sets temperature offset in celsius. If set, the temperature  will be
  /// increased by given [offset] in celsius.
  void setTemperatureOffset(final int offset) {
    if (offset == 0) {
      _offsetTemperature = 0;
    } else {
      // self.offset_temp_in_t_fine = int(math.copysign((((int(abs(value) * 100)) <<
      // 8) - 128) / 5, value))
      _offsetTemperature =
          (((offset.abs() * 100 << 8) - 128) ~/ 5) * offset.sign;
    }
  }

  /// Initiates a soft reset
  void softReset() {
    i2c.writeByteReg(i2cAddress, softRestAddress, softResetCommand);
    sleep(Duration(milliseconds: resetPeriodMilliseconds));
  }

  /// Returns the power mode.
  PowerMode getPowerMode() {
    _powerMode = PowerMode
        .values[i2c.readByteReg(i2cAddress, configT_PmodeAddress) & modeMask];

    return _powerMode;
  }

  /// Sets the [powerMode] of the sensor.
  void setPowerMode(PowerMode powerMode) {
    _setRegByte(configT_PmodeAddress, modeMask, modePostion, powerMode.index);

    powerMode = powerMode;

    // Wait for the power mode to switch to the requested value
    while (getPowerMode() != powerMode) {
      sleep(Duration(milliseconds: pollPeriodMilliseconds));
    }
  }

  void _setRegByte(
      final int address, final int mask, final int position, final int value) {
    var oldData = i2c.readByteReg(i2cAddress, address);

    int newData;
    if (position == 0) {
      newData = ((oldData & ~mask) | (value & mask));
    } else {
      newData = ((oldData & ~mask) | ((value << position) & mask));
    }
    i2c.writeByteReg(i2cAddress, address, newData & 0xff);
  }

  void _getCalibrationData() {
    // Read the raw calibration data
    var calibrationData = _readCalibrationData();

    // Temperature related coefficients
    _calibration.temperature[0] = _bytesToWord(
        calibrationData[t1MSBregister], calibrationData[t1LSBregister], false);
    _calibration.temperature[1] = _bytesToWord(
        calibrationData[t2MSBregister], calibrationData[t2LSBregister], true);
    _calibration.temperature[2] = calibrationData[t3Register];

    // Pressure related coefficients
    _calibration.pressure[0] = _bytesToWord(
        calibrationData[p1MSBregister], calibrationData[p1LSBregister], false);
    _calibration.pressure[1] = _bytesToWord(
        calibrationData[p2MSBregister], calibrationData[p2LSBregister], true);
    _calibration.pressure[2] = calibrationData[p3Register];
    _calibration.pressure[3] = _bytesToWord(
        calibrationData[p4MSBregister], calibrationData[p4LSBregister], true);
    _calibration.pressure[4] = _bytesToWord(
        calibrationData[p5MSBregister], calibrationData[p5LSBregister], true);
    _calibration.pressure[5] = calibrationData[p6Register];
    _calibration.pressure[6] = calibrationData[p7Register];
    _calibration.pressure[7] = _bytesToWord(
        calibrationData[p8MSBregister], calibrationData[p8LSBregister], true);
    _calibration.pressure[8] = _bytesToWord(
        calibrationData[p9MSBregister], calibrationData[p9LSBregister], true);
    _calibration.pressure[9] = calibrationData[p10Register] & 0xFF;

    // Humidity related coefficients
    _calibration.humidity[0] = (((calibrationData[h1MSBregister] & 0xff) <<
                humidityRegisterShiftValue) |
            (calibrationData[h1LSBregister] & bitH1dataMask)) &
        0xffff;
    _calibration.humidity[1] = (((calibrationData[h2MSBregister] & 0xff) <<
                humidityRegisterShiftValue) |
            ((calibrationData[h2LSBregister] & 0xff) >>
                humidityRegisterShiftValue)) &
        0xffff;
    _calibration.humidity[2] = calibrationData[h3Register];
    _calibration.humidity[3] = calibrationData[h4Register];
    _calibration.humidity[4] = calibrationData[h5Register];
    _calibration.humidity[5] = calibrationData[h6Register] & 0xFF;
    _calibration.humidity[6] = calibrationData[h7Register];

    // Gas heater related coefficients
    _calibration.gasHeater[0] = calibrationData[gh1Register];
    _calibration.gasHeater[1] = _bytesToWord(
        calibrationData[gh2MSBregister], calibrationData[gh2LSBregister], true);
    _calibration.gasHeater[2] = calibrationData[gh3Register];

    // Other coefficients
    // Read other heater calibration data
    // res_heat_range is the heater range stored in register address 0x02 <5:4>
    _calibration.resistanceHeaterRange =
        (i2c.readByteReg(i2cAddress, resistanceHeatRangeAddress) &
                resistanceHeatRangeMask) >>
            4;
    // res_heat_val is the heater resistance correction factor stored in
    // register address 0x00
    // (signed, value from -128 to 127)
    _calibration.resistanceHeaterValue =
        i2c.readByteReg(i2cAddress, resistanceHeatValueAddress);

    // Range switching error from register address 0x04 <7:4> (signed 4 bit)
    _calibration.rangeSwitchingError =
        (i2c.readByteReg(i2cAddress, rangeSwitchingErrorAddress) &
                rangeSwitchingErrorMask) >>
            4;
  }

  // Read calibration array
  List<int> _readCalibrationData() {
    return <int>[
      ...i2c.readBytesReg(
          i2cAddress, coeffizientAddress1, coefficientAddress1Len),
      ...i2c.readBytesReg(
          i2cAddress, coeffizientAddress2, coefficientAddress2Len)
    ];
  }

  int _bytesToWord(final int msb, final int lsb, final bool isSigned) {
    if (isSigned) {
      return (msb << 8) | (lsb & 0xff); // keep the sign of msb but not of lsb
    }
    return ((msb & 0xff) << 8) | (lsb & 0xff);
  }

  int _sumQueueValues(ListQueue<int> queue) {
    var sum = 0;
    for (var i = 0; i < queue.length; i++) {
      sum += queue.elementAt(i);
    }
    return sum;
  }

  /// Returns a [BME680result] with temperature, pressure, humidity and IAQ or
  /// throws an exception after [sensorReadRetryCounter] retries to read sensor
  /// data.
  BME680result getValues() {
    setPowerMode(PowerMode.forced);
    var retries = sensorReadRetryCounter;
    do {
      var buffer = i2c.readBytesReg(i2cAddress, field0Address, fieldLength);

      // Set to 1 during measurements, goes to 0 when measurements are completed
      var newData = (buffer[0] & newDataMask) == 0 ? true : false;

      if (newData) {
        _gasMeasurementIndex = buffer[0] & gasIndexMask;
        _measureIndex = buffer[1];

        // Read the raw data from the sensor
        var adcPres = ((buffer[2] & 0xff) << 12) |
            ((buffer[3] & 0xff) << 4) |
            ((buffer[4] & 0xff) >> 4);
        var adcTemp = ((buffer[5] & 0xff) << 12) |
            ((buffer[6] & 0xff) << 4) |
            ((buffer[7] & 0xff) >> 4);
        var adcHum = (buffer[8] << 8) | (buffer[9] & 0xff);
        var adcGasResistance =
            ((buffer[13] & 0xff) << 2) | ((buffer[14] & 0xff) >> 6);
        var gasRange = buffer[14] & gasRangeMask;

        _gasMeasurementValid = (buffer[14] & gasmValidMask) > 0;
        _heaterTempStable = (buffer[14] & heatStableMask) > 0;

        var temperature = _calculateTemperature(adcTemp);
        _temperature = temperature / 100.0;
        // Save for heater calculations
        _ambientTemperature = temperature;
        _pressure = _calculatePressure(adcPres) / 100.0;
        _humidity = _calculateHumidity(adcHum) / 1000.0;
        _gasResistance =
            _calculateGasResistance(adcGasResistance, gasRange).toDouble();
        _airQualityScore =
            _calculateAirQuality(adcGasResistance, _humidity.toInt());

        return BME680result(
            _temperature,
            _pressure,
            _humidity,
            _gasResistance,
            _airQualityScore,
            _heaterTempStable,
            _gasMeasurementValid,
            _gasMeasurementIndex,
            _measureIndex);
      }

      // Delay to poll the data
      sleep(Duration(milliseconds: pollPeriodMilliseconds));
    } while (--retries > 0);
    throw BME680exception(
        'No data available: Give up after $sensorReadRetryCounter tries');
  }

  int _calculateTemperature(final int temperatureAdc) {
    // Convert the raw temperature to degrees C using calibration_data.
    var var1 = (temperatureAdc >> 3) - (_calibration.temperature[0] << 1);
    var var2 = (var1 * _calibration.temperature[1]) >> 11;
    var var3 = ((var1 >> 1) * (var1 >> 1)) >> 12;
    var3 = (var3 * (_calibration.temperature[2] << 4)) >> 14;

    // Save temperature data for pressure calculations
    _temperatureFine = (var2 + var3) + _offsetTemperature;

    return ((_temperatureFine * 5) + 128) >> 8;
  }

  int _calculatePressure(final int pressureAdc) {
    // Convert the raw pressure using calibration data.
    var var1 = (_temperatureFine >> 1) - 64000;
    var var2 =
        ((((var1 >> 2) * (var1 >> 2)) >> 11) * _calibration.pressure[5]) >> 2;
    var2 = var2 + ((var1 * _calibration.pressure[4]) << 1);
    var2 = (var2 >> 2) + (_calibration.pressure[3] << 16);
    var1 = (((((var1 >> 2) * (var1 >> 2)) >> 13) *
                (_calibration.pressure[2] << 5)) >>
            3) +
        ((_calibration.pressure[1] * var1) >> 1);
    var1 = var1 >> 18;

    var1 = ((32768 + var1) * _calibration.pressure[0]) >> 15;
    var calculatedPressure = 1048576 - pressureAdc;
    calculatedPressure = (calculatedPressure - (var2 >> 12)) * 3125;

    if (calculatedPressure >= maxOverflowVal) {
      calculatedPressure = ((calculatedPressure ~/ var1) << 1);
    } else {
      calculatedPressure = ((calculatedPressure << 1) ~/ var1);
    }

    var1 = (_calibration.pressure[8] *
            (((calculatedPressure >> 3) * (calculatedPressure >> 3)) >> 13)) >>
        12;
    var2 = ((calculatedPressure >> 2) * _calibration.pressure[7]) >> 13;
    var var3 = ((calculatedPressure >> 8) *
            (calculatedPressure >> 8) *
            (calculatedPressure >> 8) *
            _calibration.pressure[9]) >>
        17;

    calculatedPressure = calculatedPressure +
        ((var1 + var2 + var3 + (_calibration.pressure[6] << 7)) >> 4);

    return calculatedPressure;
  }

  int _calculateHumidity(final int humidityAdc) {
    var tempScaled = ((_temperatureFine * 5) + 128) >> 8;
    var var1 = humidityAdc -
        (_calibration.humidity[0] * 16) -
        (((tempScaled * _calibration.humidity[2]) ~/ 100) >> 1);
    var var2 = (_calibration.humidity[1] *
            (((tempScaled * _calibration.humidity[3]) ~/ 100) +
                (((tempScaled *
                            ((tempScaled * _calibration.humidity[4]) ~/ 100)) >>
                        6) ~/
                    100) +
                (1 << 14))) >>
        10;
    var var3 = var1 * var2;
    var var4 = _calibration.humidity[5] << 7;
    var4 = (var4 + ((tempScaled * _calibration.humidity[6]) ~/ 100)) >> 4;
    var var5 = ((var3 >> 14) * (var3 >> 14)) >> 10;
    var var6 = (var4 * var5) >> 1;
    var calcHum = (((var3 + var6) >> 10) * 1000) >> 12;

    // Cap at 100%rH
    return min(max(calcHum, 0), 100000);
  }

  int _calculateGasResistance(final int gasResistanceAdc, final int gasRange) {
    final var1 = (1340 + (5 * _calibration.rangeSwitchingError)) *
            gasRangeLookupTable1[gasRange] >>
        16;
    final var2 = ((((gasResistanceAdc) << 15) - 16777216) + var1);
    final var3 = ((gasRangeLookupTable2[gasRange] * var1) >> 9);
    return (var3 + (var2 >> 1)) ~/ var2;
  }

  int _calculateHeaterResistance(
      final int temperature, int ambientTemperature, Calibration calibration) {
    // Cap temperature
    var normalisedTemperature = min(max(temperature, 200), 400);

    var var1 = ((ambientTemperature * calibration.gasHeater[2]) ~/ 1000) * 256;
    var var2 = (calibration.gasHeater[0] + 784) *
        (((((calibration.gasHeater[1] + 154009) * normalisedTemperature * 5) ~/
                    100) +
                3276800) ~/
            10);
    var var3 = var1 + (var2 ~/ 2);
    var var4 = (var3 ~/ (calibration.resistanceHeaterRange + 4));
    var var5 = (131 * calibration.resistanceHeaterValue) + 65536;
    var heaterResX100 = ((var4 ~/ var5) - 250) * 34;

    return (heaterResX100 + 50) ~/ 100;
  }

  double _calculateAirQuality(int gasResistance, int humidity) {
    // Set the humidity baseline to 40%, an optimal indoor humidity.
    var humidityBaseline = 40.0;
    // This sets the balance between humidity and gas reading in the calculation of
    // airQualityScore (25:75, humidity:gas)
    var humidityWeighting = 0.25;

    try {
      _gasResistanceData.removeFirst();
      _gasResistanceData.add(gasResistance);

      // Collect gas resistance burn-in values, then use the average of the last n
      // values to set the upper limit for calculating gasBaseline.
      var gasBaseline = (_sumQueueValues(_gasResistanceData) / dataGasBurnIn)
          .roundToDouble()
          .toInt();

      var gasOffset = gasBaseline - gasResistance;

      var humidityOffset = humidity - humidityBaseline;

      // Calculate humidityScore as the distance from the humidityBaseline
      double humidityScore;
      if (humidityOffset > 0) {
        humidityScore = (100.0 - humidityBaseline - humidityOffset) /
            (100.0 - humidityBaseline) *
            (humidityWeighting * 100.0);
      } else {
        humidityScore = (humidityBaseline + humidityOffset) /
            humidityBaseline *
            (humidityWeighting * 100.0);
      }

      // Calculate gasScore as the distance from the gasBaseline
      double gasScore;
      if (gasOffset > 0) {
        gasScore = (gasResistance / gasBaseline) *
            (100.0 - (humidityWeighting * 100.0));
      } else {
        gasScore = 100.0 - (humidityWeighting * 100.0);
      }

      return humidityScore + gasScore;
    } catch (e) {
      return _airQualityScore;
    }
  }

  /// Sets the temperature [profile], [heaterDuration] and the
  /// [heaterTemperature] of gas sensor. [filterSize] sets IIR filter size
  /// * Target heater profile, between  0 and 9
  /// * Target temperature in degrees celsius, between 200 and 400
  /// * Target duration in milliseconds, between 1 and 4032
  void setSensorSettings(HeaterProfile profile, int heaterTemperature,
      int heaterDuration, FilterSize filterSize) {
    setGasConfig(profile, heaterTemperature, heaterDuration);
    setPowerMode(PowerMode.sleep);
    // Set the filter size
    if (filterSize != FilterSize.none) {
      setFilter(filterSize);
    }
    // Selecting heater control for the sensor
    // Selecting heater T,P oversampling for the sensor
    // Selecting humidity oversampling for the sensor
    // Selecting the runGas and NB conversion settings for the sensor
  }

  /// Sets the temperature [profile], [heaterDuration] and the
  /// [heaterTemperature] of gas sensor.
  ///
  /// * Target heater profile, between  0 and 9
  /// * Target temperature in degrees celsius, between 200 and 400
  /// * Target duration in milliseconds, between 1 and 4032
  void setGasConfig(final HeaterProfile profile, final int heaterTemperature,
      final int heaterDuration) {
    if (_powerMode == PowerMode.forced) {
      // Select the heater profile
      setGasHeaterProfile(profile);

      // The index of the heater profile used
      // uint8_t gas_index;
      i2c.writeByteReg(
          i2cAddress,
          resistanceHeat0Address + profile.index,
          _calculateHeaterResistance(
              heaterTemperature, _ambientTemperature, _calibration));
      // uint16_t heatr_dur;
      i2c.writeByteReg(i2cAddress, gasWait0Address + profile.index,
          _calculateGasHeaterDuration(heaterDuration));

      // Bosch code only uses profile 0
      // dev->gas_sett.nb_conv = 0;
    }
  }

  /// Returns the gas sensor conversion profile.
  HeaterProfile getGasHeaterProfile() {
    return HeaterProfile.values[
        i2c.readByteReg(i2cAddress, configOdrRunGasNbcAddress) &
            nbconversionMask];
  }

  /// Sets the current gas sensor conversion [heaterProfile]. Select one of
  /// the 10 configured heating durations/set points.
  void setGasHeaterProfile(final HeaterProfile heaterProfile) {
    _setRegByte(configOdrRunGasNbcAddress, nbconversionMask,
        nbconversionPosition, heaterProfile.index);

    _gasSettings.heaterProfile = heaterProfile;
  }

  /// Checks if the heater on the sensor enabled.
  bool isHeaterEnabled() {
    return ((i2c.readByteReg(i2cAddress, configHearerControlAddress) &
                    heaterControlMask) >>
                heaterControlPosition) ==
            1
        ? false
        : true;
  }

  /// [heaterEnabled] enables/disables the heater on the sensor.
  void setHeaterEnabled(bool heaterEnabled) {
    // Turn off current injected to heater by setting bit to one
    _setRegByte(configHearerControlAddress, heaterControlMask,
        heaterControlPosition, heaterEnabled ? 0 : 1);

    _gasSettings.heaterEnabled = heaterEnabled;
  }

  /// Returns the current gas status.
  bool isGasMeasurementEnabled() {
    return ((i2c.readByteReg(i2cAddress, configOdrRunGasNbcAddress) &
                    runGasMask) >>
                runGasPosition) ==
            1
        ? true
        : false;
  }

  int _calculateGasHeaterDuration(int duration) {
    var factor = 0;
    var durval = 0;

    if (duration >= 0xfc0) {
      durval = 0xff; // Max duration
    } else {
      while (duration > 0x3F) {
        duration = duration ~/ 4;
        factor += 1;
      }
      durval = duration + (factor * 64);
    }

    return durval;
  }

  /// Sets the profile [duration] of the sensor.
  void setProfileDuration(int duration) {
    var cycles = oversampMulti2int(_sensorSettings.oversamplingTemperature);
    cycles += oversampMulti2int(_sensorSettings.oversamplingPressure);
    cycles += oversampMulti2int(_sensorSettings.oversamplingHumidity);

    /// TPH measurement duration calculated in microseconds [us]
    var tphDuration = cycles * 1963;
    tphDuration += (477 * 4); // TPH switching duration
    tphDuration += (477 * 5); // Gas measurement duration
    tphDuration += 500; // Get it to the closest whole number
    tphDuration ~/= 1000; // Convert to millisecond [ms]

    tphDuration += 1; // Wake up duration of 1ms

    // The remaining time should be used for heating
    _gasSettings.heaterDuration = duration - tphDuration;
  }

  /// Returns the total measurement duration im ms.
  int getProfileDuration() {
    var cycles = oversampMulti2int(_sensorSettings.oversamplingTemperature);
    cycles += oversampMulti2int(_sensorSettings.oversamplingPressure);
    cycles += oversampMulti2int(_sensorSettings.oversamplingHumidity);

    /// Temperature, pressure and humidity measurement duration calculated in
    /// microseconds [us]
    var duration = cycles * 1963;
    duration +=
        (477 * 4); // Temperature, pressure and humidity switching duration
    duration += (477 * 5); // Gas measurement duration
    duration += 500; // Get it to the closest whole number
    duration ~/= 1000; // Convert to millisecond [ms]

    duration += 1; // Wake up duration of 1ms

    // Get the gas duration only when gas measurements are enabled
    if (_gasSettings.gasMeasurementsEnabled) {
      // The remaining time should be used for heating
      duration += _gasSettings.heaterDuration;
    }
    return duration;
  }
}
