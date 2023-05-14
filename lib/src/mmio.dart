// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/vsergeev/c-periphery/blob/master/docs/i2c.md
// https://github.com/vsergeev/c-periphery/blob/master/src/i2c.c
// https://github.com/vsergeev/c-periphery/blob/master/src/i2c.h
// https://github.com/dart-lang/samples/tree/master/ffi

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'library.dart';
import 'signature.dart';

/// [MMIO] error code
enum MMIOerrorCode {
  /// Error code for not able to map the native C enum
  errorCodeNotMappable,

  ///  Invalid arguments
  mmioErrorArg,

  /// Opening MMIO
  mmioErrorOpen,

  /// Closing MMIO
  mmioErrorClose
}

final DynamicLibrary _peripheryLib = getPeripheryLib();

// mmio_t mmio_new(void);
final _nativeMMIOnew = voidPtrVOIDM('mmio_new');

// int mmio_close(led_t *led);
final _nativeMMIOclose = intVoidM('mmio_close');

//  void mmio_free(mmio_t mmio);
final _nativeMMIOfree = voidVoidM('mmio_free');

// int mmio_errno(mmio_t mmio);
final _nativeMMIOerrno = intVoidM('mmio_errno');

// const char mmio_errmsg(mmio_t mmio);
final _nativeMMIOerrnMsg = utf8VoidM('mmio_errmsg');

// int mmio_tostring(mmio_t *led, char *str, size_t len);
final _nativeMMIOinfo = intVoidUtf8sizeTM('mmio_tostring');

// size_t mmio_size(mmio_t *mmio);
// final _nativeMMIOsize = intVoidM('mmio_size');

// int mmio_open(mmio_t *mmio, uintptr_t base, size_t size);
// ignore: camel_case_types
typedef _mmioOpen = Int32 Function(
    Pointer<Void> handle, IntPtr base, IntPtr size);
typedef _MMIOopen = int Function(Pointer<Void> handle, int base, int size);

final _nativeMMIOopen = _peripheryLib
    .lookup<NativeFunction<_mmioOpen>>('mmio_open')
    .asFunction<_MMIOopen>();

// int mmio_open_advanced(mmio_t *mmio, uintptr_t base, size_t size, const char *path);
// ignore: camel_case_types
typedef _mmioOpenAdvanced = Int32 Function(
    Pointer<Void> handle, IntPtr base, IntPtr size, Pointer<Utf8> path);
typedef _MMIOopenAdvanced = int Function(
    Pointer<Void> handle, int base, int size, Pointer<Utf8> path);
final _nativeMMIOopenAdvanced = _peripheryLib
    .lookup<NativeFunction<_mmioOpenAdvanced>>('mmio_open_advanced')
    .asFunction<_MMIOopenAdvanced>();

// int mmio_read32(mmio_t *mmio, uintptr_t offset, uint32_t *value);
// ignore: camel_case_types
typedef _mmioRead_32 = Int32 Function(
    Pointer<Void> handle, IntPtr offset, Pointer<Uint32> value);
typedef _MMIOread32 = int Function(
    Pointer<Void> handle, int offset, Pointer<Uint32> value);

final _nativeMMIOread_32 = _peripheryLib
    .lookup<NativeFunction<_mmioRead_32>>('mmio_read32')
    .asFunction<_MMIOread32>();

// int mmio_read16(mmio_t *mmio, uintptr_t offset, uint16_t *value);
// ignore: camel_case_types
typedef _mmioRead16 = Int32 Function(
    Pointer<Void> handle, IntPtr offset, Pointer<Uint16> value);
typedef _MMIOread16 = int Function(
    Pointer<Void> handle, int offset, Pointer<Uint16> value);

final _nativeMMIOread16 = _peripheryLib
    .lookup<NativeFunction<_mmioRead16>>('mmio_read16')
    .asFunction<_MMIOread16>();

// int mmio_read8(mmio_t *mmio, uintptr_t offset, uint8_t *value);
// ignore: camel_case_types
typedef _mmioRead8 = Int32 Function(
    Pointer<Void> handle, IntPtr offset, Pointer<Uint8> value);
typedef _MMIOread8 = int Function(
    Pointer<Void> handle, int offset, Pointer<Uint8> value);

final _nativeMMIOread_8 = _peripheryLib
    .lookup<NativeFunction<_mmioRead8>>('mmio_read8')
    .asFunction<_MMIOread8>();

