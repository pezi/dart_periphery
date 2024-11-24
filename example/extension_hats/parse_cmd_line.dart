// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

enum Hat { nano, grove, grovePlus }

void usage() {
  print("Parameter: [nano|grove|grovePlus] pin");
  exit(0);
}

void usage2Pins() {
  print("Parameter: [nano|grove|grovePlus] pin1 pin2");
  exit(0);
}

(Hat hat, int pin) checkArgs(List<String> args) {
  if (args.length != 2) {
    usage();
  }
  try {
    return (Hat.values.byName(args[0]), int.parse(args[1]));
  } on Exception {
    usage();
  }
  // never reach this line
  return (Hat.nano, 0);
}

(Hat hat, int pin1, int pin2) checkArgs2Pins(List<String> args) {
  if (args.length != 3) {
    usage();
  }
  try {
    return (Hat.values.byName(args[0]), int.parse(args[1]), int.parse(args[2]));
  } on Exception {
    usage();
  }
  // never reach this line
  return (Hat.nano, 0, 0);
}
