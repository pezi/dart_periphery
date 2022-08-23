import 'dart:io';
import 'dart:isolate';
import 'dart:mirrors';

// https://stackoverflow.com/questions/66297761/dart-create-class-instance-by-string-with-class-name
void callStaticMethodOnClass(String className, String methodName) {
  final classSymbol = Symbol(className);
  final methodSymbol = Symbol(methodName);

  (currentMirrorSystem().isolate.rootLibrary.declarations[classSymbol]
          as ClassMirror)
      .invoke(methodSymbol, <dynamic>[]);
}

void dowork(var msg) {
  // print('execution from sayhii ... the message is :${msg}');
  callStaticMethodOnClass('SomeClass', 'initJob');
  // InstanceMirror im = reflect(SomeClass());
  // ClassMirror classMirror = im.type;
  // getDataMembers(classMirror);
}

void startIso() {
  // InstanceMirror im = reflect(new SomeClass());
  // ClassMirror classMirror = im.type;
  // getDataMembers(classMirror);
  Isolate.spawn(dowork, 'Hello!!');
  sleep(Duration(seconds: 2));
}
