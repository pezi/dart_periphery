// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/vsergeev/c-periphery/blob/master/docs/serial.md
// https://github.com/vsergeev/c-periphery/blob/master/src/serial.c
// https://github.com/vsergeev/c-periphery/blob/master/src/serial.h
// https://github.com/dart-lang/samples/tree/master/ffi

import 'dart:ffi';
import 'dart:convert';
import 'library.dart';
import 'package:ffi/ffi.dart';
import 'signature.dart';

/// Result of a [Serial.read] operation.
class SerialReadEvent {
  /// timeout flag of [Serial.read] operation
  bool isTimeout = false;
  int count = 0;
  List<int> data = [];
  SerialReadEvent(int read, Pointer<Uint8> buf) {
    if (read == 0) {
      isTimeout = true;
      count = 0;
    } else {
      isTimeout = false;
      count = read;
      data = <int>[];
      for (var i = 0; i < read; ++i) {
        data.add(buf[i]);
      }
    }
  }

  /// Converts the serial data to a string.
  @override
  String toString() {
    if (count == 0) {
      return '';
    }
    var buf = StringBuffer();
    for (var c in data) {
      buf.writeCharCode(c);
    }
    return buf.toString();
  }

  /// Converts the serial data (UTF8 format) to a string.
  String uf8ToString([bool allowMalformed = false]) {
    if (count == 0) {
      return '';
    }
    return Utf8Decoder(allowMalformed: allowMalformed).convert(data);
  }
}

/// [Serial] exception
class SerialException implements Exception {
  final SerialErrorCode errorCode;
  final String errorMsg;
  SerialException(this.errorCode, this.errorMsg);
  SerialException.errorCode(int code, Pointer<Void> handle)
      : errorCode = Serial.getSerialErrorCode(code),
        errorMsg = _getErrmsg(handle);
  @override
  String toString() => errorMsg;
}

/// [Serial] baudrate
enum Baudrate {
  B50,
  B75,
  B110,
  B134,
  B150,
  B200,
  B300,
  B600,
  B1200,
  B1800,
  B2400,
  B4800,
  B9600,
  B19200,
  B38400,
  B57600,
  B115200,
  B230400,
  B460800,
  B500000,
  B576000,
  B921600,
  B1000000,
  B1152000,
  B2000000,
  B2500000,
  B3000000,
  B3500000,
  B4000000,
}

/// [Serial] number of data bits
enum DataBits { DB5, DB6, DB7, DB8 }

/// Number of [Serial] stop bits
enum StopBits { SB1, SB2 }

/// [Serial] error codes
enum SerialErrorCode {
  /// Error code for not able to map the native C enum
  ERROR_CODE_NOT_MAPPABLE,

  /// Invalid arguments
  SERIAL_ERROR_ARG,

  /// Opening serial port
  SERIAL_ERROR_OPEN,

  /// Querying serial port attributes
  SERIAL_ERROR_QUERY,

  /// Configuring serial port attributes
  SERIAL_ERROR_CONFIGURE,

  /// Reading/writing serial port
  SERIAL_ERROR_IO,

  /// Closing serial port
  SERIAL_ERROR_CLOSE
}

/// [Serial] parity
enum Parity {
  PARITY_NONE,
  PARITY_ODD,
  PARITY_EVEN,
}

final DynamicLibrary _peripheryLib = getPeripheryLib();

// serial_t *serial_new(void);
final _nativeSerialNew = voidPtrVOIDM('serial_new');

//int serial_open(serial_t *serial, const char *path, uint32_t baudrate);
typedef _dart_serial_open = Int32 Function(
    Pointer<Void> handle, Pointer<Utf8> path, Uint32 baudrate);
typedef _SerialOpen = int Function(
    Pointer<Void> handle, Pointer<Utf8> path, int baudrate);
final _nativeSerialOpen = _peripheryLib
    .lookup<NativeFunction<_dart_serial_open>>('serial_open')
    .asFunction<_SerialOpen>();

