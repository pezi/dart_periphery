// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'spi.dart';

class ByteBuffer {
  final List<int> data;
  final BitOrder bitOrder;
  final bool isI2C;
  int index;
  ByteBuffer(this.data, this.isI2C)
      : bitOrder = isI2C ? BitOrder.MSB_LAST : BitOrder.MSB_FIRST,
        index = isI2C ? 0 : 1;

  int getInt16() {
    int pos1, pos2;
    if (bitOrder == BitOrder.MSB_FIRST) {
      pos1 = index + 1;
      pos2 = index;
    } else {
      pos1 = index;
      pos2 = index + 1;
    }
    var value = (data[pos1] & 0xFF) | (data[pos2] & 0xFF) << 8;
    if (value > 32768) {
      value -= 65536;
    }
    index += 2;
    return value;
  }

  int getInt8() {
    return data[index++];
  }

  void skipBytes(int value) {
    index += value;
  }
}
