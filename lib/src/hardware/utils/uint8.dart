import 'dart:typed_data';

class Uint8 {
  final ByteData _value = ByteData(1);

  Uint8(int value) {
    _value.setUint8(0, value);
  } 
  Uint8.zero();

  int get value => _value.getUint8(0);
  set value(int value) => _value.setUint8(0, value);

  Uint8 reverseByte() {
    Uint8 result = Uint8.zero();
    Uint8 tmpValue = Uint8(value);
    final Uint8 one = Uint8(1);  

    for (int i=0; i < 8; i++) {
      // first shift is useless but otherwhise this loop would shift the last
      // bit of result out (when i = 7) - off by one bit error
      result <<= 1;
      result |= tmpValue & one;
      tmpValue >>= 1;
    }

    return result;
  }

  @override
  bool operator ==(Object other) => other is Uint8 ? value == other.value : false;
  bool operator <(Uint8 other) => value < other.value;
  bool operator >(Uint8 other) => value > other.value;
  bool operator <=(Uint8 other) => value <= other.value;
  bool operator >=(Uint8 other) => value >= other.value;
  Uint8 operator +(Uint8 other) => Uint8(value + other.value);
  Uint8 operator -(Uint8 other) => Uint8(value - other.value);
  Uint8 operator &(Uint8 other) => Uint8(value & other.value);
  Uint8 operator |(Uint8 other) => Uint8(value | other.value);
  Uint8 operator >>(int other) => Uint8(value >> other);
  Uint8 operator <<(int other) => Uint8(value << other);
  Uint8 operator ~() {
    // we need to hack a little bit here since a normal 
    //int inverted is not equal to inverting a 8 bit int!

    final int value = this.value;

    // generate makes with all 1 except the 8 lsb bits 
    // Bit view: 1 1 1 .... 1 1 1 0 0 0 0 0 0 0 0
    const int mask = ~0xff;

    // or the mask and value to get some thing like the following
    // (example for `value` = 127 = 0 1 1 1 1 1 1 1)
    // Bit view: 1 1 1 .... 1 1 1 0 1 1 1 1 1 1 1
    final int tmp = mask | value;

    // now we can just negate like we would do normally
    return Uint8(~tmp);
  }

  @override
  String toString() {
    return "${value.toString()} == 0x${value.toRadixString(16)}";
  }

  @override
  int get hashCode => _value.hashCode;
}