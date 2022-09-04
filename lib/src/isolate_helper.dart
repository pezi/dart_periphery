import 'dart:isolate';
import 'dart:mirrors';
import 'dart:async';
import 'package:async/async.dart';

/// Annotation class for the init method
class InitJob {
  const InitJob();
}

abstract class JobResult {
  bool error;
  Map<String, dynamic>? data;
  JobResult(this.error, [this.data]);
}

/// Result for the init job method
class InitJobResult extends JobResult {
  String json;

  /// Result of an init job method, [error] signals an error, [json]
  InitJobResult(bool error, this.json, [Map<String, dynamic>? data])
      : super(error, data);
}

/// Annotate class for the main method
class MainJob {
  const MainJob();
}

class MainJobResult extends JobResult {
  bool exit;
  MainJobResult(bool error, this.exit, [Map<String, dynamic>? data])
      : super(error, data);
}

/// Annotation for the exit method
class ExitJob {
  const ExitJob();
}

//
class ExitJobResult extends JobResult {
  ExitJobResult(bool error, [Map<String, dynamic>? data]) : super(error, data);
}

class JobIteration {
  int iteration;
  JobIteration(this.iteration);
  JobIteration.endless() : iteration = -1;
}

var mirrorCache = <String, ClassMirror>{};

InstanceMirror callStaticMethodOnClass(String className, String methodName,
    [String json = '']) {
  final classSymbol = Symbol(className);
  final methodSymbol = Symbol(methodName);

  var cm = mirrorCache[className];
  if (cm == null) {
    cm = currentMirrorSystem().isolate.rootLibrary.declarations[classSymbol]
        as ClassMirror;
    mirrorCache[className] = cm;
  }
  return cm.invoke(methodSymbol, json.isEmpty ? <dynamic>[] : <dynamic>[json]);
}

enum JobMethod { init, main, exit }

class IsolateHelper {
  Object clazz;
  JobIteration iterationJob;
  late ClassMirror classMirror;
  Isolate? isolate;
  String? json;
  ReceivePort? receivePort;

  var mMap = <JobMethod, String>{};

  IsolateHelper(this.clazz, this.iterationJob) {
    InstanceMirror im = reflect(clazz);
    classMirror = im.type;

    for (var v in classMirror.declarations.values) {
      var name = MirrorSystem.getName(v.simpleName);
      Symbol initSym = Symbol('InitJobResult');
      Symbol mainSym = Symbol('MainJobResult');
      Symbol exitSym = Symbol('ExitJobResult');
      Symbol strSym = Symbol('String');

      // check method signature
      if (v is MethodMirror) {
        for (var m in v.metadata) {
          if (m.reflectee is InitJob && v.isStatic) {
            if (v.parameters.isNotEmpty) {
              throw Exception(
                  '@InitJob annotated method has wrong parameter signature: InitJobResult initJob()');
            }
            if (v.returnType.simpleName != initSym) {
              throw Exception(
                  '@InitJob annotated method has wrong return type: InitJobResult initJob()');
            }
            mMap[JobMethod.init] = name;
          } else if (m.reflectee is MainJob && v.isStatic) {
            if (v.parameters.length != 1 ||
                v.parameters[0].type.simpleName != strSym) {
              throw Exception(
                  '@MainJob annotated method has wrong parameter signature: MainJobResult mainJob(String json)');
            }
            if (v.returnType.simpleName != mainSym) {
              throw Exception(
                  '@MainJob annotated method has wrong return type: MainJobResult mainJob()');
            }
            mMap[JobMethod.main] = name;
          } else if (m.reflectee is ExitJob && v.isStatic) {
            if (v.parameters.length != 1 ||
                v.parameters[0].type.simpleName != strSym) {
              throw Exception(
                  '@ExitJob annotated method has wrong paramter signature: ExitJobResult exitJob(String json)');
            }
            if (v.returnType.simpleName != exitSym) {
              throw Exception(
                  '@ExitJob annotated method has wrong return type: ExitJobResult exitJob()');
            }
            mMap[JobMethod.exit] = name;
          }
        }
      }
    }
    for (var m in JobMethod.values) {
      if (!mMap.containsKey(m)) {
        throw Exception(
            "Missing static annotated method  @${m.name.split('.').last}Job inside class $im");
      }
    }
  }

  void killIsolate() {
    receivePort!.close();
    isolate!.kill(priority: Isolate.immediate);
  }

  Stream<JobResult> run() async* {
    receivePort = ReceivePort();
    isolate = await Isolate.spawn<SendPort>(_isolate, receivePort!.sendPort);

    final events = StreamQueue<dynamic>(receivePort!);

    // send class info and counter as  mao
    SendPort sendPort = await events.next;
    var classInfo = <String, String>{};
    classInfo['class'] = clazz.runtimeType.toString();
    for (var m in JobMethod.values) {
      classInfo[m.name.split('.').last] = mMap[m] as String;
    }
    classInfo['counter'] = iterationJob.iteration.toString();
    sendPort.send(classInfo);

    // wait for init map
    var initMap = await events.next;
    json = initMap['_json'];

    yield InitJobResult(
        initMap['_error'] as bool, initMap['_json'] as String, initMap);
    if (!(initMap['_error'] as bool)) {
      var loop = true;

      while (loop) {
        var result = await events.next;
        if (result['_job'] == JobMethod.exit) {
          yield ExitJobResult(initMap['_error'] as bool, result);
          loop = false;
        } else {
          yield MainJobResult(
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

    // init job
    InstanceMirror mr = callStaticMethodOnClass(
        classInfo['class'] as String, classInfo['init'] as String);
    var initResult = mr.reflectee as InitJobResult;
    var initMap = initResult.data;
    initMap = initMap ?? <String, dynamic>{};
    initMap['_job'] = JobMethod.init;
    initMap['_error'] = initResult.error;
    initMap['_json'] = initResult.json;
    sendPort.send(initMap);
    if (initResult.error) {
      commandPort.close();
      Isolate.exit();
    }

    // loop main job
    int counter = int.parse(classInfo['counter'] as String);
    bool endless = false;
    if (counter < 0) {
      endless = true;
    }
    int index = 0;
    while (true) {
      if (!endless) {
        if (index == counter) {
          break;
        }
      }
      InstanceMirror mr = callStaticMethodOnClass(classInfo['class'] as String,
          classInfo['main'] as String, initResult.json);
      var mainResult = mr.reflectee as MainJobResult;
      var mainMap = mainResult.data;
      mainMap = mainMap ?? <String, dynamic>{};
      mainMap['_job'] = JobMethod.main;
      mainMap['_error'] = mainResult.error;
      mainMap['_exit'] = mainResult.exit;
      sendPort.send(mainMap);
      if (mainResult.exit) {
        break;
      }
      ++index;
    }

    // exit job
    mr = callStaticMethodOnClass(classInfo['class'] as String,
        classInfo['exit'] as String, initResult.json);
    var exitResult = mr.reflectee as ExitJobResult;
    var exitMap = exitResult.data;
    exitMap = exitMap ?? <String, dynamic>{};

    exitMap['_job'] = JobMethod.exit;
    exitMap['_error'] = exitResult.error;
    sendPort.send(exitMap);
    Isolate.exit();
  }
}
