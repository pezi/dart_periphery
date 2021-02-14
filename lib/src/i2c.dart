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
    var index = 0;
    for (var i = 0; i < size; ++i) {
      var msg = _messages.elementAt(index++);
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
  I2Cmsg(this.addr, this.flags, this.len) : predefined = const [];

  /// Constructs an I2C message with the I2C device address [addr],
  /// [flags] list and a [predefined] transfer buffer. An empty
  /// [flags] list results [NativeI2Cmsg.flags] = 0.
  /// The message flags specify whether the message is a read (I2C_M_RD) or write (0) transaction, as well
  /// as additional options selected by the bitwise OR of their bitmasks.
  I2Cmsg.buffer(this.addr, this.flags, this.predefined)
      : len = predefined.length;

  static Pointer<NativeI2Cmsg> _toNative(List<I2Cmsg> list) {
    final ptr = allocate<NativeI2Cmsg>(count: list.length);
    var index = 0;
    for (var data in list) {
      var msg = ptr.elementAt(index++);
      msg.ref.addr = data.addr;
      msg.ref.len = data.len;
      var flags = 0;
      if (data.flags.isNotEmpty) {
        for (var f in data.flags) {
          flags |= I2CmsgFlags2Int(f);
        }
      }
      msg.ref.flags = flags;
      msg.ref.buf = allocate<Int8>(count: data.len);
      if (data.predefined.isNotEmpty) {
        var count = 0;
        for (var value in data.predefined) {
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
    var errorCode = getI2CerrorCode(value);
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
final _nativeOpen = voidUtf8M('dart_i2c_open');

// int dart_i2c_dispose(i2c_t *i2c)
final _nativeDispose = intVoidM('dart_i2c_dispose');

// int dart_i2c_errno(i2c_t *i2c)
final _nativeErrno = _peripheryLib
    .lookup<NativeFunction<intVoidS>>('dart_i2c_errno')
    .asFunction<intVoidF>();

// const char *dart_i2c_errmsg(i2c_t *i2c)
final _nativeErrmsg = _peripheryLib
    .lookup<NativeFunction<utf8VoidS>>('dart_i2c_errmsg')
    .asFunction<utf8VoidF>();

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
final _nativeInfo = utf8VoidM('dart_i2c_info');

String _getErrmsg(Pointer<Void> handle) {
  return Utf8.fromUtf8(_nativeErrmsg(handle));
}

/// I2C wrapper functions for Linux userspace i2c-dev devices.
class I2C {
  static const String _i2cBasePath = '/dev/i2c-';
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
          'I2C interface has the status released.');
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
    var nativeMsg = I2Cmsg._toNative(data);
    _checkError(_nativeTransfer(_i2cHandle, nativeMsg, data.length));
    return NativeI2CmsgHelper(nativeMsg, data.length);
  }

  /// Writes a [byteValue] to the I2C device with the [address].
  void writeByte(int address, int byteValue) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg.buffer(address, [], [byteValue]));
    var result = transfer(data);
    result.dispose();
  }

  /// Writes a [byteValue] to the [register] of the I2C device with the [address].
  void writeByteReg(int address, int register, int byteValue) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg.buffer(address, [], [register]));
    data.add(I2Cmsg.buffer(address, [], [byteValue]));
    var result = transfer(data);
    result.dispose();
  }

  /// Writes a list of [byteValue] to the [register] of the I2C device with the [address].
  void writeBytesReg(int address, int register, List<int> byteValue) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg.buffer(address, [], [register]));
    data.add(I2Cmsg.buffer(address, [], byteValue));
    var result = transfer(data);
    result.dispose();
  }

  /// Writes a [wordValue] to the I2C device with the [address].
  void writeWord(int address, int wordValue) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg.buffer(address, [], [wordValue | 0xff, wordValue >> 8]));
    var result = transfer(data);
    result.dispose();
  }

  /// Writes a [wordValue] to the [register] of the I2C device with the [address].
  void writeWordReg(int address, int register, int wordValue) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg.buffer(address, [], [register]));
    data.add(I2Cmsg.buffer(address, [], [wordValue | 0xff, wordValue >> 8]));
    var result = transfer(data);
    result.dispose();
  }

  /// Reads a byte from the I2C device with the [address].
  int readByte(int address) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg(address, [I2CmsgFlags.I2C_M_RD], 1));
    var result = transfer(data);
    try {
      var ptr = result._messages.elementAt(0).ref.buf;
      var value = ptr.elementAt(0).value;
      return value;
    } finally {
      result.dispose();
    }
  }

  /// Reads a byte from [register] of the I2C device with the [address].
  int readByteReg(int address, int register) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg.buffer(address, [], [register]));
    data.add(I2Cmsg(address, [I2CmsgFlags.I2C_M_RD], 1));
    var result = transfer(data);
    try {
      var ptr = result._messages.elementAt(1).ref.buf;
      var value = ptr.elementAt(0).value;

      return value;
    } finally {
      result.dispose();
    }
  }

  /// Reads a word from the I2C device with the [address].
  int readWord(int address) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg(address, [I2CmsgFlags.I2C_M_RD], 2));
    var result = transfer(data);
    try {
      var ptr = result._messages.elementAt(0).ref.buf;
      var value = (ptr.elementAt(0).value & 0xff) |
          (ptr.elementAt(1).value & 0xff) << 8;
      return value;
    } finally {
      result.dispose();
    }
  }

  /// Reads a [len] bytes from [register] of the I2C device with the [address].
  List<int> readBytesReg(int address, int register, int len) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg.buffer(address, [], [register]));
    data.add(I2Cmsg(address, [I2CmsgFlags.I2C_M_RD], len));

    var result = transfer(data);
    var msg2 = result._messages.elementAt(1).ref;
    try {
      var read = msg2.len;

      var ptr = msg2.buf;
      var list = <int>[];
      for (var i = 0; i < read; ++i) {
        list.add(ptr.elementAt(i).value);
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
  int getI2Cfd() {
    _checkStatus();
    return _checkError(_nativeFD(_i2cHandle));
  }

  /// Returns a string representation of the I2C handle.
  String getI2Cinfo() {
    _checkStatus();
    final ptr = _nativeInfo(_i2cHandle);
    if (ptr.address == 0) {
      // throw an exception
      _checkError(getErrno());
      return '?';
    }
    var text = Utf8.fromUtf8(ptr);
    free(ptr);
    return text;
  }

  /// Returns the libc errno of the last failure that occurred.
  int getErrno() {
    _checkStatus();
    return _nativeErrno(_i2cHandle);
  }
}
