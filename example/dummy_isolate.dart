// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

class SomeClass {
  static int counter = 0;

  @InitTask()
  static InitTaskResult initJob() {
    var dev = DummyDev();
    return InitTaskResult(false, dev.toJson());
  }

  @MainTask()
  static MainTaskResult mainJob(String json) {
    var dev = DummyDev.isolate(json);
    var m = <String, dynamic>{};
    m['result'] = '${dev.add(counter, counter)}';
    ++counter;
    return MainTaskResult(false, false, m);
  }

  @ExitTask()
  static ExitTaskResult exitJob(String json) {
    var dev = DummyDev.isolate(json);
    dev.dispose();
    var m = <String, dynamic>{};
    return ExitTaskResult(false, m);
  }
}

void main() async {
  SomeClass c = SomeClass();
  IsolateHelper h = IsolateHelper(c, TaskIteration(3));
  await for (var s in h.run()) {
    if (s is MainTaskResult) {
      print(s.data!['result']);
    }
  }

  h = IsolateHelper(c, TaskIteration.infinite());
  int index = 0;
  await for (var s in h.run()) {
    if (s is MainTaskResult) {
      print(s.data!['result']);
      if (index == 3) {
        break;
      }
      ++index;
    }
  }
  h.killIsolate();
  if (h.json != null) {
    var dev = DummyDev.isolate(h.json as String);
    dev.dispose();
  }
}
