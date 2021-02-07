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

/*
    #define I2C_M_TEN		0x0010
    #define I2C_M_RD		0x0001
    #define I2C_M_STOP		0x8000
    #define I2C_M_NOSTART		0x4000
    #define I2C_M_REV_DIR_ADDR	0x2000
    #define I2C_M_IGNORE_NAK	0x1000
    #define I2C_M_NO_RD_ACK		0x0800
    #define I2C_M_RECV_LEN		0x0400
*/

/// Native i2c_msg flags from <linux/i2c.h>
enum I2CmsgFlags {
  I2C_M_TEN,
  I2C_M_RD,
  I2C_M_STOP,
  I2C_M_NOSTART,
  I2C_M_REV_DIR_ADDR,
  I2C_M_IGNORE_NAK,
  I2C_M_NO_RD_ACK,
  I2C_M_RECV_LEN
}

/// Converts [I2CmsgFlags} to the native bit mask value.
int I2CmsgFlags2Int(I2CmsgFlags flag) {
  switch (flag) {
    case I2CmsgFlags.I2C_M_TEN:
      return 0x0010;
    case I2CmsgFlags.I2C_M_RD:
      return 0x0001;
    case I2CmsgFlags.I2C_M_STOP:
      return 0x8000;
    case I2CmsgFlags.I2C_M_NOSTART:
      return 0x4000;
    case I2CmsgFlags.I2C_M_REV_DIR_ADDR:
      return 0x2000;
    case I2CmsgFlags.I2C_M_IGNORE_NAK:
      return 0x1000;
    case I2CmsgFlags.I2C_M_NO_RD_ACK:
      return 0x0800;
    case I2CmsgFlags.I2C_M_RECV_LEN:
      return 0x0400;
  }
  return 0;
}

/// Helper class mapped to the C struct i2c_msg
class NativeI2Cmsg extends Struct {
  @Int16()
  int addr;
  @Int16()
  int flags;
  @Int16()
  int len;
  Pointer<Int8> buf;
  factory NativeI2Cmsg.allocate() => allocate<NativeI2Cmsg>().ref;
}

/// Helper class which stores an array of native 'struct i2c_msg' messages.
/// The user must call [NativeI2CmsgHelper.dispose()] to free the allocated
/// memory.
class NativeI2CmsgHelper {
  final Pointer<NativeI2Cmsg> _messages;
  final int size;
  bool _isFreed = false;
  NativeI2CmsgHelper(this._messages, this.size);

  /// Returns a Pointer<NativeI2Cmsg> to the native memory structures.
  Pointer<NativeI2Cmsg> getMessages() {
    if (_isFreed) {
      throw I2Cexception(I2CerrorCode.I2C_ERROR_CLOSE,
          "Not allowed acccess to a 'dispose()'ed memory structure.");
    }
    return _messages;
  }

  /// Frees all allocated memory blocks.
  void dispose() {
    if (_isFreed == true) {
      return;
    }
    _isFreed = true;
    int index = 0;
    for (int i = 0; i < size; ++i) {
      Pointer<NativeI2Cmsg> msg = _messages.elementAt(index++);
      if (msg.ref.buf.address != 0) {
        free(msg.ref.buf);
      }
    }
    free(_messages);
  }
}

/// High level I2Cmsg class.
class I2Cmsg {
  /// I2C device address
  final int addr;

  /// I2C transfer flags
  final List<I2CmsgFlags> flags;

  /// size of the I2C data buffer
  final int len;

  /// predefined I2C data buffer
  final List<int> predefined;

  /// Constructs an I2C message with the I2C device address [addr],
  /// [flags] list and a transfer buffer with size [len]. An empty
  /// [flags] list results [NativeI2Cmsg.flags] = 0.
  /// The message flags specify whether the message is a read (I2C_M_RD) or write (0) transaction, as well
  /// as additional options selected by the bitwise OR of their bitmasks.
  I2Cmsg(this.addr, List<I2CmsgFlags> this.flags, this.len)
      : predefined = const [];

  /// Constructs an I2C message with the I2C device address [addr],
  /// [flags] list and a [predefined] transfer buffer. An empty
  /// [flags] list results [NativeI2Cmsg.flags] = 0.
  /// The message flags specify whether the message is a read (I2C_M_RD) or write (0) transaction, as well
  /// as additional options selected by the bitwise OR of their bitmasks.
  I2Cmsg.buffer(this.addr, this.flags, this.predefined)
      : len = predefined.length {}

