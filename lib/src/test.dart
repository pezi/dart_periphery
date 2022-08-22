import 'dart:mirrors';

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
  static void init() {}
  @MainJob()
  static void main() {}
  void method() {}
}

void main() {
  InstanceMirror im = reflect(new SomeClass());

  ClassMirror classMirror = im.type;

  getDataMembers(classMirror);
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
        print(m);
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
