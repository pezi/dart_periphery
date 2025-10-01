// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/vsergeev/c-periphery/blob/master/docs/i2c.md
// https://github.com/vsergeev/c-periphery/blob/master/src/i2c.c
// https://github.com/vsergeev/c-periphery/blob/master/src/i2c.h
// https://github.com/dart-lang/samples/tree/master/ffi

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'hardware/utils/byte_buffer.dart';
import 'isolate_api.dart';
import 'json.dart';
import 'library.dart';
import 'signature.dart';

/// I2C register width, 8 or 16 bits - I2C EEPROMs support 16-bit registers
enum RegisterWidth { bits8, bits16 }

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

/// [I2C] native i2c_msg flags from `<linux/i2c.h>` - converted only to lower case
/// camel case looks a little strange
enum I2CmsgFlags {
  // ignore: constant_identifier_names
  i2c_m_ten,
  // ignore: constant_identifier_names
  i2c_m_rd,
  // ignore: constant_identifier_names
  i2c_m_stop,
  // ignore: constant_identifier_names
  i2c_m_nostart,
  // ignore: constant_identifier_names
  i2c_m_rev_dir_addr,
  // ignore: constant_identifier_names
  i2c_m_ignore_nak,
  // ignore: constant_identifier_names
  i2c_m_no_rd_ack,
  // ignore: constant_identifier_names
  i2c_m_recv_len
}

/// Helper class mapped to the C struct i2c_msg
base class NativeI2Cmsg extends Struct {
  @Int16()
  external int addr;
  @Int16()
  external int flags;
  @Int16()
  external int len;
  external Pointer<Uint8> buf;

  @override
  String toString() {
    StringBuffer ret = StringBuffer();
    ret.write(
        "address: ${addr.toRadixString(16)} flags: $flags len: $len buf:");
    for (int i = 0; i < len; ++i) {
      ret.write(" ");
      ret.write((buf[i] & 0xff).toRadixString(16));
    }
    return ret.toString();
  }
}

/// Helper class which stores an array of native 'struct i2c_msg' messages.
/// The user must call [NativeI2CmsgHelper.dispose] to free the allocated
/// memory.
class NativeI2CmsgHelper {
  final Pointer<NativeI2Cmsg> _messages;
  final int size;
  bool _isFreed = false;
  NativeI2CmsgHelper(this._messages, this.size);

  /// Returns a `Pointer<NativeI2Cmsg>` to the native memory structures.
  Pointer<NativeI2Cmsg> getMessages() {
    if (_isFreed) {
      throw I2Cexception(I2CerrorCode.i2cErrorClose,
          "Not allowed access to a 'dispose()'ed memory structure.");
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
      var msg = _messages[index++];
      if (msg.buf != nullptr) {
        malloc.free(msg.buf);
      }
    }
    malloc.free(_messages);
  }
}

/// I2Cmsg - container for the native [NativeI2Cmsg] struct.
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
  ///
  /// The message flags specify whether the message is a read (I2C_M_RD) or
  /// write (0) transaction, as well as additional options selected by the
  /// bitwise OR of their bitmasks.
  I2Cmsg(this.addr, this.flags, this.len) : predefined = const [];

  /// Constructs an I2C message with the I2C device address [addr],
  /// [flags] list and a [predefined] transfer buffer. An empty
  /// [flags] list results [NativeI2Cmsg.flags] = 0.
  ///
  /// The message flags specify whether the message is a read (I2C_M_RD) or
  /// write (0) transaction, as well as additional options selected by the
  /// bitwise OR of their bitmasks.
  I2Cmsg.buffer(this.addr, this.flags, this.predefined)
      : len = predefined.length;

  static Pointer<NativeI2Cmsg> _toNative(List<I2Cmsg> list) {
    final ptr = malloc<NativeI2Cmsg>(list.length);
    var index = 0;
    for (var data in list) {
      var msg = ptr[index++];
      msg.addr = data.addr;
      msg.len = data.len;
      var flags = 0;
      if (data.flags.isNotEmpty) {
        for (var f in data.flags) {
          flags |= I2C.i2cMsgFlags2Int(f);
        }
      }
      msg.flags = flags;
      msg.buf = malloc<Uint8>(data.len);
      if (data.predefined.isNotEmpty) {
        var count = 0;
        for (var value in data.predefined) {
          msg.buf[count++] = value;
        }
      } else {
        for (int i = 0; i < data.len; ++i) {
          msg.buf[i] = 0;
        }
      }
    }

    return ptr;
  }
}

