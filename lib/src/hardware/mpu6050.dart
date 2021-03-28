// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';
import 'package:dart_periphery/dart_periphery.dart';

import '../i2c.dart';

// https://github.com/Raspoid/raspoid/blob/master/src/main/com/raspoid/I2CComponent.java
// https://github.com/Raspoid/raspoid/blob/master/src/main/com/raspoid/additionalcomponents/MPU6050.java

/// Digital Low Pass Filter
enum DLPF {
  FILTER0,
  FILTER1,
  FILTER2,
  FILTER3,
  FILTER4,
  FILTER5,
  FILTER6,
  FILTER7
}

// Default address of the MPU6050 device.
const int DEFAULT_MPU6050_ADDRESS = 0x68;

// Default value for the digital low pass filter (DLPF) setting for both gyroscope and accelerometer.
const DLPF DEFAULT_DLPF_CFG = DLPF.FILTER6;

// Default value for the sample rate divider.
const int DEFAULT_SMPLRT_DIV = 0x00;

// Coefficient to convert an angle value from radians to degrees.
const double RADIAN_TO_DEGREE = 180 / pi;

// It is impossible to calculate an angle for the z axis from the accelerometer.
const double ACCEL_Z_ANGLE = 0;

// Sample Rate Divider
// This register specifies the divider from the gyroscope output rate used to generate
// the Sample Rate for the MPU-60X0
const int MPU6050_REG_ADDR_SMPRT_DIV = 0x19; // 25

// This register configures the external Frame Synchronization (FSYNC) pin sampling and
// the Digital Low Pass Filter (DLPF) setting for both the gyroscopes and accelerometers.
const int MPU6050_REG_ADDR_CONFIG = 0x1A; // 26

// This register is used to trigger gyroscope self-test and configure the gyroscopes’ full scale range
const int MPU6050_REG_ADDR_GYRO_CONFIG = 0x1B; // 27

// This register is used to trigger accelerometer self test and configure the accelerometer
// full scale range. This register also configures the Digital High Pass Filter (DHPF).
const int MPU6050_REG_ADDR_ACCEL_CONFIG = 0x1C; // 28

// This register enables interrupt generation by interrupt sources.
const int MPU6050_REG_ADDR_INT_ENABLE = 0x1A; // 56

// This register allows the user to configure the power mode and clock source. It also provides
// a bit for resetting the entire device, and a bit for disabling the temperature sensor.
const int MPU6050_REG_ADDR_PWR_MGMT_1 = 0x6B; // 107

// This register allows the user to configure the frequency of wake-ups in Accelerometer Only Low
// Power Mode. This register also allows the user to put individual axes of the accelerometer and
// gyroscope into standby mode.
const int MPU6050_REG_ADDR_PWR_MGMT_2 = 0x6C; // 108

// This register store the most recent accelerometer measurements
const int MPU6050_REG_ADDR_ACCEL_XOUT_H = 0x3B; // 59

// This register store the most recent accelerometer measurements
const int MPU6050_REG_ADDR_ACCEL_XOUT_L = 0x3C; // 60

// This register store the most recent accelerometer measurements
const int MPU6050_REG_ADDR_ACCEL_YOUT_H = 0x3D; // 61

// This register store the most recent accelerometer measurements
const int MPU6050_REG_ADDR_ACCEL_YOUT_L = 0x3E; // 62

// This register store the most recent accelerometer measurements
const int MPU6050_REG_ADDR_ACCEL_ZOUT_H = 0x3F; // 63

// This register store the most recent accelerometer measurements
const int MPU6050_REG_ADDR_ACCEL_ZOUT_L = 0x40; // 64

// This register store the most recent temperature sensor measurement.
const int MPU6050_REG_ADDR_TEMP_OUT_H = 0x41; // 65

// This register store the most recent temperature sensor measurement.
const int MPU6050_REG_ADDR_TEMP_OUT_L = 0x42; // 66

// This register store the most recent gyroscope measurements
const int MPU6050_REG_ADDR_GYRO_XOUT_H = 0x43; // 67

// This register store the most recent gyroscope measurements
const int MPU6050_REG_ADDR_GYRO_XOUT_L = 0x44; // 68

