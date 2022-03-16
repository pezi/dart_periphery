import 'package:test/test.dart';

import 'package:dart_periphery/src/hardware/utils/uint8.dart';

void main() {
  test("Uint8 utility test", () {
    expect(Uint8.zero(), Uint8(0));

    expect(Uint8(128).reverseByte().value, 1);
    expect(Uint8(64).reverseByte().value, 2);
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
}