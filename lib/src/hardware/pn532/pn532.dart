import 'package:collection/collection.dart';

import 'package:dart_periphery/src/hardware/pn532/base_protocol.dart';

import 'package:dart_periphery/src/hardware/pn532/constants.dart';
import 'package:dart_periphery/src/hardware/pn532/exceptions.dart';
import 'package:dart_periphery/src/hardware/utils/uint8.dart';

typedef ListCompare = bool Function(List<dynamic>, List<dynamic>);



class PN532 {
  final ListCompare _listCompare = const ListEquality().equals;

  final PN532BaseProtocol pn532ProtocolImpl;
  
  PN532({required this.pn532ProtocolImpl});

  void dispose() {
    pn532ProtocolImpl.dispose();
  }

  /// Checks the firmware version of the PN532 chip
  /// and returns the chip's firmware version as an int
  int getFirmwareVersion({int timeout=pn532StandardTimeout}) {
    List<int> response = callPN532Function(
      pn532CommandGetFirmwareVersion, 
      responseLength: 4,
      timeout: timeout,
    );

    // calculate the actual firmware version/id
    int firmwareVersion;
    firmwareVersion = response[0];
    firmwareVersion <<= 8;
    firmwareVersion |= response[1];
    firmwareVersion <<= 8;
    firmwareVersion |= response[2];
    firmwareVersion <<= 8;
    firmwareVersion |= response[3];

    return firmwareVersion;
  }

  /// Before you read MiFare-Cards you should call the `setSamConfiguration`
  /// function to configure the PN532 properly!
  List<int> getPassivTargetId({int cardBaudrate=pn532MifareIso14443A, int timeout=pn532StandardTimeout}) {
    // Send passive read command for 1 card.  Expect at most a 7 byte UUID.
    List<int> parameters = [0x01, cardBaudrate];
    List<int> response = callPN532Function(
      pn532CommandInListPassiveTarget, 
      parameters: parameters,
      responseLength: 19, 
      timeout: timeout
    );

    // Check only 1 card with up to a 7 byte UID is present.
    final int numberOfTagsFound = response[0];
    if (numberOfTagsFound != 1) {
        throw PN532MoreThenOneTagsFoundException();
    }

    final int lengthOfUid = response[5];
    if (lengthOfUid > 7) {
      throw PN532BadResponseException(
        response: response,
        additionalInformation: "Found card with unexpectedly long UID!",
      );
    }

    List<int> uid = response.sublist(6, 6 + lengthOfUid);
    return uid;
  }

  /// Send SAM configuration command with configuration for:
  /// `mode` is default = 1, normal mode
  /// `timeout` is default = 20, timeout 50ms * 20 = 1 second (PN532 timeout calculation)
  /// `irqPin` is default = 1, use IRQ pin if possible (not listened to in this driver)
  void setSamConfiguration({int mode = 1, int timeout = 20, int irqPin = 1}) {
    // Note that no other verification is necessary as call_function will
    // check the command was executed as expected.
    List<int> parameters = [Uint8(mode).value, Uint8(timeout).value, Uint8(irqPin).value];
    callPN532Function(pn532CommandSamConfiguration, parameters: parameters);
  }


  /// Send the `command` and given `parameters` to the PN532 
  /// and only wait `timeout` ms for the PN532  to say it's ready.
  /// 
  /// Also a `responseLength` can be given which reads the length from the PN532
  /// and return the response as an `List<int>`
  /// 
  /// Can throw todo
  List<int> callPN532Function(int command, {List<int> parameters=const [], int responseLength=0, int timeout=pn532StandardTimeout}) {
    final List<int> commandList = [pn532HostToPn532, command, ...parameters];
    
    // write the command to the board
    try {
      writeCommand(commandList);
    } catch (e) {
      pn532ProtocolImpl.wakeUp();
      rethrow;
    }
    

    // Wait for chip to say its ready!
    pn532ProtocolImpl.waitReady(timeout: timeout);

    // read acknowledgement
    _readAck();

    // wait for a response or return if no response is excpected
    if (responseLength == 0) {
      return [];
    } 

    // wait for the response
    pn532ProtocolImpl.waitReady(timeout: timeout);

    final List<int> response = readResponse(responseLength + 2);

    // verify the response
    if (response[0] != pn532Pn532ToHost) {
      throw PN532NotToHostResponse();
    } else if (response[1] != command + 1) {
      throw PN532WrongResponseException(
        command: command,
        response: response
      );
    }

    // return the response without the pre verification bytes
    return response.sublist(2);
  }


  /// Read the Ack flag of the PN532
  /// Can throw `PN532WrongAckException` when the read 
  /// Ack flag was not `pn532Ack`
  void _readAck() {
    const int ackBuffLen = 6;
    final List<int> response = pn532ProtocolImpl.readData(ackBuffLen);
    
    if (!_listCompare(response, pn532Ack)) {
      throw PN532WrongAckException(ackResponse: response);
    }
  }


  void writeCommand(List<int> commands) {
    Uint8 commandLength = Uint8(commands.length);
    List<int> finalCommandsList = [];
    Uint8 checksum = Uint8.zero();

    // Adding all the neccessary padding commands and add some of them to the 
    // checksum (I actually don't really know why some of same aren't taken
    // into account when we calculate the checksum)
    finalCommandsList.add(pn532Preamble);
    checksum += Uint8(pn532Preamble);
    finalCommandsList.add(pn532StartCode1);
    checksum += Uint8(pn532StartCode1);
    finalCommandsList.add(pn532StartCode2);
    checksum += Uint8(pn532StartCode2);

    finalCommandsList.add(commandLength.value);
    finalCommandsList.add((~commandLength + Uint8(1)).value);

    // adding the actual commands to the final list 
    //and calculate checksum with it
    for (int command in commands) { 
      finalCommandsList.add(command);
      checksum += Uint8(command);
    }

    finalCommandsList.add((~checksum).value);
    finalCommandsList.add(pn532Postamble);

    // sending the commands
    pn532ProtocolImpl.writeData(finalCommandsList);
  }


  List<int> readResponse(int length) {
    // Read a data frame with the expected data length
    final List<int> rawResponse = pn532ProtocolImpl.readData(length + 7);

    // remove trailing 0x00 bytes before the 0xff
    int offset;
    
    try {
      offset = rawResponse.indexOf(0xff);
    } on StateError {
      throw PN532BadResponseException(
        response: rawResponse,
        additionalInformation: "Preamble doesn't contain 0xff."
      );
    }

    // step on index after the preamble
    offset++;

    if (offset >= rawResponse.length) {
      throw PN532BadResponseException(
        response: rawResponse,
        additionalInformation: "Response doesn't contain any data"
      );
    }

    // frame length (response[offset]) and length checksum should match
    final int frameLength = rawResponse[offset];
    if (Uint8(frameLength + rawResponse[offset + 1]).value != 0) {
      throw PN532BadResponseException(
        response: rawResponse,
        additionalInformation: "The frame length and frame length checksum don't macht."
      );
    }

    // new offset without the length and length checksum
    offset += 2;

    // get actual response data and check the checksum of it
    final List<int> response = rawResponse.sublist(offset, offset + frameLength + 1);

    Uint8 checksum = Uint8(response.reduce((el1, el2) => el1 + el2));
    if (checksum != Uint8.zero()) {
      throw PN532BadResponseException(
        response: response,
        additionalInformation: "Calculated checksum doesn't match checksum."
      );
    }

    return response;
  }
}