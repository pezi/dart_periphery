import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef InitJVMFunc = Void Function();
typedef InitJVM = void Function();

typedef FreeJVMFunc = Void Function();
typedef FreeJVM = void Function();

typedef CallCreateEmojiFunc = Pointer<Utf8> Function(
    Pointer<Utf8>, Int32, Int32);
typedef CallCreateEmoji = Pointer<Utf8> Function(Pointer<Utf8>, int, int);

class JVMBridge {
  late DynamicLibrary _lib;

  late InitJVM _initJVM;
  late FreeJVM _freeJVM;
  late CallCreateEmoji _callCreateEmoji;

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

  void dispose() {
    _freeJVM();
  }
}

void main() {
  final jvmBridge = JVMBridge();

  // Call the Java method through the C interface
  String output = jvmBridge.createEmojiBMP("💩", 64, 10);
  print("Java method returned: $output");

  String output2 = jvmBridge.createEmojiBMP("⚓", 64, 10);
  print("Java method returned: $output2");

  jvmBridge.dispose();
}
