// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/vsergeev/c-periphery/blob/master/docs/i2c.md
// https://github.com/vsergeev/c-periphery/blob/master/src/i2c.c
// https://github.com/vsergeev/c-periphery/blob/master/src/i2c.h
// https://github.com/dart-lang/samples/tree/master/ffi

import 'dart:ffi';
import 'library.dart';
import 'package:ffi/ffi.dart';
import 'signature.dart';

/// MMIO error code
enum MMIOerrorCode {
  /// Error code for not able to map the native C enum
  ERROR_CODE_NOT_MAPPABLE,

  ///  Invalid arguments
  MMIO_ERROR_ARG,

  /// Opening MMIO
  MMIO_ERROR_OPEN,

  /// Closing MMIO
  MMIO_ERROR_CLOSE
}

final DynamicLibrary _peripheryLib = getPeripheryLib();

// mmio_t *dart_mmio_open(uint64_t base, size_t size)
typedef _dart_mmio_open = Pointer<Void> Function(Int64 base, Int32 size);
typedef _MMIOopen = Pointer<Void> Function(int base, int size);
final _nativeOpen = _peripheryLib
    .lookup<NativeFunction<_dart_mmio_open>>('dart_mmio_open')
    .asFunction<_MMIOopen>();

// mmio_t* dart_mmio_open_advanced(long base, size_t size,const char *path)
typedef _dart_mmio_open_advanced = Pointer<Void> Function(
    Int64 base, Int32 size, Pointer<Utf8> path);
typedef _MMIOopenAdvanced = Pointer<Void> Function(
    int base, int size, Pointer<Utf8> path);
final _nativeOpenAdvanced = _peripheryLib
    .lookup<NativeFunction<_dart_mmio_open_advanced>>('dart_mmio_open_advanced')
    .asFunction<_MMIOopenAdvanced>();

// uint64_t dart_mmio_read32(mmio_t *mmio, uint64_t offset)
typedef _dart_mmio_read = Int64 Function(Pointer<Void> handle, Int64 offset);
typedef _MMIOread = int Function(Pointer<Void> handle, int offset);
final _nativeRead32 = _peripheryLib
    .lookup<NativeFunction<_dart_mmio_read>>('dart_mmio_read32')
    .asFunction<_MMIOread>();
final _nativeRead16 = _peripheryLib
    .lookup<NativeFunction<_dart_mmio_read>>('dart_mmio_read16')
    .asFunction<_MMIOread>();
final _nativeRead8 = _peripheryLib
    .lookup<NativeFunction<_dart_mmio_read>>('dart_mmio_read8')
    .asFunction<_MMIOread>();

typedef _dart_mmio_write = Int64 Function(
    Pointer<Void> handle, Int64 offset, Int32 value);
typedef _MMIOwrite = int Function(Pointer<Void> handle, int offset, int value);
final _nativeWrite32 = _peripheryLib
    .lookup<NativeFunction<_dart_mmio_write>>('dart_mmio_write32')
    .asFunction<_MMIOwrite>();
final _nativeWrite16 = _peripheryLib
    .lookup<NativeFunction<_dart_mmio_write>>('dart_mmio_write16')
    .asFunction<_MMIOwrite>();
final _nativeWrite8 = _peripheryLib
    .lookup<NativeFunction<_dart_mmio_write>>('dart_mmio_write8')
    .asFunction<_MMIOwrite>();

typedef _dart_mmio_transfer_buf = Int32 Function(
    Pointer<Void> handle, Int32 offset, Pointer<Uint8> data, Int32 len);
typedef _MMIO_transfer_buf = int Function(
    Pointer<Void> handle, int offset, Pointer<Uint8> data, int len);
final _native_read_buf = _peripheryLib
    .lookup<NativeFunction<_dart_mmio_transfer_buf>>('dart_mmio_read')
    .asFunction<_MMIO_transfer_buf>();
final _native_write_buf = _peripheryLib
    .lookup<NativeFunction<_dart_mmio_transfer_buf>>('dart_mmio_write')
    .asFunction<_MMIO_transfer_buf>();

// char *dart_mmio_info(mmio_t *mmio)
final _nativeInfo = utf8VoidM('dart_mmio_info');

// int dart_mmio_dispose(mmio_t *mmio)
final _nativeDispose = intVoidM('dart_mmio_dispose');

// int dart_mmio_errno(mmio_t *mmio)
final _nativeErrno = intVoidM('dart_mmio_errno');

// const char *dart_mmio_errmsg(mmio_t *mmio)
final _nativeErrmsg = utf8VoidM('dart_mmio_errmsg');

/// Converts the native error code [value] to [MMIOerrorCodee].
MMIOerrorCode getMMIOerrorCode(int value) {
  // must be negative
  if (value >= 0) {
    return MMIOerrorCode.ERROR_CODE_NOT_MAPPABLE;
  }
  value = -value;

  // check range
  if (value > MMIOerrorCode.MMIO_ERROR_CLOSE.index) {
    return MMIOerrorCode.ERROR_CODE_NOT_MAPPABLE;
  }

  return MMIOerrorCode.values[value];
}

int _checkError(int value) {
  if (value < 0) {
    var errorCode = getMMIOerrorCode(value);
    throw MMIOexception(errorCode, errorCode.toString());
  }
  return value;
}

