// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/vsergeev/c-periphery/blob/master/docs/spi.md
// https://github.com/vsergeev/c-periphery/blob/master/src/spi.c
// https://github.com/vsergeev/c-periphery/blob/master/src/spi.h
// https://github.com/dart-lang/samples/tree/master/ffi

import 'dart:ffi';
import 'library.dart';
import 'package:ffi/ffi.dart';
import 'signature.dart';
import 'hardware/utils/byte_buffer.dart';
import 'dart:convert';

/// Mapped native [SPI] error codes with the same index, but different leading sign.
enum SPIerrorCode {
  /// Error code for not able to map the native C enum
  ERROR_CODE_NOT_MAPPABLE,

  /// Invalid arguments
  SPI_ERROR_ARG,

  /// Opening SPI device
  SPI_ERROR_OPEN,

  /// Querying SPI device attributes
  SPI_ERROR_QUERY,

  /// Configuring SPI device attributes
  SPI_ERROR_CONFIGURE,

  /// SPI transfer
  SPI_ERROR_TRANSFER,

  /// Closing SPI device
  SPI_ERROR_CLOSE,

  /// Unsupported attribute or operation
  SPI_ERROR_UNSUPPORTED
}

/// [SPI] modes
enum SPImode { MODE0, MODE1, MODE2, MODE3 }

/// [SPI] exception
class SPIexception implements Exception {
  final SPIerrorCode errorCode;
  final String errorMsg;
  SPIexception(this.errorCode, this.errorMsg);
  SPIexception.errorCode(int code, Pointer<Void> handle)
      : errorCode = SPI.getSPIerrorCode(code),
        errorMsg = _getErrmsg(handle);
  @override
  String toString() => errorMsg;
}

final DynamicLibrary _peripheryLib = getPeripheryLib();

// spi_t *spi_new(void);
final _nativeSPInew = voidPtrVOIDM('spi_new');

// int spi_close(led_t *led);
final _nativeSPIclose = intVoidM('spi_close');

//  void spi_free(spi_t *spi);
final _nativeSPIfree = voidVoidM('spi_free');

// int spi_errno(spi_t *spi);
final _nativeSPIerrno = intVoidM('spi_errno');

// const char *spi_errmsg(spi_t *spi);
final _nativeSPIerrnMsg = utf8VoidM('spi_errmsg');

// int spi_tostring(spi_t *led, char *str, size_t len);
final _nativeSPIinfo = intVoidUtf8sizeTM('spi_tostring');

// int spi_fd(spi_t *spi);
final _nativeSPIfd = intVoidM('spi_fd');

// int spi_transfer(spi_t *spi, const uint8_t *txbuf, uint8_t *rxbuf, size_t len);
typedef _spi_transfer = Int32 Function(Pointer<Void> handle,
    Pointer<Uint8> txbuf, Pointer<Uint8> rxbuf, IntPtr len);
typedef _spiTransfer = int Function(
    Pointer<Void> handle, Pointer<Uint8> txbuf, Pointer<Uint8> rxbuf, int len);
final _nativeTransfer = _peripheryLib
    .lookup<NativeFunction<_spi_transfer>>('spi_transfer')
    .asFunction<_spiTransfer>();

// int spi_open(spi_t *spi, const char *path, unsigned int mode, uint32_t max_speed);
typedef _spi_open = Int32 Function(
    Pointer<Void> spi, Pointer<Utf8> path, Uint32 mode, Uint32 maxSpeed);
typedef _SPIopen = int Function(
    Pointer<Void> spi, Pointer<Utf8> path, int mode, int maxSpeed);
final _nativeSPIopen = _peripheryLib
    .lookup<NativeFunction<_spi_open>>('spi_open')
    .asFunction<_SPIopen>();

// int spi_open_advanced(spi_t *spi, const char *path, unsigned int mode, uint32_t max_speed,
//                      spi_bit_order_t bit_order, uint8_t bits_per_word, uint8_t extra_flags);
typedef _spi_advanced = Int32 Function(
    Pointer<Void> spi,
    Pointer<Utf8> path,
    Uint32 mode,
    Uint32 maxSpeed,
    Uint32 bitOrder,
    Uint8 bitsPerWord,
    Uint8 extraFlags8bit);
typedef _SPIadvanced = int Function(
    Pointer<Void> spi,
    Pointer<Utf8> path,
    int mode,
    int maxSpeedInt32,
    int bitOrder,
    int bitsPerWord,
    int extraFlags8bit);
