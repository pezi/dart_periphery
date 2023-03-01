import 'dart:isolate';
import 'dart:mirrors';
import 'dart:async';
import 'package:async/async.dart';

/// Annotation class for the init method
class InitTask {
  const InitTask();
}

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

/// Annotation for the main task
class MainTask {
  const MainTask();
}

/// Result of the main task method
class MainTaskResult extends TaskResult {
  bool exit;

  /// Return value of a main task, [error] signals an error, [exit] to quit the main loop and the optional user [data].
  MainTaskResult(bool error, this.exit, [Map<String, dynamic>? data])
      : super(error, data);
}

/// Annotation for the exit task
class ExitTask {
  const ExitTask();
}

/// Result of the exit task method
class ExitTaskResult extends TaskResult {
  /// Return value of the exit task, [error] signals an error and the optional user [data].
  ExitTaskResult(bool error, [Map<String, dynamic>? data]) : super(error, data);
}

/// Number of iterations invoking the main sub task.
class TaskIteration {
  int iterations;

  /// Number of [iterations], value <0 sets an infinite loop.
  TaskIteration(this.iterations);
  TaskIteration.infinite() : iterations = -1;
}

var _mirrorCache = <String, ClassMirror>{};

InstanceMirror _callStaticMethodOnClass(String className, String methodName,
    [String json = '']) {
  final classSymbol = Symbol(className);
  final methodSymbol = Symbol(methodName);

  var cm = _mirrorCache[className];
  if (cm == null) {
    cm = currentMirrorSystem().isolate.rootLibrary.declarations[classSymbol]
        as ClassMirror;
    _mirrorCache[className] = cm;
  }
  return cm.invoke(methodSymbol, json.isEmpty ? <dynamic>[] : <dynamic>[json]);
}

/// Enum which descibres the sub tasks
enum TaskMethod { init, main, exit }

final Symbol _initSym = Symbol((InitTaskResult).toString());
final Symbol _mainSym = Symbol((MainTaskResult).toString());
final Symbol _exitSym = Symbol((ExitTaskResult).toString());
final Symbol _strSym = Symbol((String).toString());

class IsolateHelper {
  Object clazz;
  TaskIteration iterationTask;
  late ClassMirror classMirror;
  Isolate? isolate;
  String? json;
  ReceivePort? receivePort;

  var mMap = <TaskMethod, String>{};

  IsolateHelper(this.clazz, this.iterationTask) {
    InstanceMirror im = reflect(clazz);
    classMirror = im.type;

    for (var v in classMirror.declarations.values) {
      var name = MirrorSystem.getName(v.simpleName);

      // check method signature
      if (v is MethodMirror) {
        for (var m in v.metadata) {
          if (m.reflectee is InitTask && v.isStatic) {
            if (v.parameters.isNotEmpty) {
              throw Exception(
                  '@InitTask annotated method has wrong parameter signature: InitTaskResult initTask()');
            }
            if (v.returnType.simpleName != _initSym) {
              throw Exception(
                  '@InitTask annotated method has wrong return type: InitTaskResult initTask()');
            }
            mMap[TaskMethod.init] = name;
          } else if (m.reflectee is MainTask && v.isStatic) {
            if (v.parameters.length != 1 ||
                v.parameters[0].type.simpleName != _strSym) {
              throw Exception(
                  '@MainTask annotated method has wrong parameter signature: MainTaskResult mainTask(String json)');
            }
            if (v.returnType.simpleName != _mainSym) {
              throw Exception(
                  '@MainTask annotated method has wrong return type: MainTaskResult mainTask()');
            }
            mMap[TaskMethod.main] = name;
          } else if (m.reflectee is ExitTask && v.isStatic) {
            if (v.parameters.length != 1 ||
                v.parameters[0].type.simpleName != _strSym) {
              throw Exception(
                  '@ExitTask annotated method has wrong paramter signature: ExitTaskResult exitTask(String json)');
            }
            if (v.returnType.simpleName != _exitSym) {
              throw Exception(
                  '@ExitTask annotated method has wrong return type: ExitTaskResult exitTask()');
            }
            mMap[TaskMethod.exit] = name;
          }
        }
      }
    }
    for (var m in TaskMethod.values) {
      if (!mMap.containsKey(m)) {
        throw Exception(
            "Missing static annotated method  @${m.name.split('.').last}Task inside class $im");
      }
    }
  }

  /// Kills a running isolate.
  void killIsolate() {
    receivePort!.close();
    isolate!.kill(priority: Isolate.immediate);
  }

  Stream<TaskResult> run() async* {
    receivePort = ReceivePort();
    isolate = await Isolate.spawn<SendPort>(_isolate, receivePort!.sendPort);

    final events = StreamQueue<dynamic>(receivePort!);

    // send class info and counter as map
    SendPort sendPort = await events.next;
    var classInfo = <String, String>{};
    classInfo['class'] = clazz.runtimeType.toString();
    for (var m in TaskMethod.values) {
      classInfo[m.name.split('.').last] = mMap[m] as String;
    }
    classInfo['counter'] = iterationTask.iterations.toString();
    sendPort.send(classInfo);

    // wait for init map response
    var initMap = await events.next;
    json = initMap['_json'];

    // send init data
    yield InitTaskResult(
        initMap['_error'] as bool, initMap['_json'] as String, initMap);

    // if no error occures, start looping
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

    sendPort.send(null);
    await events.cancel();
  }

  static Future<void> _isolate(SendPort sendPort) async {
    final commandPort = ReceivePort();
    sendPort.send(commandPort.sendPort);
    var classInfo = <String, String>{};
    classInfo = await commandPort.first;

    // init task
    InstanceMirror mr = _callStaticMethodOnClass(
        classInfo['class'] as String, classInfo['init'] as String);
    var initResult = mr.reflectee as InitTaskResult;
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
      InstanceMirror mr = _callStaticMethodOnClass(classInfo['class'] as String,
          classInfo['main'] as String, initResult.json);
      var mainResult = mr.reflectee as MainTaskResult;
      var mainMap = mainResult.data;
      mainMap = mainMap ?? <String, dynamic>{};
      mainMap['_task'] = TaskMethod.main;
      mainMap['_error'] = mainResult.error;
      mainMap['_exit'] = mainResult.exit;
      sendPort.send(mainMap);
      if (mainResult.exit) {
        break;
      }
      ++index;
    }

    // exit task
    mr = _callStaticMethodOnClass(classInfo['class'] as String,
        classInfo['exit'] as String, initResult.json);
    var exitResult = mr.reflectee as ExitTaskResult;
    var exitMap = exitResult.data;
    exitMap = exitMap ?? <String, dynamic>{};

    exitMap['_task'] = TaskMethod.exit;
    exitMap['_error'] = exitResult.error;
    sendPort.send(exitMap);
    Isolate.exit();
  }
}
