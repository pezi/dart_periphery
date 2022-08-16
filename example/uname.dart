// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

// call linux uname() per dart:ffi
// https://man7.org/linux/man-pages/man2/uname.2.html
void main() {
  Uname uname = nativeUname();
  print('Release: ${uname.release}');
  print('Version: ${uname.version}');
  print('Node name: ${uname.nodename}');
  print('Machine: ${uname.machine}');
}
