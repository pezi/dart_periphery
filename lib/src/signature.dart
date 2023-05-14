// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Most used FFI function signatures

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'library.dart';

final DynamicLibrary _peripheryLib = loadPeripheryLib();

// ignore: camel_case_types
typedef intVoidS = Int32 Function(Pointer<Void> handle);
// ignore: camel_case_types
typedef intVoidF = int Function(Pointer<Void> handle);
intVoidF intVoidM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidS>>(method)
      .asFunction<intVoidF>();
}

// ignore: camel_case_types
typedef voidVOID = Pointer<Void> Function();
voidVOID voidPtrVOIDM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<voidVOID>>(method)
      .asFunction<voidVOID>();
}

// ignore: camel_case_types
typedef utf8VOID = Pointer<Utf8> Function();
utf8VOID utf8VOIDM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<utf8VOID>>(method)
      .asFunction<utf8VOID>();
}

// ignore: camel_case_types
typedef voidVoidS = Void Function(Pointer<Void> handle);
// ignore: camel_case_types
typedef voidVoidF = void Function(Pointer<Void> handle);
voidVoidF voidVoidM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<voidVoidS>>(method)
      .asFunction<voidVoidF>();
}

// ignore: camel_case_types
typedef intVoidInt8S = Int32 Function(Pointer<Void> handle, Int8 value);
// ignore: camel_case_types
typedef intVoidInt8F = int Function(Pointer<Void> handle, int value);
intVoidInt8F intVoidInt8M(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidInt8S>>(method)
      .asFunction<intVoidInt8F>();
}

// ignore: camel_case_types
typedef intVoidUint8S = Int32 Function(Pointer<Void> handle, Uint8 value);
// ignore: camel_case_types
typedef intVoidUint8F = int Function(Pointer<Void> handle, int value);
intVoidInt8F intVoidUint8M(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidUint8S>>(method)
      .asFunction<intVoidUint8F>();
}

// ignore: camel_case_types
typedef intVoidIntS = Int32 Function(Pointer<Void> handle, Int32 value);
// ignore: camel_case_types
typedef intVoidIntF = int Function(Pointer<Void> handle, int value);
intVoidIntF intVoidIntM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidIntS>>(method)
      .asFunction<intVoidIntF>();
}

// ignore: camel_case_types
typedef intVoidLongS = Int32 Function(Pointer<Void> handle, Int64 value);
// ignore: camel_case_types
typedef intVoidLongF = int Function(Pointer<Void> handle, int value);
intVoidLongF intVoidInt64M(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidLongS>>(method)
      .asFunction<intVoidLongF>();
}

// ignore: camel_case_types
typedef intVoidUlongS = Int32 Function(Pointer<Void> handle, Uint64 value);
// ignore: camel_case_types
typedef intVoidUlongF = int Function(Pointer<Void> handle, int value);
intVoidLongF intVoidUint64M(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidUlongS>>(method)
      .asFunction<intVoidUlongF>();
}

// ignore: camel_case_types
typedef intVoidBoolS = Int32 Function(Pointer<Void> handle, Int8 value);
// ignore: camel_case_types
typedef intVoidBoolF = int Function(Pointer<Void> handle, int value);
intVoidLongF intVoidBoolM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidBoolS>>(method)
      .asFunction<intVoidBoolF>();
}

// ignore: camel_case_types
typedef intVoidDoubleS = Int32 Function(Pointer<Void> handle, Double value);
// ignore: camel_case_types
typedef intVoidDoubleF = int Function(Pointer<Void> handle, double value);
intVoidDoubleF intVoidDoubleM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidDoubleS>>(method)
      .asFunction<intVoidDoubleF>();
}

// ignore: camel_case_types
typedef intVoidIntIntS = Int32 Function(
    Pointer<Void> handle, Int32 value, Int32 value2);
// ignore: camel_case_types
typedef intVoidIntIntF = int Function(
    Pointer<Void> handle, int value, int value2);
intVoidIntIntF intVoidIntIntM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidIntIntS>>(method)
      .asFunction<intVoidIntIntF>();
}

// ignore: camel_case_types
typedef intVoidInt8PtrS = Int32 Function(
    Pointer<Void> handle, Pointer<Int8> value);
// ignore: camel_case_types
typedef intVoidInt8PtrF = int Function(
    Pointer<Void> handle, Pointer<Int8> value);
intVoidInt8PtrF intVoidInt8PtrM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidInt8PtrS>>(method)
      .asFunction<intVoidInt8PtrF>();
}

// ignore: camel_case_types
typedef intVoidInt32PtrS = Int32 Function(
    Pointer<Void> handle, Pointer<Int32> value);
// ignore: camel_case_types
typedef intVoidInt32PtrF = int Function(
    Pointer<Void> handle, Pointer<Int32> value);