// int serial_close(led_t *led);
final _nativeSerialClose = intVoidM('serial_close');

//  void serial_free(serial_t *i2c);
final _nativeSerialFree = voidVoidM('serial_free');

// int serial_errno(serial_t *i2c);
final _nativeSerialErrno = intVoidM('serial_errno');

// const char *serial_errmsg(serial_t *i2c);
final _nativeSerialErrnMsg = utf8VoidM('serial_errmsg');

// int serial_tostring(serial_t *led, char *str, size_t len);
final _nativeSerialInfo = intVoidUtf8sizeTM('serial_tostring');

// int serial_get_baudrate(serial_t *serial, uint32_t *baudrate);
final _nativeSerialGetBaudrate = intVoidInt32PtrM('serial_get_baudrate');

// int serial_get_databits(serial_t *serial, unsigned int *databits);
final _nativeSerialGetDatabits = intVoidInt32PtrM('serial_get_databits');

// int serial_get_parity(serial_t *serial, serial_parity_t *parity);
final _nativeSerialGetParity = intVoidInt32PtrM('serial_get_parity');

// int serial_get_stopbits(serial_t *serial, unsigned int *stopbits);
final _nativeSerialGetStopbits = intVoidInt32PtrM('serial_get_stopbits');

// int serial_get_xonxoff(serial_t *serial, bool *xonxoff);
final _nativeSerialGetXonxoff = intVoidInt8PtrM('serial_get_xonxoff');

// int serial_get_rtscts(serial_t *serial, bool *rtscts);
final _nativeSerialGetRtscts = intVoidInt8PtrM('serial_get_rtscts');

// int serial_get_vmin(serial_t *serial, unsigned int *vmin);
final _nativeSerialGetVmin = intVoidInt32PtrM('serial_get_vmin');

// int serial_fd(serial_t *serial);
final _nativeSerialFd = intVoidM('serial_fd');

// int serial_set_baudrate(serial_t *serial, uint32_t baudrate);
final _nativeSerialSetBaudrate = intVoidIntM('serial_set_baudrate');

// int serial_set_databits(serial_t *serial, unsigned int databits);
final _nativeSerialSetDatabits = intVoidIntM('serial_set_databits');

// int serial_set_parity(serial_t *serial, enum serial_parity parity);
final _nativeSerialSetParity = intVoidIntM('serial_set_parity');

// int serial_set_stopbits(serial_t *serial, unsigned int stopbits);
final _nativeSerialSetStopbits = intVoidIntM('serial_set_stopbits');

// int serial_set_xonxoff(serial_t *serial, bool enabled);
final _nativeSerialSetXonxof = intVoidInt8M('serial_set_xonxoff');

// int serial_set_rtscts(serial_t *serial, bool enabled)
final _nativeSerialSetRtscts = intVoidInt8M('serial_set_rtscts');

// int serial_set_vmin(serial_t *serial, unsigned int vmin);
final _nativeSerialSetVmin = intVoidIntM('serial_set_vmin');

// int serial_open_advanced(serial_t *serial, const char *path,
//                          uint32_t baudrate, unsigned int databits,
//                          serial_parity_t parity, unsigned int stopbits,
//                          bool xonxoff, bool rtscts);
typedef _serial_open_advanced = Int32 Function(
    Pointer<Void> handle,
    Pointer<Utf8> path,
    Int32 baudrate,
    Int32 databits,
    Int32 parity,
    Int32 stopbits,
    Int32 xonxoff,
    Int32 rtscts);
typedef _SerialOpenAdvanced = int Function(
    Pointer<Void> handle,
    Pointer<Utf8> path,
    int baudrate,
    int databits,
    int parity,
    int stopbits,
    int xonxoff,
    int rtscts);
