// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

class SomeClass {
  static int counter = 0;

  @InitJob()
  static InitJobResult initJob() {
    var dev = DummyDev();
    return InitJobResult(false, dev.toJson());
  }

  @MainJob()
  static MainJobResult mainJob(String json) {
    var dev = DummyDev.isolate(json);
    var m = <String, dynamic>{};
    m['result'] = '${dev.add(counter, counter)}';
    ++counter;
    return MainJobResult(false, false, m);
  }

  @ExitJob()
  static ExitJobResult exitJob(String json) {
    var dev = DummyDev.isolate(json);
    dev.dispose();
    var m = <String, dynamic>{};
    return ExitJobResult(false, m);
  }
}

void main() async {
  SomeClass c = SomeClass();
  IsolateHelper h = IsolateHelper(c, JobIteration(3));
  await for (var s in h.run()) {
    if (s is MainJobResult) {
      print(s.data!['result']);
    }
  }

  h = IsolateHelper(c, JobIteration.endless());
  int index = 0;
  await for (var s in h.run()) {
    if (s is MainJobResult) {
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