// int mmio_read(mmio_t *mmio, uintptr_t offset, uint8_t *buf, size_t len);
// ignore: camel_case_types
typedef _mmiReadbuf = Int32 Function(
    Pointer<Void> handle, IntPtr offset, Pointer<Uint8> value, IntPtr len);
typedef _MMIOreadBuf = int Function(
    Pointer<Void> handle, int offset, Pointer<Uint8> value, int len);

final _nativeMMIOreadBuf = _peripheryLib
    .lookup<NativeFunction<_mmiReadbuf>>('mmio_read')
    .asFunction<_MMIOreadBuf>();

// int mmio_write32(mmio_t *mmio, uintptr_t offset, uint32_t value);
// ignore: camel_case_types
typedef _mmioWrite32 = Int64 Function(
    Pointer<Void> handle, IntPtr offset, Uint32 value);
typedef _MMIOwrite32 = int Function(
    Pointer<Void> handle, int offset, int value);

final _nativeMMIOwrite32 = _peripheryLib
    .lookup<NativeFunction<_mmioWrite32>>('mmio_write32')
    .asFunction<_MMIOwrite32>();

// int mmio_write16(mmio_t *mmio, uintptr_t offset, uint16_t value);
// ignore: camel_case_types
typedef _mmioWrite16 = Int64 Function(
    Pointer<Void> handle, IntPtr offset, Uint16 value);

final _nativeMMIOwrite16 = _peripheryLib
    .lookup<NativeFunction<_mmioWrite16>>('mmio_write16')
    .asFunction<_MMIOwrite32>();

// int mmio_write8(mmio_t *mmio, uintptr_t offset, uint8_t value);
// ignore: camel_case_types
typedef _mmioWrite8 = Int64 Function(
    Pointer<Void> handle, IntPtr offset, Uint8 value);

final _nativeMMIOwrite8 = _peripheryLib
    .lookup<NativeFunction<_mmioWrite8>>('mmio_write8')
    .asFunction<_MMIOwrite32>();

// int mmio_write(mmio_t *mmio, uintptr_t offset, const uint8_t *buf, size_t len);
// ignore: camel_case_types
typedef _mmioWriteBuf = Int64 Function(
    Pointer<Void> handle, IntPtr offset, Pointer<Uint8> value, IntPtr len);

typedef _MMIOwriteBuf = int Function(
    Pointer<Void> handle, int offset, Pointer<Uint8> value, int len);

final _nativeMMIOwriteBuf = _peripheryLib
    .lookup<NativeFunction<_mmioWriteBuf>>('mmio_write')
    .asFunction<_MMIOwriteBuf>();

const bufferLen = 256;

int _checkError(int value) {
  if (value < 0) {
    var errorCode = MMIO.getMMIOerrorCode(value);
    throw MMIOexception(errorCode, errorCode.toString());
  }
  return value;
}

String _getErrmsg(Pointer<Void> handle) {
  return _nativeMMIOerrnMsg(handle).toDartString();
}

/// [MMIO] exception
class MMIOexception implements Exception {
  final MMIOerrorCode errorCode;
  final String errorMsg;
  MMIOexception(this.errorCode, this.errorMsg);
  MMIOexception.errorCode(int code, Pointer<Void> handle)
      : errorCode = MMIO.getMMIOerrorCode(code),
        errorMsg = _getErrmsg(handle);
  @override
  String toString() => errorMsg;
}

/// MMIO wrapper functions for the Linux userspace <tt>/dev/mem</tt> device.
///
/// c-periphery [MMIO](https://github.com/vsergeev/c-periphery/blob/master/docs/mmio.md) documentation.
class MMIO {
  final Pointer<Void> _mmioHandle;
  bool _invalid = false;
  final int base;
  final int size;
  final String path;

  /// Maps the region of physical memory specified by the [base] physical address and [size] in bytes, using
  /// the default <tt>/dev/mem</tt> memory character device.
  ///
  /// Neither base nor size need be aligned to a page boundary.
  MMIO(this.base, this.size)
      : path = '',
        _mmioHandle = _mmioOpen(base, size);

  static Pointer<Void> _mmioOpen(int base, int size) {
    var mmioHandle = _nativeMMIOnew();
    if (mmioHandle == nullptr) {
      return throw MMIOexception(
          MMIOerrorCode.mmioErrorOpen, 'Error opening MMIO interface');
    }
    _checkError(_nativeMMIOopen(mmioHandle, base, size));
    return mmioHandle;
  }

