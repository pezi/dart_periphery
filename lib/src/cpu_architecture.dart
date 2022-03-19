import 'dart:ffi'; // For FFI
import 'package:ffi/ffi.dart';

typedef NativeCall = int Function(Pointer<Int8>);

enum CPU_ARCHITECTURE { X86, X86_64, ARM, ARM64, NOT_SUPPORTED, UNDEFINED }

final DynamicLibrary nativeAddLib = DynamicLibrary.open("libc.so.6");
NativeCall uname = nativeAddLib
    .lookup<NativeFunction<Int32 Function(Pointer<Int8>)>>("uname")
    .asFunction();

// https://en.wikipedia.org/wiki/Uname
class CpuArch {
  String machine;
  CPU_ARCHITECTURE cpuArch;

  CpuArch()
      : machine = "",
        cpuArch = CPU_ARCHITECTURE.NOT_SUPPORTED {
    Uname uname = nativeUname();
    machine = uname.machine;
    switch (uname.machine) {
      case 'i686':
      case 'i386':
        cpuArch = CPU_ARCHITECTURE.X86;
        break;
      case 'x86_64':
        cpuArch = CPU_ARCHITECTURE.X86_64;
        break;
      case 'aarch64':
      case 'aarch64_be':
      case 'arm64':
      case 'armv8b':
      case 'armv8l':
        cpuArch = CPU_ARCHITECTURE.ARM64;
        break;
      case 'armv':
      case 'armv6l': 
      case 'armv7l':
        cpuArch = CPU_ARCHITECTURE.ARM;
        break;
    }
  }
}

class Uname {
  String sysname;
  String nodename;
  String release;
  String version;
  String machine;
  Uname(this.sysname, this.nodename, this.release, this.version, this.machine);
}

Uname nativeUname() {
  // allocate a memory buffer for  struct utsname - size value derived from this source
  // https://man7.org/linux/man-pages/man2/uname.2.html
  const len = 6 * 257;

  Pointer<Int8> data = calloc<Int8>(len);

  try {
    if (uname(data) != 0) {
      throw Exception('Calling uname() failed.');
    }

    // calculate _UTSNAME_LENGTH length for char machine[];
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

    // extrract these 5 strings from the memory
    //
    //  char sysname[];    /* Operating system name (e.g., "Linux") */
    //  char nodename[];   /* Name within "some implementation-defined network" */
    //  char release[];    /* Operating system release (e.g., "2.6.28") */
    //  char version[];    /* Operating system version */
    //  char machine[];    /* /* Hardware identifier */
    for (int i = 0; i < 5; ++i) {
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
