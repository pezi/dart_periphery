// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Converted example: http://wiki.friendlyarm.com/wiki/index.php/BakeBit_-_Button

import 'package:dart_periphery/dart_periphery.dart';
import 'package:dart_periphery/src/hardware/extension_hat.dart';

const int buzzerPin = 3;
const int buttonPin = 4;

void main() {
  var hub = NanoHatHub();
  hub.pinMode(buzzerPin, PinMode.output);
  hub.pinMode(buttonPin, PinMode.input);
  while (true) {}
}