  /// Map the region of physical memory specified by the [base] physical address and [size] in bytes, using
  /// the specified memory character device [path].
  ///
  /// This open function can be used with sandboxed memory character devices, e.g. <tt>/dev/gpiomem</tt>.
  /// Neither base nor size need be aligned to a page boundary.
  MMIO.advanced(this.base, this.size, this.path)
      : _mmioHandle = _mmioOpenAdvanced(base, size, path);

  static Pointer<Void> _mmioOpenAdvanced(int base, int size, String path) {
    var mmioHandle = _nativeMMIOnew();
    if (mmioHandle == nullptr) {
      return throw MMIOexception(
          MMIOerrorCode.mmioErrorOpen, 'Error opening MMIO interface');
    }
    _checkError(
        _nativeMMIOopenAdvanced(mmioHandle, base, size, path.toNativeUtf8()));
    return mmioHandle;
  }

  /// Converts the native error code [value] to [MMIOerrorCode].
  static MMIOerrorCode getMMIOerrorCode(int value) {
    // must be negative
    if (value >= 0) {
      return MMIOerrorCode.errorCodeNotMappable;
    }
    value = -value;

    // check range
    if (value > MMIOerrorCode.mmioErrorClose.index) {
      return MMIOerrorCode.errorCodeNotMappable;
    }

    return MMIOerrorCode.values[value];
  }

  /// Reads 32-bits from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened with.
  int read32(int offset) {
    var data = malloc<Uint32>(1);
    try {
      _checkError(_nativeMMIOread_32(_mmioHandle, offset, data));
      return data.value;
    } finally {
      malloc.free(data);
    }
  }

  /// Reads 16-bits from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened with.
  int read16(int offset) {
    var data = malloc<Uint16>(1);
    try {
      _checkError(_nativeMMIOread16(_mmioHandle, offset, data));
      return data.value;
    } finally {
      malloc.free(data);
    }
  }

  /// Reads 8-bits from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened with.
  int read8(int offset) {
    var data = malloc<Uint8>(1);
    try {
      _checkError(_nativeMMIOread_8(_mmioHandle, offset, data));
      return data.value;
    } finally {
      malloc.free(data);
    }
  }

  /// Reads an byte array from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened with.
  List<int> read(int offset, int len) {
    var buf = malloc<Uint8>(len);
    try {
      _checkError(_nativeMMIOreadBuf(_mmioHandle, offset, buf, len));
      var data = <int>[];
      for (var i = 0; i < len; ++i) {
        data.add(buf[i]);
      }
      return data;
    } finally {
      malloc.free(buf);
    }
  }

  /// Writes 32-bits from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened with.
  void write32(int offset, int value) {
    _checkError(_nativeMMIOwrite32(_mmioHandle, offset, value));
  }

  /// Writes 16-bits from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened with.
  void write16(int offset, int value) {
    _checkError(_nativeMMIOwrite16(_mmioHandle, offset, value));
  }

  /// Writes 8-bits from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened with.
  void write8(int offset, int value) {
    _checkError(_nativeMMIOwrite8(_mmioHandle, offset, value));
  }

  /// Writes an byte array from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened with.
  void write(int offset, List<int> data) {
    var buf = malloc<Uint8>(data.length);
    try {
      for (var i = 0; i < data.length; ++i) {
        buf[i] = data[i];
      }
      _checkError(_nativeMMIOwriteBuf(_mmioHandle, offset, buf, data.length));
    } finally {
      malloc.free(buf);
    }
  }

  /// Fast access for [MMIO.read32]
  int operator [](int i) => read32(i);

  /// Fast access for [MMIO.write32]
  operator []=(int i, int value) => write32(i, value); // set

  void _checkStatus() {
    if (_invalid) {
      throw MMIOexception(MMIOerrorCode.mmioErrorClose,
          'MMIO interface has the status released.');
    }
  }

  /// Releases all interal native resoures.
  void dispose() {
    _checkStatus();
    _invalid = true;
    _checkError(_nativeMMIOclose(_mmioHandle));
    _nativeMMIOfree(_mmioHandle);
  }

  /// Returns the libc errno of the last failure that occurred.
  int getErrno() {
    _checkStatus();
    return _nativeMMIOerrno(_mmioHandle);
  }

  /// Returns a string representation of the MMIO handle.
  String getMMIOinfo() {
    _checkStatus();
    var data = malloc<Int8>(bufferLen).cast<Utf8>();
    try {
      _checkError(_nativeMMIOinfo(_mmioHandle, data, bufferLen));
      return data.toDartString();
    } finally {
      malloc.free(data);
    }
  }
}
