// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import 'package:dart_periphery/dart_periphery.dart';

enum LoadLib {
  selfExtraction,
  reuseExistingLibrary,
  setTempDir,
  setAbsolutePath,
  currentPath,
  sharedLibrary
}

// Test cases for the different c-periphery loading mechanism.
void main() {
  LoadLib type = LoadLib.selfExtraction;
  switch (type) {
    case LoadLib.selfExtraction:
      print(type.name);
      print('c-periphery version: ${getCperipheryVersion()}');
      print('library path  ${getPeripheryLibPath()}');
      break;
    case LoadLib.reuseExistingLibrary:
      print(type.name);
      reuseTmpFileLibrary(true);
      print('c-periphery version: ${getCperipheryVersion()}');
      print('library path  ${getPeripheryLibPath()}');
      final stat = FileStat.statSync(getPeripheryLibPath());
      print('Accessed: ${stat.accessed}');
      print('Modified: ${stat.modified}');
      print('Changed:  ${stat.changed}');
      print("Should be older!");
      break;
    case LoadLib.setTempDir:
      print(type.name);
      setTempDirectory('/home/pi/test/');
      print('c-periphery version: ${getCperipheryVersion()}');
      print('library path  ${getPeripheryLibPath()}');
      break;
    case LoadLib.setAbsolutePath:
      print(type.name);
      setCustomLibrary('/home/pi/test/libperiphery_arm.so');
      print('c-periphery version: ${getCperipheryVersion()}');
      print('library path  ${getPeripheryLibPath()}');
      break;
    case LoadLib.currentPath:
      print(type.name);
      useLocalLibrary();
      print('c-periphery version: ${getCperipheryVersion()}');
      print('library path  ${getPeripheryLibPath()}');
      break;
    case LoadLib.sharedLibrary:
      print(type.name);
      useSharedLibrary();
      print('c-periphery version: ${getCperipheryVersion()}');
      print('library path  ${getPeripheryLibPath()}');
      break;
  }
}
