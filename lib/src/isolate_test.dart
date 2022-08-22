// https://dart.dev/guides/language/concurrency
// https://dart.dev/guides/language/concurrency
// https://github.com/dart-lang/samples/blob/master/isolates/bin/long_running_isolate.dart
// https://stackoverflow.com/questions/42611880/difference-between-await-for-and-listen-in-dart
// https://www.geeksforgeeks.org/dart-extends-vs-with-vs-implements/

import 'dart:isolate';
import 'dart:async';
import 'package:async/async.dart';
import 'package:dart_periphery/dart_periphery.dart';
import 'package:dart_periphery/src/isolate_helper.dart';
import 'dart:io';
import 'dart:mirrors';

import 'dummy.dart';

void serialInit(Serial s) {
  // Return firmware version and sensor serial number - two lines
  s.writeString('Y\r\n');
  var event = s.read(256, 1000);
  print(event.toString());

  // Request temperature, humidity and CO2 level.
  s.writeString('M 4164\r\n');
  // Select polling mode
  s.writeString('K 2\r\n');
}

void serialExit(Serial s) {
  s.dispose();
}

String serialJob(Serial s) {
  s.writeString('Q\r\n');
  var event = s.read(256, 1000);
  String result = event.toString();
  sleep(Duration(seconds: 5));
  return result;
}

void dummyInit(DummyDev dd) {}

void dummyExit(DummyDev dd) {}

String dummyJob(DummyDev dd) {
  return "hello world";
}

void main() async {
//  var s = Serial('/dev/serial0', Baudrate.b9600);

  var d = DummyDev();
  IsolateContainer<DummyDev> ih =
      IsolateContainer(d, dummyInit, dummyJob, dummyExit, 3);

  await for (final data in ih.run()) {
    print("data from isolate: $data");
  }
}

Stream<String> _sendAndReceive(Serial serial) async* {
  final p = ReceivePort();
  await Isolate.spawn<SendPort>(_readAndParseJsonService, p.sendPort);

  // Convert the ReceivePort into a StreamQueue to receive messages from the
  // spawned isolate using a pull-based interface. Events are stored in this
  // queue until they are accessed by `events.next`.
  final events = StreamQueue<dynamic>(p);

  // The first message from the spawned isolate is a SendPort. This port is
  // used to communicate with the spawned isolate.
  SendPort sendPort = await events.next;

  sendPort.send(serial.toJson());
  int handle = await events.next;
  serial.setHandle(handle);

  while (true) {
    String data = await events.next;

    // Add the result to the stream returned by this async* function.
    yield data;
  }

  // Send a signal to the spawned isolate indicating that it should exit.
  sendPort.send(null);

  // Dispose the StreamQueue.
  await events.cancel();
}

Future<void> _readAndParseJsonService(SendPort p) async {
  print('Spawned isolate started.');

  // Send a SendPort to the main isolate so that it can send JSON strings to
  // this isolate.
  final commandPort = ReceivePort();
  p.send(commandPort.sendPort);

  // Wait for messages from the main isolate.
  String serialJSON = await commandPort.first;

  var s = Serial.isolate(serialJSON);

  p.send(s.getHandle());
  try {
    print('Serial interface info: ${s.getSerialInfo()}');

    // Return firmware version and sensor serial number - two lines
    s.writeString('Y\r\n');
    var event = s.read(256, 1000);
    print(event.toString());

    // Request temperature, humidity and CO2 level.
    s.writeString('M 4164\r\n');
    // Select polling mode
    s.writeString('K 2\r\n');
    // print any response
    event = s.read(256, 1000);
    print('Response ${event.toString()}');
    sleep(Duration(seconds: 1));
    while (true) {
      s.writeString('Q\r\n');
      event = s.read(256, 1000);
      String result = event.toString();
      print(result);
      p.send(result);
      sleep(Duration(seconds: 5));
    }
  } finally {
    s.dispose();
  }
}
