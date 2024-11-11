import 'package:dart_periphery/dart_periphery.dart';

// PN532 is a highly integrated transceiver module for contactless communication
// at 13.56 MHz based on the 80C51 microcontroller core.
void main() {
  PN532BaseProtocol pn532Impl = PN532I2CImpl(irqPin: 16);
  PN532 pn532 = PN532(pn532ProtocolImpl: pn532Impl);

  print(pn532.getFirmwareVersion());
}
