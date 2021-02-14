import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'library.dart';

final DynamicLibrary _peripheryLib = getPeripheryLib();

typedef intVoidS = Int32 Function(Pointer<Void> handle);
typedef intVoidF = int Function(Pointer<Void> handle);
intVoidF intVoidM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidS>>(method)
      .asFunction<intVoidF>();
}

typedef intVoidIntS = Int32 Function(Pointer<Void> handle, Int32 value);
typedef intVoidIntF = int Function(Pointer<Void> handle, int value);
intVoidIntF intVoidIntM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidIntS>>(method)
      .asFunction<intVoidIntF>();
}

typedef intVoidIntIntS = Int32 Function(
    Pointer<Void> handle, Int32 value, Int32 value2);
typedef intVoidIntIntF = int Function(
    Pointer<Void> handle, int value, int value2);
intVoidIntIntF intVoidIntIntM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidIntIntS>>(method)
      .asFunction<intVoidIntIntF>();
}

typedef utf8VoidS = Pointer<Utf8> Function(Pointer<Void> handle);
typedef utf8VoidF = Pointer<Utf8> Function(Pointer<Void> handle);
utf8VoidF utf8VoidM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<utf8VoidS>>(method)
      .asFunction<utf8VoidF>();
}

typedef utf8VoidIntS = Pointer<Utf8> Function(
    Pointer<Void> handle, Int32 value);
typedef utf8VoidIntF = Pointer<Utf8> Function(Pointer<Void> handle, int value);
utf8VoidIntF utf8VoidIntM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<utf8VoidIntS>>(method)
      .asFunction<utf8VoidIntF>();
}

typedef voidUtf8S = Pointer<Void> Function(Pointer<Utf8> string);
typedef voidUtf8F = Pointer<Void> Function(Pointer<Utf8> string);
voidUtf8F voidUtf8M(String method) {
  return _peripheryLib
      .lookup<NativeFunction<voidUtf8S>>(method)
      .asFunction<voidUtf8S>();
}
