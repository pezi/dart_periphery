// https://github.com/Chouffy/python_sensor_aht20/blob/main/AHT20.py
// https://github.com/adafruit/Adafruit_CircuitPython_AHTx0/blob/main/adafruit_ahtx0.py

/// Default I2C address of the [AHTX0] sensor
const int ahtx0DefaultI2Caddress = 0x38;

/// [AHTX0] commands
enum AHTX0command {
  aht10Calibrate(0xE1),
  aht20Calibrate(0xBE),
  triggerReading(0xAC),
  softReset(0xBA),
  statusBusy(0x80),
  statusCalibrated(0x08);

  final int command;
  const AHTX0command(this.command);
}

/// [AHTX0] exception
class AHTX0exception implements Exception {
  AHTX0exception(this.errorMsg);
  final String errorMsg;
  @override
  String toString() => errorMsg;
}

/// [AHTX0] measured data: temperature and humidity sensor.
class AHTX0result {
  /// temperature °C
  final double temperature;

  /// relative humidity %
  final double humidity;

  AHTX0result(this.temperature, this.humidity);

  /// Returns a [AHTX0result] as a JSON string. [fractionDigits] controls the number of fraction digits.
  String toJSON([int fractionDigits = 2]) {
    return '{"temperature":"${temperature.toStringAsFixed(fractionDigits)}","humidity":"${humidity.toStringAsFixed(fractionDigits)}"}';
  }
}
