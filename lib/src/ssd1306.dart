// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "i2c.dart";

const int SSD1306_SETCONTRAST = 0x81;
const int SSD1306_ACTIVATE_SCROLL = 0x2F;
const int SSD1306_DEACTIVATE_SCROLL = 0x2E;
const int SSD1306_SET_VERTICAL_SCROLL_AREA = 0xA3;
const int SSD1306_RIGHT_HORIZONTAL_SCROLL = 0x26;
const int SSD1306_LEFT_HORIZONTAL_SCROLL = 0x27;
const int SSD1306_VERTICAL_AND_RIGHT_HORIZONTAL_SCROLL = 0x29;
const int SSD1306_VERTICAL_AND_LEFT_HORIZONTAL_SCROLL = 0x2A;
const int SSD1306_DISPLAY_ON = 0xAF;
const int SSD1306_DISPLAY_OFF = 0xAE;

const List<int> initSequence = [
  0xae,
  0xd5,
  0x80,
  0xa8,
  0x3f,
  0xd3,
  0x00,
  0x40,
  0x8d,
  0x14,
  0x20,
  0x00,
  0xa1,
  0xc8,
  0xda,
  0x12,
  0x81,
  0xcf,
  0xd9,
  0xf1,
  0xdb,
  0x40,
  0xa4,
  0xa6,
  0xaf
];

/**
 * <p>
 * Hardware access class for a SSD1306 OLED display with the dimensions 128x64.
 * </p>
 * @author Peter Sauer
 *
 */
class OLED_SSD1306 {
  static final int I2C_DEFAULT_ADDRESS = 0x3c;
  int i2cAddress = I2C_DEFAULT_ADDRESS;
  // command set

  I2C device;

  static final int width = 128;
  static final int height = 64;
  static final int offeset = width >> 3;

  OLED_SSD1306(this.device);

  OLED_SSD1306.i2cAddress(this.device, this.i2cAddress);

  void resetPos() {
    device.writeBytesReg(i2cAddress, 0x00, List.filled(3, 0));
  }

  void init() {
    device.writeBytesReg(i2cAddress, 0x00, initSequence);
  }
}