/// [I2C] error codes
enum I2CerrorCode {
  /// Error code for not able to map the native C enum
  errorCodeNotMappable,

  /// Invalid arguments
  i2cErrorArg,

  /// Opening I2C device
  i2cErrorOpen,

  /// Querying I2C device attributes
  i2cErrorQuery,

  /// I2C not supported on this device

  i2cErrorNotSupported,

  /// I2C transfer
  i2cErrorTransfer,

  /// Closing I2C device
  i2cErrorClose
}

const bufferLen = 256;

int _checkError(int value) {
  if (value < 0) {
    var errorCode = I2C.getI2CerrorCode(value);
    throw I2Cexception(errorCode, errorCode.toString());
  }
  return value;
}

/// [I2C] exception
class I2Cexception implements Exception {
  final I2CerrorCode errorCode;
  final String errorMsg;
  I2Cexception.empty()
      : errorCode = I2CerrorCode.errorCodeNotMappable,
        errorMsg = '';
  I2Cexception(this.errorCode, this.errorMsg);
  I2Cexception.errorCode(int code, Pointer<Void> handle)
      : errorCode = I2C.getI2CerrorCode(code),
        errorMsg = _getErrmsg(handle);
  @override
  String toString() => errorMsg;
}

final DynamicLibrary _peripheryLib = loadPeripheryLib();

// i2c_t *i2c_new(void);
final _nativeI2Cnew = voidPtrVOIDM('i2c_new');

//int i2c_open(i2c_t *i2c, const char *path);
final _nativeI2Copen = voidVoidUtf8M('i2c_open');

// int i2c_close(led_t *led);
final _nativeI2Cclose = intVoidM('i2c_close');

//  void i2c_free(i2c_t *i2c);
final _nativeI2Cfree = voidVoidM('i2c_free');

// int i2c_errno(i2c_t *i2c);
final _nativeI2Cerrno = intVoidM('i2c_errno');

// const char *i2c_errmsg(i2c_t *i2c);
final _nativeI2CerrnMsg = utf8VoidM('i2c_errmsg');

// int i2c_tostring(i2c_t *led, char *str, size_t len);
final _nativeI2Cinfo = intVoidUtf8sizeTM('i2c_tostring');

// int i2c_fd(i2c_t *i2c);
final _nativeI2Cfd = intVoidM('i2c_fd');

//  int i2c_transfer(i2c_t *i2c, struct i2c_msg *msgs, size_t count);
// ignore: camel_case_types
typedef _i2cTransfer = Int32 Function(
    Pointer<Void> handle, Pointer<NativeI2Cmsg> mgs, IntPtr count);
typedef _I2Ctransfer = int Function(
    Pointer<Void> handle, Pointer<NativeI2Cmsg> mgs, int count);
final _nativeI2ctransfer = _peripheryLib
    .lookup<NativeFunction<_i2cTransfer>>('i2c_transfer')
    .asFunction<_I2Ctransfer>();

String _getErrmsg(Pointer<Void> handle) {
  return _nativeI2CerrnMsg(handle).toDartString();
}

/// I2C wrapper functions for Linux userspace i2c-dev devices.
///
/// c-periphery [I2C](https://github.com/vsergeev/c-periphery/blob/master/docs/i2c.md)
/// documentation.
class I2C extends IsolateAPI {
  static const String _i2cBasePath = '/dev/i2c-';
  late Pointer<Void> _i2cHandle;
  late Pointer<Utf8> _nativeName;
  final String path;
  final int busNum;
  bool _invalid = false;

  /// Opens the i2c-dev device at the specified path (e.g. "/dev/i2c-[busNum]").
  I2C(this.busNum) : path = _i2cBasePath + busNum.toString() {
    var tupple = _openI2C(_i2cBasePath + busNum.toString());
    _i2cHandle = tupple.$1;
    _nativeName = tupple.$2;
  }

  /// Duplicates an existing [I2C] from a JSON string. This special constructor
  /// is used to transfer an existing [I2C] to an other isolate.
  I2C.isolate(String json)
      : path = jsonMap(json)['path'] as String,
        busNum = jsonMap(json)['bus'] as int,
        _i2cHandle = Pointer<Void>.fromAddress(jsonMap(json)['handle'] as int),
        _nativeName = Pointer<Utf8>.fromAddress(jsonMap(json)['name'] as int);

  /// Converts a [I2C] to a JSON string. See constructor [isolate] for details.
  @override
  String toJson() {
    return '{"class":"I2C","path":"$path","bus":$busNum,"handle":${_i2cHandle.address},"name":${_nativeName.address}}';
  }

