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
import 'hardware/util.dart';

enum _SPIproperty {
  MODE,
  MAX_SPEED,
  BIT_ORDER,
  BITS_PER_WORD,
  EXTRA_FLAGS,
  EXTRA_FLAGS32,
  FILE_DESCRIPTOR
}

/// Mapped native GPIO error codes with the same index, but different leading sign.
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

enum SPImode { MODE0, MODE1, MODE2, MODE3 }

/// SPI exception
class SPIexception implements Exception {
  final SPIerrorCode errorCode;
  final String errorMsg;
  SPIexception(this.errorCode, this.errorMsg);
  SPIexception.errorCode(int code, Pointer<Void> handle)
      : errorCode = getSPIerrorCode(code),
        errorMsg = _getErrmsg(handle);
  @override
  String toString() => errorMsg;
}

/// Converts the native error code [value] to [GPIOerrorCode].
SPIerrorCode getSPIerrorCode(int value) {
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

final DynamicLibrary _peripheryLib = getPeripheryLib();

// int dart_spi_errno(spi_t *spi)
typedef _dart_spi_errno = Int32 Function(Pointer<Void> handle);
typedef _SPIerrno = int Function(Pointer<Void> handle);
final _nativeErrno = _peripheryLib
    .lookup<NativeFunction<_dart_spi_errno>>('dart_spi_errno')
    .asFunction<_SPIerrno>();

// const char *dart_spi_errmsg(spi_t *spi)
typedef _dart_spi_errmsg = Pointer<Utf8> Function(Pointer<Void> handle);
typedef _SPIerrmsg = Pointer<Utf8> Function(Pointer<Void> hanlde);
final _nativeErrmsg = _peripheryLib
    .lookup<NativeFunction<_dart_spi_errmsg>>('dart_spi_errmsg')
    .asFunction<_SPIerrmsg>();

// int dart_spi_dispose(gpio_t *spi)
typedef _dart_spi_dispose = Int32 Function(Pointer<Void> handle);
typedef _SPIdispose = int Function(Pointer<Void> handle);
final _nativeDispose = _peripheryLib
    .lookup<NativeFunction<_dart_spi_dispose>>('dart_spi_dispose')
    .asFunction<_SPIdispose>();

// spi_t *dart_spi_open(const char *path,int mode,int maxSpeed)
typedef _dart_spi_open = Pointer<Void> Function(
    Pointer<Utf8> path, Int32 mode, Int32 maxSpeed);
typedef _SPIopen = Pointer<Void> Function(
    Pointer<Utf8> path, int mode, int maxSpeed);
final _nativeOpen = _peripheryLib
    .lookup<NativeFunction<_dart_spi_open>>('dart_spi_open')
    .asFunction<_SPIopen>();

// spi_t *dart_spi_open_advancded(const char *path,int mode,int maxSpeed, int bit_ordner,int bits_per_word,int extra_flags_8bit)
typedef _dart_spi_advanced = Pointer<Void> Function(
    Pointer<Utf8> path,
    Int32 mode,
    Int32 maxSpeed,
    Int32 bitOrder,
    Int32 bitsPerWord,
    Int32 extraFlags8bit);
typedef _SPIadvanced = Pointer<Void> Function(Pointer<Utf8> path, int mode,
    int maxSpeedInt32, int bitOrder, int bitsPerWord, int extraFlags8bit);
final _nativeAdvanced = _peripheryLib
    .lookup<NativeFunction<_dart_spi_advanced>>('dart_spi_advanced')
    .asFunction<_SPIadvanced>();

final _nativeAdvanced2 = _peripheryLib
    .lookup<NativeFunction<_dart_spi_advanced>>('dart_spi_advanced2')
    .asFunction<_SPIadvanced>();

// int dart_spi_fd(spi_t *spi)
typedef _dart_spi_fd = Int32 Function(Pointer<Void> handle);
typedef _spiFd = int Function(Pointer<Void> handle);
final _nativeFD = _peripheryLib
    .lookup<NativeFunction<_dart_spi_fd>>('dart_spi_fd')
    .asFunction<_spiFd>();

// char *dart_spi_info(spi_t *spi)
typedef _dart_spi_info = Pointer<Utf8> Function(Pointer<Void> handle);
typedef _spiInfo = Pointer<Utf8> Function(Pointer<Void> handle);
final _nativeInfo = _peripheryLib
    .lookup<NativeFunction<_dart_spi_info>>('dart_spi_info')
    .asFunction<_spiInfo>();

// int dart_spi_transfer(const uint8_t *txbuf,const uint8_t *rxbuf,size_t len)
typedef _dart_spi_transfer = Int32 Function(
    Pointer<Void> handle, Pointer<Int8> txbuf, Pointer<Int8> rxbuf, Int32 len);
typedef _spiTransfer = int Function(
    Pointer<Void> handle, Pointer<Int8> txbuf, Pointer<Int8> rxbuf, int len);
final _nativeTransfer = _peripheryLib
    .lookup<NativeFunction<_dart_spi_transfer>>('dart_spi_transfer')
    .asFunction<_spiTransfer>();

// int dart_get_property(spi_t *spi,SPIproperty prop)
final _nativeGetProperty = intVoidIntM('dart_get_property');

// int dart_set_property(spi_t *spi,SPIproperty prop,int value)
final _nativeSetProperty = intVoidIntIntM('dart_set_property');

String _getErrmsg(Pointer<Void> handle) {
  return Utf8.fromUtf8(_nativeErrmsg(handle));
}

int _checkError(int value) {
  if (value < 0) {
    var errorCode = getSPIerrorCode(value);
    throw SPIexception(errorCode, errorCode.toString());
  }
  return value;
}

/// SPI wrapper functions for Linux userspace <tt>spidev</tt> devices.
class SPI {
  final int bus;
  final int chip;
  String path;
  final SPImode mode;
  final int maxSpeed;
  Pointer<Void> _spiHandle;
  final BitOrder bitOrder;
  final int bitsPerWord;
  final int extraFlags;
  bool _invalid = false;

  void _checkSPI(int bus, int chip) {
    if (bus < 0) {
      throw SPIexception(SPIerrorCode.SPI_ERROR_ARG, "Bus can't be negative");
    }
    if (chip < 0) {
      throw SPIexception(SPIerrorCode.SPI_ERROR_ARG, "Chip can't be negative");
    }
  }

  /// Opens the spidev device at the  path ("/dev/spidev[bus].[chip]"), with the specified
  /// SPI [mode], specified [maxspeed] in hertz, and the defaults of MSB_FIRST bit order,
  /// and 8 bits per word.
  ///
  /// SPI [mode] can be 0, 1, 2, or 3.
  SPI(this.bus, this.chip, this.mode, this.maxSpeed)
      : bitOrder = BitOrder.MSB_FIRST,
        bitsPerWord = 8,
        extraFlags = 0 {
    _checkSPI(bus, chip);
    path = '/dev/spidev$bus.$chip';
    _spiHandle =
        _checkHandle(_nativeOpen(Utf8.toUtf8(path), mode.index, maxSpeed));
  }

  /// Opens the spidev device at the specified path ("/dev/spidev[bus].[chip]"), with the specified SPI mode,
  /// [maxSspeed] in hertz, [bitOrder], [bitsPerWord], and [extraflags].
  ///
  /// SPI mode can be 0, 1, 2, or 3. [bitOrder] can be [BitOrder.MSB_FIRST] or
  /// [BitOrder.LSB_FIRST], [bitsPerWord] specifies the transfer word size.
  /// [extraflags] specified additional flags bitwise-ORed with the SPI mode.
  SPI.openAdvanced(this.bus, this.chip, this.mode, this.maxSpeed, this.bitOrder,
      this.bitsPerWord, this.extraFlags) {
    _checkSPI(bus, chip);
    path = '/dev/spidev$bus.$chip';
    _spiHandle = _checkHandle(_nativeAdvanced(Utf8.toUtf8(path), mode.index,
        maxSpeed, bitOrder.index, bitsPerWord, extraFlags));
  }

  /// Opens the spidev device at the specified path ("/dev/spidev[bus].[chip]"), with the specified SPI mode,
  /// [maxSspeed] in hertz, [bitOrder], [bitsPerWord], and [extraflags]. This open function is the same as
  /// [SPI.openAdvanced()], except that extra_flags can be 32-bits.
  ///
  /// SPI mode can be 0, 1, 2, or 3. [bitOrder] can be [BitOrder.MSB_FIRST] or
  /// [BitOrder.LSB_FIRST], [bitsPerWord] specifies the transfer word size.
  /// [extraflags] specified additional flags bitwise-ORed with the SPI mode.
  SPI.openAdvanced2(this.bus, this.chip, this.path, this.mode, this.maxSpeed,
      this.bitOrder, this.bitsPerWord, this.extraFlags) {
    _checkSPI(bus, chip);
    path = '/dev/spidev$bus.$chip';
    _spiHandle = _checkHandle(_nativeAdvanced2(Utf8.toUtf8(path), mode.index,
        maxSpeed, bitOrder.index, bitsPerWord, extraFlags));
  }

  void _checkStatus() {
    if (_invalid) {
      throw SPIexception(SPIerrorCode.SPI_ERROR_CLOSE,
          'spi interface has the status released.');
    }
  }

  Pointer<Void> _checkHandle(Pointer<Void> handle) {
    // handle 0 indicates an internal error
    if (handle.address == 0) {
      throw SPIexception(SPIerrorCode.SPI_ERROR_OPEN, 'Error opening SPI bus');
    }
    return handle;
  }

  /// Shifts out [data], while shifting in the data to the result buffer. If [reuseBuffer]
  /// is true, [data] will be used the result buffer, for false a new buffer
  /// will be created.
  ///
  /// Returns a 'List<int>' result buffer.
  List<int> transfer(List<int> data, bool reuseBuffer) {
    Pointer<Int8> inPtr;
    // ignore: avoid_init_to_null
    Pointer<Int8> outPtr = null;
    var input = allocate<Int8>(count: data.length);
    try {
      var index = 0;
      for (var v in data) {
        input.elementAt(index++).value = v;
      }
      if (reuseBuffer) {
        inPtr = outPtr = input;
      } else {
        inPtr = input;
        outPtr = allocate<Int8>(count: data.length);
      }

      _checkError(_nativeTransfer(_spiHandle, inPtr, outPtr, data.length));

      List<int> result;
      if (reuseBuffer) {
        data.clear();
        result = data;
      } else {
        result = <int>[];
      }
      for (var i = 0; i < data.length; ++i) {
        result.add(outPtr.elementAt(i).value);
      }
      return result;
    } finally {
      free(inPtr);
      if (outPtr != null) {
        free(outPtr);
      }
    }
  }

  /// Shifts out [len] word counts of the [data] budder, while shifting in the result buffer. If [reuseBuffer]
  /// is true, [data] will be used the result buffer, for false a new buffer
  /// will be created.
  ///
  /// Returns a ' Pointer<Int8>' result buffer. Be aware to [free()] the low level system memory buffers!
  Pointer<Int8> transferInt8(Pointer<Int8> data, bool reuseBuffer, int len) {
    Pointer<Int8> inPtr;
    // ignore: avoid_init_to_null
    Pointer<Int8> outPtr = null;
    if (reuseBuffer) {
      inPtr = outPtr = data;
    } else {
      inPtr = data;
      outPtr = allocate<Int8>(count: len);
    }
    _checkError(_nativeTransfer(_spiHandle, inPtr, outPtr, len));
    return outPtr;
  }

  /// Releases all interal native resoures.
  void dispose() {
    _checkStatus();
    _invalid = true;
    _checkError(_nativeDispose(_spiHandle));
  }

  /// Returns the file descriptor (for the underlying SPI-dev device) of the SPI handle.
  int getSerialFD() {
    _checkStatus();
    return _checkError(_nativeFD(_spiHandle));
  }

  /// Returns a string representation of the spi handle.
  String getSPIinfo() {
    _checkStatus();
    final ptr = _nativeInfo(_spiHandle);
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
    return _nativeErrno(_spiHandle);
  }

  /// Returns the [SPImode].
  SPImode getSPImode() {
    _checkStatus();
    return SPImode.values[
        _checkError(_nativeGetProperty(_spiHandle, _SPIproperty.MODE.index))];
  }

  /// Sets the [SPImode].
  void setSPImode(SPImode mode) {
    _checkStatus();
    _checkError(
        _nativeSetProperty(_spiHandle, _SPIproperty.MODE.index, mode.index));
  }

  /// Returns the max speed of the SPI bus.
  int getSPImaxSpeed() {
    _checkStatus();
    return _checkError(
        _nativeGetProperty(_spiHandle, _SPIproperty.MAX_SPEED.index));
  }

  /// Sets the [maxSpeed] of the SPI bus.
  void setSPImaxSpeed(int maxSpeed) {
    _checkStatus();
    _checkError(
        _nativeSetProperty(_spiHandle, _SPIproperty.MAX_SPEED.index, maxSpeed));
  }

  /// Returns the [BitOrder].
  BitOrder getSPIbitOrder() {
    _checkStatus();
    return BitOrder.values[_checkError(
        _nativeGetProperty(_spiHandle, _SPIproperty.BIT_ORDER.index))];
  }

  /// Sets the [bitOrder].
  void setSPIbitOrder(BitOrder bitOrder) {
    _checkStatus();
    _checkError(_nativeSetProperty(
        _spiHandle, _SPIproperty.BIT_ORDER.index, bitOrder.index));
  }

  /// Returns bits per word.
  int getSPIbitsPerWord() {
    _checkStatus();
    return _checkError(
        _nativeGetProperty(_spiHandle, _SPIproperty.BITS_PER_WORD.index));
  }

  /// Returns the 8-bit extra flags mask.
  int getSPIextraFlags() {
    _checkStatus();
    return _checkError(
        _nativeGetProperty(_spiHandle, _SPIproperty.EXTRA_FLAGS.index));
  }

  /// Sets the 8-bit extra flags mask.
  void setSPIextraFlags(int value) {
    _checkStatus();
    _checkError(
        _nativeSetProperty(_spiHandle, _SPIproperty.EXTRA_FLAGS.index, value));
  }

  /// Returns the 32-bit extra flags mask.
  int getSPIextraFlags32() {
    _checkStatus();
    return _checkError(
        _nativeGetProperty(_spiHandle, _SPIproperty.EXTRA_FLAGS32.index));
  }

  /// Sets the 32-bit extra flags mask.
  void setSPIextraFlags32(int value) {
    _checkStatus();
    _checkError(_nativeSetProperty(
        _spiHandle, _SPIproperty.EXTRA_FLAGS32.index, value));
  }

  /// Returns the file descriptor (for the underlying <tt>spidev</tt> device) of the SPI handle.
  int getSPIfd() {
    _checkStatus();
    return _nativeGetProperty(_spiHandle, _SPIproperty.FILE_DESCRIPTOR.index);
  }
}
