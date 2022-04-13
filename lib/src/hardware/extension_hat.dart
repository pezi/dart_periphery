// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import '../i2c.dart';

const int digitalReadCmd = 1;
const int digitalWriteCmd = 2;
const int analogReadCmd = 3;
const int analogWriteCmd = 4;
const int pinModeCmd = 5;
const int ultraSonicCmd = 7;
const int firmwareCmd = 8;
const int ledbarInitCmd = 110;
const int ledbarReleaseCmd = 111;
const int ledbarShowCmd = 112;
const int servoAttachCmd = 120;
const int servoDetachCmd = 121;
const int servoWriteCmd = 122;

/// Command buffer for a hat command.
///
/// Format: byte 1 : command, byte 2 : pin, byte 3 and 4: optional parameter
class HatCmd {
  int cmd;
  HatCmd(this.cmd);

  /// Returns an command buffer containing a command.
  List<int> getCmdSeq() {
    var data = List<int>.filled(4, 0);
    data[0] = cmd;
    return data;
  }

  /// Returns a command buffer containing a command, a [pin] and two optional values: [value] and  [value2].
  List<int> getCmdSeqExt(int pin, [int value = 0, int value2 = 0]) {
    var data = <int>[];
    data.add(cmd);
    data.add(pin);
    data.add(value);
    data.add(value2);
    return data;
  }
}

/// Digital value a [GrovePiPlusHat] or [NanoHatHub] pin.
enum DigitalValue { low, high }

/// Pin mode of a  [GrovePiPlusHat] or [NanoHatHub] pin.
enum PinMode { input, output }

// default i2c address
const int hatArduinoI2Caddress = 0x04;
const int hatRegister = 1;

const int delay = 50;

// The orginal C code for the GrovePi Plus uses retries due a hardware problem :(!
// NanoHat Hub has no problems, seems to be the better hardware!
int retry = 3;

/// Base class for the I2C communication between the SoC
/// (RaspberryPi & NanoPi) and the Arduino Nano based hat.
///
///  <a href="http://wiki.friendlyarm.com/wiki/index.php/BakeBit_-_NanoHat_Hub">NanoHat Hub</a><br>
///  <a href="https://wiki.seeedstudio.com/GrovePi_Plus">GrovePi Plus</a>
///
class ArduinoBasedHat {
  final I2C i2c;
  bool _autoWait = false;
  int _lastAction = 0;

  /// Sets the [i2c] bus.
  ArduinoBasedHat(this.i2c);

  /// Updates the timestamp of the last action.
  void _updateLastAction() {
    if (_autoWait) {
      _lastAction = DateTime.now().millisecondsSinceEpoch;
    }
  }

  /// Enable or disables the auto wait.
  void setAutoWait(bool flag) {
    _autoWait = flag;
  }

  /// Ensures that a delay of at last [delay] ms go by.
  void autoWait() {
    if (_autoWait) {
      var diff = DateTime.now().millisecondsSinceEpoch - _lastAction;
      if (diff < delay) {
        sleep(Duration(microseconds: diff));
      }
    }
  }

  /// Reads a byte array from the I2C bus.
  List<int> readI2Cblock(int len) {
    autoWait();
    var error = I2Cexception.empty();
    for (var i = 0; i < retry; ++i) {
      try {
        var data = i2c.readBytesReg(hatArduinoI2Caddress, hatRegister, len);
        _updateLastAction();
        return data;
      } on I2Cexception catch (e) {
        error = e;
        sleep(Duration(milliseconds: delay));
      }
    }
    throw error;
  }

  /// Writes a byte array to the I2C bus.
  void writeI2Cblock(List<int> data) {
    autoWait();
    var error = I2Cexception.empty();
    for (var i = 0; i < retry; ++i) {
      try {
        i2c.writeBytesReg(hatArduinoI2Caddress, hatRegister, data);
        _updateLastAction();
        return;
      } on I2Cexception catch (e) {
        error = e;
        sleep(Duration(milliseconds: delay));
      }
    }
    throw error;
  }

