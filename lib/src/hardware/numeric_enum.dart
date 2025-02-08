// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Abstract wrapper class for enums with integer values.
abstract class IntEnum {
  /// Returns the int value of the enum.
  int getValue();
}

/// Abstract wrapper class for enums with doubles values.
abstract class DoubleEnum {
  /// Returns the double value of the enum.
  double getValue();
}
