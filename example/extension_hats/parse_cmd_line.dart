// Copyright (c) 2024,2025 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_periphery/src/gpio.dart';

/// Supported extensions hats
enum Hat {
  /// Generic GPIO - no Hat needed
  gpio,

  /// FriendlyElec Nano hat
  nano,

  /// SeeedStudio Grove hat
  grove,

  /// Seeed Studio Grove Plus hat
  grovePlus
}

void usage(String pin, [bool gpio = true]) {
  print("Parameter: [${gpio ? "gpio|" : ""}nano|grove|grovePlus] $pin");
  exit(0);
}

void usage2Pins(String pin1, String pin2, [bool gpio = true]) {
  print("Parameter: [${gpio ? "gpio|" : ""}nano|grove|grovePlus] $pin1 $pin2");
  exit(0);
}

(Hat hat, int pin) checkArgs(bool analog, List<String> args,
    [String pin = "pin"]) {
  if (args.length != 2) {
    usage(pin);
  }
  try {
    return (Hat.values.byName(args[0]), int.parse(args[1]));
  } on Exception {
    usage(pin);
  }
  // never reach this line
  return (Hat.nano, 0);
}

(Hat hat, int pin1, int pin2) checkArgs2Pins(
  bool analog,
  List<String> args, [
  String pin1 = "pin1",
  String pin2 = "pin2",
]) {
  if (args.length != 3) {
    usage2Pins(pin1, pin2, !analog);
  }
  try {
    return (Hat.values.byName(args[0]), int.parse(args[1]), int.parse(args[2]));
  } on Exception {
    usage2Pins(pin1, pin2, !analog);
  }
  // never reach this line
  return (Hat.nano, 0, 0);
}
