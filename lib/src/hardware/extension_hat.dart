// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/friendlyarm/BakeBit/blob/master/Firmware/Source/bakebit_v1.0.0/bakebit_v1.0.0.ino

import 'dart:io';

import 'package:dart_periphery/src/isolate_api.dart';

import '../i2c.dart';

enum HatType { nano, grovePlus, grove }

enum Command {
  digitalRead(1),
  digitalWrite(2),
  analogRead(3),
  analogWrite(4),
  pinMode(5),
  ultraSonic(7),
  firmware(8),
  ledbarInit(110),
  ledbarRelease(111),
  ledbarShow(112),
  servoAttach(120),
  servoDetach(121),
  servoWrite(122);

  final int value;

  const Command(this.value);
}

/// Command buffer for a hat command.
///
/// Format: byte 1 : command, byte 2 : pin, byte 3 and 4: optional parameter
class HatCmd {
  Command cmd;
  HatCmd(this.cmd);

  /// Returns an command buffer containing a command.
  List<int> getCmdSeq() {
    var data = List<int>.filled(4, 0);
    data[0] = cmd.value;
    return data;
  }

  /// Returns a command buffer containing a command, a [pin] and two
  /// optional values: [value] and [value2].
  List<int> getCmdSeqExt(int pin, [int value = 0, int value2 = 0]) {
    var data = <int>[];
    data.add(cmd.value);
    data.add(pin);
    data.add(value);
    data.add(value2);
    return data;
  }
}

/// Digital pin value
enum DigitalValue {
  low,
  high;

  /// Inverts a [DigitalValue]
  DigitalValue invert() {
    return index == 0 ? DigitalValue.high : DigitalValue.low;
  }
}

/// Pin mode
enum PinMode { input, output }

// default i2c address
const int hatArduinoI2Caddress = 0x04;
const int hatRegister = 1;

const int delay = 50;

// The original C code for the GrovePi Plus uses retries
// due a hardware problem :(!
// NanoHat Hub has no problems, seems to be the better hardware!
int retry = 3;

/// Base class for the I2C communication between the SoC
/// (RaspberryPi & NanoPi) and the Arduino Nano based hat.
///
///  [NanoHat](http://wiki.friendlyelec.com/wiki/index.php/BakeBit_-_NanoHat_Hub)
///
///  [GrovePi Plus](https://wiki.seeedstudio.com/GrovePi_Plus)
///
///
class ArduinoBasedHat extends IsolateAPI {
  final I2C i2c;
  bool _autoWait = false;
  int _lastAction = 0;

  /// Sets the [i2c] bus.
  ArduinoBasedHat(this.i2c);
  ArduinoBasedHat.isolate(this.i2c);

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
        writeI2Cblock(HatCmd(Command.pinMode).getCmdSeqExt(pin, mode.index));
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
        writeI2Cblock(HatCmd(Command.digitalRead).getCmdSeqExt(pin));
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
        writeI2Cblock(
            HatCmd(Command.digitalWrite).getCmdSeqExt(pin, value.index));
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
        writeI2Cblock(HatCmd(Command.analogRead).getCmdSeqExt(pin));
        sleep(Duration(milliseconds: delay));
        var data = i2c.readBytesReg(hatArduinoI2Caddress, hatRegister, 4);
        var value = (data[1] & 0xff) << 8 | (data[2] & 0xff);
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
        writeI2Cblock(HatCmd(Command.analogWrite).getCmdSeqExt(pin, value));
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
        writeI2Cblock(HatCmd(Command.firmware).getCmdSeq());
        sleep(Duration(milliseconds: 100));
        var data = i2c.readBytesReg(hatArduinoI2Caddress, hatRegister, 4);
        _updateLastAction();
        return '${data[1] & 0xff}.${data[2] & 0xff}.${data[3] & 0xff}';
      } on I2Cexception catch (e) {
        error = e;
        sleep(Duration(milliseconds: delay));
      }
    }
    throw error;
  }

  void _sendCmd(Command cmd, int pin, [int value1 = 0, int value2 = 0]) {
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

  @override
  IsolateAPI fromJson(String json) {
    return ArduinoBasedHat.isolate(I2C.isolate(json));
  }

  @override
  int getHandle() {
    throw UnimplementedError();
  }

  @override
  void setHandle(int handle) {
    throw UnimplementedError();
  }

  @override
  String toJson() {
    return i2c.toJson();
  }
}

