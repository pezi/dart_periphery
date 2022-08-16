// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:stack_trace/stack_trace.dart';

void pressKey() {
  stdin.readLineSync();
}

bool pressKeyYes() {
  return stdin.readLineSync().toString().toLowerCase().startsWith('y');
}

void main(List<String> args) {
  passert(true);
}

void passert(bool b) {
  if (!b) {
    throw AssertionError();
  }
  var frame = Frame.caller(1);
  print('[OK] file: ${frame.uri.path} line: ${frame.line}');
}
