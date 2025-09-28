// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Resources:
// https://github.com/DexterInd/GrovePi/blob/master/Software/Python/grove_gps/grove_gps_data.py/
// https://github.com/microsoft/IoT-For-Beginners/blob/main/3-transport/lessons/1-location-tracking/pi-gps-sensor.md
// https://simcom.ee/documents/SIM28/SIM28%40SIM68R%40SIM68V_NMEA%20Messages%20Specification_V1.00.pdf  - page 10

/*
Exmaple 

$GNGGA,062151.000,5005.12390,N,01811.91859,E,1,05,6.0,202.8,M,41.8,M,,*49
$GNGLL,5005.12390,N,01811.91859,E,062151.000,A,A*4A
$GNGSA,A,3,02,04,,,,,,,,,,,8.5,6.0,6.0,1*3A
$GNGSA,A,3,21,35,44,,,,,,,,,,8.5,6.0,6.0,4*3C
$GPGSV,2,1,07,01,81,164,,02,48,146,3

*/

// nmea_parser.dart
// Minimal Dart parser for AIR530 (NMEA-0183) to get lat, lon, and MSL altitude.

class GnssFix {
  final double? lat; // decimal degrees (WGS-84)
  final double? lon; // decimal degrees (WGS-84)
  final double? msl; // meters above mean sea level (from GGA)
  final DateTime? utc; // optional: parsed from NMEA time if present
  final bool valid;

  const GnssFix({this.lat, this.lon, this.msl, this.utc, required this.valid});

  @override
  String toString() =>
      'GnssFix(valid: $valid, lat: $lat, lon: $lon, msl: $msl, utc: $utc)';
}

class NmeaParser {
  /// Parse a multi-line NMEA block. Returns the first valid fix found.
  static GnssFix parse(String nmeaBlock) {
    GnssFix? ggaFix;
    GnssFix? gllFix;

    for (final raw in nmeaBlock.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty || !line.startsWith(r'$') || !line.contains('*')) {
        continue;
      }
      if (!_checksumOk(line)) continue; // skip bad checksums

      final body = line.substring(
          1, line.indexOf('*')); // without leading '$' and trailing checksum
      final fields = body.split(',');

      if (fields.isEmpty) continue;
      final talkerSentence = fields.first; // e.g., GNGGA, GPGGA, GNGLL, etc.
      final sentence = talkerSentence.length >= 5
          ? talkerSentence
              .substring(talkerSentence.length - 3) // last 3 chars like "GGA"
          : talkerSentence;

      switch (sentence) {
        case 'GGA':
          final fix = _parseGGA(fields);
          if (fix != null && fix.valid) {
            ggaFix ??= fix; // keep the first valid GGA
          }
          break;
        case 'GLL':
          final fix = _parseGLL(fields);
          if (fix != null && fix.valid) {
            gllFix ??= fix;
          }
          break;
        default:
          // ignore others
          break;
      }
    }

    // Prefer GGA (has MSL). If absent, return GLL (lat/lon only).
    return ggaFix ??
        (gllFix != null
            ? GnssFix(
                lat: gllFix.lat,
                lon: gllFix.lon,
                msl: null,
                utc: gllFix.utc,
                valid: true)
            : const GnssFix(valid: false));
  }

  // ---------- Helpers ----------

  static GnssFix? _parseGGA(List<String> f) {
    // NMEA GGA indices:
    // 0: GxGGA, 1: hhmmss.sss, 2: lat, 3: N/S, 4: lon, 5: E/W,
    // 6: fix quality (0=no fix), 7: sats used, 8: HDOP, 9: alt MSL, 10: 'M', 11: geoid sep, 12: 'M', ...
    if (f.length < 10) return null;

    final fixQuality = _toInt(f[6]);
    if (fixQuality == null || fixQuality == 0) {
      // no valid fix
      return const GnssFix(valid: false);
    }

    final lat = _nmeaCoordToDecimal(f[2], f[3]);
    final lon = _nmeaCoordToDecimal(f[4], f[5]);
    final msl = _toDouble(f[9]);
    final utc = _parseUtcTime(f[1]);

    if (lat == null || lon == null) return const GnssFix(valid: false);
    return GnssFix(lat: lat, lon: lon, msl: msl, utc: utc, valid: true);
  }

  static GnssFix? _parseGLL(List<String> f) {
    // NMEA GLL indices:
    // 0: GxGLL, 1: lat, 2: N/S, 3: lon, 4: E/W, 5: hhmmss.sss, 6: status (A/V), 7: mode (A/D/E/N) [optional]
    if (f.length < 7) return null;

    final status = f[6].isNotEmpty ? f[6][0] : 'V';
    if (status != 'A') return const GnssFix(valid: false);

    final lat = _nmeaCoordToDecimal(f[1], f[2]);
    final lon = _nmeaCoordToDecimal(f[3], f[4]);
    final utc = _parseUtcTime(f[5]);

    if (lat == null || lon == null) return const GnssFix(valid: false);
    return GnssFix(lat: lat, lon: lon, msl: null, utc: utc, valid: true);
  }

  static bool _checksumOk(String line) {
    final star = line.lastIndexOf('*');
    if (star <= 0 || star + 3 > line.length) return false;
    final data = line.substring(1, star); // exclude '$'
    final given = line.substring(star + 1);
    final calc = data.codeUnits.reduce((a, b) => a ^ b);
    final hex = calc.toRadixString(16).toUpperCase().padLeft(2, '0');
    return hex == given.toUpperCase();
  }

  /// Convert NMEA ddmm.mmmm (lat) or dddmm.mmmm (lon) + hemisphere to decimal degrees.
  static double? _nmeaCoordToDecimal(String coord, String hemi) {
    if (coord.isEmpty || hemi.isEmpty) return null;
    final dot = coord.indexOf('.');
    if (dot < 0) return null;

    // More robust: lat has 2 deg, lon has 3 deg. Infer from hemisphere + total length.
    final isLon = (hemi == 'E' || hemi == 'W');
    final dLen = isLon ? 3 : 2;

    // Split degrees and minutes
    final degStr = coord.substring(0, dLen);
    final minStr = coord.substring(dLen);

    final deg = double.tryParse(degStr);
    final minutes = double.tryParse(minStr);
    if (deg == null || minutes == null) return null;

    double dec = deg + (minutes / 60.0);
    if (hemi == 'S' || hemi == 'W') dec = -dec;
    return dec;
  }

  static DateTime? _parseUtcTime(String hhmmss) {
    if (hhmmss.isEmpty) return null;
    // Only time-of-day; date is unknown. We return today’s UTC with that time.
    // If you need exact date, combine with an RMC date when available.
    final h = _toInt(hhmmss.substring(0, 2)) ?? 0;
    final m = _toInt(hhmmss.substring(2, 4)) ?? 0;
    final sPart = hhmmss.substring(4);
    final s = double.tryParse(sPart) ?? 0.0;
    final sec = s.floor();
    final micro = ((s - sec) * 1e6).round();
    final now = DateTime.now().toUtc();
    return DateTime.utc(
        now.year, now.month, now.day, h, m, sec, 0, micro ~/ 1000);
    // (microseconds truncated to milliseconds for DateTime)
  }

  static int? _toInt(String v) => v.isEmpty ? null : int.tryParse(v);
  static double? _toDouble(String v) => v.isEmpty ? null : double.tryParse(v);
}
