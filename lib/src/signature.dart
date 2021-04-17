// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Most used FFI function signatures

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

typedef voidVOID = Pointer<Void> Function();
voidVOID voidPtrVOIDM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<voidVOID>>(method)
      .asFunction<voidVOID>();
}

typedef utf8VOID = Pointer<Utf8> Function();
utf8VOID utf8VOIDM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<utf8VOID>>(method)
      .asFunction<utf8VOID>();
}

typedef voidVoidS = Void Function(Pointer<Void> handle);
typedef voidVoidF = void Function(Pointer<Void> handle);
voidVoidF voidVoidM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<voidVoidS>>(method)
      .asFunction<voidVoidF>();
}

typedef intVoidInt8S = Int32 Function(Pointer<Void> handle, Int8 value);
typedef intVoidInt8F = int Function(Pointer<Void> handle, int value);
intVoidInt8F intVoidInt8M(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidInt8S>>(method)
      .asFunction<intVoidInt8F>();
}

typedef intVoidUint8S = Int32 Function(Pointer<Void> handle, Uint8 value);
typedef intVoidUint8F = int Function(Pointer<Void> handle, int value);
intVoidInt8F intVoidUint8M(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidUint8S>>(method)
      .asFunction<intVoidUint8F>();
}

typedef intVoidIntS = Int32 Function(Pointer<Void> handle, Int32 value);
typedef intVoidIntF = int Function(Pointer<Void> handle, int value);
intVoidIntF intVoidIntM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidIntS>>(method)
      .asFunction<intVoidIntF>();
}

typedef intVoidLongS = Int32 Function(Pointer<Void> handle, Int64 value);
typedef intVoidLongF = int Function(Pointer<Void> handle, int value);
intVoidLongF intVoidInt64M(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidLongS>>(method)
      .asFunction<intVoidLongF>();
}

typedef intVoidUlongS = Int32 Function(Pointer<Void> handle, Uint64 value);
typedef intVoidUlongF = int Function(Pointer<Void> handle, int value);
intVoidLongF intVoidUint64M(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidUlongS>>(method)
      .asFunction<intVoidUlongF>();
}

typedef intVoidBoolS = Int32 Function(Pointer<Void> handle, Int8 value);
typedef intVoidBoolF = int Function(Pointer<Void> handle, int value);
intVoidLongF intVoidBoolM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidBoolS>>(method)
      .asFunction<intVoidBoolF>();
}

typedef intVoidDoubleS = Int32 Function(Pointer<Void> handle, Double value);
typedef intVoidDoubleF = int Function(Pointer<Void> handle, double value);
intVoidDoubleF intVoidDoubleM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidDoubleS>>(method)
      .asFunction<intVoidDoubleF>();
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

typedef intVoidInt8PtrS = Int32 Function(
    Pointer<Void> handle, Pointer<Int8> value);
typedef intVoidInt8PtrF = int Function(
    Pointer<Void> handle, Pointer<Int8> value);
intVoidInt8PtrF intVoidInt8PtrM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidInt8PtrS>>(method)
      .asFunction<intVoidInt8PtrF>();
}

typedef intVoidInt32PtrS = Int32 Function(
    Pointer<Void> handle, Pointer<Int32> value);
typedef intVoidInt32PtrF = int Function(
    Pointer<Void> handle, Pointer<Int32> value);
intVoidInt32PtrF intVoidInt32PtrM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidInt32PtrS>>(method)
      .asFunction<intVoidInt32PtrF>();
}

typedef intVoidInt64PtrS = Int32 Function(
    Pointer<Void> handle, Pointer<Int64> value);
typedef intVoidInt64PtrF = int Function(
    Pointer<Void> handle, Pointer<Int64> value);
intVoidInt64PtrF intVoidInt64PtrM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidInt64PtrS>>(method)
      .asFunction<intVoidInt64PtrF>();
}

typedef intVoidUint64PtrS = Int32 Function(
    Pointer<Void> handle, Pointer<Uint64> value);
typedef intVoidUint64PtrF = int Function(
    Pointer<Void> handle, Pointer<Uint64> value);
intVoidUint64PtrF intVoidUint64PtrM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidUint64PtrS>>(method)
      .asFunction<intVoidUint64PtrF>();
}

typedef intVoidDoublePtrS = Int32 Function(
    Pointer<Void> handle, Pointer<Double> value);
typedef intVoidDoublePtrF = int Function(
    Pointer<Void> handle, Pointer<Double> value);
intVoidDoublePtrF intVoidDoublePtrM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidDoublePtrS>>(method)
      .asFunction<intVoidDoublePtrF>();
}

typedef utf8VoidS = Pointer<Utf8> Function(Pointer<Void> handle);
typedef utf8VoidF = Pointer<Utf8> Function(Pointer<Void> handle);
utf8VoidF utf8VoidM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<utf8VoidS>>(method)
      .asFunction<utf8VoidF>();
}

typedef int8VoidS = Pointer<Int8> Function(Pointer<Void> handle);
typedef int8VoidF = Pointer<Int8> Function(Pointer<Void> handle);
int8VoidF int8VoidM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<int8VoidS>>(method)
      .asFunction<int8VoidF>();
}

typedef intVoidInt8IntS = Int32 Function(
    Pointer<Void> handle, Pointer<Int8> string, Int32 len);
typedef intVoidInt8IntF = int Function(
    Pointer<Void> handle, Pointer<Int8> string, int len);
intVoidInt8IntF intVoidInt8IntM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidInt8IntS>>(method)
      .asFunction<intVoidInt8IntF>();
}

typedef intVoidUtf8IntS = Int32 Function(
    Pointer<Void> handle, Pointer<Utf8> string, Int32 len);
typedef intVoidUtf8IntF = int Function(
    Pointer<Void> handle, Pointer<Utf8> string, int len);
intVoidUtf8IntF intVoidUtf8IntM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidUtf8IntS>>(method)
      .asFunction<intVoidUtf8IntF>();
}

typedef intVoidUtf8sizeTS = Int32 Function(
    Pointer<Void> handle, Pointer<Utf8> string, IntPtr len);
typedef intVoidUtf8sizeTF = int Function(
    Pointer<Void> handle, Pointer<Utf8> string, int len);
intVoidUtf8sizeTF intVoidUtf8sizeTM(String method) {
  return _peripheryLib
      .lookup<NativeFunction<intVoidUtf8sizeTS>>(method)
      .asFunction<intVoidUtf8IntF>();
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
voidUtf8S voidUtf8M(String method) {
  return _peripheryLib
      .lookup<NativeFunction<voidUtf8S>>(method)
      .asFunction<voidUtf8S>();
}

typedef voidVoidUtf8S = Int32 Function(Pointer<Void>, Pointer<Utf8> path);
typedef voidVoidUtf8F = int Function(Pointer<Void>, Pointer<Utf8> path);
voidVoidUtf8F voidVoidUtf8M(String method) {
  return _peripheryLib
      .lookup<NativeFunction<voidVoidUtf8S>>(method)
      .asFunction<voidVoidUtf8F>();
}
