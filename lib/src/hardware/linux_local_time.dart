// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'package:ffi/ffi.dart';

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

/// Representation of the C 'struct timeval' defined in `<sys/time.h>`
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

/// Sets the linux system (local) time using a [DateTime].
///
/// The provided [DateTime] is assumed to represent local time.
/// The code converts it to UTC (because the system clock is in UTC)
/// and then fills a timeval structure for `settimeofday`.
bool setLinuxLocalTime(DateTime dt) {
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
      return false;
    } else {
      return true;
    }
  } finally {
    // Free the allocated memory.
    calloc.free(tvPtr);
  }
}
