// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Bit order of multiple byte data of [I2C] or [SPI] devices. This order
/// is defined by manufacturer of the device.
enum BitOrder { msbFirst, msbLast }

enum ByteBufferSrc { i2c, spi, undefined }

/// Helper class for reading 16/8-bit values from a byte array.
class ByteBuffer {
  final List<int> data;
  final BitOrder bitOrder;
  final ByteBufferSrc dataSource;
  int _index;

  /// Creates a byte buffer with [data] and a default [bitOrder]. [dataSource] defines the source, a I2C or a SPI read operation.
  ///
  /// For [dataSource] = [ByteBufferSrc.spi] the internal buffer index starts with 1.
  ByteBuffer(this.data, this.dataSource, this.bitOrder)
      : _index = (dataSource == ByteBufferSrc.i2c ||
                dataSource == ByteBufferSrc.undefined)
            ? 0
            : 1;

  /// Returns a signed 16-bit value.
  int getInt16() {
    int pos1, pos2;
    if (bitOrder == BitOrder.msbFirst) {
      pos1 = _index + 1;
      pos2 = _index;
    } else {
      pos1 = _index;
      pos2 = _index + 1;
    }
    var value = (data[pos1] & 0xFF) | (data[pos2] & 0xFF) << 8;
    if (value > 32768) {
      value -= 65536;
    }
    _index += 2;
    return value;
  }

  /// Returns a signed 8-bit value.
  int getInt8() {
    return data[_index++];
  }

  /// Skips [value] bytes.
  void skipBytes(int value) {
    _index += value;
  }
}

const int polynomial = 0x31;

/// CRC8 checksum
int crc8(List<int> data) {
  var crc = 0xff;

  for (var b in data) {
    crc ^= b;

    for (var i = 0; i < 8; ++i) {
      if (crc & 0x80 != 0) {
        crc <<= 1;
        crc ^= 0x131;
      } else {
        crc <<= 1;
      }
    }
  }
  return crc & 0xff;
}

/// Checks the CRC of byte buffer with following order: [byte<sub>1</sub>,byte<sub>2</sub>,crc,...]
bool checkCRC(List<int> data) {
  if (data.length % 3 != 0) {
    return false;
  }
  for (var i = 0; i < data.length; i += 3) {
    if (crc8([data[i], data[i + 1]]) != (data[i + 2] & 0xff)) {
      return false;
    }
  }
  return true;
}

/// Converter for string with bin value to int
extension BinConverter on String {
  /// Coverts string containing a binary sequence with a leading b to a an int.
  /// '0b10000000'
  int bin() {
    var s = this;
    // skip the optional b
    var pos = s.indexOf('b');
    if (pos > 0) {
      s = s.substring(pos + 1);
    }
    return int.parse(s, radix: 2);
  }
}