  /// Sets the pin [mode] for a [pin].
  void pinMode(int pin, PinMode mode) {
    autoWait();
    var error = I2Cexception.empty();
    for (var i = 0; i < retry; ++i) {
      try {
        writeI2Cblock(HatCmd(pinModeCmd).getCmdSeqExt(pin, mode.index));
        _updateLastAction();
        return;
      } on I2Cexception catch (e) {
        error = e;
        sleep(Duration(milliseconds: delay));
      }
    }
    throw error;
  }

  /// Reads a [DigitalValue] from a given [pin].
  DigitalValue digitalRead(int pin) {
    autoWait();
    var error = I2Cexception.empty();
    for (var i = 0; i < retry; ++i) {
      try {
        writeI2Cblock(HatCmd(digitalReadCmd).getCmdSeqExt(pin));
        sleep(Duration(milliseconds: delay));
        var value = i2c.readByteReg(hatArduinoI2Caddress, 1);
        _updateLastAction();
        if (value == 0) {
          return DigitalValue.low;
        }
        return DigitalValue.high;
      } on I2Cexception catch (e) {
        error = e;
        sleep(Duration(milliseconds: delay));
      }
    }
    throw error;
  }

  /// Writes a digital [value] to a given [pin].
  void digitalWrite(int pin, DigitalValue value) {
    autoWait();
    var error = I2Cexception.empty();
    for (var i = 0; i < retry; ++i) {
      try {
        writeI2Cblock(HatCmd(digitalWriteCmd).getCmdSeqExt(pin, value.index));
        _updateLastAction();
        return;
      } on I2Cexception catch (e) {
        error = e;
        sleep(Duration(milliseconds: delay));
      }
    }
    throw error;
  }

  /// Reads an analog value from a given [pin].
  int analogRead(int pin) {
    autoWait();
    var error = I2Cexception.empty();
    for (var i = 0; i < retry; ++i) {
      try {
        writeI2Cblock(HatCmd(analogReadCmd).getCmdSeqExt(pin));
        sleep(Duration(milliseconds: delay));
        var data = i2c.readBytesReg(hatArduinoI2Caddress, hatRegister, 4);
        var value = (data[1] & 0xff) * 256 + (data[2]);
        if (value == 65535) {
          value = -1;
        }
        _updateLastAction();
        return value;
      } on I2Cexception catch (e) {
        error = e;
        sleep(Duration(milliseconds: delay));
      }
    }
    throw error;
  }

  /// Writes an analog [value] to a [pin].
  void analogWrite(int pin, int value) {
    autoWait();
    var error = I2Cexception.empty();
    for (var i = 0; i < retry; ++i) {
      try {
        writeI2Cblock(HatCmd(analogWriteCmd).getCmdSeqExt(pin, value));
        _updateLastAction();
        return;
      } on I2Cexception catch (e) {
        error = e;
        sleep(Duration(milliseconds: delay));
      }
    }
    throw error;
  }

  /// Returns the firmware of the hat.
  String getFirmwareVersion() {
    autoWait();
    var error = I2Cexception.empty();
    for (var i = 0; i < retry; ++i) {
      try {
        writeI2Cblock(HatCmd(firmwareCmd).getCmdSeq());
        sleep(Duration(milliseconds: 100));
        var data = i2c.readBytesReg(hatArduinoI2Caddress, hatRegister, 4);
        print(data.length);
        _updateLastAction();
        return '${data[1] & 0xff}.${data[2] & 0xff}.${data[3] & 0xff}';
      } on I2Cexception catch (e) {
        error = e;
        sleep(Duration(milliseconds: delay));
      }
    }
    throw error;
  }

  void _sendCmd(int cmd, int pin, [int value1 = 0, int value2 = 0]) {
    autoWait();
    var error = I2Cexception.empty();
    for (var i = 0; i < retry; ++i) {
      try {
        writeI2Cblock(HatCmd(cmd).getCmdSeqExt(pin, value1, value2));
        _updateLastAction();
        return;
      } on I2Cexception catch (e) {
        error = e;
        sleep(Duration(milliseconds: delay));
      }
    }
    throw error;
  }
}

/// Extension hat from [FriendlyARM](http://wiki.friendlyarm.com/wiki/index.php/BakeBit_-_NanoHat_Hub)
///
/// See
class NanoHatHub extends ArduinoBasedHat {
  int i2cBus;
  NanoHatHub([this.i2cBus = 0]) : super(I2C(i2cBus));