final _nativeSPIopenAdvanced = _peripheryLib
    .lookup<NativeFunction<_spi_advanced>>('spi_open_advanced')
    .asFunction<_SPIadvanced>();

// int spi_open_advanced2(spi_t *spi, const char *path, unsigned int mode, uint32_t max_speed,
//                       spi_bit_order_t bit_order, uint8_t bits_per_word, uint32_t extra_flags)
typedef _spi_advanced2 = Int32 Function(
    Pointer<Void> spi,
    Pointer<Utf8> path,
    Int32 mode,
    Int32 maxSpeed,
    Int32 bitOrder,
    Int8 bitsPerWord,
    Int32 extraFlags8bit);
typedef _SPIadvanced2 = int Function(
    Pointer<Void> spi,
    Pointer<Utf8> path,
    int mode,
    int maxSpeedInt32,
    int bitOrder,
    int bitsPerWord,
    int extraFlags32bit);
final _nativeSPIopenAdvanced2 = _peripheryLib
    .lookup<NativeFunction<_spi_advanced2>>('spi_open_advanced2')
    .asFunction<_SPIadvanced2>();

// int spi_get_mode(spi_t *spi, unsigned int *mode);
var _nativeSPIgetMode = intVoidInt32PtrM('spi_get_mode');

// int spi_get_max_speed(spi_t *spi, uint32_t *max_speed);
var _nativeSPIgetMaxSpeed = intVoidInt32PtrM('spi_get_max_speed');

// int spi_get_bit_order(spi_t *spi, spi_bit_order_t *bit_order);
var _nativeSPIgetBitOrder = intVoidInt32PtrM('spi_get_bit_order');

// int spi_get_extra_flags32(spi_t *spi, uint32_t *extra_flags);
var _nativeSPIgetExtraFlags32 = intVoidInt32PtrM('spi_get_extra_flags32');

// int spi_get_bits_per_word(spi_t *spi, uint8_t *bits_per_word);
var _nativeSPIgetBitsPerWord = intVoidInt8PtrM('spi_get_bits_per_word');

// int spi_get_extra_flags(spi_t *spi, uint8_t *extra_flags);
var _nativeSPIgetExtraFlags = intVoidInt8PtrM('spi_get_extra_flags');

// int spi_set_mode(spi_t *spi, unsigned int mode);
var _nativeSPIsetMode = intVoidIntM('spi_set_mode');

// int spi_set_max_speed(spi_t *spi, uint32_t max_speed);
var _nativeSPIsetMaxSpeed = intVoidIntM('spi_set_max_speed');

// int spi_set_bit_order(spi_t *spi, spi_bit_order_t bit_order);
var _nativeSPIsetBitOrder = intVoidIntM('spi_set_bit_order');

// int spi_set_extra_flags32(spi_t *spi, uint32_t extra_flags);
var _nativeSPIsetExtraFlags32 = intVoidIntM('spi_set_extra_flags32');

// int spi_set_bits_per_word(spi_t *spi, uint8_t bits_per_word);
var _nativeSPIsetBitsPerWord = intVoidUint8M('spi_set_bits_per_word');

// int spi_set_extra_flags(spi_t *spi, uint8_t extra_flags);
var _nativeSPIsetExtraFlags = intVoidUint8M('spi_set_extra_flags');

String _getErrmsg(Pointer<Void> handle) {
  return _nativeSPIerrnMsg(handle).toDartString();
}

const BUFFER_LEN = 256;

int _checkError(int value) {
  if (value < 0) {
    var errorCode = SPI.getSPIerrorCode(value);
    throw SPIexception(errorCode, errorCode.toString());
  }
  return value;
}

final Map<String, dynamic> _map = {};

Map<String, dynamic> _jsonMap(String json) {
  if (_map.isEmpty) {
    _map.addAll(jsonDecode(json) as Map<String, dynamic>);
  }
  return _map;
}

/// SPI wrapper functions for Linux userspace <tt>spidev</tt> devices.
///
/// c-periphery [SPI](https://github.com/vsergeev/c-periphery/blob/master/docs/spi.md) documentation.
class SPI {
  /// SPI bus number:  /dev/spidev[bus].[chip]
  final int bus;

  /// SPI chip number:  /dev/spidev[bus].[chip]
  final int chip;