/// Extension hat from [FriendlyARM](http://wiki.friendlyelec.com/wiki/index.php/BakeBit_-_NanoHat_Hub)
/// https://github.com/friendlyarm/BakeBit
class NanoHatHub extends ArduinoBasedHat implements IsolateAPI {
  NanoHatHub([int i2cBus = 0]) : super(I2C(i2cBus));
  NanoHatHub.isolate(super.i2c);

  @override
  IsolateAPI fromJson(String json) {
    return NanoHatHub.isolate(I2C.isolate(json));
  }

  @override
  int getHandle() {
    throw UnimplementedError();
  }

  @override
  void setHandle(int handle) {
    throw UnimplementedError();
  }

  @override
  String toJson() {
    return i2c.toJson();
  }

  /// Initializes the [LED bar](http://wiki.friendlyelec.com/wiki/index.php/BakeBit_-_LED_Bar):
  void ledBarInitExt(int pin, int chipset, int ledNumber) {
    _sendCmd(Command.ledbarInit, pin, chipset, ledNumber);
  }

  /// Initialize the LED bar.
  void ledBarInit(int pin) {
    _sendCmd(Command.ledbarInit, pin, 0, 5);
  }

  /// Shows the LED bar.
  void ledBarShow(int pin, int highBits, int lowBits) {
    _sendCmd(Command.ledbarShow, pin, highBits, lowBits);
  }

  /// Releases the LED bar.
  void ledBarRelease(int pin) {
    _sendCmd(Command.ledbarRelease, pin);
  }

  /// Attaches the servo to [pin].
  void servoAttach(int pin) {
    _sendCmd(Command.servoAttach, pin);
  }

  /// Detaches the servo from [pin].
  ///
  /// https://wiki.friendlyelec.com/wiki/index.php/BakeBit_-_Servo
  void servoDetach(int pin) {
    _sendCmd(Command.servoDetach, pin);
  }

  /// Steers the position of the servo at [pin] to [position].
  /// For details see  http://wiki.friendlyelec.com/wiki/index.php/BakeBit_-_Servo
  void servoWrite(int pin, int position) {
    _sendCmd(Command.servoWrite, pin, position);
  }

