// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import '../i2c.dart';
import 'dart:collection';
import 'util.dart';
import 'dart:math';

// This code is derived from https://github.com/mattjlewis/diozero/blob/master/diozero-core/src/main/java/com/diozero/devices/BME680.java
// https://cdn-shop.adafruit.com/product-files/3660/BME680.pdf

/// Default I2C address for the sensor.
const int BME680_DEFAULT_I2C_ADDRESS = 0x76;

/// Alternative I2C address for the sensor.
const int BME680_ALTERNATIVE_I2C_ADDRESS = 0x77;

/// Chip vendor for the BME680
const String CHIP_VENDOR = 'Bosch';

/// Chip name for the BME680
const String CHIP_NAME = 'BME680';

/// Chip ID for the BME680
const int CHIP_ID_BME680 = 0x61;

/// Minimum pressure in hPa the sensor can measure.
const double MIN_PRESSURE_HPA = 300;

/// Maximum pressure in hPa the sensor can measure.
const double MAX_PRESSURE_HPA = 1100;

/// Minimum humidity in percentage the sensor can measure.
const double MIN_HUMIDITY_PERCENT = 0;

/// Maximum humidity in percentage the sensor can measure.
const double MAX_HUMIDITY_PERCENT = 100;

/// Minimum humidity in percentage the sensor can measure.
const double MIN_GAS_PERCENT = 10;

/// Maximum humidity in percentage the sensor can measure.
const double MAX_GAS_PERCENT = 95;

/// Maximum power consumption in micro-amperes when measuring temperature.
const double MAX_POWER_CONSUMPTION_TEMP_UA = 350;

/// Maximum power consumption in micro-amperes when measuring pressure.
const double MAX_POWER_CONSUMPTION_PRESSURE_UA = 714;

/// Maximum power consumption in micro-amperes when measuring pressure.
const double MAX_POWER_CONSUMPTION_HUMIDITY_UA = 340;

/// Maximum power consumption in micro-amperes when measuring volatile gases.
const double MAX_POWER_CONSUMPTION_GAS_UA = 13; // 12f

/// Maximum frequency of the measurements.
const double MAX_FREQ_HZ = 181;

/// Minimum frequency of the measurements.
const double MIN_FREQ_HZ = 23.1;

// Power mode
enum PowerMode { SLEEP, FORCED }
enum OversamplingMultiplier { X0, X1, X2, X4, X8, X16 }

int oversampMulti2int(OversamplingMultiplier v) {
  return int.parse(v.toString().substring(1));
}

/// IIR filter size
enum FilterSize {
  NONE,
  SIZE_1,
  SIZE_3,
  SIZE_7,
  SIZE_15,
  SIZE_31,
  SIZE_63,
  SIZE_127
}

/// Gas heater profile
enum HeaterProfile {
  PROFILE_0,
  PROFILE_1,
  PROFILE_2,
  PROFILE_3,
  PROFILE_4,
  PROFILE_5,
  PROFILE_6,
  PROFILE_7,
  PROFILE_8,
  PROFILE_9
}

// Gas heater duration.
const int MIN_HEATER_DURATION = 1;
const int MAX_HEATER_DURATION = 4032;

// Registers
const int CHIP_ID_ADDRESS = 0xD0;
const int SOFT_RESET_ADDRESS = 0xe0;

// Sensor configuration registers
const int CONFIG_HEATER_CONTROL_ADDRESS = 0x70;
const int CONFIG_ODR_RUN_GAS_NBC_ADDRESS = 0x71;
const int CONFIG_OS_H_ADDRESS = 0x72;
const int CONFIG_T_P_MODE_ADDRESS = 0x74;
const int CONFIG_ODR_FILTER_ADDRESS = 0x75;

// field_x related defines
const int FIELD0_ADDRESS = 0x1d;
const int FIELD_LENGTH = 15;
const int FIELD_ADDRESS_OFFSET = 17;

// Heater settings
const int RESISTANCE_HEAT0_ADDRESS = 0x5a;
const int GAS_WAIT0_ADDRESS = 0x64;