// This register store the most recent gyroscope measurements
const int MPU6050_REG_ADDR_GYRO_YOUT_H = 0x45; // 69

// This register store the most recent gyroscope measurements
const int MPU6050_REG_ADDR_GYRO_YOUT_L = 0x46; // 70

/// This register store the most recent gyroscope measurements
const int MPU6050_REG_ADDR_GYRO_ZOUT_H = 0x47; // 71

// This register store the most recent gyroscope measurements.
const int MPU6050_REG_ADDR_GYRO_ZOUT_L = 0x48; // 72

/// MPU6050 exception
class MPU6050exception implements Exception {
  MPU6050exception(this.errorMsg);
  final String errorMsg;
  @override
  String toString() => errorMsg;
}

/// MPU-6050 Six-Axis (Gyro + Accelerometer) sensor
class MPU6050 {
  final I2C i2c;

  final int i2cAddress;

  DLPF _dlpfCfg = DEFAULT_DLPF_CFG;

  // Value used for the sample rate divider.
  final int _smplrtDiv;

  final bool isRunningIsolate;

  final int i2cBus;

  // Sensisitivty of the measures from the accelerometer. Used to convert accelerometer values.
  double _accelLSBSensitivity = 0;

  /// Sensitivity of the measures from the gyroscope. Used to convert gyroscope values to degrees/sec.
  double _gyroLSBSensitivity = 0;

  // late Timer _updatingTimer;
  // bool _updatingTimerRunning = false;
  int _lastUpdateTime = 0;

  // ACCELEROMETER

  /// Last acceleration value, in g, retrieved from the accelerometer, for the x axis. - (using the updating thread)
  double _accelAccelerationX = 0;

  /// Last acceleration value, in g, retrieved from the accelerometer, for the y axis. -(using the updating thread)
  double _accelAccelerationY = 0;

  /// Last acceleration value, in g, retrieved from the accelerometer, for the z axis. - (using the updating thread)
  double _accelAccelerationZ = 0;

  /// Last angle value, in °, retrieved from the accelerometer, for the x axis.
  /// (using the updating thread)
  double _accelAngleX = 0;

  /// Last angle value, in °, retrieved from the accelerometer, for the y axis.
  /// (using the updating thread)
  double _accelAngleY = 0;

  /// Last angle value, in °, retrieved from the accelerometer, for the z axis.
  /// (using the updating thread)
  double _accelAngleZ = 0;

  // GYROSCOPE

  /// Last angular speed value, in °/sec, retrieved from the gyroscope, for the x axis.
  /// (using the updating thread)
  double _gyroAngularSpeedX = 0;

  /// Last angular speed value, in °/sec, retrieved from the gyroscope, for the y axis.
  /// (using the updating thread)
  double _gyroAngularSpeedY = 0;

  /// Last angular speed value, in °/sec, retrieved from the gyroscope, for the z axis.
  /// (using the updating thread)
  double _gyroAngularSpeedZ = 0;

  /// Last angle value, in °, calculated from the gyroscope, for the x axis.
  /// (using the updating thread)
  double _gyroAngleX = 0;

  /// Last angle value, in °, calculated from the gyroscope, for the y axis.
  /// (using the updating thread)
  double _gyroAngleY = 0;

  /// Last angle value, in °, calculated from the gyroscope, for the z axis.
  /// (using the updating thread)
  double _gyroAngleZ = 0;

  /// Calculated offset for the angular speed from the gyroscope, for the x axis.
  double _gyroAngularSpeedOffsetX = 0;

  /// Calculated offset for the angular speed from the gyroscope, for the y axis.
  double _gyroAngularSpeedOffsetY = 0;

  /// Calculated offset for the angular speed from the gyroscope, for the z axis.
  double _gyroAngularSpeedOffsetZ = 0;

  // FILTERED

  /// Last angle value, in °, calculated from the accelerometer and the gyroscope,
  /// for the x axis.
  double _filteredAngleX = 0;

  /// Last angle value, in °, calculated from the accelerometer and the gyroscope,
  /// for the y axis.
  double _filteredAngleY = 0;