final _nativeOpenAdvanced = _peripheryLib
    .lookup<NativeFunction<_serial_open_advanced>>('serial_open_advanced')
    .asFunction<_SerialOpenAdvanced>();

//  int serial_read(serial_t *serial, uint8_t *buf, size_t len, int timeout_ms);
typedef _serial_read = Int32 Function(
    Pointer<Void> handle, Pointer<Uint8> buf, IntPtr len, Int32 timeoutMillis);
typedef _SerialRead = int Function(
    Pointer<Void> handle, Pointer<Uint8> buf, int len, int timeoutMillis);
final _nativeSerialRead = _peripheryLib
    .lookup<NativeFunction<_serial_read>>('serial_read')
    .asFunction<_SerialRead>();

// int serial_write(serial_t *serial, const uint8_t *buf, size_t len);
typedef _serial_write = Int32 Function(
    Pointer<Void> handle, Pointer<Uint8> buf, IntPtr len);
typedef _SerialWrite = int Function(
    Pointer<Void> handle, Pointer<Uint8> buf, int len);
final _nativeSerialWrite = _peripheryLib
    .lookup<NativeFunction<_serial_write>>('serial_write')
    .asFunction<_SerialWrite>();

// int serial_flush(serial_t *serial);
final _nativeSerialFlush = intVoidM('serial_flush');

// int serial_input_waiting(serial_t *serial, unsigned int *count);
final _nativeSerialInputWaiting = intVoidInt32PtrM('serial_input_waiting');

// int serial_output_waiting(serial_t *serial, unsigned int *count);
final _nativeSerialOutputWaiting = intVoidInt32PtrM('serial_output_waiting');

// int serial_poll(serial_t *serial, int timeout_ms);
final _nativeSerialPool = intVoidIntM('serial_poll');

// int serial_get_vtime(serial_t *serial, float *vtime);
typedef _serial_get_vtime = Int32 Function(
    Pointer<Void> handle, Pointer<Float>);
typedef _SerialGetVTIME = int Function(Pointer<Void> handle, Pointer<Float>);
final _nativeSerialGetVtime = _peripheryLib
    .lookup<NativeFunction<_serial_get_vtime>>('serial_get_vtime')
    .asFunction<_SerialGetVTIME>();

// int serial_set_vtime(serial_t *serial, float vtime);
typedef _serial_set_vtime = Int32 Function(Pointer<Void> handle, Float vtime);
typedef _SerialSetVTIME = int Function(Pointer<Void> handle, double vtime);
final _nativeSerialSetVtime = _peripheryLib
    .lookup<NativeFunction<_serial_set_vtime>>('serial_set_vtime')
    .asFunction<_SerialSetVTIME>();

String _getErrmsg(Pointer<Void> handle) {
  return _nativeSerialErrnMsg(handle).toDartString();
}

const BUFFER_LEN = 256;

int _checkError(int value) {
  if (value < 0) {
    var errorCode = Serial.getSerialErrorCode(value);
    throw SerialException(errorCode, errorCode.toString());
  }
  return value;
}

/// Serial wrapper functions for Linux userspace termios tty devices.
///
/// c-periphery [Serial](https://github.com/vsergeev/c-periphery/blob/master/docs/serial.md) documentation.
class Serial {
  final String path;
  final Baudrate baudrate;
  final DataBits databits;
  final Parity parity;
  final StopBits stopbits;
  final bool xonxoff;
  final bool rtsct;
  final Pointer<Void> _serialHandle;
  bool _invalid = false;

  void _checkStatus() {
    if (_invalid) {
      throw SerialException(SerialErrorCode.SERIAL_ERROR_CLOSE,
          'Serial interface has the status released.');
    }
  }

  /// Converts the native error code [value] to [SerialErrorCode].
  static SerialErrorCode getSerialErrorCode(int value) {
    // must be negative
    if (value >= 0) {
      return SerialErrorCode.ERROR_CODE_NOT_MAPPABLE;
    }
    value = -value;

    // check range
    if (value > SerialErrorCode.SERIAL_ERROR_CLOSE.index) {
      return SerialErrorCode.ERROR_CODE_NOT_MAPPABLE;
    }

    return SerialErrorCode.values[value];
  }

