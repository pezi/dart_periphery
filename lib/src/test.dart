import 'dart:io';
import 'dart:isolate';
import 'dart:mirrors';

import 'package:dart_periphery/src/test2.dart';

class SomeAnnotation {
  const SomeAnnotation(this.someField);
  final String someField;
}

class InitJob {
  const InitJob();
}

class MainJob {
  const MainJob();
}

class ExitJob {}

class SomeClass {
  @InitJob()
  static void initJob() {
    print("-->init job");
  }

  @MainJob()
  static void mainJob() {
    print("-->main job");
  }

  void method() {}
}

void dowork(var msg) {
  // print('execution from sayhii ... the message is :${msg}');
  callStaticMethodOnClass('SomeClass', 'initJob');
  // InstanceMirror im = reflect(SomeClass());
  // ClassMirror classMirror = im.type;
  // getDataMembers(classMirror);
}

void main() {
  // InstanceMirror im = reflect(new SomeClass());
  // ClassMirror classMirror = im.type;
  // getDataMembers(classMirror);
  // Isolate.spawn(dowork, 'Hello!!');
  startIso();
  sleep(Duration(seconds: 2));
}

void getDataMembers(ClassMirror classMirror) {
  // final DeclarationMirror clazzDeclaration = reflectClass(clazz);

  for (var v in classMirror.declarations.values) {
    var name = MirrorSystem.getName(v.simpleName);

    if (v is VariableMirror) {
      print('Variable: $name');

      print('const: ${v.isConst}');

      print('final: ${v.isFinal}');

      print('private: ${v.isPrivate}');

      print('static: ${v.isStatic}');

      print('extension: ${v.isExtensionMember}');
    } else if (v is MethodMirror) {
      for (var m in v.metadata) {
        if (m.reflectee is MainJob) {
          classMirror.invoke(Symbol(name), []);
        }
      }
      print('Method: $name');

      print('abstract: ${v.isAbstract}');

      print('private: ${v.isPrivate}');

      print('static: ${v.isStatic}');

      print('extension: ${v.isExtensionMember}');

      print('constructor: ${v.isConstructor}');

      print('top level: ${v.isTopLevel}');
    }

    print('-----------------------------');
  }
}