  /// Last angle value, in °, calculated from the accelerometer and the gyroscope,
  /// for the z axis. (using the updating thread)
  double _filteredAngleZ = 0;

  /// Opens a MPU6050 on the [i2c] with the optional default values
  MPU6050(
    this.i2c, [
    this.i2cAddress = DEFAULT_MPU6050_ADDRESS,
    this._dlpfCfg = DEFAULT_DLPF_CFG,
    this._smplrtDiv = DEFAULT_SMPLRT_DIV,
  ])  : isRunningIsolate = false,
        i2cBus = i2c.busNum {
    // 1. waking up the MPU6050 (0x00 = 0000 0000) as it starts in sleep mode.
    i2c.writeByteReg(i2cAddress, MPU6050_REG_ADDR_PWR_MGMT_1, 0x00);

    // 2. sample rate divider
    // The sensor register output, FIFO output, and DMP sampling are all based on the Sample Rate.
    // The Sample Rate is generated by dividing the gyroscope output rate by SMPLRT_DIV:
    //      Sample Rate = Gyroscope Output Rate / (1 + SMPLRT_DIV)
    // where Gyroscope Output Rate = 8kHz when the DLPF is disabled (DLPF_CFG = 0 or 7),
    // and 1kHz when the DLPF is enabled (see register 26).
    // SMPLRT_DIV set the rate to the default value : Sample Rate = Gyroscope Rate.
    i2c.writeByteReg(i2cAddress, MPU6050_REG_ADDR_SMPRT_DIV, _smplrtDiv);

    // 3. This register configures the external Frame Synchronization (FSYNC)
    // pin sampling and the Digital Low Pass Filter (DLPF) setting for both
    // the gyroscopes and accelerometers.
    setDLPFConfig(_dlpfCfg);

    // 4. Gyroscope configuration
    // FS_SEL selects the full scale range of the gyroscope outputs.
    var fsSel = 0 << 3; // FS_SEL +- 250 °/s
    _gyroLSBSensitivity = 131; // cfr [datasheet 2 - p.31]
    i2c.writeByteReg(i2cAddress, MPU6050_REG_ADDR_GYRO_CONFIG, fsSel);

    // 5. Accelerometer configuration [datasheet 2 - p.29]
    var afsSel =
        0; // AFS_SEL full scale range: ± 2g. LSB sensitivity : 16384 LSB/g
    _accelLSBSensitivity = 16384; // LSB Sensitivity corresponding to AFS_SEL 0
    i2c.writeByteReg(i2cAddress, MPU6050_REG_ADDR_ACCEL_CONFIG, afsSel);

    // 6. Disable interrupts
    i2c.writeByteReg(i2cAddress, MPU6050_REG_ADDR_INT_ENABLE, 0x00);

    // 7. Disable standby mode
    i2c.writeByteReg(i2cAddress, MPU6050_REG_ADDR_PWR_MGMT_2, 0x00);

    _calibrateSensors();
  }

  /// Returns the Sample Rate of the MPU6050 in Hz.
  ///
  /// The Sample Rate is generated by dividing the gyroscope output rate
  /// by SMPLRT_DIV:
  ///              Sample Rate = Gyroscope Output Rate / (1 + SMPLRT_DIV)
  /// where Gyroscope Output Rate = 8kHz when the DLPF is disabled (DLPF_CFG = 0 or 7),
  /// and 1kHz when the DLPF is enabled.
  ///
  /// Note: The accelerometer output rate is 1kHz (accelerometer and not gyroscope !).
  /// This means that for a Sample Rate greater than 1kHz, the same accelerometer
  /// sample may be output to the FIFO, DMP, and sensor registers more than once.
  ///
  int getSampleRate() {
    var gyroscopeOutputRate =
        (_dlpfCfg == DLPF.FILTER0 || _dlpfCfg == DLPF.FILTER7)
            ? 8000
            : 1000; // 8kHz if DLPG disabled, and 1kHz if enabled.
    return gyroscopeOutputRate ~/ (1 + _smplrtDiv);
  }

  /// Sets the Digital Low Pass Filter (DLPF).
  void setDLPFConfig(DLPF filter) {
    _dlpfCfg = filter;
    i2c.writeByteReg(i2cAddress, MPU6050_REG_ADDR_CONFIG, _dlpfCfg.index);
  }