  static Pointer<NativeI2Cmsg> _toNative(List<I2Cmsg> list) {
    final Pointer<NativeI2Cmsg> ptr =
        allocate<NativeI2Cmsg>(count: list.length);
    int index = 0;
    for (I2Cmsg data in list) {
      Pointer<NativeI2Cmsg> msg = ptr.elementAt(index++);
      msg.ref.addr = data.addr;
      msg.ref.len = data.len;
      int flags = 0;
      if (data.flags.isNotEmpty) {
        for (I2CmsgFlags f in data.flags) {
          flags |= I2CmsgFlags2Int(f);
        }
      }
      msg.ref.flags = flags;
      msg.ref.buf = allocate<Int8>(count: data.len);
      if (data.predefined.isNotEmpty) {
        int count = 0;
        for (int value in data.predefined) {
          msg.ref.buf.elementAt(count++).value = value;
        }
      }
    }
    return ptr;
  }
}

/// I2C error codes
enum I2CerrorCode {
  /// Error code for not able to map the native C enum
  ERROR_CODE_NOT_MAPPABLE,

  /// Invalid arguments
  I2C_ERROR_ARG,

  /// Opening I2C device
  I2C_ERROR_OPEN,

  /// Querying I2C device attributes
  I2C_ERROR_QUERY,

  /// I2C not supported on this device

  I2C_ERROR_NOT_SUPPORTED,

  /// I2C transfer
  I2C_ERROR_TRANSFER,

  /// Closing I2C device
  I2C_ERROR_CLOSE
}

/// Converts the native error code [value] to [I2CerrorCode].
I2CerrorCode getI2CerrorCode(int value) {
  // must be negative
  if (value >= 0) {
    return I2CerrorCode.ERROR_CODE_NOT_MAPPABLE;
  }
  value = -value;

  // check range
  if (value > I2CerrorCode.I2C_ERROR_CLOSE.index) {
    return I2CerrorCode.ERROR_CODE_NOT_MAPPABLE;
  }

  return I2CerrorCode.values[value];
}

int _checkError(int value) {
  if (value < 0) {
    I2CerrorCode errorCode = getI2CerrorCode(value);
    throw I2Cexception(errorCode, errorCode.toString());
  }
  return value;
}

// I2C exception
class I2Cexception implements Exception {
  final I2CerrorCode errorCode;
  final String errorMsg;
  I2Cexception(this.errorCode, this.errorMsg);
  I2Cexception.errorCode(int code, Pointer<Void> handle)
      : errorCode = getI2CerrorCode(code),
        errorMsg = _getErrmsg(handle);
  @override
  String toString() => errorMsg;
}

final DynamicLibrary _peripheryLib = getPeripheryLib();

// i2c_t* dart_i2c_open(const char *path)
typedef _dart_i2c_open = Pointer<Void> Function(Pointer<Utf8> path);
typedef _I2Copen = Pointer<Void> Function(Pointer<Utf8> path);
final _nativeOpen = _peripheryLib
    .lookup<NativeFunction<_dart_i2c_open>>('dart_i2c_open')
    .asFunction<_I2Copen>();

// int dart_i2c_dispose(i2c_t *i2c)
typedef _dart_i2c_dispose = Int32 Function(Pointer<Void> handle);
typedef _I2Cdispose = int Function(Pointer<Void> handle);
final _nativeDispose = _peripheryLib
    .lookup<NativeFunction<_dart_i2c_dispose>>('dart_i2c_dispose')
    .asFunction<_I2Cdispose>();

// int dart_i2c_errno(i2c_t *i2c)
typedef _dart_i2c_errno = Int32 Function(Pointer<Void> handle);
typedef _I2Cerrno = int Function(Pointer<Void> handle);
final _nativeErrno = _peripheryLib
    .lookup<NativeFunction<_dart_i2c_errno>>('dart_i2c_errno')
    .asFunction<_I2Cerrno>();

// const char *dart_i2c_errmsg(i2c_t *i2c)
typedef _dart_i2c_errmsg = Pointer<Utf8> Function(Pointer<Void> length);
typedef _I2Cerrmsg = Pointer<Utf8> Function(Pointer<Void> length);
final _nativeErrmsg = _peripheryLib
    .lookup<NativeFunction<_dart_i2c_errmsg>>('dart_i2c_errmsg')
    .asFunction<_I2Cerrmsg>();