String _getErrmsg(Pointer<Void> handle) {
  return Utf8.fromUtf8(_nativeErrmsg(handle));
}

// MMIO exception
class MMIOexception implements Exception {
  final MMIOerrorCode errorCode;
  final String errorMsg;
  MMIOexception(this.errorCode, this.errorMsg);
  MMIOexception.errorCode(int code, Pointer<Void> handle)
      : errorCode = getMMIOerrorCode(code),
        errorMsg = _getErrmsg(handle);
  @override
  String toString() => errorMsg;
}

const int MASK_32 = 0xFFFFFFFF;

/// MMIO wrapper functions for the Linux userspace <tt>/dev/mem</tt> device.
class MMIO {
  Pointer<Void> _mmioHandle;
  bool _invalid = false;
  int base;
  int size;
  String path;

  /// Maps the region of physical memory specified by the [base] physical address and [size] in bytes, using
  /// the default <tt>/dev/mem</tt> memory character device.
  ///
  /// Neither base nor size need be aligned to a page boundary.
  MMIO(this.base, this.size) : path = '' {
    _mmioHandle = _checkHandle(_nativeOpen(base, size));
  }

  /// Map the region of physical memory specified by the [base] physical address and [size] in bytes, using
  /// the specified memory character device [path].
  ///
  /// This open function can be used with sandboxed memory character devices, e.g. <tt>/dev/gpiomem</tt>.
  /// Neither base nor size need be aligned to a page boundary.
  MMIO.advanced(this.base, this.size, this.path) {
    _mmioHandle =
        _checkHandle(_nativeOpenAdvanced(base, size, Utf8.toUtf8(path)));
  }

  /// Reads 32-bits from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened with.
  int read32(int offset) {
    var value = _nativeRead32(_mmioHandle, offset);
    if (value ^ MASK_32 != 0) {
      _checkError(-(value >> 32));
    }
    return value;
  }

  /// Reads 16-bits from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened with.
  int read16(int offset) {
    var value = _nativeRead16(_mmioHandle, offset);
    if (value ^ MASK_32 != 0) {
      _checkError(-(value >> 32));
    }
    return value;
  }

  /// Reads 8-bits from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened with.
  int read8(int offset) {
    var value = _nativeRead8(_mmioHandle, offset);
    if (value ^ MASK_32 != 0) {
      _checkError(-(value >> 32));
    }
    return value;
  }

  /// Reads an byte array from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened with.
  List<int> read(int offset, int len) {
    var buf = allocate<Uint8>(count: len);
    try {
      _checkError(_native_read_buf(_mmioHandle, offset, buf, len));
      var data = <int>[];
      for (var i = 0; i < len; ++i) {
        data.add(buf.elementAt(i).value);
      }
      return data;
    } finally {
      free(buf);
    }
  }

  /// Writes 32-bits from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened wi
  void write32(int offset, int value) {
    _checkError(_nativeWrite32(_mmioHandle, offset, value));
  }

  /// Writes 16-bits from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened wi
  void write16(int offset, int value) {
    _checkError(_nativeWrite16(_mmioHandle, offset, value));
  }

  /// Writes 8-bits from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened wi
  void write8(int offset, int value) {
    _checkError(_nativeWrite8(_mmioHandle, offset, value));
  }

  /// Writes an byte array from mapped physical memory, starting at the specified byte offset, relative to the
  /// base address the MMIO handle was opened with.
  void write(int offset, List<int> data) {
    var buf = allocate<Uint8>(count: data.length);
    try {
      for (var i = 0; i < data.length; ++i) {
        buf.elementAt(i).value = data[i];
      }
      _checkError(_native_write_buf(_mmioHandle, offset, buf, data.length));
    } finally {
      free(buf);
    }
  }

  /// Fast access for [MMIO.read32]
  int operator [](int i) => read32(i);

  /// Fast access for [MMIO.write32]
  operator []=(int i, int value) => write32(i, value); // set

  Pointer<Void> _checkHandle(Pointer<Void> handle) {
    // handle 0 indicates an internal error
    if (handle.address == 0) {
      throw MMIOexception(MMIOerrorCode.MMIO_ERROR_OPEN, 'Error opening MMIO');
    }
    return handle;
  }

  void _checkStatus() {
    if (_invalid) {
      throw MMIOexception(MMIOerrorCode.MMIO_ERROR_CLOSE,
          'MMIO interface has the status released.');
    }
  }

  /// Releases all interal native resoures.
  void dispose() {
    _checkStatus();
    _invalid = true;
    _checkError(_nativeDispose(_mmioHandle));
  }

  /// Returns the libc errno of the last failure that occurred.
  int getErrno() {
    _checkStatus();
    return _nativeErrno(_mmioHandle);
  }

  /// Returns a string representation of the MMIO handle.
  String getMMIOinfo() {
    _checkStatus();
    final ptr = _nativeInfo(_mmioHandle);
    if (ptr.address == 0) {
      // throw an exception
      _checkError(getErrno());
      return '?';
    }
    var text = Utf8.fromUtf8(ptr);
    free(ptr);
    return text;
  }
}
