import 'dart:io';

import 'package:dart_periphery/dart_periphery.dart';
import 'package:dart_periphery/src/hardware/pn532/constants.dart';

class PN532I2CImpl extends PN532BaseProtocol {
  final I2C i2c;
  final GPIO? hardwareRequestGPIO;

  /// The `busNumber` corresponds to the the `i2c-x` file. (With the `x` being
  /// the `busNumber`)
  ///
  /// The connections are the following:
  /// The `SDA` of PN532 must be connected to the `SDA` of the Pi.
  /// The `SCL` of PN532 must be connected to the `SCL` of the Pi.
  ///
  /// The `irqPin`, `resetPin` and `hardwareRequestPin` are all optional!
  /// OPTIONAL: The `IRQ` of PN532 should be connected to a `GPIO` pin of your choice (default: 16) of the Pi.
  /// OPTIONAL: The `RSTPDN` of PN532 should be connected to a `GPIO` pin of your choice (default: 12) of the Pi.
  /// OPTIONAL: The `PIN32` of PN532 should be connected to a `GPIO` pin of your choice of the Pi. (This is the `hardwareRequestPin`)
  /// For the `IRQ`, `RSTPDN` and `hardwareRequestPin` pin you can choose any
  /// GPIO pin of the pi just be aware that it seems like that the used dart
  /// package `dart_periphery` can't open all GPIOs
  /// (like in my test GPIO09) - then just use a different one.
  ///
  /// Also be sure that the `irqPin` is properly connected since the interrupt
  /// works the way that the `irqPin` uses low to activate - means that if it
  /// isn't properly connect the driver doesn't wait for the PN532 to be ready
  /// for a response and you get kind of cryptic responses like
  /// `PN532BadResponseException` just because of the wrongly connected `irqPin`.
  ///
  /// Also be aware that the `RSTPDN` pin is NOT the `RSTO` Pin!
  PN532I2CImpl({
    int busNumber = 1,
    int? resetPin,
    int? irqPin,
    int? hardwareRequestPin,
  })  : i2c = I2C(busNumber),
        hardwareRequestGPIO = hardwareRequestPin == null
            ? null
            : GPIO(hardwareRequestPin, GPIOdirection.gpioDirOut),
        super(resetPin: resetPin, irqPin: irqPin);

  @override
  List<int> readData(int length) {
    int readyByte = i2c.readByte(pn532I2CAddress);
    if (readyByte != pn532I2CReady) {
      throw PN532NotReadyException();
    }

    List<int> response = i2c.readBytes(pn532I2CAddress, length + 1);

    // convert the int to a uint8 to get the actual value
    // (negative values are actually the only problem here)
    response = response.map((integer) => Uint8(integer).value).toList();

    return response.getRange(1, response.length).toList();
  }

  @override
  void wakeUp() {
    hardwareRequestGPIO?.write(true);
    sleep(const Duration(milliseconds: 100));
    hardwareRequestGPIO?.write(false);
    sleep(const Duration(milliseconds: 100));
    hardwareRequestGPIO?.write(true);
    sleep(const Duration(milliseconds: 500));
  }

  @override
  void writeData(List<int> data) {
    i2c.writeBytes(pn532I2CAddress, data);
  }

  @override
  bool isReady(int attemptCount) {
    int ready = i2c.readByte(pn532I2CAddress);
    return ready == pn532I2CReady;
  }

  @override
  void dispose() {
    super.dispose();
    i2c.dispose();
  }
}