//  int dart_i2c_transfer(i2c_t *i2c, struct i2c_msg *msgs, size_t count)
typedef _dart_i2c_transfer = Int32 Function(
    Pointer<Void> handle, Pointer<NativeI2Cmsg>, Int32 length);
typedef _I2Ctransfer = int Function(
    Pointer<Void> handle, Pointer<NativeI2Cmsg>, int length);
final _nativeTransfer = _peripheryLib
    .lookup<NativeFunction<_dart_i2c_transfer>>('dart_i2c_transfer')
    .asFunction<_I2Ctransfer>();

// int dart_i2c_fd(i2c_t *i2c)
typedef _dart_i2c_fd = Int32 Function(Pointer<Void> handle);
typedef _I2Cfd = int Function(Pointer<Void> handle);
final _nativeFD = _peripheryLib
    .lookup<NativeFunction<_dart_i2c_fd>>('dart_i2c_fd')
    .asFunction<_I2Cfd>();

// char *dart_i2c_info(i2c_t *i2c)
typedef _dart_i2c_info = Pointer<Utf8> Function(Pointer<Void> handle);
typedef _I2Cinfo = Pointer<Utf8> Function(Pointer<Void> handle);
final _nativeInfo = _peripheryLib
    .lookup<NativeFunction<_dart_i2c_info>>('dart_i2c_info')
    .asFunction<_I2Cinfo>();

String _getErrmsg(Pointer<Void> handle) {
  return Utf8.fromUtf8(_nativeErrmsg(handle));
}

/// I2C wrapper functions for Linux userspace i2c-dev devices.
class I2C {
  static const String _i2cBasePath = "/dev/i2c-";
  Pointer<Void> _i2cHandle;
  final String path;
  final int busNum;
  bool _invalid = false;

  /// Opens the i2c-dev device at the specified path (e.g. "/dev/i2c-[busNum]").
  I2C(this.busNum) : path = _i2cBasePath + busNum.toString() {
    _i2cHandle = _checkHandle(_nativeOpen(Utf8.toUtf8(path)));
  }

  void _checkStatus() {
    if (_invalid) {
      throw I2Cexception(I2CerrorCode.I2C_ERROR_CLOSE,
          "I2C interface has the status released.");
    }
  }

  Pointer<Void> _checkHandle(Pointer<Void> handle) {
    // handle 0 indicates an internal error
    if (handle.address == 0) {
      throw I2Cexception(I2CerrorCode.I2C_ERROR_OPEN, 'Error opening I2C bus');
    }
    return handle;
  }

  /// Transfers a list of [I2Cmsg].
  ///
  /// Each I2C message structure  specifies the transfer of a consecutive number of bytes to a slave address.
  /// The slave address, message flags, buffer length, and pointer to a byte buffer should be specified in each message.
  /// The message flags specify whether the message is a read (I2C_M_RD) or write (0) transaction, as well
  ///  as additional options selected by the bitwise OR of their bitmasks.
  ///
  /// Returns a [NativeI2CmsgHelper] which contains  the [NativeI2Cmsg] list. To free the allocated memory
  /// resources [NativeI2Cmsg.allocate()] must be called by the user.
  NativeI2CmsgHelper transfer(List<I2Cmsg> data) {
    _checkStatus();
    Pointer<NativeI2Cmsg> nativeMsg = I2Cmsg._toNative(data);
    _checkError(_nativeTransfer(_i2cHandle, nativeMsg, data.length));
    return NativeI2CmsgHelper(nativeMsg, data.length);
  }

  /// Writes a [byteValue] to the I2C device with the [address].
  void writeByte(int address, int byteValue) {
    List<I2Cmsg> data = [];
    data.add(I2Cmsg.buffer(address, [], [byteValue]));
    NativeI2CmsgHelper result = transfer(data);
    result.dispose();
  }

  /// Writes a [byteValue] to the [register] of the I2C device with the [address].
  void writeByteReg(int address, int register, int byteValue) {
    List<I2Cmsg> data = [];
    data.add(I2Cmsg.buffer(address, [], [register]));
    data.add(I2Cmsg.buffer(address, [], [byteValue]));
    NativeI2CmsgHelper result = transfer(data);
    result.dispose();
  }

