// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// IAQ (Index of Air Quality) based on following source
/// https://community.bosch-sensortec.com/t5/MEMS-sensors-forum/BME680-688-IAQ-meaning/td-p/45196
/// converted to a Dart representation.
library;

/// Helper for lower/uppercase checking
extension CharacterCase on String {
  bool isUpperCase() {
    int ascii = codeUnitAt(0);
    return ascii >= 'A'.codeUnitAt(0) && ascii <= 'Z'.codeUnitAt(0);
  }

  bool isLowerCase() {
    int ascii = codeUnitAt(0);
    return ascii >= 'a'.codeUnitAt(0) && ascii <= 'z'.codeUnitAt(0);
  }
}

/// Returns an [AirQuality] for a [iaq] value.
///
/// IAQ (Index of Air Quality) based on following [source](https://community.bosch-sensortec.com/t5/MEMS-sensors-forum/BME680-688-IAQ-meaning/td-p/45196).
AirQuality getAirQuality(int iaq) {
  for (var q in AirQuality.values) {
    if (q == AirQuality.invalidValue) {
      break;
    }
    if (iaq >= q.lowerBound && iaq <= q.upperBound) {
      return q;
    }
  }
  return AirQuality.invalidValue;
}

/// IAQ values: excellent - invalidValue - containing range and color
///
/// [source](https://community.bosch-sensortec.com/t5/MEMS-sensors-forum/BME680-688-IAQ-meaning/td-p/45196).
enum AirQuality {
  excellent(0, 50, 0xFF02E400),
  good(51, 100, 0xFF92D04F),
  lightlyPolluted(101, 150, 0xFFFFFC01),
  moderatelyPolluted(151, 200, 0xFFFF7E09),
  heavilyPolluted(201, 250, 0xFFFF2613),
  severelyPolluted(251, 350, 0xFF99154C, false),
  extremelyPolluted(351, 500, 0xFF663301, false),
  invalidValue(-1, -1, 0);

  @override
  String toString() {
    // split enum name at the first upper case
    for (int i = 0; i < name.length; i++) {
      if (name[i].isUpperCase()) {
        return '${name.substring(0, i)} ${name.substring(i).toLowerCase()}';
      }
    }
    return name;
  }

  /// Creates an [AirQuality] instance defined by the interval
  /// [lowerBound] - [upperBound] and applies the color scheme as described in
  /// the official [documentation](https://community.bosch-sensortec.com/t5/MEMS-sensors-forum/BME680-688-IAQ-meaning/td-p/45196).
  /// The signal [color] parameter represents an IAQ value, while the
  /// [isTextColorBlack] flag indicates whether black or white text should be
  /// used on the [color] background.
  const AirQuality(this.lowerBound, this.upperBound, this.color,
      [this.isTextColorBlack = true]);
  final int lowerBound;
  final int upperBound;
  final int color;
  final bool isTextColorBlack;
}
