// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'package:ffi/ffi.dart';

import '../../dart_periphery.dart';

// Resources
// https://github.com/adafruit/Adafruit_CircuitPython_DS1307/blob/main/adafruit_ds1307.py
// https://github.com/brainelectronics/micropython-ds1307/blob/main/ds1307/ds1307.py

/// Default address of the [DS1307] sensor.
const int ds1307DefaultI2Caddress = 0x68;

enum DS1307reg {
  dateTime(0),
  chipHalt(128),
  controlReg(7),
  ramlReg(8);

  const DS1307reg(this.reg);
  final int reg;
}

/// [DS1307] exception
class DS1307exception implements Exception {
  DS1307exception(this.errorMsg);
  final String errorMsg;
  @override
  String toString() => errorMsg;
}

int bcd2dec(int value) {
  return ((value >> 4) * 10) + (value & 0x0F);
}

int dec2bcd(int value) {
  return (value ~/ 10) << 4 | (value % 10);
}

/// DS1307 real time clock
///
/// See for more
/// * [SHT31 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_ds1307.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/ds1307.dart)
/// * [Datasheet](https://www.analog.com/media/en/technical-documentation/data-sheets/ds1307.pdf)
class DS1307 {
  final I2C i2c;
  final int i2cAddress;

  // Creates a DS1307 rtc instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  DS1307(this.i2c, [this.i2cAddress = ds1307DefaultI2Caddress]) {
    var value = i2c.readByteReg(ds1307DefaultI2Caddress, 0x07);
    print(value);
    if (value & 0x6C != 0) {
      throw DS1307exception("Unable to find DS1307 at i2c address 0x68.");
    }
    value = i2c.readByteReg(ds1307DefaultI2Caddress, 0x03);
    if (value & 0x6C != 0xF8) {
      throw DS1307exception("Unable to find DS1307 at i2c address 0x68.");
    }
  }

  DateTime getDateTime() {
    var data =
        i2c.readBytesReg(ds1307DefaultI2Caddress, DS1307reg.dateTime.reg, 7);
    int year = bcd2dec(data[6]) + 2000;
    int month = bcd2dec(data[5]);
    int day = bcd2dec(data[4]);
    int hour = bcd2dec(data[2]);
    int minute = bcd2dec(data[1]);
    int second = bcd2dec(data[0] & 0x7f);

    // Create a DateTime object with time.
    return DateTime(year, month, day, hour, minute, second);
  }

  void setDateTime(DateTime dateTime) {
    var data = List<int>.filled(7, 0);
    data[0] = dec2bcd(dateTime.second);
    data[1] = dec2bcd(dateTime.minute);
    data[2] = dec2bcd(dateTime.hour);
    data[3] = dec2bcd(dateTime.weekday);
    data[4] = dec2bcd(dateTime.day);
    data[5] = dec2bcd(dateTime.month);
    data[6] = dec2bcd(dateTime.year - 2000);

    i2c.writeBytesReg(ds1307DefaultI2Caddress, DS1307reg.dateTime.reg, data);
  }
}

// Load the standard C library.
final DynamicLibrary libc = DynamicLibrary.open('libc.so.6');

/// FFI binding for settimeofday:
///   int settimeofday(const struct timeval *tv, const struct timezone *tz);
/// We pass a null pointer for tz.
typedef SettimeofdayNative = Int32 Function(
    Pointer<Timeval> tv, Pointer<Void> tz);
typedef SettimeofdayDart = int Function(Pointer<Timeval> tv, Pointer<Void> tz);

final SettimeofdayDart settimeofday =
    libc.lookupFunction<SettimeofdayNative, SettimeofdayDart>('settimeofday');

/// Representation of the C 'struct timeval' defined in <sys/time.h>
///
/// In Linux on 64-bit systems, both fields are typically 64-bit integers:
///   struct timeval {
///       time_t      tv_sec;   // seconds since epoch
///       suseconds_t tv_usec;  // microseconds
///   };
base class Timeval extends Struct {
  @Int64()
  // ignore: non_constant_identifier_names
  external int tv_sec;

  @Int64()
  // ignore: non_constant_identifier_names
  external int tv_usec;
}

/// Sets the linux system (local) time using a Dart [DateTime].
///
/// The provided [dt] is assumed to represent local time.
/// The code converts it to UTC (because the system clock is in UTC)
/// and then fills a timeval structure for settimeofday.
void setLinuxLocalTime(DateTime dt) {
  // Convert the provided DateTime to UTC.
  final dtUtc = dt.toUtc();

  // Get the total microseconds since the Unix epoch.
  final microsecondsSinceEpoch = dtUtc.microsecondsSinceEpoch;
  final seconds = microsecondsSinceEpoch ~/ 1000000;
  final microseconds = microsecondsSinceEpoch % 1000000;

  // Allocate and populate the timeval struct.
  final Pointer<Timeval> tvPtr = calloc<Timeval>();

  tvPtr.ref.tv_sec = seconds;
  tvPtr.ref.tv_usec = microseconds;

  try {
    // Call settimeofday. The second parameter (tz) is passed as nullptr.
    final int result = settimeofday(tvPtr, nullptr);
    if (result != 0) {
      print(
          "Failed to set system time. Are you running as root? (Error code: $result)");
    } else {
      print("System time successfully set to: $dt");
    }
  } finally {
    // Free the allocated memory.
    calloc.free(tvPtr);
  }
}
