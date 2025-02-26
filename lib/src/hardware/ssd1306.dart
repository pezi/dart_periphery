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

const int width = 128;
const int height = 64;
const int offset = width ~/ 8;

/// Sensirion SHT4x temperature and humidity sensor with a high accuracy.
///
/// See for more
/// * [SHT31 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_ssd1306.dart)
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
        i2cAddress, 0x40, List<int>.filled(width * height ~/ 8, 0x00));
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
      height,
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

  int convertByte(int index, int j) {
    int mask = 1 << j;
    int byte = 0;

    for (int i = 0; i < 8; i++) {
      if ((_data[index + offset * i] & mask) != 0) {
        byte |= (1 << i);
      }
    }
    return byte;
  }

  void displayBitmap(Uint8List data) {
    resetPos();
    _data = data;
    int index = 0;
    int count = 0;

    var buffer = Uint8List(data.length);
    for (int y = 0; y < height / 8; ++y) {
      int pos = index;
      for (int i = 0; i < width / 8; ++i) {
        for (int j = 7; j >= 0; --j) {
          buffer[count++] = convertByte(pos, j);
        }
        ++pos;
      }
      index += width;
    }
    i2c.writeBytesReg(i2cAddress, 0x40, buffer.toList());
  }

  void displayNativeBitmap(Uint8List data) {
    resetPos();
    i2c.writeBytesReg(i2cAddress, 0x40, data.toList());
  }
}