  /// Converts a [baudrate] enum to an int value;
  static int baudrate2Int(Baudrate baudrate) {
    const tmp = 'Baudrate.B';
    return int.parse(baudrate.toString().substring(tmp.length));
  }

  /// Converts a [databits] enum to an int value;
  static int databits2Int(DataBits databits) {
    const tmp = 'DataBits.DB';
    return int.parse(databits.toString().substring(tmp.length));
  }

  /// Converts a [stopbits] enum to an int value;
  static int stopbits2Int(StopBits stopbits) {
    const tmp = 'StopBits.SB';
    return int.parse(stopbits.toString().substring(tmp.length));
  }

  /// Opens the <tt>tty</tt> device at the specified [path] (e.g. "/dev/ttyUSB0"), with the specified [baudrate], and the
  /// defaults of 8 data bits, no parity, 1 stop bit, software flow control (xonxoff) off, hardware flow control (rtscts) off.
  Serial(this.path, this.baudrate)
      : databits = DataBits.DB8,
        parity = Parity.PARITY_NONE,
        stopbits = StopBits.SB1,
        rtsct = false,
        xonxoff = false,
        _serialHandle = _openSerial(path, baudrate);

  static Pointer<Void> _openSerial(String path, Baudrate baudrate) {
    var _serialHandle = _nativeSerialNew();
    if (_serialHandle == nullptr) {
      return throw SerialException(
          SerialErrorCode.SERIAL_ERROR_OPEN, 'Error opening serial interface');
    }
    _checkError(_nativeSerialOpen(
        _serialHandle, path.toNativeUtf8(), baudrate2Int(baudrate)));
    return _serialHandle;
  }

  /// Opens the <tt>tty</tt> device at the specified [path] (e.g. "/dev/ttyUSB0"), with the specified [baudrate], [databits],
  /// [parity], [stopbits], software flow control ([xonxoff]), and hardware flow control ([rtsct]) settings.
  ///
  /// serial should be a valid pointer to an allocated Serial handle structure. databits can be 5, 6, 7, or 8.
  /// parity can be PARITY_NONE, PARITY_ODD, or PARITY_EVEN . StopBits can be 1 or 2.
  Serial.advanced(this.path, this.baudrate, this.databits, this.parity,
      this.stopbits, this.xonxoff, this.rtsct)
      : _serialHandle = _openSerialAdvanced(
            path, baudrate, databits, parity, stopbits, xonxoff, rtsct);

  static Pointer<Void> _openSerialAdvanced(
      String path,
      Baudrate baudrate,
      DataBits databits,
      Parity parity,
      StopBits stopbits,
      bool xonxoff,
      bool rtsct) {
    var _serialHandle = _nativeSerialNew();
    if (_serialHandle == nullptr) {
      return throw SerialException(
          SerialErrorCode.SERIAL_ERROR_OPEN, 'Error opening serial interface');
    }
    _checkError(_nativeOpenAdvanced(
        _serialHandle,
        path.toNativeUtf8(),
        baudrate2Int(baudrate),
        databits2Int(databits),
        parity.index,
        stopbits2Int(stopbits),
        xonxoff ? 1 : 0,
        rtsct ? 1 : 0));
    return _serialHandle;
  }

  /// Polls for data available for reading from the serial port.
  ///
  ///
  /// [timeout] can be positive for a timeout in milliseconds, zero for a non-blocking poll, or negative
  /// for a blocking poll.
  /// Returns 'true' on success (data available for reading), 'false on timeout,
  bool poll(int timeout) {
    _checkStatus();
    return _checkError(_nativeSerialPool(_serialHandle, timeout)) == 1
        ? true
        : false;
  }

