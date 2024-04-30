// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

// Improve performance inside the isolate(String json) constructor, cache JSON maps
final Map<int, Map<String, dynamic>> _jsonCache = {};

Map<String, dynamic> jsonMap(String json) {
  Map<String, dynamic>? map = _jsonCache[json.hashCode];
  if (map == null) {
    map = {};
    _jsonCache[json.hashCode] = map;
  }
  if (map.isEmpty) {
    map.addAll(jsonDecode(json) as Map<String, dynamic>);
  }
  return map;
}
