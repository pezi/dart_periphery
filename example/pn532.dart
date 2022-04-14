import 'package:dart_periphery/dart_periphery.dart';

void main() {
  PN532BaseProtocol pn532Impl = PN532I2CImpl(irqPin: 16);
  PN532 pn532 = PN532(pn532ProtocolImpl: pn532Impl);

  print(pn532.getFirmwareVersion());
}