  /// SPI device path:  /dev/spidev[bus].[chip]
  final String path;

  /// SPI mode
  final SPImode mode;

  /// SPI bus speed
  final int maxSpeed;

  /// SPI bit order
  final BitOrder bitOrder;

  /// SPI transfer word size
  final int bitsPerWord;

  /// SPI extra flags
  final int extraFlags;

  bool _invalid = false;
  late Pointer<Void> _spiHandle;

  void _checkSPI(int bus, int chip) {
    if (bus < 0) {
      throw SPIexception(SPIerrorCode.SPI_ERROR_ARG, "Bus can't be negative");
    }
    if (chip < 0) {
      throw SPIexception(SPIerrorCode.SPI_ERROR_ARG, "Chip can't be negative");
    }
  }

  /// Converts a [SPI] to a JSON string. See constructor [isolate] for detials.
  String toJson() {
    return '{"bus":$bus,"chip":$chip,"path":"$path","bitOrder":${bitOrder.index},"mode":${mode.index},"speed":$maxSpeed,"bits":$bitsPerWord,"flags":$extraFlags,"handle":${_spiHandle.address}}';
  }

  /// Opens the SPI device at the  path ("/dev/spidev[bus].[chip]"), with the specified
  /// SPI [mode], specified [maxSpeed] in hertz, and the defaults of MSB_FIRST bit order,
  /// and 8 bits per word.
  ///
  /// SPI [mode] can be 0, 1, 2, or 3.
  SPI(this.bus, this.chip, this.mode, this.maxSpeed)
      : bitOrder = BitOrder.MSB_FIRST,
        bitsPerWord = 8,
        extraFlags = 0,
        path = '/dev/spidev$bus.$chip' {
    _checkSPI(bus, chip);
    _spiHandle = _spiOpen(path, mode, maxSpeed);
  }

  Pointer<Void> _spiOpen(String path, SPImode mode, int maxSpeed) {
    var _spiHandle = _nativeSPInew();
    if (_spiHandle == nullptr) {
      return throw SPIexception(
          SPIerrorCode.SPI_ERROR_OPEN, 'Error opening SPI bus');
    }
    _checkError(
        _nativeSPIopen(_spiHandle, path.toNativeUtf8(), mode.index, maxSpeed));
    return _spiHandle;
  }

  /// Opens the SPI device at the specified path ("/dev/spidev[bus].[chip]"), with the specified SPI mode,
  /// [maxSpeed] in hertz, [bitOrder], [bitsPerWord], and [extraFlags].
  ///
  /// SPI mode can be 0, 1, 2, or 3. [bitOrder] can be [BitOrder.MSB_FIRST] or
  /// [BitOrder.MSB_LAST], [bitsPerWord] specifies the transfer word size.
  /// [extraFlags] specified additional flags bitwise-ORed with the SPI mode.
  SPI.openAdvanced(this.bus, this.chip, this.mode, this.maxSpeed, this.bitOrder,
      this.bitsPerWord, this.extraFlags)
      : path = '/dev/spidev$bus.$chip' {
    _checkSPI(bus, chip);
    _spiHandle = _spiOpenAdvanced(
        path, mode, maxSpeed, bitOrder, bitsPerWord, extraFlags);
  }

  /// Duplicates an existing [SPI] from a JSON string. This special constructor
  /// is used to transfer an existing [SPI] to an other isolate.
  SPI.isolate(String json)
      : path = _jsonMap(json)['path'] as String,
        chip = _jsonMap(json)['chip'] as int,
        maxSpeed = _jsonMap(json)['speed'] as int,
        bus = _jsonMap(json)['bus'] as int,
        bitsPerWord = _jsonMap(json)['bits'] as int,
        extraFlags = _jsonMap(json)['flags'] as int,
        bitOrder = BitOrder.values[_jsonMap(json)['bitOrder'] as int],
        mode = SPImode.values[_jsonMap(json)['mode'] as int],
        _spiHandle = Pointer<Void>.fromAddress(_jsonMap(json)['handle'] as int);

  Pointer<Void> _spiOpenAdvanced(String path, SPImode mode, int maxSpeed,
      BitOrder bitOrder, int bitsPerWord, int extraFlags) {
    var _spiHandle = _nativeSPInew();
    if (_spiHandle == nullptr) {
      return throw SPIexception(
          SPIerrorCode.SPI_ERROR_OPEN, 'Error opening SPI bus');
    }
    _checkError(_nativeSPIopenAdvanced(_spiHandle, path.toNativeUtf8(),
        mode.index, maxSpeed, bitOrder.index, bitsPerWord, extraFlags));
    return _spiHandle;
  }