  int _getInt32Value(intVoidInt32PtrF f) {
    _checkStatus();
    var data = malloc<Int32>(1);
    try {
      _checkError(f(_serialHandle, data));
      return data[0];
    } finally {
      malloc.free(data);
    }
  }

  bool _getBoolValue(intVoidInt8PtrF f) {
    _checkStatus();
    var data = malloc<Int8>(1);
    try {
      _checkError(f(_serialHandle, data));
      return data[0] != 0;
    } finally {
      malloc.free(data);
    }
  }

  /// Gets the number of bytes waiting to be written to the serial port.
  int getOutputWaiting() {
    _checkStatus();
    return _getInt32Value(_nativeSerialOutputWaiting);
  }

  /// Gets the number of bytes waiting to be read from the serial port.
  int getInputWaiting() {
    _checkStatus();
    return _getInt32Value(_nativeSerialInputWaiting);
  }

  /// Reads up to [len] number of bytes from the serial port with the specified
  /// millisecond timeout.
  ///
  /// [timeout] can be positive for a blocking read with atimeout in milliseconds, zero
  /// for a non-blocking read, or negative for a blocking read that will block until length number of bytes are read.
  /// For a non-blocking or timeout-bound read, this method may return less than the requested number of bytes.
  /// For a blocking read with the VMIN setting configured, this method will block until at least VMIN bytes are read.
  /// For a blocking read with both VMIN and VTIME settings configured, this method will block until at least
  /// VMIN bytes are read or the VTIME interbyte timeout expires after the last byte read.
  /// In either case, this method may return less than the requested number of bytes.
  /// [timeout] can be positive for a blocking read with a timeout in milliseconds, zero for a non-blocking read, or
  /// negative for a blocking read.
  ///
  /// Returns a 'ReadEvent' containing the number of bytes read and a bytes array on success, false on timeout.
  SerialReadEvent read(int len, int timeout) {
    _checkStatus();

    var data = malloc<Uint8>(len);
    try {
      var dataRead =
          _checkError(_nativeSerialRead(_serialHandle, data, len, timeout));
      return SerialReadEvent(dataRead, data);
    } finally {
      malloc.free(data);
    }
  }

  /// Returns the libc errno of the last failure that occurred.
  int getErrno() {
    _checkStatus();
    return _nativeSerialErrno(_serialHandle);
  }

  /// Writes a list of bytes to the serial port.
  /// Returns the number of bytes written on success,
  int write(List<int> list) {
    _checkStatus();
    if (list.isEmpty) {
      return 0;
    }
    var ptr = malloc<Uint8>(list.length);
    try {
      var index = 0;
      for (var i in list) {
        ptr[index++] = i;
      }
      var result = _nativeSerialWrite(_serialHandle, ptr, list.length);
      return _checkError(result);
    } finally {
      malloc.free(ptr);
    }
  }

  /// Writes a string as list of UTF8 aware bytes to the serial port.
  /// Returns the number of bytes written on succes
  int writeString(String data) {
    return write(utf8.encode(data));
  }

  /// Flushes the write buffer of the serial port (i.e. force its write immediately).
  void flush() {
    _checkStatus();
    _checkError(_nativeSerialFlush(_serialHandle));
  }

  /// Releases all native resources.
  void dispose() {
    _checkStatus();
    _invalid = true;
    _checkError(_nativeSerialClose(_serialHandle));
    _nativeSerialFree(_serialHandle);
  }