  /// Initializes the [LED bar](http://wiki.friendlyarm.com/wiki/index.php/BakeBit_-_LED_Bar):
  void ledBarInitExt(int pin, int chipset, int ledNumber) {
    _sendCmd(ledbarInitCmd, pin, chipset, ledNumber);
  }

  /// Initialize the LED bar.
  void ledBarInit(int pin) {
    _sendCmd(ledbarInitCmd, pin, 0, 5);
  }

  /// Shows the LED bar.
  void ledBarShow(int pin, int highBits, int lowBits) {
    _sendCmd(ledbarShowCmd, pin, highBits, lowBits);
  }

  /// Releases the LED bar.
  void ledBarRelease(int pin) {
    _sendCmd(ledbarReleaseCmd, pin);
  }

  /// Attachs the servo to [pin].
  void servoAttach(int pin) {
    _sendCmd(servoAttachCmd, pin);
  }

  /// Detatchs the servo from [pin].
  ///
  /// http://wiki.friendlyarm.com/wiki/index.php/BakeBit_-_Servo
  void servoDetach(int pin) {
    _sendCmd(servoDetachCmd, pin);
  }

  /// Steers the position of the servo at [pin] to [position].
  /// For detials see  http://wiki.friendlyarm.com/wiki/index.php/BakeBit_-_Servo
  void servoWrite(int pin, int position) {
    _sendCmd(servoWriteCmd, pin, position);
  }

  /// Reads a value from the 'Ultrasonic Ranger' in the range form range 5-300cm.
  /// http://wiki.friendlyarm.com/wiki/index.php/BakeBit_-_Ultrasonic_Ranger
  int readUltrasonic(int pin) {
    autoWait();
    var error = I2Cexception.empty();
    for (var i = 0; i < retry; ++i) {
      try {
        writeI2Cblock(HatCmd(ultraSonicCmd).getCmdSeqExt(pin));
        sleep(Duration(milliseconds: 100));
        var data = i2c.readBytesReg(hatArduinoI2Caddress, hatRegister, 3);
        _updateLastAction();
        return (data[1] & 0xff) * 256 | (data[2] & 0xff);
      } on I2Cexception catch (e) {
        error = e;
        sleep(Duration(milliseconds: delay));
      }
    }
    throw error;
  }
}

/// LED bar color - see [NanoHatHub.ledBarInitExt] for details.
enum LedBarColor { green, red, yellow, blue, ghostWhite, orange, cyan }

/// LED bar led numeration - see [NanoHatHub.ledBarInitExt] for details.
enum LedBarLed { led1, led2, led3, led4, led5 }

/// Helper class for the [BakeBit LED bar](http://wiki.friendlyarm.com/wiki/index.php/BakeBit_-_LED_Bar) -
/// see [NanoHatHub.ledBarInitExt] for details.
class BakeBitLedBar {
  int bitMask;

  BakeBitLedBar() : bitMask = 0;

  /// Sets [led] ([LedBarLed.LED1]-[LedBarLed.LED5]) to [color].
  void setLed(LedBarLed led, LedBarColor color) {
    bitMask |= (color.index + 1) << (led.index * 3);
  }

  /// Returns the lower internal 8-bit mask.
  int getLowBits() {
    return bitMask & 0xff;
  }

  /// Returns the upper internal 8-bit mask.
  int getHighBits() {
    return (bitMask & 0xff00) >> 8;
  }

  // Returns the internal 16-bit mask.
  int getBitMask() {
    return bitMask;
  }
}

/// SeedStudio [GrovePiPlusHat](https://wiki.seeedstudio.com/GrovePi_Plus/)
///
/// Do not use this hardware
/// - UART is not working correct with some devices e.g. CozIR CO2 sensor
/// - Problems using more than 2 I2C devices
/// - Problems using I2C and SPI bus at the same time
class GrovePiPlusHat extends ArduinoBasedHat {
  final int i2cBus;
  GrovePiPlusHat([this.i2cBus = 1]) : super(I2C(i2cBus));
}

