import 'package:dart_periphery/src/hardware/pn532/constants.dart';

/// The abstract base class for all exceptions
abstract class PN532Exception implements Exception {
  final String information;

  PN532Exception({
    this.information = 'Something went wrong when communicating with the PN532.'
  });

  @override
  String toString() {
    return super.toString() + "\nAdditional info:\n$information";
  }
}


class PN532TimeoutExcepiton extends PN532Exception {
  final int timeout;

  PN532TimeoutExcepiton({
    required this.timeout,
    String? additionalInfo,
  }) : super(information: "When waiting ($timeout ms) for the PN532 didn't respond. ${additionalInfo ?? ''}");
}


class PN532WrongAckException extends PN532Exception {
  final List<int> ackResponse;

  PN532WrongAckException({
    required this.ackResponse,
  }) : super(information: "$ackResponse - the received ack response.\n$pn532Ack - the ack response should be");
}


class PN532WrongFirmwareException extends PN532Exception {
  final List<int> firmwareResponse;

  PN532WrongFirmwareException({
    required this.firmwareResponse,
  }) : super(information: "The first 6 bytes of the response should match:\n$firmwareResponse - the received firmware response.\n$pn532Ack - the firmware response should be");
}


class PN532MoreThenOneTagsFoundException extends PN532Exception {
  PN532MoreThenOneTagsFoundException() : super(information: "When reading the passiv target more than one UUID was found");
}


class PN532WrongResponseException extends PN532Exception {
  final int command;
  final List<int> response;

  PN532WrongResponseException({
    required this.command,
    required this.response,
  }) : super(information: "The received response: $response, doesn't match the called function $command");
}


class PN532BadResponseException extends PN532Exception {
  final List<int> response;

  PN532BadResponseException({
    required this.response,
    String? additionalInformation,
  }) : super(information: "The bad response was the following $response. ${additionalInformation ?? ''}");
}


class PN532NotToHostResponse extends PN532Exception {
  PN532NotToHostResponse() : super(information: "The response didn't have the $pn532Pn532ToHost flag set.");
}


class PN532NotReadyException extends PN532Exception {
  PN532NotReadyException() : super(information: "The first read byte didn't macht $pn532I2CReady");
}