  /// Returns the baudrate.
  /// See [baudrate2Int] for converting the result to an integer.
  Baudrate getBaudrate() {
    _checkStatus();
    switch (_getInt32Value(_nativeSerialGetBaudrate)) {
      case 50:
        return Baudrate.B50;
      case 75:
        return Baudrate.B75;
      case 110:
        return Baudrate.B110;
      case 134:
        return Baudrate.B134;
      case 150:
        return Baudrate.B150;
      case 200:
        return Baudrate.B200;
      case 300:
        return Baudrate.B300;
      case 600:
        return Baudrate.B600;
      case 1200:
        return Baudrate.B1200;
      case 1800:
        return Baudrate.B1800;
      case 2400:
        return Baudrate.B2400;
      case 4800:
        return Baudrate.B4800;
      case 9600:
        return Baudrate.B9600;
      case 19200:
        return Baudrate.B19200;
      case 38400:
        return Baudrate.B38400;
      case 57600:
        return Baudrate.B57600;
      case 115200:
        return Baudrate.B115200;
      case 230400:
        return Baudrate.B230400;
      case 460800:
        return Baudrate.B460800;
      case 500000:
        return Baudrate.B500000;
      case 576000:
        return Baudrate.B576000;
      case 1000000:
        return Baudrate.B1000000;
      case 1152000:
        return Baudrate.B1152000;
      case 2000000:
        return Baudrate.B2000000;
      case 2500000:
        return Baudrate.B2500000;
      case 3000000:
        return Baudrate.B3000000;
      case 3500000:
        return Baudrate.B3500000;
      case 4000000:
        return Baudrate.B4000000;
    }
    throw SerialException(SerialErrorCode.ERROR_CODE_NOT_MAPPABLE,
        'Unable to map baudrate to enum');
  }

  /// Sets the [baudrate].
  void setBaudrate(Baudrate baudrate) {
    _checkStatus();
    _checkError(
        _nativeSerialSetBaudrate(_serialHandle, baudrate2Int(baudrate)));
  }

  /// Returns the number of data bits.
  /// See [databits2Int] for converting the result to an integer.
  DataBits getDataBits() {
    _checkStatus();
    switch (_getInt32Value(_nativeSerialGetDatabits)) {
      case 5:
        return DataBits.DB5;
      case 6:
        return DataBits.DB6;
      case 7:
        return DataBits.DB7;
      case 8:
        return DataBits.DB8;
    }
    throw SerialException(SerialErrorCode.ERROR_CODE_NOT_MAPPABLE,
        'Unable to map data bits to enum');
  }

  /// Sets the number of [databits].
  void setDataBits(DataBits databits) {
    _checkStatus();
    _checkError(
        _nativeSerialSetDatabits(_serialHandle, databits2Int(databits)));
  }

  /// Returns the number of stop bits.
  /// See [stopbits2Int] for converting the result to an integer.
  StopBits getStopBits() {
    _checkStatus();
    switch (_getInt32Value(_nativeSerialGetStopbits)) {
      case 1:
        return StopBits.SB1;
      case 2:
        return StopBits.SB2;
    }
    throw SerialException(SerialErrorCode.ERROR_CODE_NOT_MAPPABLE,
        'Unable to map stop bits to enum');
  }

  /// Sets the number of [stopbits].
  void setStopBits(StopBits stopbits) {
    _checkStatus();
    _checkError(
        _nativeSerialSetStopbits(_serialHandle, stopbits2Int(stopbits)));
  }

  /// Returns the parity property.
  Parity getParity() {
    _checkStatus();
    return Parity.values[_getInt32Value(_nativeSerialGetParity)];
  }

  /// Sets the [parity].
  void setParity(Parity parity) {
    _checkStatus();
    _checkError(_nativeSerialSetParity(_serialHandle, parity.index));
  }

  /// Returns if the setXONXOFF protocol is enabled or disabled.
  bool getXONXOFF() {
    return _getBoolValue(_nativeSerialGetXonxoff);
  }

  /// [flag] enables, or disables the setXONXOFF protocol.
  void setXONXOFF(bool flag) {
    _checkStatus();
    _checkError(_nativeSerialSetXonxof(_serialHandle, flag == true ? 1 : 0));
  }

  /// Returns if the RTS/CTS (request to send/ clear to send) flow control is enabled or disabled.
  bool getRTSCTS() {
    return _getBoolValue(_nativeSerialGetRtscts);
  }

