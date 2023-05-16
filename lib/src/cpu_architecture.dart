import 'dart:ffi';
import 'dart:io';

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
  final ostype = File('/proc/sys/kernel/ostype').readAsStringSync();
  final hostname = File('/proc/sys/kernel/hostname').readAsStringSync();
  final osrelease = File('/proc/sys/kernel/osrelease').readAsStringSync();
  final version = File('/proc/sys/kernel/version').readAsStringSync();

  // Kernels since 6.1 also have `/proc/sys/kernel/arch`.
  final machine = (Process.runSync('uname', ['-m']).stdout as String).trim();

  return Uname(ostype, hostname, osrelease, version, machine);
}

enum CpuArchitecture { x86, x86_64, arm, arm64, notSupported, undefined }

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
    switch (Abi.current()) {
      case Abi.linuxIA32:
        cpuArch = CpuArchitecture.x86;
        break;
      case Abi.linuxX64:
        cpuArch = CpuArchitecture.x86_64;
        break;
      case Abi.linuxArm64:
        cpuArch = CpuArchitecture.arm64;
        break;
      case Abi.linuxArm:
        cpuArch = CpuArchitecture.arm;
        break;
    }
  }
}