  /// Reads a value from the 'Ultrasonic Ranger' in the range form range 5-300cm.
  /// http://wiki.friendlyelec.com/wiki/index.php/BakeBit_-_Ultrasonic_Ranger
  int readUltrasonic(int pin) {
    autoWait();
    var error = I2Cexception.empty();
    for (var i = 0; i < retry; ++i) {
      try {
        writeI2Cblock(HatCmd(Command.ultraSonic).getCmdSeqExt(pin));
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

/// Helper class for the [BakeBit LED bar](http://wiki.friendlyelec.com/wiki/index.php/BakeBit_-_LED_Bar) -
/// see [NanoHatHub.ledBarInitExt] for details.
class BakeBitLedBar {
  int bitMask;

  BakeBitLedBar() : bitMask = 0;

  /// Sets [led] ([LedBarLed.led1]-[LedBarLed.led5]) to [color].
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
/// Do not use this hardware!
/// - UART is not working correct with some devices e.g. CozIR CO2 sensor
/// - Problems using more than 2 I2C devices
/// - Problems using I2C and SPI bus at the same time
///
/// | Paramter        | GrovePi+    |
/// | ----------------| ----------- |
/// | Working Voltage | 5V          |
/// | MCU             | ATMEGA328P  |
/// | Grove Ports     | 7 x Digital(5V), 3 x Analog(5V), 3 x I2C(5V) |
/// |                 | 1 x SERIAL: Connect to ATMEGA328P D0/1(5V) |
/// |                 | 1 x RPISER: Connect to Raspberry Pi(3.3V), 1 x ISP  |
/// | Grove-Digital   | Connect to ATMEGA328P digital pins and transfer to I2C |
/// |                 | signal, then through level converter to Raspberry Pi |
/// | Grove-Analog    | Connect to ATMEGA328P analog pins(10bit ADC) and then |
/// |                 | transfer to I2C signal, then through level converter to |
/// |                 | Raspberry Pi |
/// | Grove-I2C       | Connect through level converter to Raspberry Pi |
class GrovePiPlusHat extends ArduinoBasedHat implements IsolateAPI {
  GrovePiPlusHat([int i2cBus = 1]) : super(I2C(i2cBus));
  GrovePiPlusHat.isolate(super.i2c);

  @override
  IsolateAPI fromJson(String json) {
    return GrovePiPlusHat.isolate(I2C.isolate(json));
  }

  @override
  int getHandle() {
    throw UnimplementedError();
  }

  @override
  void setHandle(int handle) {
    throw UnimplementedError();
  }

  @override
  String toJson() {
    return i2c.toJson();
  }
}

const int rpiHatPid = 0x04;
const int rpiZeroHatPid = 0x05;

///  [Grove Base Hat RaspberryPi](https://www.seeedstudio.com/Grove-Base-Hat-for-Raspberry-Pi.html)
///
///  [Grove Base Hat RaspberryPi Zero](https://wiki.seeedstudio.com/Grove_Base_Hat_for_Raspberry_Pi_Zero)
///
///
/// | Parameter            | Grove Base Hat                      |
/// |----------------------|-------------------------------------|
/// | Working Voltage      | 3.3V                                |
/// | MCU                  | STM32F030F4P6                       |
/// | Grove Ports Pi       | 6 x Digital(3.3V), 4 x Analog(3.3V) |
/// |                      | 3 x I2C(3.3V); 1 x PWM(3.3V)        |
/// |                      | 1 x RPISER(UART) connect to Pi(3.3V)|
/// |                      |                                     |
/// | Grove Ports Pi Zero  | 2 x Digital(3.3V), 3 x Analog(3.3V) |
/// |                      | 3 x I2C(3.3V), 1 x PWM(3.3V)        |
/// |                      | 1 x RPISER(UART) connect to Pi(3.3V)|
/// |                      |                                     |
/// | Grove-Digital        | Connect to Raspberry Pi directly    |
/// | Grove-Analog         | Connect to STM32F030F4P6(12bit ADC  |
/// |                      | and then transfer to I2C signal,    |
/// |                      | route to Pi directly                |
/// | Grove-I2C, Grove-PWM | Connect to Raspberry Pi directly    |
/// | and RPISER           |                                     |
class GroveBaseHat extends IsolateAPI {
  final I2C i2c;
  int _id = 0;
  GroveBaseHat([int i2cBus = 1]) : i2c = I2C(i2cBus);
  GroveBaseHat.isolate(this.i2c);

  /// Returns the internal hardware id of the hat.
  /// RPI_HAT_PID (0x4) for a `Grove Base Hat RPi`, and
  /// RPI_ZERO_HAT_PID (0x05) for a `Grove Base Hat RPi Zero`.
  int getId() {
    if (_id == 0) {
      _id = _read16BitRegister(0x00);
    }
    return _id;
  }

  /// Returns the name of the hat model.
  String getName() {
    switch (getId()) {
      case rpiHatPid:
        return 'Grove Base Hat RPi';

      case rpiZeroHatPid:
        return 'Grove Base Hat RPi Zero';
    }
    return 'Unknown Hat model';
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

  /// Reads the ratio between channel input voltage and power voltage
  /// (most time it's 3.3V).
  /// [channel] 0 - 7, specify the channel to read, returns the ration in 0.1%.
  int readRatio(int channel) {
    _checkChannel(channel);
    return _read16BitRegister(0x30 + channel);
  }

  /// Returns `true` for the Pi Zero model, false for the Pi model.
  bool isHatRPiZero() {
    return rpiZeroHatPid == getId();
  }

  @override
  IsolateAPI fromJson(String json) {
    return GroveBaseHat.isolate(I2C.isolate(json));
  }

  @override
  int getHandle() {
    throw UnimplementedError();
  }

  @override
  void setHandle(int handle) {
    throw UnimplementedError();
  }

  @override
  String toJson() {
    return i2c.toJson();
  }
}
