// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

// https://github.com/vsergeev/c-periphery/blob/master/tests/test_pwm.c

void test() {
  try {
    /* Open non-existent PWM chip */
    PWM(9999, 0);
  } on PWMexception catch (e) {
    if (e.errorCode != PWMerrorCode.PWM_ERROR_OPEN) {}
  }
}
