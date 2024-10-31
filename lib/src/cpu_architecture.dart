import 'dart:ffi'; // For FFI

import 'package:ffi/ffi.dart';

typedef NativeCall = int Function(Pointer<Int8>);

/// Supported CPU architectures
enum CpuArchitecture {
  x86,
  x86_64,
  arm,
  arm64,
  riscv64,
  notSupported,
  undefined
}

final DynamicLibrary nativeAddLib = DynamicLibrary.open("libc.so.6");
NativeCall uname = nativeAddLib
    .lookup<NativeFunction<Int32 Function(Pointer<Int8>)>>("uname")
    .asFunction();

// https://en.wikipedia.org/wiki/Uname

/// Class which holds the CPU architecture of the SoC.
class CpuArch {
  static CpuArch? _cpuArch;
  String machine;
  CpuArchitecture cpuArch;

  factory CpuArch() {
    _cpuArch ??= CpuArch._internal();
    return _cpuArch as CpuArch;
  }

  CpuArch._internal()
      : machine = "",
        cpuArch = CpuArchitecture.notSupported {
    Uname uname = nativeUname();
    machine = uname.machine;
    switch (uname.machine) {
      case 'i686':
      case 'i386':
        cpuArch = CpuArchitecture.x86;
        break;
      case 'x86_64':
        cpuArch = CpuArchitecture.x86_64;
        break;
      case 'aarch64':
      case 'aarch64_be':
      case 'arm64':
      case 'armv8b':
      case 'armv8l':
        cpuArch = CpuArchitecture.arm64;
        break;
      case 'armv':
      case 'armv6l':
      case 'armv7l':
        cpuArch = CpuArchitecture.arm;
        break;
    }
  }
}

/// Uname class, container for the Linux uname struct values.
class Uname {
  String sysname;
  String nodename;
  String release;
  String version;
  String machine;
  Uname(this.sysname, this.nodename, this.release, this.version, this.machine);
}

/// Calls the native uname() function.
Uname nativeUname() {
  // allocate a memory buffer for struct utsname - size value derived from this source
  // https://man7.org/linux/man-pages/man2/uname.2.html
  const len = 6 * 257; // maxium size
  const enumElements = 5;

  Pointer<Int8> data = calloc<Int8>(len);

  try {
    if (uname(data) != 0) {
      throw Exception('Calling uname() failed.');
    }

    // calculate _UTSNAME_LENGTH
    var utslen = 0;
    label:
    for (int i = 0; i < len; ++i) {
      if (data[i] == 0) {
        for (int j = i + 1; j < len; ++j) {
          if (data[j] != 0) {
            utslen = j;
            break label;
          }
        }
      }
    }

    var values = <String>[];

    // extract these 5 strings from the memory
    //
    // char sysname[];    /* Operating system name (e.g., "Linux") */
    // char nodename[];   /* Name within "some implementation-defined network" */
    // char release[];    /* Operating system release (e.g., "2.6.28") */
    // char version[];    /* Operating system version */
    // char machine[];    /* Hardware identifier */
    for (int i = 0; i < enumElements; ++i) {
      var start = utslen * i;
      StringBuffer buf = StringBuffer();
      for (int i = start; i < len; ++i) {
        if (data[i] == 0) {
          break;
        }
        buf.write(String.fromCharCode(data[i]));
      }
      values.add(buf.toString());
    }
    return Uname(values[0], values[1], values[2], values[3], values[4]);
  } finally {
    malloc.free(data);
  }
}
