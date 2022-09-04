import 'package:dart_periphery/src/isolate_helper.dart';

import 'dummy.dart';

class SomeClass {
  static int counter = 0;

  @InitJob()
  static InitJobResult initJob() {
    var dev = DummyDev();
    return InitJobResult(true, dev.toJson());
  }

  @MainJob()
  static MainJobResult mainJob(String json) {
    var dev = DummyDev.isolate(json);
    var m = <String, dynamic>{};
    m['result'] = '${counter++}';
    return MainJobResult(false, false, m);
  }

  @ExitJob()
  static ExitJobResult exitJob(String json) {
    var dev = DummyDev.isolate(json);
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
    var dummy = DummyDev.isolate(h.json as String);
    // close  handle
  }
}
