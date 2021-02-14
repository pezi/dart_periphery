// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

void main() {
  var pwm = PWM(0, 0);
  try {
    print(pwm.getPWMinfo());
    pwm.setPeriodNs(10000000);
    pwm.setDutyCycleNs(8000000);
    print(pwm.getPeriodNs());
    pwm.enable();
    print('Wait 20 seconds');
    sleep(Duration(seconds: 20));
    pwm.disable();
  } finally {
    pwm.dispose();
  }
}
