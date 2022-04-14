import 'package:test/test.dart';

import 'package:dart_periphery/src/hardware/utils/uint.dart';

void main() {
  // const int maxUint8 = 255;
  // const int maxUint16 = 65535;
  const int maxUint32 = 4294967295;

  test("Uint8 utility test", () {
    expect(Uint8.zero(), Uint8(0));

    expect(Uint8(128).reverseBytes().value, 1);
    expect(Uint8(64).reverseBytes().value, 2);
    expect(Uint8(128) == Uint8(128), true);
    expect(Uint8(128) < Uint8(127), false);
    expect(Uint8(128) > Uint8(127), true);
    expect(Uint8(128) <= Uint8(127), false);
    expect(Uint8(128) >= Uint8(127), true);
    expect(Uint8(128) <= Uint8(128), true);
    expect(Uint8(128) >= Uint8(128), true);
    expect(Uint8(128) + Uint8(128), Uint8(0));
    expect(Uint8(128) + Uint8(129), Uint8(1));
    expect(Uint8(129) + Uint8(128), Uint8(1));
    expect(Uint8(128) - Uint8(128), Uint8(0));
    expect(Uint8(128) - Uint8(129), Uint8(255));
    expect(Uint8(129) - Uint8(128), Uint8(1));
    expect(Uint8(128) & Uint8(128), Uint8(128));
    expect(Uint8(255) & Uint8(128), Uint8(128));
    expect(Uint8(0) & Uint8(128), Uint8(0));
    expect(Uint8(128) | Uint8(1), Uint8(129));
    expect(Uint8(128) | Uint8(64), Uint8(192));
    expect(Uint8(128) >> 1, Uint8(64));
    expect(Uint8(128) >> 2, Uint8(32));
    expect(Uint8(1) >> 1, Uint8(0));
    expect(Uint8(128) << 1, Uint8(0));
    expect(Uint8(0) << 2, Uint8(0));
    expect(Uint8(1) << 1, Uint8(2));
    expect(~Uint8(1), Uint8(254));
    expect(~Uint8(127), Uint8(128));
  });

  test("Uint16 utility test", () {
    expect(Uint16.zero(), Uint16(0));

    expect(Uint16(128).reverseBytes().value, 256);
    expect(Uint16(64).reverseBytes().value, 512);
    expect(Uint16(128) == Uint16(128), true);
    expect(Uint16(128) < Uint16(127), false);
    expect(Uint16(128) > Uint16(127), true);
    expect(Uint16(128) <= Uint16(127), false);
    expect(Uint16(128) >= Uint16(127), true);
    expect(Uint16(128) <= Uint16(128), true);
    expect(Uint16(128) >= Uint16(128), true);
    expect(Uint16(65535) + Uint16(1), Uint16(0));
    expect(Uint16(65535) + Uint16(2), Uint16(1));
    expect(Uint16(2) + Uint16(65535), Uint16(1));
    expect(Uint16(65535) - Uint16(65535), Uint16(0));
    expect(Uint16(65533) - Uint16(65534), Uint16(65535));
    expect(Uint16(65535) - Uint16(65534), Uint16(1));
    expect(Uint16(128) & Uint16(128), Uint16(128));
    expect(Uint16(255) & Uint16(128), Uint16(128));
    expect(Uint16(0) & Uint16(128), Uint16(0));
    expect(Uint16(128) | Uint16(1), Uint16(129));
    expect(Uint16(128) | Uint16(64), Uint16(192));
    expect(Uint16(32768) >> 1, Uint16(16384));
    expect(Uint16(32768) >> 2, Uint16(8192));
    expect(Uint16(1) >> 1, Uint16(0));
    expect(Uint16(32768) << 1, Uint16(0));
    expect(Uint16(0) << 2, Uint16(0));
    expect(Uint16(1) << 1, Uint16(2));
    expect(~Uint16(1), Uint16(65534));
    expect(~Uint16(127), Uint16(65408));
  });

  test("Uint32 utility test", () {
    expect(Uint32.zero(), Uint32(0));

    expect(Uint32(1 << 31).reverseBytes().value, 1);
    expect(Uint32(1 << 30).reverseBytes().value, 2);
    expect(Uint32(maxUint32) == Uint32(maxUint32), true);
    expect(Uint32(128) < Uint32(127), false);
    expect(Uint32(128) > Uint32(127), true);
    expect(Uint32(128) <= Uint32(127), false);
    expect(Uint32(128) >= Uint32(127), true);
    expect(Uint32(128) <= Uint32(128), true);
    expect(Uint32(128) >= Uint32(128), true);
    expect(Uint32(1 << 31) + Uint32(1 << 31), Uint32(0));
    expect(Uint32(1 << 31) + Uint32((1 << 31) + 1), Uint32(1));
    expect(Uint32((1 << 31) + 1) + Uint32(1 << 31), Uint32(1));
    expect(Uint32(1 << 31) - Uint32(1 << 31), Uint32(0));
    expect(Uint32(1 << 31) - Uint32((1 << 31) + 1), Uint32(maxUint32));
    expect(Uint32((1 << 31) + 1) - Uint32(1 << 31), Uint32(1));
    expect(Uint32(128) & Uint32(128), Uint32(128));
    expect(Uint32(255) & Uint32(128), Uint32(128));
    expect(Uint32(0) & Uint32(128), Uint32(0));
    expect(Uint32(128) | Uint32(1), Uint32(129));
    expect(Uint32(128) | Uint32(64), Uint32(192));
    expect(Uint32(1 << 31) >> 1, Uint32(1 << 30));
    expect(Uint32(1 << 31) >> 2, Uint32(1 << 29));
    expect(Uint32(1) >> 1, Uint32(0));
    expect(Uint32(1 << 31) << 1, Uint32(0));
    expect(Uint32(0) << 2, Uint32(0));
    expect(Uint32(1) << 1, Uint32(2));
    expect(~Uint32(maxUint32), Uint32(0));
    expect(~Uint32(maxUint32 - 1), Uint32(1));
  });
}
