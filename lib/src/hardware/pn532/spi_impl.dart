import 'dart:io';

import 'package:dart_periphery/dart_periphery.dart';

import 'package:dart_periphery/src/hardware/pn532/base_protocol.dart';
import 'package:dart_periphery/src/hardware/pn532/constants.dart';
import 'package:dart_periphery/src/hardware/utils/uint.dart';

class PN532SpiImpl extends PN532BaseProtocol {
  final GPIO? chipSelectGpio;
  final SPI spi;

  List<int> pn532StatusList = [pn532SpiStartRead, 0x00];

  /// The `irqPin` and the `resetPin` are both optional!
  /// Actually the `irqPin` isn't used at all and the `resetPin` doesn't seem
  /// to work (at least at my board - I always have to power it off once it hangs).
  ///
  /// The `spiBus` and `spiChip` corresponds to /dev/spidev`[spiBus]`.`[spiChip]`.
  ///
  /// The connection are the following:
  /// The `SCK/SCLK` of PN532 must be connected to `SCK/SCLK` of the Pi.
  /// The `MOSI` of PN532 must be connected to `MOSI` of the Pi.
  /// The `MISO` of PN532 must be connected to `MISO` of the Pi.
  /// The `SS/NSS` of PN532 must be connected to `CE0` or the one specifed in `chipSelectPin`.
  /// OPTIONAL: The `IRQ` of PN532 should be connected to a `GPIO` pin of your choice (default: 16) of the Pi.
  /// OPTIONAL: The `RSTO` of PN532 should be connected to a `GPIO` pin of your choice (default: 12) of the Pi.
  /// For the `IRQ`, `RSTO` and `chipSelectPin` pin you can choose any
  /// GPIO pin of the pi just be aware that it seems like that the used dart
  /// package `dart_periphery` can't open all GPIOs
  /// (like in my test GPIO09) - then just use a different one.
  ///
  /// Also be sure that the `irqPin` is properly connected since the interrupt
  /// works the way that the `irqPin` uses low to activate - means that if it
  /// isn't properly connect the driver doesn't wait for the PN532 to be ready
  /// for a response and you get kind of cryptic responses like
  /// `PN532BadResponseException` just because of the wrongly connected `irqPin`.
  PN532SpiImpl({
    int? resetPin,
    int? irqPin,
    int? chipSelectPin,
    int spiBus = 0,
    int spiChip = 0,
  })  : chipSelectGpio = chipSelectPin == null
            ? null
            : GPIO(chipSelectPin, GPIOdirection.gpioDirIn),
        spi = SPI(spiBus, spiChip, SPImode.mode0, 500000),
        super(resetPin: resetPin, irqPin: irqPin) {
    reset();
    wakeUp();
  }

  List<int> reverseUint8List(List<int> list) {
    return list.map((integer) => Uint8(integer).reverseBytes().value).toList();
  }

  List<int> readWriteHelper(List<int> message) {
    // pull the chipSelect low to start communication
    if (chipSelectGpio != null) {
      chipSelectGpio!.write(false);
      sleep(const Duration(microseconds: 1));
    }

    // reverse bytes (since MSB and LSB differences)
    final List<int> reversedMessage = reverseUint8List(message);

    // transfer the message and read euqally big response
    final List<int> reversedResponse = spi.transfer(reversedMessage, false);

    // get the actual response data
    final List<int> response = reverseUint8List(reversedResponse);

    // pull the chipSelect high to stop communicaiton
    if (chipSelectGpio != null) {
      chipSelectGpio!.write(true);
      sleep(const Duration(microseconds: 1));
    }

    return response;
  }

  @override
  List<int> readData(int length) {
    // generate a list of length + 1 and the first element is
    // `pn532SpiDataRead` and the rest is filled with zeros
    final List<int> frame = [pn532SpiDataRead, ...List.filled(length, 0)];

    sleep(const Duration(milliseconds: 5));

    // transfer the list and read into it at the same time
    final List<int> response = readWriteHelper(frame);

    // get the response of the frame (without the added first byte) and return it
    return response.sublist(1);
  }

  @override
  bool isReady(int attemptCount) {
    if (attemptCount == 0) {
      pn532StatusList = [pn532SpiStartRead, 0x00];
    }

    pn532StatusList = readWriteHelper(pn532StatusList);

    return pn532StatusList[1] == pn532SpiReady;
  }

  @override
  void wakeUp() {
    // Send any special commands/data to wake up PN532

    if (chipSelectGpio != null) {
      sleep(const Duration(milliseconds: 1000));
      chipSelectGpio!.write(false);
      sleep(const Duration(milliseconds: 2)); // T_osc_start
    }

    List<int> data = [0x00];
    readWriteHelper(data);
    sleep(const Duration(milliseconds: 1000));
  }

  @override
  void writeData(List<int> data) {
    // generate a list of length + 1 and the first element is
    // `pn532SpiDataRead` and the rest is filled with zeros
    final List<int> frame = [pn532SpiDataWrite, ...data];
    readWriteHelper(frame);
  }

  @override
  void dispose() {
    super.dispose();
    chipSelectGpio?.dispose();
    spi.dispose();
  }
}