  void _checkStatus() {
    if (_invalid) {
      throw I2Cexception(
          I2CerrorCode.i2cErrorClose, 'I2C interface has the status released.');
    }
  }

  static (Pointer<Void>, Pointer<Utf8>) _openI2C(String path) {
    var i2cHandle = _nativeI2Cnew();
    if (i2cHandle == nullptr) {
      return throw I2Cexception(
          I2CerrorCode.i2cErrorOpen, 'Error opening I2C bus');
    }
    var nativePath = path.toNativeUtf8();
    try {
      _checkError(_nativeI2Copen(i2cHandle, nativePath));
    } catch (_) {
      _nativeI2Cfree(i2cHandle);
      malloc.free(nativePath);
      rethrow;
    }
    return (i2cHandle, nativePath);
  }

  /// Converts the native error code [value] to [I2CerrorCode].
  static I2CerrorCode getI2CerrorCode(int value) {
    // must be negative
    if (value >= 0) {
      return I2CerrorCode.errorCodeNotMappable;
    }
    value = -value;

    // check range
    if (value > I2CerrorCode.i2cErrorClose.index) {
      return I2CerrorCode.errorCodeNotMappable;
    }

    return I2CerrorCode.values[value];
  }

  /// Converts [I2CmsgFlags] to the native bit mask value.
  static int i2cMsgFlags2Int(I2CmsgFlags flag) {
    switch (flag) {
      case I2CmsgFlags.i2c_m_ten:
        return 0x0010;
      case I2CmsgFlags.i2c_m_rd:
        return 0x0001;
      case I2CmsgFlags.i2c_m_stop:
        return 0x8000;
      case I2CmsgFlags.i2c_m_nostart:
        return 0x4000;
      case I2CmsgFlags.i2c_m_rev_dir_addr:
        return 0x2000;
      case I2CmsgFlags.i2c_m_ignore_nak:
        return 0x1000;
      case I2CmsgFlags.i2c_m_no_rd_ack:
        return 0x0800;
      case I2CmsgFlags.i2c_m_recv_len:
        return 0x0400;
    }
  }

  /// Transfers a list of [I2Cmsg].
  ///
  /// Each I2C message structure  specifies the transfer of a consecutive
  ///  number of bytes to a slave address.
  /// The slave address, message flags, buffer length, and pointer to a byte
  ///  buffer should be specified in each message.
  /// The message flags specify whether the message is a read (I2C_M_RD) or
  /// write (0) transaction, as well as additional options selected by the
  /// bitwise OR of their bitmasks.
  ///
  /// Returns a [NativeI2CmsgHelper] which contains  the [NativeI2Cmsg] list.
  /// To free the allocated memory
  /// resources [NativeI2CmsgHelper.dispose] must be called by the user.
  NativeI2CmsgHelper transfer(List<I2Cmsg> data) {
    _checkStatus();
    var nativeMsg = I2Cmsg._toNative(data);
    try {
      _checkError(_nativeI2ctransfer(_i2cHandle, nativeMsg, data.length));
    } catch (_) {
      NativeI2CmsgHelper(nativeMsg, data.length).dispose();
      rethrow;
    }
    return NativeI2CmsgHelper(nativeMsg, data.length);
  }

