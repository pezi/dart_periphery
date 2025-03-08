import 'dart:typed_data';

// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

// https://github.com/stlehmann/micropython-ssd1306/blob/master/ssd1306.py#L112
// https://javl.github.io/image2cpp/

enum Command {
  setContrast(0x81),
  activateScroll(0x2F),
  deactivateScroll(0x2E),
  setVerticalScrollArea(0xA3),
  rightHorizontalScroll(0x26),
  leftHorizontalScroll(0x27),
  verticalAndRightHorizontalScroll(0x29),
  verticalAndLeftHorizontalScroll(0x2A),
  displayOn(0xAF),
  displayOff(0xAE);

  final int command;
  const Command(this.command);
}

/// Default address of the [SSD1306] display.
const int ssd1306DefaultI2Caddress = 0x3C;

List<int> _initSequence = [
  0xAE,
  0xD5,
  0x80,
  0xA8,
  0x3F,
  0xD3,
  0x00,
  0x40,
  0x8D,
  0x14,
  0x20,
  0x00,
  0xA1,
  0xC8,
  0xDA,
  0x12,
  0x81,
  0xCF,
  0xD9,
  0xF1,
  0xDB,
  0x40,
  0xA4,
  0xA6,
  0xAF
];

const int _width = 128;
const int _height = 64;
const int _offset = _width ~/ 8;

/// SSD1306 128 x 64 Dot Matrix OLED
///
/// See for more
/// * [SSD1306 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_ssd1306.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/ssd1306.dart)
/// * [Datasheet](https://cdn-shop.adafruit.com/datasheets/SSD1306.pdf)
class SSD1306 {
  final I2C i2c;
  final int i2cAddress;
  late Uint8List _data;

  /// Creates a SSD1306 instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  SSD1306(this.i2c, [this.i2cAddress = ssd1306DefaultI2Caddress]) {
    i2c.writeBytesReg(i2cAddress, 0, _initSequence);
  }

  /// Resets the internal memory write index to the begin.
  void resetPos() {
    i2c.writeBytesReg(i2cAddress, 0, [0xb0, 0x00, 0x10]);
  }

  /// Stops the scrolling of the display.
  void stopScroll() {
    i2c.writeByteReg(i2cAddress, 0, Command.deactivateScroll.command);
  }

  /// Clears the display.
  void clear() {
    resetPos();
    i2c.writeBytesReg(
        i2cAddress, 0x40, List<int>.filled(_width * _height ~/ 8, 0x00));
  }

  /// Sets the [contrast] of the display.
  void setContrast(int contrast) {
    i2c.writeByteReg(i2cAddress, 0, Command.setContrast.command);
    i2c.writeByteReg(i2cAddress, 0, contrast & 0xFF);
  }

  /// Turns on the display.
  void displayOn() {
    i2c.writeByteReg(i2cAddress, 0, Command.displayOn.command);
  }

  /// Turns off the display.
  void displayOff() {
    i2c.writeByteReg(i2cAddress, 0, Command.displayOff.command);
  }

  /// Initiates vertical scrolling of the display content towards [left],
  /// starting from position [start] and continuing until [end].
  void scrollHorizontally(bool left, int start, int end) {
    i2c.writeBytesReg(i2cAddress, 0, [
      left
          ? Command.leftHorizontalScroll.command
          : Command.rightHorizontalScroll.command,
      0x00,
      start,
      0x00,
      end,
      0x00,
      0xFF,
      Command.activateScroll.command
    ]);
  }

  /// Initiates diagonal scrolling of the display content towards [left],
  /// starting from position [start] and continuing until [end].
  void scrollDiagonally(bool left, int start, int end) {
    i2c.writeBytesReg(i2cAddress, 0, [
      Command.setVerticalScrollArea.command,
      0x00,
      _height,
      left
          ? Command.verticalAndLeftHorizontalScroll.command
          : Command.verticalAndRightHorizontalScroll.command,
      0x00,
      start,
      0x00,
      end,
      0x01,
      Command.activateScroll.command
    ]);
  }

  int _convertByte(int index, int j) {
    int mask = 1 << j;
    int byte = 0;

    for (int i = 0; i < 8; i++) {
      if ((_data[index + _offset * i] & mask) != 0) {
        byte |= (1 << i);
      }
    }
    return byte;
  }

  /// Displays a bitmap with SSD1306 specific [data].
  void displayBitmap(Uint8List data) {
    resetPos();
    _data = data;
    int index = 0;
    int count = 0;

    var buffer = Uint8List(data.length);
    for (int y = 0; y < _height / 8; ++y) {
      int pos = index;
      for (int i = 0; i < _width / 8; ++i) {
        for (int j = 7; j >= 0; --j) {
          buffer[count++] = _convertByte(pos, j);
        }
        ++pos;
      }
      index += _width;
    }
    i2c.writeBytesReg(i2cAddress, 0x40, buffer);
  }

  /// Displays a bitmap with SSD1306 specific [data].
  ///
  ///	*	The display has 8 pages for a 128×64 display (each 8 pixels high).
  /// *	Each page contains 128 columns.
  /// * A single byte in the SSD1306 RAM represents 8 vertical pixels, with the LSB (bit 0) at the top and MSB (bit 7) at the bottom.
  ///
  /// e.g. 0x18 (00011000b) represents
  /// ```
  /// ░ Bit 0
  /// ░ Bit 1
  /// ░ Bit 2
  /// █ Bit 3
  /// █ Bit 4
  /// ░ Bit 5
  /// ░ Bit 6
  /// ░ Bit 7

  /// ```
  void displayNativeBitmap(Uint8List data) {
    resetPos();
    i2c.writeUint8Reg(i2cAddress, 0x40, data);
  }
}