const int rpiHatPid = 0x04;
const int rpiZeroHatPid = 0x05;

/// SeedStudio [Grove Base Hat for Raspberry Pi](https://wiki.seeedstudio.com/Grove_Base_Hat_for_Raspberry_Pi/)
class GroveBaseHat {
  final I2C i2c;
  final int i2cBus;
  int _id = 0;
  GroveBaseHat([this.i2cBus = 1]) : i2c = I2C(i2cBus);

  /// Returns the internal hardware id of the hat.
  /// RPI_HAT_PID (0x4) for a 'Grove Base Hat RPi', and
  /// RPI_ZERO_HAT_PID (0x05) for a 'Grove Base Hat RPi Zero'.
  int getId() {
    if (_id == 0) {
      _id = _read16BitRegister(0x00);
    }
    return _id;
  }

  /// Returns the name of the hat model.
  String getName() {
    print(getId());
    switch (getId()) {
      case rpiHatPid:
        return 'Grove Base Hat RPi';

      case rpiZeroHatPid:
        return 'Grove Base Hat RPi Zero';
    }
    return 'Unkown Hat model';
  }

  void _checkChannel(int channel) {
    if (!(channel >= 0 && channel <= 7)) {
      throw ('Invalid channel $channel - valid range [0,7]');
    }
  }

  /// Reads the raw data of ADC unit, with 12 bits resolution
  /// from the [channel] 0 - 7 and
  /// returns a ADC result in the range [0 - 4095].
  int readADCraw(int channel) {
    _checkChannel(channel);
    return _read16BitRegister(0x10 + channel);
  }

  /// Reads the voltage data of ADC unit from the [channel] 0 - 7 and
  /// returns the voltage in mV.
  int readInputVoltage(int channel) {
    _checkChannel(channel);
    return _read16BitRegister(0x20 + channel);
  }

  /// Returns the supply voltage.
  int getGrovePowerSupplyVoltage() {
    return _read16BitRegister(0x29);
  }

  /// Returns the firmware version.
  int getFirmware() {
    return _read16BitRegister(0x02);
  }

  int _read16BitRegister(int cmd) {
    i2c.writeByte(hatArduinoI2Caddress, cmd);
    return i2c.readWord(hatArduinoI2Caddress);
  }

  /// Changes the I2C address of the hat. NOT TESTED!
  void changeI2Caddress(int newI2Caddress) {
    i2c.writeWordReg(hatArduinoI2Caddress, 0, (0xC0 << 16) | newI2Caddress);
  }

  /// Resets the hat. NOT TESTED!
  void resetHat() {
    i2c.writeByteReg(hatArduinoI2Caddress, 0, 0xF0);
  }

  /// Reads the ratio between channel input voltage and power voltage (most time it's 3.3V).
  /// [channel] 0 - 7, specify the channel to read, returns the ration in 0.1%.
  int readRatio(int channel) {
    _checkChannel(channel);
    return _read16BitRegister(0x30 + channel);
  }

  /// Returns true for the Pi Zero model, false for the Pi model.
  bool isHatRPiZero() {
    return rpiZeroHatPid == getId();
  }
}

/*

void main() {
  var hat = ArduinoBasedHat(I2C(0));
  print(hat.getFirmwareVersion());
  hat.pinMode(3, PinMode.OUTPUT);
  hat.digitalWrite(3, DigitalValue.LOW);

  hat.pinMode(4, PinMode.INPUT);
  var on = false;
  while (true) {
    var v = hat.digitalRead(4);
    //print(v);
    if (v == DigitalValue.LOW && on == false) {
      hat.digitalWrite(3, DigitalValue.HIGH);
      on = true;
    }
    if (v == DigitalValue.HIGH && on == true) {
      hat.digitalWrite(3, DigitalValue.LOW);
      on = false;
    }
    sleep(Duration(milliseconds: 100));
  }
  //sleep(Duration(seconds: 10));
  //hat.digitalWrite(3, DigitalValue.LOW);
}
*/

void main() {
  var hat = GroveBaseHat();
  print(hat.getFirmware());
  print(hat.getName());
  while (true) {
    print(hat.readADCraw(0));
    sleep(Duration(milliseconds: 500));
  }
}
