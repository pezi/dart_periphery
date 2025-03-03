// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

import 'dart:convert';

import 'package:dart_periphery/dart_periphery.dart';

typedef InitJVMFunc = Void Function();
typedef InitJVM = void Function();

typedef FreeJVMFunc = Void Function();
typedef FreeJVM = void Function();

typedef CallCreateEmojiFunc = Pointer<Utf8> Function(
    Pointer<Utf8>, Int32, Int32);
typedef CallCreateEmoji = Pointer<Utf8> Function(Pointer<Utf8>, int, int);

typedef CallScriptFunc = Pointer<Utf8> Function(Pointer<Utf8>);
typedef CallScript = Pointer<Utf8> Function(Pointer<Utf8>);

class JVMBridge {
  late DynamicLibrary _lib;

  late InitJVM _initJVM;
  late FreeJVM _freeJVM;
  late CallCreateEmoji _callCreateEmoji;
  late CallScript _callScript;

  JVMBridge() {
    // Load the shared library based on the platform
    if (Platform.isMacOS) {
      _lib = DynamicLibrary.open("libjvmbridge.dylib");
    } else if (Platform.isLinux) {
      _lib = DynamicLibrary.open("libjvmbridge.so");
    } else if (Platform.isWindows) {
      _lib = DynamicLibrary.open("jvmbridge.dll");
    } else {
      throw UnsupportedError("Unsupported platform");
    }

    // Load functions from the shared library
    _initJVM = _lib.lookupFunction<InitJVMFunc, InitJVM>("initJVMenv");
    _freeJVM = _lib.lookupFunction<FreeJVMFunc, FreeJVM>("freeJVMenv");
    _callCreateEmoji =
        _lib.lookupFunction<CallCreateEmojiFunc, CallCreateEmoji>(
            "call_create_emoji");
    _callScript =
        _lib.lookupFunction<CallScriptFunc, CallScript>("call_create_script");

    // Initialize JVM
    _initJVM();
  }

  String createEmojiBMP(String emoji, int size, int offset) {
    final Pointer<Utf8> emojiPtr = emoji.toNativeUtf8();
    final Pointer<Utf8> resultPtr = _callCreateEmoji(emojiPtr, size, offset);
    final String result = resultPtr.toDartString();

    malloc.free(emojiPtr);
    return result;
  }

  String script(String script) {
    final Pointer<Utf8> scriptPtr = script.toNativeUtf8();
    final Pointer<Utf8> resultPtr = _callScript(scriptPtr);
    final String result = resultPtr.toDartString();
    malloc.free(scriptPtr);
    return result;
  }

  void dispose() {
    _freeJVM();
  }
}

var script = "int midY = height / 2;\n" +
    "int amplitude = height / 3;\n" +
    "double frequency = 2 * Math.PI / width;\n" +
    "for (int x = 0; x < width; x++) {\n" +
    "    int y = midY + (int) (amplitude * Math.sin(frequency * x));\n" +
    "    image.setRGB(x, y, Color.WHITE.getRGB());\n" +
    "}\n";

void main() {
  final jvmBridge = JVMBridge();

  var i2c = I2C(1);
  try {
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print('I2C info: ${i2c.getI2Cinfo()}');

    var oled = SSD1306(i2c);

    ;
    oled.displayBitmap(base64.decode(jvmBridge.script(script)));
    sleep(Duration(seconds: 4));
    oled.displayBitmap(base64.decode(jvmBridge.createEmojiBMP("#", 64, 10)));
  } finally {
    i2c.dispose();
  }
  jvmBridge.dispose();
}
