// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

///  Interface for pass device info as JSON to an isolate.
abstract class IsolateAPI {
  String toJson();
  IsolateAPI fromJson(String json);
  int getHandle();
  void setHandle(int handle);
  bool isIsolate();
}
