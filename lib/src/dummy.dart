// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/src/isolate_helper.dart';
import 'dart:ffi';

class DummyDev implements IsolateAPI {
  Pointer<Void> _dummyHandler;

  DummyDev() : _dummyHandler = Pointer.fromAddress(42);

  @override
  IsolateAPI fromJson(String json) {
    return DummyDev();
  }

  @override
  int getHandle() {
    return _dummyHandler.address;
  }

  @override
  void setHandle(int handle) {
    _dummyHandler = Pointer<Void>.fromAddress(handle);
  }

  @override
  String toJson() {
    return "Dummy Dev";
  }
}