// Commands
const int SOFT_RESET_COMMAND = 0xb6;

// BME680 coefficients related defines
const int COEFFICIENT_ADDRESS1_LEN = 25;
const int COEFFICIENT_ADDRESS2_LEN = 16;

// Coefficient's address
const int COEFFICIENT_ADDRESS1 = 0x89;
const int COEFFICIENT_ADDRESS2 = 0xe1;

// Other coefficient's address
const int RESISTANCE_HEAT_VALUE_ADDRESS = 0x00;
const int RESISTANCE_HEAT_RANGE_ADDRESS = 0x02;
const int RANGE_SWITCHING_ERROR_ADDRESS = 0x04;
const int SENSOR_CONFIG_START_ADDRESS = 0x5A;
const int GAS_CONFIG_START_ADDRESS = 0x64;

// Mask definitions
final int GAS_MEASURE_MASK = bin2int('0b00110000');
final int NBCONVERSION_MASK = bin2int('0b00001111');
final int FILTER_MASK = bin2int('0b00011100');
final int OVERSAMPLING_TEMPERATURE_MASK = bin2int('0b11100000');
final int OVERSAMPLING_PRESSURE_MASK = bin2int('0b00011100');
final int OVERSAMPLING_HUMIDITY_MASK = bin2int('0b00000111');
final int HEATER_CONTROL_MASK = bin2int('0b00001000');
final int RUN_GAS_MASK = bin2int('0b00010000');
final int MODE_MASK = bin2int('0b00000011');
final int RESISTANCE_HEAT_RANGE_MASK = bin2int('0b00110000');
final int RANGE_SWITCHING_ERROR_MASK = bin2int('0b11110000');
final int NEW_DATA_MASK = bin2int('0b10000000');
final int GAS_INDEX_MASK = bin2int('0b00001111');
final int GAS_RANGE_MASK = bin2int('0b00001111');
final int GASM_VALID_MASK = bin2int('0b00100000');
final int HEAT_STABLE_MASK = bin2int('0b00010000');
final int MEM_PAGE_MASK = bin2int('0b00010000');
final int SPI_RD_MASK = bin2int('0b10000000');
final int SPI_WR_MASK = bin2int('0b01111111');
final int BIT_H1_DATA_MASK = bin2int('0b00001111');

// Bit position definitions for sensor settings
const int GAS_MEASURE_POSITION = 4;
const int NBCONVERSION_POSITION = 0;
const int FILTER_POSITION = 2;
const int OVERSAMPLING_TEMPERATURE_POSITION = 5;
const int OVERSAMPLING_PRESSURE_POSITION = 2;
const int OVERSAMPLING_HUMIDITY_POSITION = 0;
const int HEATER_CONTROL_POSITION = 3;
const int RUN_GAS_POSITION = 4;
const int MODE_POSITION = 0;

// Array Index to Field data mapping for Calibration Data
const int T2_LSB_REGISTER = 1;
const int T2_MSB_REGISTER = 2;
const int T3_REGISTER = 3;
const int P1_LSB_REGISTER = 5;
const int P1_MSB_REGISTER = 6;
const int P2_LSB_REGISTER = 7;
const int P2_MSB_REGISTER = 8;
const int P3_REGISTER = 9;
const int P4_LSB_REGISTER = 11;
const int P4_MSB_REGISTER = 12;
const int P5_LSB_REGISTER = 13;
const int P5_MSB_REGISTER = 14;
const int P7_REGISTER = 15;
const int P6_REGISTER = 16;
const int P8_LSB_REGISTER = 19;
const int P8_MSB_REGISTER = 20;
const int P9_LSB_REGISTER = 21;
const int P9_MSB_REGISTER = 22;
const int P10_REGISTER = 23;
const int H2_MSB_REGISTER = 25;
const int H2_LSB_REGISTER = 26;
const int H1_LSB_REGISTER = 26;
const int H1_MSB_REGISTER = 27;
const int H3_REGISTER = 28;
const int H4_REGISTER = 29;
const int H5_REGISTER = 30;
const int H6_REGISTER = 31;
const int H7_REGISTER = 32;
const int T1_LSB_REGISTER = 33;
const int T1_MSB_REGISTER = 34;
const int GH2_LSB_REGISTER = 35;
const int GH2_MSB_REGISTER = 36;
const int GH1_REGISTER = 37;
const int GH3_REGISTER = 38;

