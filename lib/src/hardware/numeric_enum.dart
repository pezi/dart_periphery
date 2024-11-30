abstract class IntEnum {
  int getValue();
}

abstract class DoubleEnum {
  double getValue();
}

/*
enum TemplateIntEnum implements IntEnum {
  test(1);
  final int value;
  const TemplateIntEnum(this.value);

  @override
  int getValue() {
    return value;
  }
}
*/