  /// Returns the Digital Low Pass Filter (DLPF).
  DLPF getDLPFConfig() {
    return _dlpfCfg;
  }

  // Callibrates the accelerometer and gyroscope sensors.
  void _calibrateSensors() {
    var nbReadings = 50;

    // Gyroscope offsets
    _gyroAngularSpeedOffsetX = 0;
    _gyroAngularSpeedOffsetY = 0;
    _gyroAngularSpeedOffsetZ = 0;
    for (var i = 0; i < nbReadings; i++) {
      var angularSpeeds = readScaledGyroscopeValues();
      _gyroAngularSpeedOffsetX += angularSpeeds[0];
      _gyroAngularSpeedOffsetY += angularSpeeds[1];
      _gyroAngularSpeedOffsetZ += angularSpeeds[2];
      sleep(Duration(milliseconds: 100));
    }
    _gyroAngularSpeedOffsetX /= nbReadings;
    _gyroAngularSpeedOffsetY /= nbReadings;
    _gyroAngularSpeedOffsetZ /= nbReadings;
  }

  // Reads the most recent gyroscope values on the MPU6050 for X, Y and Z axis,
  // and calculates the corresponding angular speeds in degrees/sec,
  // according to the selected FS_SEL mode.
  List<double> readScaledGyroscopeValues() {
    var array = <double>[];
    array.add(readWord2C(MPU6050_REG_ADDR_GYRO_XOUT_H) / _gyroLSBSensitivity);
    array.add(readWord2C(MPU6050_REG_ADDR_GYRO_YOUT_H) / _gyroLSBSensitivity);
    array.add(readWord2C(MPU6050_REG_ADDR_GYRO_ZOUT_H) / _gyroLSBSensitivity);
    return array;
  }

  int readWord2C(int registerAddress) {
    var value = i2c.readByteReg(i2cAddress, registerAddress) & 0xff;
    value = value << 8;
    value += i2c.readByteReg(i2cAddress, (registerAddress + 1)) & 0xff;

    if (value >= 0x8000) value = -(65536 - value);
    return value;
  }

  // Gets the distance between two points.
  double _distance(double a, double b) {
    return sqrt(a * a + b * b);
  }

  double _getAccelXAngle(double x, double y, double z) {
    // v1 - 360
    var radians = atan2(y, _distance(x, z));
    var delta = 0;
    if (y >= 0) {
      if (z >= 0) {
        // pass
      } else {
        radians *= -1;
        delta = 180;
      }
    } else {
      if (z <= 0) {
        radians *= -1;
        delta = 180;
      } else {
        delta = 360;
      }
    }
    return radians * RADIAN_TO_DEGREE + delta;
  }

  double _getAccelYAngle(double x, double y, double z) {
    // v2
    var tan = -1 * x / _distance(y, z);
    var delta = 0;
    if (x <= 0) {
      if (z >= 0) {
        // q1
        // nothing to do
      } else {
        // q2
        tan *= -1;
        delta = 180;
      }
    } else {
      if (z <= 0) {
        // q3
        tan *= -1;
        delta = 180;
      } else {
        // q4
        delta = 360;
      }
    }
    return atan(tan) * RADIAN_TO_DEGREE + delta;
  }

  double _getAccelZAngle() {
    return ACCEL_Z_ANGLE;
  }

  // Reads the most recent accelerometer values on MPU6050 for X, Y and Z axis,
  // and calculates the corresponding accelerations in g, according to the
  // selected AFS_SEL mode.
  List<double> readScaledAccelerometerValues() {
    var array = <double>[];
    array.add(readWord2C(MPU6050_REG_ADDR_ACCEL_XOUT_H) / _accelLSBSensitivity);
    array.add(readWord2C(MPU6050_REG_ADDR_ACCEL_YOUT_H) / _accelLSBSensitivity);
    array
        .add(readWord2C(MPU6050_REG_ADDR_ACCEL_ZOUT_H) / -_accelLSBSensitivity);
    return array;
  }