  /// Opens the SPI device at the specified [path], with the specified SPI mode,
  /// [maxSpeed] in hertz, [bitOrder], [bitsPerWord], and [extraFlags]. This open function is the same as
  /// [SPI.openAdvanced], except that extra_flags can be 32-bits.
  ///
  /// SPI mode can be 0, 1, 2, or 3. [bitOrder] can be [BitOrder.MSB_FIRST] or
  /// [BitOrder.MSB_LAST], [bitsPerWord] specifies the transfer word size.
  /// [extraFlags] specified additional flags bitwise-ORed with the SPI mode.
  SPI.openAdvanced2(this.bus, this.chip, this.path, this.mode, this.maxSpeed,
      this.bitOrder, this.bitsPerWord, this.extraFlags) {
    _checkSPI(bus, chip);
    _spiHandle = _spiOpenAdvanced2(
        path, mode, maxSpeed, bitOrder, bitsPerWord, extraFlags);
  }

  Pointer<Void> _spiOpenAdvanced2(String path, SPImode mode, int maxSpeed,
      BitOrder bitOrder, int bitsPerWord, int extraFlags) {
    var _spiHandle = _nativeSPInew();
    if (_spiHandle == nullptr) {
      return throw SPIexception(
          SPIerrorCode.SPI_ERROR_OPEN, 'Error opening SPI bus');
    }
    _checkError(_nativeSPIopenAdvanced2(_spiHandle, path.toNativeUtf8(),
        mode.index, maxSpeed, bitOrder.index, bitsPerWord, extraFlags));
    return _spiHandle;
  }

  /// Converts the native error code [value] to [GPIOerrorCode].
  static SPIerrorCode getSPIerrorCode(int value) {
    // must be negative
    if (value >= 0) {
      return SPIerrorCode.ERROR_CODE_NOT_MAPPABLE;
    }
    value = -value;

    // check range
    if (value > SPIerrorCode.SPI_ERROR_UNSUPPORTED.index) {
      return SPIerrorCode.ERROR_CODE_NOT_MAPPABLE;
    }

    return SPIerrorCode.values[value];
  }

  void _checkStatus() {
    if (_invalid) {
      throw SPIexception(SPIerrorCode.SPI_ERROR_CLOSE,
          'SPI interface has the status released.');
    }
  }

  /// Shifts out [data], while shifting in the data to the result buffer. If [reuseBuffer]
  /// is true, [data] will be used for the result buffer, for false a new buffer
  /// will be created.
  ///
  /// Returns a 'List<int>' result buffer.
  List<int> transfer(List<int> data, bool reuseBuffer) {
    // ignore: avoid_init_to_null
    Pointer<Uint8> inPtr = nullptr;
    // ignore: avoid_init_to_null
    Pointer<Uint8> outPtr = nullptr;
    var input = malloc<Uint8>(data.length);
    try {
      var index = 0;
      for (var v in data) {
        input[index++] = v;
      }
      if (reuseBuffer) {
        inPtr = outPtr = input;
      } else {
        inPtr = input;
        outPtr = malloc<Uint8>(data.length);
      }

      _checkError(_nativeTransfer(_spiHandle, inPtr, outPtr, data.length));

      List<int> result;
      var length = data.length;
      if (reuseBuffer) {
        data.clear();
        result = data;
      } else {
        result = <int>[];
      }
      for (var i = 0; i < length; ++i) {
        result.add(outPtr[i]);
      }
      return result;
    } finally {
      if (inPtr != nullptr) {
        malloc.free(inPtr);
      }
      if (outPtr != nullptr && !reuseBuffer) {
        malloc.free(outPtr);
      }
    }
  }

  /// Shifts out [len] word counts of the [data] budder, while shifting in the result buffer. If [reuseBuffer]
  /// is true, [data] will be used the result buffer, for false a new buffer
  /// will be created.
  ///
  /// Returns a ' Pointer<Int8>' result buffer. Be aware to malloc.free the low level system memory buffers!
  Pointer<Uint8> transferInt8(Pointer<Uint8> data, bool reuseBuffer, int len) {
    Pointer<Uint8> inPtr;
    Pointer<Uint8> outPtr = nullptr;
    if (reuseBuffer) {
      inPtr = outPtr = data;
    } else {
      inPtr = data;
      outPtr = malloc<Uint8>(len);
    }
    _checkError(_nativeTransfer(_spiHandle, inPtr, outPtr, len));
    return outPtr;
  }

