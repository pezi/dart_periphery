// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

class SerialIsolateExample {
  @InitJob()
  static InitJobResult initJob() {
    var data = <String, dynamic>{};
    try {
      var s = Serial('/dev/serial0', Baudrate.b9600);
      // Return firmware version and sensor serial number - two lines
      s.writeString('Y\r\n');
      var event = s.read(256, 1000);
      data['serial'] = event.toString();

      // Request temperature, humidity and CO2 level.
      s.writeString('M 4164\r\n');
      // Select polling mode
      s.writeString('K 2\r\n');
      // consume any response
      event = s.read(256, 1000);

      return InitJobResult(false, s.toJson(), data);
    } catch (e, s) {
      data['exception'] = e.toString();
      data['stacktrace'] = s.toString();
      return InitJobResult(true, '', data);
    }
  }

  @MainJob()
  static MainJobResult mainJob(String json) {
    var data = <String, dynamic>{};
    try {
      var s = Serial.isolate(json);
      s.writeString('Q\r\n');
      var event = s.read(256, 1000);
      data['result'] = event.toString();
      sleep(Duration(seconds: 5));
      // indicate no error, continue main loop, pass user data
      return MainJobResult(false, false, data);
    } catch (e, s) {
      data['exception'] = e.toString();
      data['stacktrace'] = s.toString();
      // indicate an error and terminate main loop
      return MainJobResult(true, true, data);
    }
  }

  @ExitJob()
  static ExitJobResult exitJob(String json) {
    var s = Serial.isolate(json);
    s.dispose();
    var m = <String, dynamic>{};
    return ExitJobResult(false, m);
  }
}

///
/// [COZIR CO2 Sensor](https://co2meters.com/Documentation/Manuals/Manual_GC_0024_0025_0026_Revised8.pdf)
///
void main() async {
  SerialIsolateExample c = SerialIsolateExample();
  IsolateHelper h = IsolateHelper(c, JobIteration(3));
  await for (var s in h.run()) {
    if (s is InitJobResult) {
      print('Init job');
      if (s.error) {
        print('An error occured');
        print("Excpetion: ${s.data!['exception']}");
        print("Stacktrace: ${s.data!['stacktrace']}");
      } else {
        print("Serial number: ${s.data!['serial']}");
      }
    } else if (s is MainJobResult) {
      print('Main job');
      if (s.error) {
        print('An error occured');
        print("Excpetion: ${s.data!['exception']}");
        print("Stacktrace: ${s.data!['stacktrace']}");
      } else {
        print(s.data!['result']);
      }
    }
  }
}
