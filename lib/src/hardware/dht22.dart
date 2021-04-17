// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/nebulx29/dht22/blob/master/dht22.c
// https://stackoverflow.com/questions/41120541/dht22-sensor-pi4j-java
// https://buyzero.de/blogs/news/tutorial-dht22-dht11-und-am2302-temperatursensor-feuchtigkeitsensor-am-raspberry-pi-anschliessen-und-ansteuern
//

// import '../gpio.dart';
import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

const int MAX_TIMINGS = 85;

/// [DHT22] measured data: temperature and humidity.
class DHT22result {
  final bool isValid;

  /// temperature °C
  final double temperature;

  /// relative humidity %
  final double humidity;

  DHT22result(this.temperature, this.humidity) : isValid = true;
  DHT22result.invalid()
      : temperature = -1,
        humidity = -1,
        isValid = false;

  @override
  String toString() =>
      'DHT22result [isValid=$isValid,temperature=$temperature, humidity=$humidity]';

  /// Returns a [DHT22result] as a JSON string. [fractionDigits] controls the number fraction digits.
  String toJSON([int fractionDigits = 2]) {
    return '{"temperature":"${temperature.toStringAsFixed(fractionDigits)}","humidity":"${humidity.toStringAsFixed(fractionDigits)}"';
  }
}

class DHT22 {
  int pin;
  GPIO gpio;

  DHT22(this.pin) : gpio = GPIO(pin, GPIOdirection.GPIO_DIR_OUT);

  DHT22result getValues() {
    var lastState = true;
    var dht22_dat = List<int>.filled(5, 0);
    var j = 0;
    gpio.setGPIOdirection(GPIOdirection.GPIO_DIR_OUT);
    gpio.write(false);
    sleep(Duration(milliseconds: 18));
    gpio.write(false);
    gpio.setGPIOdirection(GPIOdirection.GPIO_DIR_IN);
    for (var i = 0; i < MAX_TIMINGS; i++) {
      var counter = 0;
      while (gpio.read() == lastState) {
        counter++;
        sleep(Duration(microseconds: 1));
        if (counter == 255) {
          break;
        }
      }

      lastState = gpio.read();

      if (counter == 255) {
        break;
      }

      // ignore first 3 transitions
      if (i >= 4 && i % 2 == 0) {
        // shove each bit into the storage bytes
        dht22_dat[j >> 3] <<= 1;
        if (counter > 16) {
          dht22_dat[j >> 3] |= 1;
        }
        j++;
      }
    }
    if (j >= 40 && checkParity(dht22_dat)) {
      var humidity = ((dht22_dat[0] << 8) + dht22_dat[1]) / 10;

      if (humidity > 100) {
        humidity = dht22_dat[0].toDouble();
      }
      var temperature = (((dht22_dat[2] & 0x7F) << 8) + dht22_dat[3]) / 10;
      if (temperature > 125) {
        temperature = dht22_dat[2].toDouble(); // for DHT11
      }
      if (dht22_dat[2] & 0x80 != 0) {
        temperature = -temperature; // for DHT11
      }
      return DHT22result(temperature, humidity);
    }
    return DHT22result.invalid();
  }

  bool checkParity(List<int> dht22_dat) {
    return dht22_dat[4] ==
        (dht22_dat[0] + dht22_dat[1] + dht22_dat[2] + dht22_dat[3] & 0xFF);
  }
}

void main() {
  var dht22 = DHT22(3);
  for (var i = 0; i < 5; ++i) {
    print(dht22.getValues());
    sleep(Duration(seconds: 5));
  }
}