  /// Releases all interal native resoures.
  void dispose() {
    _checkStatus();
    _invalid = true;
    _checkError(_nativeSPIclose(_spiHandle));
    _nativeSPIfree(_spiHandle);
  }

  /// Returns a string representation of the spi handle.
  String getSPIinfo() {
    _checkStatus();
    var data = malloc<Int8>(BUFFER_LEN).cast<Utf8>();
    try {
      _checkError(_nativeSPIinfo(_spiHandle, data, BUFFER_LEN));
      return data.toDartString();
    } finally {
      malloc.free(data);
    }
  }

  /// Returns the libc errno of the last failure that occurred.
  int getErrno() {
    _checkStatus();
    return _nativeSPIerrno(_spiHandle);
  }

  int _getInt32Value(intVoidInt32PtrF f) {
    _checkStatus();
    var data = malloc<Int32>(1);
    try {
      _checkError(f(_spiHandle, data));
      return data[0];
    } finally {
      malloc.free(data);
    }
  }

  int _getInt8Value(intVoidInt8PtrF f) {
    _checkStatus();
    var data = malloc<Int8>(1);
    try {
      _checkError(f(_spiHandle, data));
      return data[0];
    } finally {
      malloc.free(data);
    }
  }

  /// Returns the [SPImode].
  SPImode getSPImode() {
    _checkStatus();
    return SPImode.values[_checkError(_getInt32Value(_nativeSPIgetMode))];
  }

  /// Sets the [SPImode].
  void setSPImode(SPImode mode) {
    _checkStatus();
    _checkError(_nativeSPIsetMode(_spiHandle, mode.index));
  }

  /// Returns the max speed of the SPI bus.
  int getSPImaxSpeed() {
    _checkStatus();
    return _checkError(_getInt32Value(_nativeSPIgetMaxSpeed));
  }

  /// Sets the [maxSpeed] of the SPI bus.
  void setSPImaxSpeed(int maxSpeed) {
    _checkStatus();
    _checkError(_nativeSPIsetMaxSpeed(_spiHandle, maxSpeed));
  }

  /// Returns the [BitOrder].
  BitOrder getSPIbitOrder() {
    _checkStatus();
    return BitOrder.values[_checkError(_getInt32Value(_nativeSPIgetBitOrder))];
  }

  /// Sets the [bitOrder].
  void setSPIbitOrder(BitOrder bitOrder) {
    _checkStatus();
    _checkError(_nativeSPIsetBitOrder(_spiHandle, bitOrder.index));
  }

  /// Returns bits per word.
  int getSPIbitsPerWord() {
    _checkStatus();
    return _checkError(_getInt8Value(_nativeSPIgetBitsPerWord));
  }

  /// Sets the bits per word.
  void setSPIbitsPerWord(int value) {
    _checkStatus();
    _checkError(_nativeSPIsetBitsPerWord(_spiHandle, value));
  }

  /// Returns the 8-bit extra flags mask.
  int getSPIextraFlags() {
    _checkStatus();
    return _checkError(_getInt8Value(_nativeSPIgetExtraFlags));
  }

  /// Sets the 8-bit extra flags mask.
  void setSPIextraFlags(int value) {
    _checkStatus();
    _checkError(_nativeSPIsetExtraFlags(_spiHandle, value));
  }

  /// Returns the 32-bit extra flags mask.
  int getSPIextraFlags32() {
    _checkStatus();
    return _checkError(_getInt32Value(_nativeSPIgetExtraFlags32));
  }

  /// Sets the 32-bit extra flags mask.
  void setSPIextraFlags32(int value) {
    _checkStatus();
    _checkError(_nativeSPIsetExtraFlags32(_spiHandle, value));
  }

  /// Returns the file descriptor (for the underlying <tt>spidev</tt> device) of the SPI handle.
  int getSPIfd() {
    _checkStatus();
    return _checkError(_nativeSPIfd(_spiHandle));
  }

  /// Returns the address of the internal handle.
  int getHandle() {
    return _spiHandle.address;
  }
}
