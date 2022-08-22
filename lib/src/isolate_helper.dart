// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import 'dart:async';
import 'package:async/async.dart';
import 'dart:mirrors';

typedef InitJob<K> = void Function(K value);
typedef MainJob<K> = String Function(K value);
typedef ExitJob<K> = void Function(K value);

class Test {
  static void doWork() {
    print("test 42");
  }
}

void findStaticAndInvoke(String name) {
  ClassMirror r = reflectClass(Test);
  MethodMirror? sFn;
  var s = Symbol(name);

  while (sFn == null) {
    sFn = r.staticMembers[s];
    if (sFn != null) {
      break;
    }
    r = r.superclass as ClassMirror;
  }

  if (sFn != null) {
    if (sFn.isGetter) {
      print(r.getField(s).reflectee);
    } else {
      r.invoke(s, []);
    }
  }
}

void callStaticMethodOnClass(String s, String t) {
  final classSymbol = Symbol(s);
  final methodSymbol = Symbol(t);
  ClassMirror classMirror = reflectClass(Test);
  print(classMirror);

  (currentMirrorSystem().isolate.rootLibrary.declarations[classSymbol]
          as ClassMirror)
      .invoke(methodSymbol, <dynamic>[]);
}

abstract class IsolateAPI {
  String toJson();
  int getHandle();
  void setHandle(int handle);
}

class IsolateContainer<T extends IsolateAPI> {
  T device;

  InitJob<T> init;
  MainJob<T> mainJob;
  ExitJob<T> exitJob;
  int counter;
  static Function? call;

  IsolateContainer(
      this.device, this.init, this.mainJob, this.exitJob, this.counter);
  IsolateContainer.runOnce(this.device, this.init, this.mainJob, this.exitJob)
      : counter = 1;
  IsolateContainer.infinitLoop(
      this.device, this.init, this.mainJob, this.exitJob)
      : counter = 0;

  Stream<String> run() async* {
    init(device);
    findStaticAndInvoke("doWork");
    final p = ReceivePort();
    await Isolate.spawn<SendPort>(_isolateMainJob, p.sendPort);
    // Convert the ReceivePort into a StreamQueue to receive messages from the
    // spawned isolate using a pull-based interface. Events are stored in this
    // queue until they are accessed by `events.next`.
    final events = StreamQueue<dynamic>(p);

    // The first message from the spawned isolate is a SendPort. This port is
    // used to communicate with the spawned isolate.
    SendPort sendPort = await events.next;
    sendPort.send(device.toJson());
    device.setHandle(await events.next);

    while (true) {
      String data = await events.next;

      // Add the result to the stream returned by this async* function.
      yield data;
    }
  }

  static Future<void> _isolateMainJob(SendPort p) async {
    // Send a SendPort to the main isolate so that it can send JSON strings to
    // this isolate.
    print("i am here 43");
    findStaticAndInvoke("doWork");
    // callStaticMethodOnClass("Test", "doWork");

    final commandPort = ReceivePort();
    p.send(commandPort.sendPort);
/*
  // Wait for messages from the main isolate.
  String json = await commandPort.first;

  var hw = device.fromJson(json);
  p.send(hw.getHandle());
  int c = 1;
  while (true) {
    p.send(mainJob(hw as T));
    if (counter != 0) {
      if (c == counter) {
        break;
      }
      ++counter;
    }
  }
  */
  }
}
