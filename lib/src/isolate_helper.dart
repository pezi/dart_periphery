import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';

import 'isolate_test.dart';

/// Construct a class by name
class ClassFactory {
  static final Map<String, IsolateWrapper Function()> _constructors = {
    'SomeClass': () => SomeClass(),
  };

  static IsolateWrapper createInstance(String className) {
    var constructor = _constructors[className];
    if (constructor != null) {
      return constructor();
    } else {
      throw Exception("Class not found: $className");
    }
  }
}

/// generic task result
abstract class TaskResult {
  bool error;
  Map<String, dynamic>? data;
  TaskResult(this.error, [this.data]);
}

/// Result of the init task
class InitTaskResult extends TaskResult {
  String json;

  /// Return value of the init task, [error] signals an error, [json] represents the device configuration and the optional user [data].
  InitTaskResult(bool error, this.json, [Map<String, dynamic>? data])
      : super(error, data);
}

/// Result of the main task method
class MainTaskResult extends TaskResult {
  bool exit;

  /// Return value of a main task, [error] signals an error, [exit] to quit the main loop and the optional user [data].
  MainTaskResult(bool error, this.exit, [Map<String, dynamic>? data])
      : super(error, data);
}

/// Result of the exit task method
class ExitTaskResult extends TaskResult {
  /// Return value of the exit task, [error] signals an error and the optional user [data].
  ExitTaskResult(bool error, [Map<String, dynamic>? data]) : super(error, data);
}

/// Number of iterations invoking the main sub task.
class TaskIteration {
  int iterations;

  /// Number of [iterations], value < 0 sets an infinite loop.
  TaskIteration(this.iterations);
  TaskIteration.infinite() : iterations = -1;
}

/// Sub tasks
enum TaskMethod { init, main, exit }

abstract class IsolateWrapper {
  IsolateWrapper();
  InitTaskResult init();
  MainTaskResult main(String json);
  ExitTaskResult exit(String json);
  void processData(Object data);
}

/// Run an [IsolateWrapper] based class as an isolate
class IsolateHelper {
  IsolateWrapper className;
  TaskIteration iterationTask;

  Isolate? isolate;
  String? json;
  ReceivePort? receivePort;
  SendPort? sendPort;

  IsolateHelper(this.className, this.iterationTask);

  /// Kills a running isolate.
  void killIsolate() {
    receivePort!.close();
    isolate!.kill(priority: Isolate.immediate);
  }

  // Start
  Stream<TaskResult> run() async* {
    receivePort = ReceivePort();
    isolate = await Isolate.spawn<SendPort>(_isolate, receivePort!.sendPort);

    final events = StreamQueue<dynamic>(receivePort!);

    // send class info and counter as map
    sendPort = await events.next;
    var classInfo = <String, String>{};

    classInfo['counter'] = iterationTask.iterations.toString();
    classInfo['className'] = className.runtimeType.toString();
    sendPort?.send(classInfo);

    // wait for init map response
    var initMap = await events.next;
    json = initMap['_json'];

    // send init data
    yield InitTaskResult(
        initMap['_error'] as bool, initMap['_json'] as String, initMap);

    // if no error occurs, start looping
    if (!(initMap['_error'] as bool)) {
      var loop = true;

      while (loop) {
        var result = await events.next;
        if (result['_task'] == TaskMethod.exit) {
          yield ExitTaskResult(initMap['_error'] as bool, result);
          loop = false;
        } else {
          yield MainTaskResult(
              result['_error'] as bool, result['_exit'] as bool, result);
        }
      }
    }

    sendPort?.send(null);
    await events.cancel();
  }

  /// Starts the isolate servicing the [IsolateWrapper] API: init, main, exit
  /// Hint: according documentation this method must be static
  static Future<void> _isolate(SendPort sendPort) async {
    final commandPort = ReceivePort();
    sendPort.send(commandPort.sendPort);
    var classInfo = <String, String>{};

    late IsolateWrapper clazz;

    bool mainLoopRunning = false;

    commandPort.listen((message) async {
      if (mainLoopRunning) {
        clazz.processData(message);
        return;
      }

      mainLoopRunning = true;

      classInfo = message;
      clazz = ClassFactory.createInstance(classInfo['className']!);
      // init task
      var initResult = clazz.init();
      var initMap = initResult.data;
      initMap = initMap ?? <String, dynamic>{};
      initMap['_task'] = TaskMethod.init;
      initMap['_error'] = initResult.error;
      initMap['_json'] = initResult.json;
      sendPort.send(initMap);
      if (initResult.error) {
        commandPort.close();
        Isolate.exit();
      }

      // loop main task
      int counter = int.parse(classInfo['counter'] as String);
      bool infinite = false;
      if (counter <= 0) {
        infinite = true;
      }
      int index = 0;
      while (true) {
        if (!infinite) {
          if (index == counter) {
            break;
          }
        }

        var mainResult = clazz.main(initResult.json);
        var mainMap = mainResult.data;
        mainMap = mainMap ?? <String, dynamic>{};
        mainMap['_task'] = TaskMethod.main;
        mainMap['_error'] = mainResult.error;
        mainMap['_exit'] = mainResult.exit;
        sendPort.send(mainMap);
        if (mainResult.exit) {
          break;
        }
        // https://stackoverflow.com/questions/61127575/how-to-compare-the-type-variable-in-is-operator-in-dart
        // this line does the trick to enable the listener to receive the next event!
        await Future.delayed(Duration.zero);
        ++index;
      }

      // exit task - if the main loop is finite
      var exitResult = clazz.exit(initResult.json);
      var exitMap = exitResult.data;
      exitMap = exitMap ?? <String, dynamic>{};

      exitMap['_task'] = TaskMethod.exit;
      exitMap['_error'] = exitResult.error;
      sendPort.send(exitMap);
      Isolate.exit();
    });
  }
}