  /// [flag] enables, or disables the RTSCTS flow control.
  void setRTSCTS(bool flag) {
    _checkStatus();
    _checkError(_nativeSerialSetRtscts(_serialHandle, flag == true ? 1 : 0));
  }

  /// Gets the termios VMIN settings, respectively, of the underlying tty device.
  /// VMIN specifies the minimum number of bytes returned from a blocking read. VTIME specifies the timeout in seconds
  /// of a blocking read. When both VMIN and VTIME settings are configured, VTIME acts as an interbyte
  /// timeout that restarts on every byte received, and a blocking read will block until either VMIN bytes are
  /// read or the VTIME timeout expires after the last byte read. See the termios man page for more information.
  /// vmin can be between 0 and 255. vtime can be between 0 and 25.5 seconds, with a resolution of 0.1 seconds.
  int getVMIN() {
    _checkStatus();
    return _getInt32Value(_nativeSerialGetVmin);
  }

  /// Sets the termios VMIN settings, respectively, of the underlying tty device.
  /// VMIN specifies the minimum number of bytes returned from a blocking read. VTIME specifies the timeout in seconds
  /// of a blocking read. When both VMIN and VTIME settings are configured, VTIME acts as an interbyte
  /// timeout that restarts on every byte received, and a blocking read will block until either VMIN bytes are
  /// read or the VTIME timeout expires after the last byte read. See the termios man page for more information.
  /// vmin can be between 0 and 255. vtime can be between 0 and 25.5 seconds, with a resolution of 0.1 seconds.
  void setVMIN(int vmin) {
    _checkStatus();
    _checkError(_nativeSerialSetVmin(_serialHandle, vmin));
  }

  /// Gets the termios VTIME settings, respectively, of the underlying tty device.
  /// VMIN specifies the minimum number of bytes returned from a blocking read. VTIME specifies the timeout in seconds
  /// of a blocking read. When both VMIN and VTIME settings are configured, VTIME acts as an interbyte
  /// timeout that restarts on every byte received, and a blocking read will block until either VMIN bytes are
  /// read or the VTIME timeout expires after the last byte read. See the termios man page for more information.
  /// vmin can be between 0 and 255. vtime can be between 0 and 25.5 seconds, with a resolution of 0.1 seconds.
  double getVTIME() {
    _checkStatus();
    var data = malloc<Float>(1);
    try {
      _checkError(_nativeSerialGetVtime(_serialHandle, data));
      return data[0];
    } finally {
      malloc.free(data);
    }
  }

  /// Sets the termios VTIME settings, respectively, of the underlying tty device.
  /// VMIN specifies the minimum number of bytes returned from a blocking read. VTIME specifies the timeout in seconds
  /// of a blocking read. When both VMIN and VTIME settings are configured, VTIME acts as an interbyte
  /// timeout that restarts on every byte received, and a blocking read will block until either VMIN bytes are
  /// read or the VTIME timeout expires after the last byte read. See the termios man page for more information.
  /// vmin can be between 0 and 255. vtime can be between 0 and 25.5 seconds, with a resolution of 0.1 seconds.
  void setVTIME(double vtime) {
    _checkStatus();
    _checkError(_nativeSerialSetVtime(_serialHandle, vtime));
  }

  /// Returns the file descriptor (for the underlying tty device) of the Serial handle.
  int getSerialFD() {
    _checkStatus();
    return _nativeSerialFd(_serialHandle);
  }

  /// Returns a string representation of the Serial handle.
  String getSerialInfo() {
    _checkStatus();
    var data = malloc<Int8>(BUFFER_LEN).cast<Utf8>();
    try {
      _checkError(_nativeSerialInfo(_serialHandle, data, BUFFER_LEN));
      return data.toDartString();
    } finally {
      malloc.free(data);
    }
  }
}