  /// Writes a [byteValue] to the I2C device with the [address].
  ///
  /// Some I2C devices can directly be written without an explicit register.
  void writeByte(int address, int byteValue) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg.buffer(address, [], [byteValue]));
    var result = transfer(data);
    result.dispose();
  }

  /// Helper method to handle [resgisters]´s bit [order]/ [width].
  List<int> _adjustRegister(int register, BitOrder order, RegisterWidth width) {
    if (width == RegisterWidth.bits8) {
      if (register > 0xFF) {
        throw FormatException(
            'Parameter register doesn´t fit 8-bit I2C register');
      }
      return [register];
    }
    if (register > 0xFFFF) {
      throw FormatException(
          'Parameter register doesn´t fit 16-bit I2C register');
    }
    if (order == BitOrder.msbLast) {
      return [
        register & 0xFF,
        register >> 8,
      ];
    }
    return [
      register >> 8,
      register & 0xFF,
    ];
  }

  /// Writes a [byteValue] to the [register] of the I2C device with
  /// the [address].  The optional register
  /// parameters bit [order]/[width] enables 16-bit register.
  ///
  /// The bit [order] depends on the I2C device.
  void writeByteReg(int address, int register, int byteValue,
      [BitOrder order = BitOrder.msbLast,
      RegisterWidth width = RegisterWidth.bits8]) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg.buffer(
        address, [], [..._adjustRegister(register, order, width), byteValue]));
    var result = transfer(data);
    result.dispose();
  }

  /// Writes [byteData] to the [register] of the I2C device with the [address]
  /// The optional register parameters bit [order]/[width] enables 16-bit registers.
  ///
  /// The bit [order] depends on the I2C device.
  void writeBytesReg(int address, int register, List<int> byteData,
      [BitOrder order = BitOrder.msbLast,
      RegisterWidth width = RegisterWidth.bits8]) {
    var data = <I2Cmsg>[];
    var bData = <int>[];
    bData.addAll(_adjustRegister(register, order, width));
    bData.addAll(byteData);
    data.add(I2Cmsg.buffer(address, [], bData));
    var result = transfer(data);
    result.dispose();
  }

  void writeUint8Reg(int address, int register, Uint8List byteData,
      [BitOrder order = BitOrder.msbLast,
      RegisterWidth width = RegisterWidth.bits8]) {
    var data = <I2Cmsg>[];
    var reg = _adjustRegister(register, order, width);
    var bData = Uint8List(reg.length + byteData.length);
    bData.addAll(reg);
    bData.addAll(byteData);
    data.add(I2Cmsg.buffer(address, [], bData));
    var result = transfer(data);
    result.dispose();
  }

  // Uint8List

  /// Writes [byteData] to the I2C device with the [address].
  ///
  /// Some I2C devices can directly be written without an explicit register.
  void writeBytes(int address, List<int> byteData) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg.buffer(address, [], byteData));
    var result = transfer(data);
    result.dispose();
  }

  /// Writes a [wordValue] to the I2C device with the [address] and the
  /// bit [order].
  ///
  /// Some I2C devices can directly be written without an explicit register.
  void writeWord(int address, int wordValue,
      [BitOrder order = BitOrder.msbLast]) {
    var data = <I2Cmsg>[];
    var array = <int>[];
    if (order == BitOrder.msbLast) {
      array = [wordValue & 0xff, wordValue >> 8];
    } else {
      array = [wordValue >> 8, wordValue & 0xff];
    }
    data.add(I2Cmsg.buffer(address, [], array));
    var result = transfer(data);
    result.dispose();
  }

  /// Writes a [wordValue] to the [register] of the I2C device with
  /// the [address] and the bit [order]. The optional register
  /// parameters bit [width] enables 16-bit register.
  ///
  /// The bit [order] depends on the I2C device.
  void writeWordReg(int address, int register, int wordValue,
      [BitOrder order = BitOrder.msbLast,
      RegisterWidth width = RegisterWidth.bits8]) {
    var data = <I2Cmsg>[];
    var array = <int>[];
    array.addAll(_adjustRegister(register, order, width));
    if (order == BitOrder.msbLast) {
      array.add(wordValue & 0xff);
      array.add(wordValue >> 8);
    } else {
      array.add(wordValue >> 8);
      array.add(wordValue & 0xff);
    }
    data.add(I2Cmsg.buffer(address, [], array));
    var result = transfer(data);
    result.dispose();
  }

  /// Reads a word from the I2C device with the [address] and the bit [order]].
  ///
  /// The optional register parameters bit [width] enables 16-bit register.
  ///
  /// Some I2C devices can directly be read without an explicit register.
  /// The bit [order] depends on the I2C device.
  int readWord(int address,
      [BitOrder order = BitOrder.msbLast,
      RegisterWidth width = RegisterWidth.bits8]) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg(address, [I2CmsgFlags.i2c_m_rd], 2));
    var result = transfer(data);
    try {
      var ptr = result._messages[0].buf;
      var value = (ptr[(order == BitOrder.msbLast ? 0 : 1)] & 0xff) |
          (ptr[(order == BitOrder.msbLast ? 1 : 0)] & 0xff) << 8;
      return value;
    } finally {
      result.dispose();
    }
  }

  // int swapBytes16(int value) {
  //  return ((value & 0xFF) << 8) | ((value >> 8) & 0xFF);
  // }

  /// Reads a word from [register] of the I2C device with the [address] with the
  ///  bit [order].
  ///
  /// The optional register parameters bit [width] enables 16-bit register.
  ///
  /// The bit [order] depends on the I2C device.
  int readWordReg(int address, int register,
      [BitOrder order = BitOrder.msbLast,
      RegisterWidth width = RegisterWidth.bits8]) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg.buffer(
        address, [], [..._adjustRegister(register, order, width)]));
    data.add(I2Cmsg(address, [I2CmsgFlags.i2c_m_rd], 2));
    var result = transfer(data);
    try {
      var ptr = result._messages[1].buf;
      var value = (ptr[(order == BitOrder.msbLast ? 0 : 1)] & 0xff) |
          (ptr[(order == BitOrder.msbLast ? 1 : 0)] & 0xff) << 8;
      return value;
    } finally {
      result.dispose();
    }
  }

  /// Reads a byte from the I2C device with the [address]. The optional register
  /// parameters bit [order]/[width] enables 16-bit register.
  ///
  /// Some I2C devices can directly be read without explicit register.
  /// The bit [order] depends on the I2C device.
  int readByte(int address) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg(address, [I2CmsgFlags.i2c_m_rd], 1));
    var result = transfer(data);
    try {
      var ptr = result._messages[0].buf;
      var value = ptr[0];
      return value;
    } finally {
      result.dispose();
    }
  }

  /// Reads a byte from [register] of the I2C device with the [address].
  ///
  /// The optional register parameters bit [order]/[width] enables
  /// 16-bit register.
  ///
  /// The bit [order] depends on the I2C device.
  int readByteReg(int address, int register,
      [BitOrder order = BitOrder.msbLast,
      RegisterWidth width = RegisterWidth.bits8]) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg.buffer(
        address, [], [..._adjustRegister(register, order, width)]));
    data.add(I2Cmsg(address, [I2CmsgFlags.i2c_m_rd], 1));
    var result = transfer(data);
    try {
      var ptr = result._messages[1].buf;
      var value = ptr[0];
      return value;
    } finally {
      result.dispose();
    }
  }

  /// Reads [len] bytes from [register] of the I2C device with the [address].
  ///
  /// The optional register parameters bit [order]/[width] enables
  /// 16-bit register.
  ///
  /// Some I2C devices can directly be read without explicit register.
  /// The bit [order] depends on the I2C device.
  List<int> readBytesReg(int address, int register, int len,
      [BitOrder order = BitOrder.msbLast,
      RegisterWidth width = RegisterWidth.bits8]) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg.buffer(
        address, [], [..._adjustRegister(register, order, width)]));
    data.add(I2Cmsg(address, [I2CmsgFlags.i2c_m_rd], len));

    var result = transfer(data);
    var msg2 = result._messages[1];
    try {
      var read = msg2.len;
      var ptr = msg2.buf;
      var list = <int>[];
      for (var i = 0; i < read; ++i) {
        list.add(ptr[i]);
      }
      return list;
    } finally {
      result.dispose();
    }
  }

  /// Reads [len] bytes from the I2C device with the [address].
  List<int> readBytes(int address, int len) {
    var data = <I2Cmsg>[];
    data.add(I2Cmsg(address, [I2CmsgFlags.i2c_m_rd], len));
    var result = transfer(data);
    var msg2 = result._messages[0];
    try {
      var read = msg2.len;
      var ptr = msg2.buf;
      var list = <int>[];
      for (var i = 0; i < read; ++i) {
        list.add(ptr[i]);
      }
      return list;
    } finally {
      result.dispose();
    }
  }

  /// Releases all internal native resources.
  void dispose() {
    _checkStatus();
    _invalid = true;
    _checkError(_nativeI2Cclose(_i2cHandle));
    _nativeI2Cfree(_i2cHandle);
    malloc.free(_nativeName);
  }

  /// Returns the address of the internal handle.
  @override
  int getHandle() {
    return _i2cHandle.address;
  }

  /// Returns the file descriptor (for the underlying i2c-dev device) of
  /// the I2C handle.
  int getI2Cfd() {
    _checkStatus();
    return _nativeI2Cfd(_i2cHandle);
  }

  /// Returns a string representation of the I2C handle.
  String getI2Cinfo() {
    _checkStatus();
    var data = malloc<Int8>(bufferLen).cast<Utf8>();
    try {
      _checkError(_nativeI2Cinfo(_i2cHandle, data, bufferLen));
      return data.toDartString();
    } finally {
      malloc.free(data);
    }
  }

  /// Returns the libc errno of the last failure that occurred.
  int getErrno() {
    _checkStatus();
    return _nativeI2Cerrno(_i2cHandle);
  }

  @override
  IsolateAPI fromJson(String json) {
    return I2C.isolate(json);
  }

  /// Set the address of the internal handle.
  @override
  void setHandle(int handle) {
    _i2cHandle = Pointer<Void>.fromAddress(handle);
  }
}