intVoidInt32PtrF intVoidInt32PtrM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidInt32PtrS>>(method)
      .asFunction<intVoidInt32PtrF>();
}

// ignore: camel_case_types
typedef intVoidInt64PtrS = Int32 Function(
    Pointer<Void> handle, Pointer<Int64> value);
// ignore: camel_case_types
typedef intVoidInt64PtrF = int Function(
    Pointer<Void> handle, Pointer<Int64> value);
intVoidInt64PtrF intVoidInt64PtrM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidInt64PtrS>>(method)
      .asFunction<intVoidInt64PtrF>();
}

// ignore: camel_case_types
typedef intVoidUint64PtrS = Int32 Function(
    Pointer<Void> handle, Pointer<Uint64> value);
// ignore: camel_case_types
typedef intVoidUint64PtrF = int Function(
    Pointer<Void> handle, Pointer<Uint64> value);
intVoidUint64PtrF intVoidUint64PtrM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidUint64PtrS>>(method)
      .asFunction<intVoidUint64PtrF>();
}

// ignore: camel_case_types
typedef intVoidDoublePtrS = Int32 Function(
    Pointer<Void> handle, Pointer<Double> value);
// ignore: camel_case_types
typedef intVoidDoublePtrF = int Function(
    Pointer<Void> handle, Pointer<Double> value);
intVoidDoublePtrF intVoidDoublePtrM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidDoublePtrS>>(method)
      .asFunction<intVoidDoublePtrF>();
}

// ignore: camel_case_types
typedef utf8VoidS = Pointer<Utf8> Function(Pointer<Void> handle);
// ignore: camel_case_types
typedef utf8VoidF = Pointer<Utf8> Function(Pointer<Void> handle);
utf8VoidF utf8VoidM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<utf8VoidS>>(method)
      .asFunction<utf8VoidF>();
}

// ignore: camel_case_types
typedef int8VoidS = Pointer<Int8> Function(Pointer<Void> handle);
// ignore: camel_case_types
typedef int8VoidF = Pointer<Int8> Function(Pointer<Void> handle);
int8VoidF int8VoidM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<int8VoidS>>(method)
      .asFunction<int8VoidF>();
}

// ignore: camel_case_types
typedef intVoidInt8IntS = Int32 Function(
    Pointer<Void> handle, Pointer<Int8> string, Int32 len);
// ignore: camel_case_types
typedef intVoidInt8IntF = int Function(
    Pointer<Void> handle, Pointer<Int8> string, int len);
intVoidInt8IntF intVoidInt8IntM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidInt8IntS>>(method)
      .asFunction<intVoidInt8IntF>();
}

// ignore: camel_case_types
typedef intVoidUtf8IntS = Int32 Function(
    Pointer<Void> handle, Pointer<Utf8> string, Int32 len);
// ignore: camel_case_types
typedef intVoidUtf8IntF = int Function(
    Pointer<Void> handle, Pointer<Utf8> string, int len);
intVoidUtf8IntF intVoidUtf8IntM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidUtf8IntS>>(method)
      .asFunction<intVoidUtf8IntF>();
}

// ignore: camel_case_types
typedef intVoidUtf8sizeTS = Int32 Function(
    Pointer<Void> handle, Pointer<Utf8> string, IntPtr len);
// ignore: camel_case_types
typedef intVoidUtf8sizeTF = int Function(
    Pointer<Void> handle, Pointer<Utf8> string, int len);
intVoidUtf8sizeTF intVoidUtf8sizeTM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidUtf8sizeTS>>(method)
      .asFunction<intVoidUtf8IntF>();
}

// ignore: camel_case_types
typedef utf8VoidIntS = Pointer<Utf8> Function(
    Pointer<Void> handle, Int32 value);
// ignore: camel_case_types
typedef utf8VoidIntF = Pointer<Utf8> Function(Pointer<Void> handle, int value);
utf8VoidIntF utf8VoidIntM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<utf8VoidIntS>>(method)
      .asFunction<utf8VoidIntF>();
}

// ignore: camel_case_types
typedef voidUtf8S = Pointer<Void> Function(Pointer<Utf8> string);
voidUtf8S voidUtf8M(String method) {
  return _peripheryLib
      .lookup<NativeFunction<voidUtf8S>>(method)
      .asFunction<voidUtf8S>();
}

// ignore: camel_case_types
typedef voidVoidUtf8S = Int32 Function(Pointer<Void>, Pointer<Utf8> path);
// ignore: camel_case_types
typedef voidVoidUtf8F = int Function(Pointer<Void>, Pointer<Utf8> path);
voidVoidUtf8F voidVoidUtf8M(String method) {
  return _peripheryLib
      .lookup<NativeFunction<voidVoidUtf8S>>(method)
      .asFunction<voidVoidUtf8F>();
}
