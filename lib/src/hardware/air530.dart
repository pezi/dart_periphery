// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Resources:
// https://github.com/DexterInd/GrovePi/blob/master/Software/Python/grove_gps/grove_gps_data.py/
// https://github.com/microsoft/IoT-For-Beginners/blob/main/3-transport/lessons/1-location-tracking/pi-gps-sensor.md
// https://simcom.ee/documents/SIM28/SIM28%40SIM68R%40SIM68V_NMEA%20Messages%20Specification_V1.00.pdf  - page 10


import 'package:dart_periphery/dart_periphery.dart';

const gpsData = '\$GPGGA';

// Global Positioning System Fixed Data
// GPGGA,091926.000,3113.3166,N,12121.2682,E,1,09,0.9,36.9,M,7.9,M,,0000*56<CR><LF

class GPS {
  bool _dataAvailable = false;
  GPS(String raw) {
    int pos = raw.lastIndexOf(gpsData);
    if (pos > 0) {
      var parts = raw.substring(pos + gpsData.length).split(',');
    }
  }

  bool hasData() {
    return _dataAvailable;
  }
}

// GPS Sensor
///
///
void main() {
  var s = Serial('/dev/serial0', Baudrate.b9600);
  try {
    var event = s.read(256, 1000);
  } finally {
    s.dispose();
  }
}