  /// Writes a list of [byteValue] to the [register] of the I2C device with the [address].
  void writeBytesReg(int address, int register, List<int> byteValue) {
    List<I2Cmsg> data = [];
    data.add(I2Cmsg.buffer(address, [], [register]));
    data.add(I2Cmsg.buffer(address, [], byteValue));
    NativeI2CmsgHelper result = transfer(data);
    result.dispose();
  }

  /// Writes a [wordValue] to the I2C device with the [address].
  void writeWord(int address, int wordValue) {
    List<I2Cmsg> data = [];
    data.add(I2Cmsg.buffer(address, [], [wordValue | 0xff, wordValue >> 8]));
    NativeI2CmsgHelper result = transfer(data);
    result.dispose();
  }

  /// Writes a [wordValue] to the [register] of the I2C device with the [address].
  void writeWordReg(int address, int register, int wordValue) {
    List<I2Cmsg> data = [];
    data.add(I2Cmsg.buffer(address, [], [register]));
    data.add(I2Cmsg.buffer(address, [], [wordValue | 0xff, wordValue >> 8]));
    NativeI2CmsgHelper result = transfer(data);
    result.dispose();
  }

  /// Reads a byte from the I2C device with the [address].
  int readByte(int address) {
    List<I2Cmsg> data = [];
    data.add(I2Cmsg(address, [I2CmsgFlags.I2C_M_RD], 1));
    NativeI2CmsgHelper result = transfer(data);
    try {
      Pointer<Int8> ptr = result._messages.elementAt(0).ref.buf;
      int value = ptr.elementAt(0).value & 0xff;
      return value;
    } finally {
      result.dispose();
    }
  }

  /// Reads a byte from [register] of the I2C device with the [address].
  int readByteReg(int address, int register) {
    List<I2Cmsg> data = [];
    data.add(I2Cmsg.buffer(address, [], [register]));
    data.add(I2Cmsg(address, [I2CmsgFlags.I2C_M_RD], 1));
    NativeI2CmsgHelper result = transfer(data);
    try {
      Pointer<Int8> ptr = result._messages.elementAt(1).ref.buf;
      int value = ptr.elementAt(0).value & 0xff;
      return value;
    } finally {
      result.dispose();
    }
  }

  /// Reads a word from the I2C device with the [address].
  int readWord(int address) {
    List<I2Cmsg> data = [];
    data.add(I2Cmsg(address, [I2CmsgFlags.I2C_M_RD], 2));
    NativeI2CmsgHelper result = transfer(data);
    try {
      Pointer<Int8> ptr = result._messages.elementAt(0).ref.buf;
      int value = (ptr.elementAt(0).value & 0xff) +
          (ptr.elementAt(1).value & 0xff) * 256;
      return value;
    } finally {
      result.dispose();
    }
  }

  /// Reads a [len] bytes from [register] of the I2C device with the [address].
  List<int> readBytesReg(int address, int register, int len) {
    List<I2Cmsg> data = [];
    data.add(I2Cmsg.buffer(address, [], [register]));
    data.add(I2Cmsg(address, [I2CmsgFlags.I2C_M_RD], len));

    NativeI2CmsgHelper result = transfer(data);
    NativeI2Cmsg msg2 = result._messages.elementAt(1).ref;
    try {
      int read = msg2.len;

      Pointer<Int8> ptr = msg2.buf;
      List<int> list = [];
      for (int i = 0; i < read; ++i) {
        list.add(ptr.elementAt(i).value & 0xff);
      }
      return list;
    } finally {
      result.dispose();
    }
  }

  /// Releases all interal native resoures.
  void dispose() {
    _checkStatus();
    _invalid = true;
    _checkError(_nativeDispose(_i2cHandle));
  }

  /// Returns the file descriptor (for the underlying i2c-dev device) of the I2C handle.
  int getSerialFD() {
    _checkStatus();
    return _checkError(_nativeFD(_i2cHandle));
  }

  /// Returns a string representation of the I2C handle.
  String getI2Cinfo() {
    _checkStatus();
    final Pointer<Utf8> ptr = _nativeInfo(_i2cHandle);
    if (ptr.address == 0) {
      // throw an exception
      _checkError(getErrno());
      return "?";
    }
    String text = Utf8.fromUtf8(ptr);
    free(ptr);
    return text;
  }

  /// Returns the libc errno of the last failure that occurred.
  int getErrno() {
    _checkStatus();
    return _nativeErrno(_i2cHandle);
  }
}
