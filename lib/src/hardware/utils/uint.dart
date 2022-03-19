import 'dart:typed_data';

abstract class Uint<T extends Uint<T>> {

  final int numberOfBytesRequired;
  final T Function(int) constructorCallback;

  final ByteData _value;
  late final int negationMask;

  Uint({
    required this.numberOfBytesRequired, 
    required this.constructorCallback,
    required int value
  }) : _value = ByteData(numberOfBytesRequired)
  {
    // calculate the negation mask once
    const int baseMask = 0xff;
    int tmpMask = 0xff;
    for (int i = 1; i < numberOfBytesRequired; i++) {
      tmpMask <<= 8;
      tmpMask |= baseMask;
    }
    negationMask = ~tmpMask;

    // set the actual value using the in the subclass specified setter
    this.value = value;
  }

  int get value;
  set value(int value);

  T reverseBytes() {
    T result = constructorCallback(0);
    T tmpValue = constructorCallback(value);
    final T one = constructorCallback(1);  

    for (int i=0; i < numberOfBytesRequired * 8; i++) {
      // first shift is useless but otherwhise this loop would shift the last
      // bit of result out (when i = 7) - off by one bit error
      result <<= 1;
      result |= tmpValue & one;
      tmpValue >>= 1;
    }

    return result;
  }

  @override
  bool operator ==(Object other) => other is T ? value == other.value : false;
  bool operator <(T other) => value < other.value;
  bool operator >(T other) => value > other.value;
  bool operator <=(T other) => value <= other.value;
  bool operator >=(T other) => value >= other.value;
  T operator +(T other) => constructorCallback(value + other.value);
  T operator -(T other) => constructorCallback(value - other.value);
  T operator &(T other) => constructorCallback(value & other.value);
  T operator |(T other) => constructorCallback(value | other.value);
  T operator >>(int other) => constructorCallback(value >> other);
  T operator <<(int other) => constructorCallback(value << other);
  T operator ~() {
    // we need to hack a little bit here since a normal 
    //int inverted is not equal to inverting a 8 bit int!

    final int value = this.value;

    // The in the compiler generated mask (negationMask) 
    //with all 1 except e.g the 8 lsb 
    // Example Bit view: 1 1 1 .... 1 1 1 0 0 0 0 0 0 0 0

    // or the mask and value to get some thing like the following
    // (example for `value` = 127 = 0 1 1 1 1 1 1 1)
    // Bit view: 1 1 1 .... 1 1 1 0 1 1 1 1 1 1 1
    final int tmp = negationMask | value;

    // now we can just negate like we would do normally
    return constructorCallback(~tmp);
  }

  @override
  String toString() {
    return "${value.toString()} == 0x${value.toRadixString(16)}";
  }

  @override
  int get hashCode => _value.hashCode;
}


class Uint8 extends Uint<Uint8> {
  Uint8(int value) : super(
    numberOfBytesRequired: 1, 
    constructorCallback: Uint8.new, 
    value: value
  );
  Uint8.zero() : this(0);

  @override
  int get value => _value.getUint8(0);

  @override
  set value(int value) => _value.setUint8(0, value);
}


class Uint16 extends Uint<Uint16> {
  Uint16(int value) : super(
    numberOfBytesRequired: 2, 
    constructorCallback: Uint16.new, 
    value: value
  );
  Uint16.zero() : this(0);

  @override
  int get value => _value.getUint16(0);

  @override
  set value(int value) => _value.setUint16(0, value);
}


class Uint32 extends Uint<Uint32> {
  Uint32(int value) : super(
    numberOfBytesRequired: 4, 
    constructorCallback: Uint32.new, 
    value: value
  );
  Uint32.zero() : this(0);

  @override
  int get value => _value.getUint32(0);

  @override
  set value(int value) => _value.setUint32(0, value);
}