// This max value is used to provide precedence to multiplication or division
// in pressure compensation equation to achieve least loss of precision and
// avoiding overflows.
// i.e Comparing value, BME680_MAX_OVERFLOW_VAL = INT32_C(1 << 30)
// Other code has this at (1 << 31)
const int MAX_OVERFLOW_VAL = 0x40000000;

const int HUMIDITY_REGISTER_SHIFT_VALUE = 4;
const int RESET_PERIOD_MILLISECONDS = 10;
const int POLL_PERIOD_MILLISECONDS = 10;

// Look up tables for the possible gas range values
const List<int> GAS_RANGE_LOOKUP_TABLE_1 = [
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

const List<int> GAS_RANGE_LOOKUP_TABLE_2 = [
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

const int DATA_GAS_BURN_IN = 50;

/// BME680 exception
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
  HeaterProfile heaterProfile = HeaterProfile.PROFILE_0;
  // Variable to store heater control
  bool heaterEnabled = false;
  // Run gas enable value
  bool gasMeasurementsEnabled = false;
  // Store duration profile
  int heaterDuration = 0;
}

class SensorSettings {
  /// Humidity oversampling
  OversamplingMultiplier oversamplingHumidity = OversamplingMultiplier.X0;

  /// Temperature oversampling
  OversamplingMultiplier oversamplingTemperature = OversamplingMultiplier.X0;

  /// Pressure oversampling
  OversamplingMultiplier oversamplingPressure = OversamplingMultiplier.X0;

  /// Filter coefficient
  FilterSize filter = FilterSize.NONE;
}

class BME680result {
  // Contains new_data, gasm_valid & heat_stab
  bool newData = false;
  bool heaterTempStable = false;
  bool gasMeasurementValid = false;
  // The index of the heater profile used
  int gasMeasurementIndex = -1;
  // Measurement index to track order
  int measureIndex = -1;
  // Temperature in degree celsius x100
  double temperature = 0;
  // Pressure in Pascal
  double pressure = 0;
  // Humidity in % relative humidity x1000
  double humidity = 0;
  // Gas resistance in Ohms
  double gasResistance = 0;
  // Indoor air quality score index
  double airQualityScore = 0;
}

/// BME680 sensot for temperature, humidity, pressure and gas sensor
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
  /* ! Sensor power modes */
  PowerMode _powerMode = PowerMode.SLEEP;
  BME680result data = BME680result();
  final ListQueue<int> _gasResistanceData = ListQueue(DATA_GAS_BURN_IN);
  int _offsetTemperature = 0;

  /// Opens a BME680 sensor conntected with the [i2c] bus at the [i2cAddress = BME680_DEFAULT_I2C_ADDRESS] .
  BME680(I2C i2c, [this.i2cAddress = BME680_DEFAULT_I2C_ADDRESS]) : i2c = i2c {
    _initialise();
  }

  int getChipId() => _chipId;

  void _initialise() {
    for (var i = 0; i < DATA_GAS_BURN_IN; i++) {
      _gasResistanceData.add(0);
    }
    _chipId = i2c.readByteReg(i2cAddress, CHIP_ID_ADDRESS);
    if (_chipId != CHIP_ID_BME680) {
      throw BME680exception('$CHIP_VENDOR $CHIP_NAME not found.');
    }
    softReset();
    setPowerMode(PowerMode.SLEEP);

    _getCalibrationData();

    // It is highly recommended to set first osrs_h<2:0> followed by osrs_t<2:0> and
    // osrs_p<2:0> in one write command (see Section 3.3).
    setHumidityOversample(OversamplingMultiplier.X2); // 0x72
    setTemperatureOversample(OversamplingMultiplier.X4); // 0x74
    setPressureOversample(OversamplingMultiplier.X8); // 0x74

    setFilter(FilterSize.SIZE_3);

    // setHeaterEnabled(true);
    setGasMeasurementEnabled(true);

    setTemperatureOffset(0);

    getSensorData();
  }

  /// Returns the temperature oversampling.
  OversamplingMultiplier getTemperatureOversample() {
    return OversamplingMultiplier.values[
        (i2c.readByteReg(i2cAddress, CONFIG_T_P_MODE_ADDRESS) &
                OVERSAMPLING_TEMPERATURE_MASK) >>
            OVERSAMPLING_TEMPERATURE_POSITION];
  }

  /// Sets the temperature oversampling
  /// A higher oversampling value means more stable sensor readings, with less
  /// noise and jitter.
  ///
  /// However each step of oversampling adds about 2ms to the latency, causing a
  /// slower response time to fast transients.
  void setTemperatureOversample(OversamplingMultiplier value) {
    _setRegByte(CONFIG_T_P_MODE_ADDRESS, OVERSAMPLING_TEMPERATURE_MASK,
        OVERSAMPLING_TEMPERATURE_POSITION, value.index);
    _sensorSettings.oversamplingTemperature = value;
  }

  /// Returns the humidity oversampling.
  OversamplingMultiplier getHumidityOversample() {
    return OversamplingMultiplier.values[
        (i2c.readByteReg(i2cAddress, CONFIG_OS_H_ADDRESS) &
                OVERSAMPLING_HUMIDITY_MASK) >>
            OVERSAMPLING_HUMIDITY_POSITION];
  }

  /// Sets the humidity oversampling to [value].
  /// A higher oversampling value means more stable sensor readings, with less
  /// noise and jitter.
  ///
  /// However each step of oversampling adds about 2ms to the latency, causing a
  /// slower response time to fast transients.
  void setHumidityOversample(final OversamplingMultiplier value) {
    _setRegByte(CONFIG_OS_H_ADDRESS, OVERSAMPLING_HUMIDITY_MASK,
        OVERSAMPLING_HUMIDITY_POSITION, value.index);

    _sensorSettings.oversamplingHumidity = value;
  }

  // Set pressure oversampling to [value].
  // A higher oversampling value means more stable sensor readings, with less
  // noise and jitter.
  //
  // However each step of oversampling adds about 2ms to the latency,
  // causing a slower response time to fast transients.
  void setPressureOversample(final OversamplingMultiplier value) {
    _setRegByte(CONFIG_T_P_MODE_ADDRESS, OVERSAMPLING_PRESSURE_MASK,
        OVERSAMPLING_PRESSURE_POSITION, value.index);

    _sensorSettings.oversamplingPressure = value;
  }

  /// Returns the pressure oversampling.
  OversamplingMultiplier getPressureOversample() {
    return OversamplingMultiplier.values[
        (i2c.readByteReg(i2cAddress, CONFIG_T_P_MODE_ADDRESS) &
                OVERSAMPLING_PRESSURE_MASK) >>
            OVERSAMPLING_PRESSURE_POSITION];
  }

  /// Returns the IIR filter size.
  FilterSize getFilter() {
    return FilterSize.values[
        (i2c.readByteReg(i2cAddress, CONFIG_ODR_FILTER_ADDRESS) &
                FILTER_MASK) >>
            FILTER_POSITION];
  }

  /// Sets the IIR filter size.
  /// Optionally remove short term fluctuations from the temperature and pressure
  /// readings,
  // increasing their resolution but reducing their bandwidth.
  /// Enabling the IIR filter does not slow down the time a reading takes,
  /// but will slow down the BME680s response to changes in temperature and
  /// pressure.

  /// When the IIR filter is enabled, the temperature and pressure resolution is
  /// effectively 20bit.
  /// When it is disabled, it is 16bit + oversampling-1 bits.
  void setFilter(final FilterSize value) {
    _setRegByte(
        CONFIG_ODR_FILTER_ADDRESS, FILTER_MASK, FILTER_POSITION, value.index);

    _sensorSettings.filter = value;
  }

  /// Enables/disables the gas sensor.
  void setGasMeasurementEnabled(final bool gasMeasurementsEnabled) {
    // The gas conversions are started only in appropriate mode if run_gas = '1'
    _setRegByte(CONFIG_ODR_RUN_GAS_NBC_ADDRESS, RUN_GAS_MASK, RUN_GAS_POSITION,
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
    i2c.writeByteReg(i2cAddress, SOFT_RESET_ADDRESS, SOFT_RESET_COMMAND);
    sleep(Duration(milliseconds: RESET_PERIOD_MILLISECONDS));
  }

  /// Returns the power mode.
  PowerMode getPowerMode() {
    _powerMode = PowerMode.values[
        i2c.readByteReg(i2cAddress, CONFIG_T_P_MODE_ADDRESS) & MODE_MASK];

    return _powerMode;
  }

  /// Sets the [powerMode] of the sensor.
  void setPowerMode(PowerMode powerMode) {
    _setRegByte(
        CONFIG_T_P_MODE_ADDRESS, MODE_MASK, MODE_POSITION, powerMode.index);

    powerMode = powerMode;

    // Wait for the power mode to switch to the requested value
    while (getPowerMode() != powerMode) {
      sleep(Duration(milliseconds: POLL_PERIOD_MILLISECONDS));
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
    var calibration_data = _readCalibrationData();

    /* Temperature related coefficients */
    _calibration.temperature[0] = _bytesToWord(
        calibration_data[T1_MSB_REGISTER],
        calibration_data[T1_LSB_REGISTER],
        false);
    _calibration.temperature[1] = _bytesToWord(
        calibration_data[T2_MSB_REGISTER],
        calibration_data[T2_LSB_REGISTER],
        true);
    _calibration.temperature[2] = calibration_data[T3_REGISTER];

    /* Pressure related coefficients */
    _calibration.pressure[0] = _bytesToWord(calibration_data[P1_MSB_REGISTER],
        calibration_data[P1_LSB_REGISTER], false);
    _calibration.pressure[1] = _bytesToWord(calibration_data[P2_MSB_REGISTER],
        calibration_data[P2_LSB_REGISTER], true);
    _calibration.pressure[2] = calibration_data[P3_REGISTER];
    _calibration.pressure[3] = _bytesToWord(calibration_data[P4_MSB_REGISTER],
        calibration_data[P4_LSB_REGISTER], true);
    _calibration.pressure[4] = _bytesToWord(calibration_data[P5_MSB_REGISTER],
        calibration_data[P5_LSB_REGISTER], true);
    _calibration.pressure[5] = calibration_data[P6_REGISTER];
    _calibration.pressure[6] = calibration_data[P7_REGISTER];
    _calibration.pressure[7] = _bytesToWord(calibration_data[P8_MSB_REGISTER],
        calibration_data[P8_LSB_REGISTER], true);
    _calibration.pressure[8] = _bytesToWord(calibration_data[P9_MSB_REGISTER],
        calibration_data[P9_LSB_REGISTER], true);
    _calibration.pressure[9] = calibration_data[P10_REGISTER] & 0xFF;

    /* Humidity related coefficients */
    _calibration.humidity[0] = (((calibration_data[H1_MSB_REGISTER] & 0xff) <<
                HUMIDITY_REGISTER_SHIFT_VALUE) |
            (calibration_data[H1_LSB_REGISTER] & BIT_H1_DATA_MASK)) &
        0xffff;
    _calibration.humidity[1] = (((calibration_data[H2_MSB_REGISTER] & 0xff) <<
                HUMIDITY_REGISTER_SHIFT_VALUE) |
            ((calibration_data[H2_LSB_REGISTER] & 0xff) >>
                HUMIDITY_REGISTER_SHIFT_VALUE)) &
        0xffff;
    _calibration.humidity[2] = calibration_data[H3_REGISTER];
    _calibration.humidity[3] = calibration_data[H4_REGISTER];
    _calibration.humidity[4] = calibration_data[H5_REGISTER];
    _calibration.humidity[5] = calibration_data[H6_REGISTER] & 0xFF;
    _calibration.humidity[6] = calibration_data[H7_REGISTER];

    // Gas heater related coefficients
    _calibration.gasHeater[0] = calibration_data[GH1_REGISTER];
    _calibration.gasHeater[1] = _bytesToWord(calibration_data[GH2_MSB_REGISTER],
        calibration_data[GH2_LSB_REGISTER], true);
    _calibration.gasHeater[2] = calibration_data[GH3_REGISTER];

    /* Other coefficients */
    // Read other heater calibration data
    // res_heat_range is the heater range stored in register address 0x02 <5:4>
    _calibration.resistanceHeaterRange =
        (i2c.readByteReg(i2cAddress, RESISTANCE_HEAT_RANGE_ADDRESS) &
                RESISTANCE_HEAT_RANGE_MASK) >>
            4;
    // res_heat_val is the heater resistance correction factor stored in register
    // address 0x00
    // (signed, value from -128 to 127)
    _calibration.resistanceHeaterValue =
        i2c.readByteReg(i2cAddress, RESISTANCE_HEAT_VALUE_ADDRESS);

    // Range switching error from register address 0x04 <7:4> (signed 4 bit)
    _calibration.rangeSwitchingError =
        (i2c.readByteReg(i2cAddress, RANGE_SWITCHING_ERROR_ADDRESS) &
                RANGE_SWITCHING_ERROR_MASK) >>
            4;
  }

  // Read calibration array
  List<int> _readCalibrationData() {
    return <int>[
      ...i2c.readBytesReg(
          i2cAddress, COEFFICIENT_ADDRESS1, COEFFICIENT_ADDRESS1_LEN),
      ...i2c.readBytesReg(
          i2cAddress, COEFFICIENT_ADDRESS2, COEFFICIENT_ADDRESS2_LEN)
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

  BME680result getSensorData() {
    setPowerMode(PowerMode.FORCED);

    var tries = 10;
    do {
      var buffer = i2c.readBytesReg(i2cAddress, FIELD0_ADDRESS, FIELD_LENGTH);

      // Set to 1 during measurements, goes to 0 when measurements are completed
      var new_data = (buffer[0] & NEW_DATA_MASK) == 0 ? true : false;

      if (new_data) {
        data.newData = new_data;
        data.gasMeasurementIndex = buffer[0] & GAS_INDEX_MASK;
        data.measureIndex = buffer[1];

        // Read the raw data from the sensor
        var adc_pres = ((buffer[2] & 0xff) << 12) |
            ((buffer[3] & 0xff) << 4) |
            ((buffer[4] & 0xff) >> 4);
        var adc_temp = ((buffer[5] & 0xff) << 12) |
            ((buffer[6] & 0xff) << 4) |
            ((buffer[7] & 0xff) >> 4);
        var adc_hum = (buffer[8] << 8) | (buffer[9] & 0xff);
        var adc_gas_resistance =
            ((buffer[13] & 0xff) << 2) | ((buffer[14] & 0xff) >> 6);
        var gas_range = buffer[14] & GAS_RANGE_MASK;

        data.gasMeasurementValid = (buffer[14] & GASM_VALID_MASK) > 0;
        data.heaterTempStable = (buffer[14] & HEAT_STABLE_MASK) > 0;

        var temperature = _calculateTemperature(adc_temp);
        data.temperature = temperature / 100.0;
        // Save for heater calculations
        _ambientTemperature = temperature;
        data.pressure = _calculatePressure(adc_pres) / 100.0;
        data.humidity = _calculateHumidity(adc_hum) / 1000.0;
        data.gasResistance =
            _calculateGasResistance(adc_gas_resistance, gas_range).toDouble();
        data.airQualityScore =
            _calculateAirQuality(adc_gas_resistance, data.humidity.toInt());

        break;
      }

      // Delay to poll the data
      sleep(Duration(milliseconds: POLL_PERIOD_MILLISECONDS));
    } while (--tries > 0);

    return data;
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
    var calculated_pressure = 1048576 - pressureAdc;
    calculated_pressure = (calculated_pressure - (var2 >> 12)) * 3125;

    if (calculated_pressure >= MAX_OVERFLOW_VAL) {
      calculated_pressure = ((calculated_pressure ~/ var1) << 1);
    } else {
      calculated_pressure = ((calculated_pressure << 1) ~/ var1);
    }

    var1 = (_calibration.pressure[8] *
            (((calculated_pressure >> 3) * (calculated_pressure >> 3)) >>
                13)) >>
        12;
    var2 = ((calculated_pressure >> 2) * _calibration.pressure[7]) >> 13;
    var var3 = ((calculated_pressure >> 8) *
            (calculated_pressure >> 8) *
            (calculated_pressure >> 8) *
            _calibration.pressure[9]) >>
        17;

    calculated_pressure = calculated_pressure +
        ((var1 + var2 + var3 + (_calibration.pressure[6] << 7)) >> 4);

    return calculated_pressure;
  }

  int _calculateHumidity(final int humidityAdc) {
    var temp_scaled = ((_temperatureFine * 5) + 128) >> 8;
    var var1 = humidityAdc -
        (_calibration.humidity[0] * 16) -
        (((temp_scaled * _calibration.humidity[2]) ~/ 100) >> 1);
    var var2 = (_calibration.humidity[1] *
            (((temp_scaled * _calibration.humidity[3]) ~/ 100) +
                (((temp_scaled *
                            ((temp_scaled * _calibration.humidity[4]) ~/
                                100)) >>
                        6) ~/
                    100) +
                (1 << 14))) >>
        10;
    var var3 = var1 * var2;
    var var4 = _calibration.humidity[5] << 7;
    var4 = (var4 + ((temp_scaled * _calibration.humidity[6]) ~/ 100)) >> 4;
    var var5 = ((var3 >> 14) * (var3 >> 14)) >> 10;
    var var6 = (var4 * var5) >> 1;
    var calc_hum = (((var3 + var6) >> 10) * 1000) >> 12;

    // Cap at 100%rH
    return min(max(calc_hum, 0), 100000);
  }

  int _calculateGasResistance(final int gasResistanceAdc, final int gasRange) {
    final var1 = (1340 + (5 * _calibration.rangeSwitchingError)) *
            GAS_RANGE_LOOKUP_TABLE_1[gasRange] >>
        16;
    final var2 = ((((gasResistanceAdc) << 15) - 16777216) + var1);
    final var3 = ((GAS_RANGE_LOOKUP_TABLE_2[gasRange] * var1) >> 9);
    return (var3 + (var2 >> 1)) ~/ var2;
  }

  int _calculateHeaterResistance(
      final int temperature, int ambientTemperature, Calibration calibration) {
    /* Cap temperature */
    var normalised_temperature = min(max(temperature, 200), 400);

    var var1 = ((ambientTemperature * calibration.gasHeater[2]) ~/ 1000) * 256;
    var var2 = (calibration.gasHeater[0] + 784) *
        (((((calibration.gasHeater[1] + 154009) * normalised_temperature * 5) ~/
                    100) +
                3276800) ~/
            10);
    var var3 = var1 + (var2 ~/ 2);
    var var4 = (var3 ~/ (calibration.resistanceHeaterRange + 4));
    var var5 = (131 * calibration.resistanceHeaterValue) + 65536;
    var heater_res_x100 = ((var4 ~/ var5) - 250) * 34;

    return (heater_res_x100 + 50) ~/ 100;
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
      var gasBaseline = (_sumQueueValues(_gasResistanceData) / DATA_GAS_BURN_IN)
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
      return data.airQualityScore;
    }
  }

  ///
  void setSensorSettings(HeaterProfile heaterProfile, int heaterTemperature,
      int heaterDuration, FilterSize filterSize) {
    setGasConfig(heaterProfile, heaterTemperature, heaterDuration);
    setPowerMode(PowerMode.SLEEP);
    // Set the filter size
    if (filterSize != FilterSize.NONE) {
      setFilter(filterSize);
    }
    // Selecting heater control for the sensor
    // Selecting heater T,P oversampling for the sensor
    // Selecting humidity oversampling for the sensor
    // Selecting the runGas and NB conversion settings for the sensor
  }

  // Sets the temperature and duration of gas sensor heater
  // Target heater profile, between  0 and 9
  // Target temperature in degrees celsius, between 200 and 400
  // Target duration in milliseconds, between 1 and 4032
  void setGasConfig(final HeaterProfile profile, final int heaterTemperature,
      final int heaterDuration) {
    if (_powerMode == PowerMode.FORCED) {
      // Select the heater profile
      setGasHeaterProfile(profile);

      /* ! The index of the heater profile used */
      // uint8_t gas_index;
      i2c.writeByteReg(
          i2cAddress,
          RESISTANCE_HEAT0_ADDRESS + profile.index,
          _calculateHeaterResistance(
              heaterTemperature, _ambientTemperature, _calibration));
      // uint16_t heatr_dur;
      i2c.writeByteReg(i2cAddress, GAS_WAIT0_ADDRESS + profile.index,
          _calculateGasHeaterDuration(heaterDuration));

      // Bosch code only uses profile 0
      // dev->gas_sett.nb_conv = 0;
    }
  }

  /// Returns the gas sensor conversion profile.
  HeaterProfile getGasHeaterProfile() {
    return HeaterProfile.values[
        i2c.readByteReg(i2cAddress, CONFIG_ODR_RUN_GAS_NBC_ADDRESS) &
            NBCONVERSION_MASK];
  }

  /// Sets the current gas sensor conversion [heaterProfile]. Select one of the 10
  /// configured heating durations/set points.
  void setGasHeaterProfile(final HeaterProfile heaterProfile) {
    _setRegByte(CONFIG_ODR_RUN_GAS_NBC_ADDRESS, NBCONVERSION_MASK,
        NBCONVERSION_POSITION, heaterProfile.index);

    _gasSettings.heaterProfile = heaterProfile;
  }

  /// Checks if the heater on the sensor enabled.
  bool isHeaterEnabled() {
    return ((i2c.readByteReg(i2cAddress, CONFIG_HEATER_CONTROL_ADDRESS) &
                    HEATER_CONTROL_MASK) >>
                HEATER_CONTROL_POSITION) ==
            1
        ? false
        : true;
  }

  /// The flag [heaterEnabled] enables/disables the heater on the sensor.
  void setHeaterEnabled(bool heaterEnabled) {
    // Turn off current injected to heater by setting bit to one
    _setRegByte(CONFIG_HEATER_CONTROL_ADDRESS, HEATER_CONTROL_MASK,
        HEATER_CONTROL_POSITION, heaterEnabled ? 0 : 1);

    _gasSettings.heaterEnabled = heaterEnabled;
  }

  /// Returns the current gas status.
  bool isGasMeasurementEnabled() {
    return ((i2c.readByteReg(i2cAddress, CONFIG_ODR_RUN_GAS_NBC_ADDRESS) &
                    RUN_GAS_MASK) >>
                RUN_GAS_POSITION) ==
            1
        ? true
        : false;
  }

  int _calculateGasHeaterDuration(int duration) {
    var factor = 0;
    var durval = 0;

    if (duration >= 0xfc0) {
      durval = 0xff; /* Max duration */
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
    var tph_duration = cycles * 1963;
    tph_duration += (477 * 4); // TPH switching duration
    tph_duration += (477 * 5); // Gas measurement duration
    tph_duration += 500; // Get it to the closest whole number
    tph_duration ~/= 1000; // Convert to milisecond [ms]

    tph_duration += 1; // Wake up duration of 1ms

    // The remaining time should be used for heating
    _gasSettings.heaterDuration = duration - tph_duration;
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
    duration ~/= 1000; // Convert to milisecond [ms]

    duration += 1; // Wake up duration of 1ms

    // Get the gas duration only when gas measurements are enabled
    if (_gasSettings.gasMeasurementsEnabled) {
      // The remaining time should be used for heating */
      duration += _gasSettings.heaterDuration;
    }
    return duration;
  }
}
