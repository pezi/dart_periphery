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

enum _SerialProperty {
  BAUDRATE,
  DATABITS,
  PARITY,
  STOPBITS,
  XONXOFF,
  RTSCTS,
  VMIN
}

// map native struct
//
// typedef struct read_event
// {
//    int count;
//    uint8_t *data;
// } read_event_t;
//
class _ReadEvent extends Struct {
  @Int32()
  external int count;
  external Pointer<Int8> data;
  factory _ReadEvent.allocate() => malloc<_ReadEvent>().ref;
}

/// Result of a [Serial.read] operation.
class SerialReadEvent {
  /// timeout flag of [Serial.read] operation
  bool isTimeout = false;
  int count = 0;
  List<int> data = [];
  SerialReadEvent(_ReadEvent event) {
    if (event.count == 0) {
      isTimeout = true;
      count = 0;
      data = [];
    } else {
      isTimeout = false;
      count = event.count;
      data = [];
      for (var i = 0; i < event.count; ++i) {
        data.add(event.data[i]);
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

/// Serial exception
class SerialException implements Exception {
  final SerialErrorCode errorCode;
  final String errorMsg;
  SerialException(this.errorCode, this.errorMsg);
  SerialException.errorCode(int code, Pointer<Void> handle)
      : errorCode = getSerialErrorCode(code),
        errorMsg = _getErrmsg(handle);
  @override
  String toString() => errorMsg;
}

/// Serial baudrate
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

/// Number of data bits
enum DataBits { DB5, DB6, DB7, DB8 }

/// Number of stop bits
enum StopBits { SB1, SB2 }

/// Serial error codes
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

// Serial parity
enum Parity {
  PARITY_NONE,
  PARITY_ODD,
  PARITY_EVEN,
}

/// Converts the native error code [value] to [SerialErrorCode].
SerialErrorCode getSerialErrorCode(int value) {
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

final DynamicLibrary _peripheryLib = getPeripheryLib();

// serial_t *dart_serial_open(const char *path, int baudrate)
typedef _dart_serial_open = Pointer<Void> Function(
    Pointer<Utf8> path, Int32 baudrate);
typedef _SerialOpen = Pointer<Void> Function(Pointer<Utf8> path, int baudrate);
final _nativeOpen = _peripheryLib
    .lookup<NativeFunction<_dart_serial_open>>('dart_serial_open')
    .asFunction<_SerialOpen>();

// serial_t * dart_serial_open_advanced(const char *path,
//                              uint32_t baudrate, unsigned int databits,
//                              serial_parity_t parity, unsigned int stopbits,
//                              int xonxoff, int rtscts)
typedef _dart_serial_open_advanced = Pointer<Void> Function(
    Pointer<Utf8> path,
    Int32 baudrate,
    Int32 databits,
    Int32 parity,
    Int32 stopbits,
    Int32 xonxoff,
    Int32 rtscts);
typedef _SerialOpenAdvanced = Pointer<Void> Function(
    Pointer<Utf8> path,
    int baudrate,
    int databits,
    int parity,
    int stopbits,
    int xonxoff,
    int rtscts);
final _nativeOpenAdvanced = _peripheryLib
    .lookup<NativeFunction<_dart_serial_open_advanced>>(
        'dart_serial_open_advanced')
    .asFunction<_SerialOpenAdvanced>();

// const char *dart_serial_errmsg(serial_t *serial)
final _nativeErrmsg = _peripheryLib
    .lookup<NativeFunction<utf8VoidS>>('dart_serial_errmsg')
    .asFunction<utf8VoidF>();

// read_event_t *dart_serial_read(serial_t *serial, int len, int timeout_ms
typedef _dart_serial_read = Pointer<_ReadEvent> Function(
    Pointer<Void> handle, Int32 len, Int32 timeoutMillis);
typedef _SerialReadEvent = Pointer<_ReadEvent> Function(
    Pointer<Void> handle, int len, int timeoutMillis);
final _nativeReadEvent = _peripheryLib
    .lookup<NativeFunction<_dart_serial_read>>('dart_serial_read')
    .asFunction<_SerialReadEvent>();

// int dart_serial_write(serial_t *serial,const uint8_t *buf, size_t len)
typedef _dart_serial_write = Int32 Function(
    Pointer<Void> handle, Pointer<Int8>, Int32 len);
typedef _SerialWrite = int Function(
    Pointer<Void> handle, Pointer<Int8>, int len);
final _nativeWrite = _peripheryLib
    .lookup<NativeFunction<_dart_serial_write>>('dart_serial_write')
    .asFunction<_SerialWrite>();

// int dart_serial_flush(serial_t *serial)
final _nativeFlush = _peripheryLib
    .lookup<NativeFunction<intVoidS>>('dart_serial_flush')
    .asFunction<intVoidF>();

// int dart_serial_dispose(serial_t *serial)
final _nativeDispose = _peripheryLib
    .lookup<NativeFunction<intVoidS>>('dart_serial_dispose')
    .asFunction<intVoidF>();

// int dart_serial_input_waiting(serial_t *serial)
final _nativeSerialInputWaiting = _peripheryLib
    .lookup<NativeFunction<intVoidS>>('dart_serial_input_waiting')
    .asFunction<intVoidF>();

// int dart_serial_output_waiting(serial_t *serial)
final _nativeSerialOutputWaiting = _peripheryLib
    .lookup<NativeFunction<intVoidS>>('dart_serial_output_waiting')
    .asFunction<intVoidF>();

// int dart_serial_poll(serial_t *serial,int timeout_ms)
final _nativePool = _peripheryLib
    .lookup<NativeFunction<intVoidIntS>>('dart_serial_poll')
    .asFunction<intVoidIntF>();

//int dart_serial_get_property(serial_t *serial,SerialProperty_t property)
final _nativeGetSerialProperty = _peripheryLib
    .lookup<NativeFunction<intVoidIntS>>('dart_serial_get_property')
    .asFunction<intVoidIntF>();

// int dart_serial_set_property(serial_t *serial,SerialProperty_t property,int value
typedef _dart_serial_set_property = Int32 Function(
    Pointer<Void> handle, Int32 serialProperty, Int32 value);
typedef _SerialSetProperty = int Function(
    Pointer<Void> handle, int serialProperty, int value);
final _nativeSetSerialProperty = _peripheryLib
    .lookup<NativeFunction<_dart_serial_set_property>>(
        'dart_serial_set_property')
    .asFunction<_SerialSetProperty>();

// double dart_serial_get_vtime(serial_t *serial)
typedef _dart_serial_get_vtime = Double Function(Pointer<Void> handle);
typedef _SerialGetVTIME = double Function(Pointer<Void> handle);
final _nativeGetVTIME = _peripheryLib
    .lookup<NativeFunction<_dart_serial_get_vtime>>('dart_serial_get_vtime')
    .asFunction<_SerialGetVTIME>();

// int dart_serial_set_vtime(serial_t *serial,double vtime)
typedef _dart_serial_set_vtime = Int32 Function(
    Pointer<Void> handle, Double vtime);
typedef _SerialSetVTIME = int Function(Pointer<Void> handle, double vtime);
final _nativeSetVTIME = _peripheryLib
    .lookup<NativeFunction<_dart_serial_set_vtime>>('dart_serial_set_vtime')
    .asFunction<_SerialSetVTIME>();

// int dart_serial_fd(serial_t *serial) {
final _nativeFD = _peripheryLib
    .lookup<NativeFunction<intVoidS>>('dart_serial_fd')
    .asFunction<intVoidF>();

// char *dart_serial_info(serial_t *serial)
final _nativeInfo = _peripheryLib
    .lookup<NativeFunction<utf8VoidS>>('dart_serial_info')
    .asFunction<utf8VoidF>();

// int serial_errno(serial_t *serial);
final _nativeErrno = _peripheryLib
    .lookup<NativeFunction<intVoidS>>('dart_serial_errno')
    .asFunction<intVoidF>();

/// Converts a [baudrate] enum to an int value;
int baudrate2Int(Baudrate baudrate) {
  const tmp = 'Baudrate.B';
  return int.parse(baudrate.toString().substring(tmp.length));
}

/// Converts a [databits] enum to an int value;
int databits2Int(DataBits databits) {
  const tmp = 'DataBits.DB';
  return int.parse(databits.toString().substring(tmp.length));
}

/// Converts a [stopbits] enum to an int value;
int stopbits2Int(StopBits stopbits) {
  const tmp = 'StopBits.SB';
  return int.parse(stopbits.toString().substring(tmp.length));
}

String _getErrmsg(Pointer<Void> handle) {
  return _nativeErrmsg(handle).toDartString();
}

int _checkError(int value) {
  if (value < 0) {
    var errorCode = getSerialErrorCode(value);
    throw SerialException(errorCode, errorCode.toString());
  }
  return value;
}

Pointer<Void> _checkHandle(Pointer<Void> handle) {
  // handle 0 indicates an internal error
  if (handle.address == 0) {
    throw SerialException(
        SerialErrorCode.SERIAL_ERROR_OPEN, 'Error opening serial port');
  }
  return handle;
}

/// Serial wrapper functions for Linux userspace termios tty devices.
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

  /// Opens the <tt>tty</tt> device at the specified [path] (e.g. "/dev/ttyUSB0"), with the specified [baudrate], and the
  /// defaults of 8 data bits, no parity, 1 stop bit, software flow control (xonxoff) off, hardware flow control (rtscts) off.
  Serial(this.path, this.baudrate)
      : databits = DataBits.DB8,
        parity = Parity.PARITY_NONE,
        stopbits = StopBits.SB1,
        rtsct = false,
        xonxoff = false,
        _serialHandle = _checkHandle(
            _nativeOpen(path.toNativeUtf8(), baudrate2Int(baudrate)));

  /// Opens the <tt>tty</tt> device at the specified [path] (e.g. "/dev/ttyUSB0"), with the specified [baudrate], [databits],
  /// [parity], [stopbits], software flow control ([xonxoff]), and hardware flow control ([rtsct]) settings.
  ///
  /// serial should be a valid pointer to an allocated Serial handle structure. databits can be 5, 6, 7, or 8.
  /// parity can be PARITY_NONE, PARITY_ODD, or PARITY_EVEN . StopBits can be 1 or 2.
  Serial.advanced(this.path, this.baudrate, this.databits, this.parity,
      this.stopbits, this.xonxoff, this.rtsct)
      : _serialHandle = _checkHandle(_nativeOpenAdvanced(
            path.toNativeUtf8(),
            baudrate2Int(baudrate),
            databits2Int(databits),
            parity.index,
            stopbits2Int(stopbits),
            xonxoff ? 1 : 0,
            rtsct ? 1 : 0));

  /// Polls for data available for reading from the serial port.
  ///
  ///
  /// [timeout] can be positive for a timeout in milliseconds, zero for a non-blocking poll, or negative
  /// for a blocking poll.
  /// Returns 'true' on success (data available for reading), 'false on timeout,
  bool poll(int timeout) {
    _checkStatus();
    return _checkError(_nativePool(_serialHandle, timeout)) == 1 ? true : false;
  }

  /// Gets the number of bytes waiting to be written to the serial port.
  int getOutputWaiting() {
    _checkStatus();
    return _checkError(_nativeSerialOutputWaiting(_serialHandle));
  }

  /// Gets the number of bytes waiting to be read from the serial port.
  int getInputWaiting() {
    _checkStatus();
    return _checkError(_nativeSerialInputWaiting(_serialHandle));
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
    var event = _nativeReadEvent(_serialHandle, len, timeout);
    try {
      _checkError(event.ref.count);
      return SerialReadEvent(event.ref);
    } finally {
      if (event.ref.data.address != 0) {
        malloc.free(event.ref.data);
      }
      malloc.free(event);
    }
  }

  /// Returns the libc errno of the last failure that occurred.
  int getErrno() {
    _checkStatus();
    return _nativeErrno(_serialHandle);
  }

  /// Writes a list of bytes to the serial port.
  /// Returns the number of bytes written on success,
  int write(List<int> list) {
    _checkStatus();
    if (list.isEmpty) {
      return 0;
    }
    var ptr = malloc<Int8>(list.length);
    try {
      var index = 0;
      for (var i in list) {
        ptr[index++] = i;
      }
      var result = _nativeWrite(_serialHandle, ptr, list.length);
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
    _checkError(_nativeFlush(_serialHandle));
  }

  /// Releases all native resources.
  void dispose() {
    _checkStatus();
    _invalid = true;
    _checkError(_nativeDispose(_serialHandle));
  }

  /// Returns the baudrate.
  /// See [baudrate2Int] for converting the result to an integer.
  Baudrate getBaudrate() {
    _checkStatus();
    return Baudrate.values[_checkError(_nativeGetSerialProperty(
        _serialHandle, _SerialProperty.BAUDRATE.index))];
  }

  /// Sets the [baudrate].
  void setBaudrate(Baudrate baudrate) {
    _checkError(_nativeSetSerialProperty(
        _serialHandle, _SerialProperty.BAUDRATE.index, baudrate2Int(baudrate)));
  }

  /// Returns the number of data bits.
  /// See [databits2Int] for converting the result to an integer.
  DataBits getDataBits() {
    _checkStatus();
    return DataBits.values[_checkError(_nativeGetSerialProperty(
        _serialHandle, _SerialProperty.DATABITS.index))];
  }

  /// Sets the number of [databits].
  void setDataBits(DataBits databits) {
    _checkStatus();
    _checkError(_nativeSetSerialProperty(
        _serialHandle, _SerialProperty.DATABITS.index, databits2Int(databits)));
  }

  /// Returns the number of stop bits.
  /// See [stopbits2Int] for converting the result to an integer.
  StopBits getStopBits() {
    _checkStatus();
    return StopBits.values[_checkError(_nativeGetSerialProperty(
        _serialHandle, _SerialProperty.STOPBITS.index))];
  }

  /// Sets the number of [stopbits].
  void setStopBits(StopBits stopbits) {
    _checkStatus();
    _checkError(_nativeSetSerialProperty(
        _serialHandle, _SerialProperty.STOPBITS.index, stopbits2Int(stopbits)));
  }

  /// Returns the parity property.
  Parity getParity() {
    _checkStatus();
    return Parity.values[_checkError(
        _nativeGetSerialProperty(_serialHandle, _SerialProperty.PARITY.index))];
  }

  /// Sets the [parity].
  void setParity(Parity parity) {
    _checkStatus();
    _checkError(_nativeSetSerialProperty(
        _serialHandle, _SerialProperty.PARITY.index, parity.index));
  }

  /// Returns if the setXONXOFF protocol is enabled or disabled.
  bool isXONXOFF() {
    _checkStatus();
    return _checkError(_nativeGetSerialProperty(
                _serialHandle, _SerialProperty.XONXOFF.index)) ==
            1
        ? true
        : false;
  }

  /// [flag] enables, or disables the setXONXOFF protocol.
  void setXONXOFF(bool flag) {
    _checkStatus();
    _checkError(_nativeSetSerialProperty(
        _serialHandle, _SerialProperty.XONXOFF.index, flag == true ? 1 : 0));
  }

  /// Returns if the RTS/CTS (request to send/ clear to send) flow control is enabled or disabled.
  bool isRTSCTS() {
    _checkStatus();
    return _checkError(_nativeGetSerialProperty(
                _serialHandle, _SerialProperty.RTSCTS.index)) ==
            1
        ? true
        : false;
  }

  /// [flag] enables, or disables the RTSCTS flow control.
  void setRTSCTS(bool flag) {
    _checkStatus();
    _checkError(_nativeSetSerialProperty(
        _serialHandle, _SerialProperty.RTSCTS.index, flag == true ? 1 : 0));
  }

  /// Gets the termios VMIN settings, respectively, of the underlying tty device.
  /// VMIN specifies the minimum number of bytes returned from a blocking read. VTIME specifies the timeout in seconds
  /// of a blocking read. When both VMIN and VTIME settings are configured, VTIME acts as an interbyte
  /// timeout that restarts on every byte received, and a blocking read will block until either VMIN bytes are
  /// read or the VTIME timeout expires after the last byte read. See the termios man page for more information.
  /// vmin can be between 0 and 255. vtime can be between 0 and 25.5 seconds, with a resolution of 0.1 seconds.
  int getVMIN() {
    _checkStatus();
    return _checkError(
        _nativeGetSerialProperty(_serialHandle, _SerialProperty.VMIN.index));
  }

  /// Sets the termios VMIN settings, respectively, of the underlying tty device.
  /// VMIN specifies the minimum number of bytes returned from a blocking read. VTIME specifies the timeout in seconds
  /// of a blocking read. When both VMIN and VTIME settings are configured, VTIME acts as an interbyte
  /// timeout that restarts on every byte received, and a blocking read will block until either VMIN bytes are
  /// read or the VTIME timeout expires after the last byte read. See the termios man page for more information.
  /// vmin can be between 0 and 255. vtime can be between 0 and 25.5 seconds, with a resolution of 0.1 seconds.
  void setVMIN(int vmin) {
    _checkStatus();
    _checkError(_nativeSetSerialProperty(
        _serialHandle, _SerialProperty.VMIN.index, vmin));
  }

  /// Gets the termios VTIME settings, respectively, of the underlying tty device.
  /// VMIN specifies the minimum number of bytes returned from a blocking read. VTIME specifies the timeout in seconds
  /// of a blocking read. When both VMIN and VTIME settings are configured, VTIME acts as an interbyte
  /// timeout that restarts on every byte received, and a blocking read will block until either VMIN bytes are
  /// read or the VTIME timeout expires after the last byte read. See the termios man page for more information.
  /// vmin can be between 0 and 255. vtime can be between 0 and 25.5 seconds, with a resolution of 0.1 seconds.
  double getVTIME() {
    _checkStatus();
    var vtime = _nativeGetVTIME(_serialHandle);
    _checkError(vtime.toInt());
    return vtime;
  }

  /// Sets the termios VTIME settings, respectively, of the underlying tty device.
  /// VMIN specifies the minimum number of bytes returned from a blocking read. VTIME specifies the timeout in seconds
  /// of a blocking read. When both VMIN and VTIME settings are configured, VTIME acts as an interbyte
  /// timeout that restarts on every byte received, and a blocking read will block until either VMIN bytes are
  /// read or the VTIME timeout expires after the last byte read. See the termios man page for more information.
  /// vmin can be between 0 and 255. vtime can be between 0 and 25.5 seconds, with a resolution of 0.1 seconds.
  void setVTIME(double vtime) {
    _checkStatus();
    _checkError(_nativeSetVTIME(_serialHandle, vtime));
  }

  /// Returns the file descriptor (for the underlying tty device) of the Serial handle.
  int getSerialFD() {
    _checkStatus();
    return _checkError(_nativeFD(_serialHandle));
  }

  /// Returns a string representation of the Serial handle.
  String getSerialInfo() {
    _checkStatus();
    var ptr = _nativeInfo(_serialHandle);
    if (ptr.address == 0) {
      // throw an exception
      _checkError(getErrno());
      return '?';
    }
    var text = ptr.toDartString();
    malloc.free(ptr);
    return text;
  }
}