  /// This method should be called repeatedly with a high frequency to get accurate values.
  void updateValues() {
    if (_lastUpdateTime == 0) {
      _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
    }
    // Accelerometer
    var accelerations = readScaledAccelerometerValues();
    _accelAccelerationX = accelerations[0];
    _accelAccelerationY = accelerations[1];
    _accelAccelerationZ = accelerations[2];

    _accelAngleX = _getAccelXAngle(
        _accelAccelerationX, _accelAccelerationY, _accelAccelerationZ);
    _accelAngleY = _getAccelYAngle(
        _accelAccelerationX, _accelAccelerationY, _accelAccelerationZ);
    _accelAngleZ = _getAccelZAngle();

    // Gyroscope
    var angularSpeeds = readScaledGyroscopeValues();
    _gyroAngularSpeedX = angularSpeeds[0] - _gyroAngularSpeedOffsetX;
    _gyroAngularSpeedY = angularSpeeds[1] - _gyroAngularSpeedOffsetY;
    _gyroAngularSpeedZ = angularSpeeds[2] - _gyroAngularSpeedOffsetZ;
    // angular speed * time = angle
    var dt = (DateTime.now().millisecondsSinceEpoch - _lastUpdateTime).abs() /
        1000.0; // s
    var deltaGyroAngleX = _gyroAngularSpeedX * dt;
    var deltaGyroAngleY = _gyroAngularSpeedY * dt;
    var deltaGyroAngleZ = _gyroAngularSpeedZ * dt;

    _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

    _gyroAngleX += deltaGyroAngleX;
    _gyroAngleY += deltaGyroAngleY;
    _gyroAngleZ += deltaGyroAngleZ;

    // Complementary Filter
    var alpha = 0.96;
    _filteredAngleX = alpha * (_filteredAngleX + deltaGyroAngleX) +
        (1.0 - alpha) * _accelAngleX;
    _filteredAngleY = alpha * (_filteredAngleY + deltaGyroAngleY) +
        (1.0 - alpha) * _accelAngleY;
    _filteredAngleZ = _filteredAngleZ + deltaGyroAngleZ;
  }

  /// Gets the last acceleration values, in g, retrieved from the accelerometer,
  /// for the x, y and z axis. Call [updateValues] repeatedly with a high frequency
  /// to get accurate values.
  List<double> getAccelAccelerations() {
    return [_accelAccelerationX, _accelAccelerationY, _accelAccelerationZ];
  }

  /// Gets the last angle values, in °, retrieved from the accelerometer,
  /// for the x, y and z axis. Call [updateValues] repeatedly with a high frequency
  /// to get accurate values.
  List<double> getAccelAngles() {
    return [_accelAngleX, _accelAngleY, _accelAngleZ];
  }

  /// Gets the last angular speed values, in °/sec, retrieved from the gyroscope,
  /// for the x, y and z axis. Call [updateValues] repeatedly with a high frequency
  /// to get accurate values.
  List<double> getGyroAngularSpeeds() {
    return [_gyroAngularSpeedX, _gyroAngularSpeedY, _gyroAngularSpeedZ];
  }

  /// Gets the last angles values, in °, retrieved from the gyroscope,
  /// for the x, y and z axis. Call [updateValues] repeatedly with a high frequency
  /// to get accurate values.
  List<double> getGyroAngles() {
    // _isTimerRunning();
    return [_gyroAngleX, _gyroAngleY, _gyroAngleZ];
  }

  // Returns the calculated offsets for the angular speeds from the gyroscope,
  // for the x, y and z axis. Call [updateValues] repeatedly with a high frequency
  /// to get accurate values.
  List<double> getGyroAngularSpeedsOffsets() {
    return [
      _gyroAngularSpeedOffsetX,
      _gyroAngularSpeedOffsetY,
      _gyroAngularSpeedOffsetZ
    ];
  }

  /// Last angle value, in °, calculated from the accelerometer and the gyroscope,
  /// for the x, y and z axis.  Call [updateValues] repeatedly with a high frequency
  /// to get accurate values.
  List<double> getFilteredAngles() {
    return [_filteredAngleX, _filteredAngleY, _filteredAngleZ];
  }
}
