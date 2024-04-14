import 'dart:async';
import 'dart:io';

import 'dummy.dart';
import 'isolate_helper.dart';

class SomeClass extends IsolateWrapper {
  int counter = 0;
  late DummyDev dev;
  @override
  InitTaskResult init() {
    dev = DummyDev();
    return InitTaskResult(false, dev.toJson());
  }

  @override
  MainTaskResult main(String json) {
    try {
      print("*main job");
      var m = <String, dynamic>{};
      m['result'] = '$counter';
      print("pass $counter");
      if (counter != 0) {
        sleep(Duration(seconds: 1));
      }
      ++counter;
      return MainTaskResult(false, false, m);
    } catch (e) {
      // No specified type, handles all
      print('Something really unknown: $e');
      return MainTaskResult(false, false, null);
    }
  }

  @override
  ExitTaskResult exit(String json) {
    dev.dispose();
    var m = <String, dynamic>{};
    return ExitTaskResult(false, m);
  }

  @override
  void processData(Object data) {
    print('*$data*');
  }
}

void main() async {
  print("start");
  IsolateHelper h = IsolateHelper(SomeClass(), TaskIteration.infinite());

  /*
  await for (var s in h.run()) {
    if (s is MainTaskResult) {
      print(s.data!['result']);
    }
  }
  */
  // https://dart.dev/articles/libraries/creating-streams
  // https://blog.stackademic.com/demystifying-streams-in-flutter-a-beginners-guide-593cde00cd5e
  Stream<TaskResult> tr = h.run();
  StreamSubscription<TaskResult> subscription = tr.listen(
    (task) {
      if (task is InitTaskResult) {
      } else {
        print('Received number: ${task.data!['result']}');
        h.sendPort?.send("test");
      }
    },
    onDone: () {
      print('Stream is done.');
    },
    onError: (error) {
      print('Error occurred: $error');
    },
  );
}
