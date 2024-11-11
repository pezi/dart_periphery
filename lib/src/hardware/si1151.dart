// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_periphery/src/hardware/utils/byte_buffer.dart';

import '../../dart_periphery.dart';

/// [SI1151] exception
class SI1151exception implements Exception {
  final String errorMsg;
  @override
  String toString() => errorMsg;

  SI1151exception(this.errorMsg);
}
