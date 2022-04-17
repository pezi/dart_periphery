
# dart_periphery

![alt text](https://raw.githubusercontent.com/pezi/dart_periphery_img/main/header.jpg "Title")

[![pub package](https://img.shields.io/badge/pub-v0.9.1-orange)](https://pub.dartlang.org/packages/dart_periphery)

## Important hint

**v0.9.x** is an API change release, which fixes all the camel case warnings of the source code. When starting this project enums and variables from existing C und Java code were not converted to camel case.

e.g. `GPIOdirection.GPIO_DIR_OUT` changed to `GPIOdirection.gpioDirOut`


## Introduction

**dart_periphery** is a Dart port of the native [c-periphery library](https://github.com/vsergeev/c-periphery)
  for Linux Peripheral I/O (GPIO, LED, PWM, SPI, I2C, MMIO and Serial peripheral I/O). This package is specially intended for SoCs like Raspberry Pi, NanoPi, Banana Pi et al.

### What is c-periphery?

Abstract from the project web site:

>c-periphery is a small C library for
>
>* GPIO,
>* LED,
>* PWM,
>* SPI,
>* I2C,
>* MMIO (Memory Mapped I/O)
>* Serial peripheral I/O
>
>interface access in userspace Linux. c-periphery simplifies and consolidates the native Linux APIs to these interfaces. c-periphery is useful in embedded Linux environments (including Raspberry Pi, BeagleBone, etc. platforms) for interfacing with external peripherals. c-periphery is re-entrant, has no dependencies outside the standard C library and Linux, compiles into a static library for easy integration with other projects, and is MIT licensed

**dart_periphery** binds the c-periphery library with the help of the [dart:ffi](https://dart.dev/guides/libraries/c-interop) mechanism. Nevertheless, **dart_periphery** tries to be close as possible to the original library. See following [documentation](https://github.com/vsergeev/c-periphery/tree/master/docs). Thanks to **Vanya Sergeev** for his great job!

## Why c-periphery?

The number of GPIO libraries/interfaces is becoming increasingly smaller.

* The famous wiringpi library is [deprecated](https://hackaday.com/2019/09/18/wiringpi-library-to-be-deprecated).
* GPIO sysfs is [deprecated](https://www.raspberrypi.org/forums/viewtopic.php?t=274416).

**dart_periphery** - all interfaces are ported:

* [GPIO](#gpio) example / [API](https://pub.dev/documentation/dart_periphery/latest/dart_periphery/GPIO-class.html)
* [I2C](#i2c) example / [API](https://pub.dev/documentation/dart_periphery/latest/dart_periphery/I2C-class.html)
* [SPI](#spi) example / [API](https://pub.dev/documentation/dart_periphery/latest/dart_periphery/SPI-class.html)
* [Serial](#serial) example / [API](https://pub.dev/documentation/dart_periphery/latest/dart_periphery/Serial-class.html)
* [PWM](#pwm) example / [API](https://pub.dev/documentation/dart_periphery/latest/dart_periphery/PWM-class.html)
* [Led](#led) (onboard leds) example / [API](https://pub.dev/documentation/dart_periphery/latest/dart_periphery/Led-class.html)
* [MMIO](#mmio) (Memory Mapped I/O) example / [API](https://pub.dev/documentation/dart_periphery/latest/dart_periphery/MMIO-class.html)

## Examples

### GPIO

![alt text](https://raw.githubusercontent.com/pezi/dart_periphery_img/main/pi.jpg "Led demo")

``` dart
import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

void main() {
  var config = GPIOconfig();
  config.direction = GPIOdirection.gpioDirOut;
  print('Native c-periphery Version :  ${getCperipheryVersion()}');
  print('GPIO test');
  var gpio = GPIO(18, GPIOdirection.gpioDirOut);
  var gpio2 = GPIO(16, GPIOdirection.gpioDirOut;
  var gpio3 = GPIO.advanced(5, config);

  print('GPIO info: ' + gpio.getGPIOinfo());

  print('GPIO native file handle: ${gpio.getGPIOfd()}');
  print('GPIO chip name: ${gpio.getGPIOchipName()}');
  print('GPIO chip label: ${gpio.getGPIOchipLabel()}');
  print('GPIO chip name: ${gpio.getGPIOchipName()}');
  print('CPIO chip label: ${gpio.getGPIOchipLabel()}');

  for (var i = 0; i < 10; ++i) {
    gpio.write(true);
    gpio2.write(true);
    gpio3.write(true);
    sleep(Duration(milliseconds: 200));
    gpio.write(false);
    gpio2.write(false);
    gpio3.write(false);
    sleep(Duration(milliseconds: 200));
  }

  gpio.dispose();
  gpio2.dispose();
  gpio3.dispose();
}

```

### I2C

![alt text](https://raw.githubusercontent.com/pezi/dart_periphery_img/main/bme280.jpg "BME280 Sensor")

``` dart
import 'package:dart_periphery/dart_periphery.dart';

/// https://wiki.seeedstudio.com/Grove-Barometer_Sensor-BME280/
/// Grove - Temp&Humi&Barometer Sensor (BME280) is a breakout board for Bosch BMP280 high-precision,
/// low-power combined humidity, pressure, and temperature sensor.
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspbery Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(1);
  try {
    print('I2C info:' + i2c.getI2Cinfo());
    var bme280 = BME280(i2c);
    var r = bme280.getValues();
    print('Temperature [°] ${r.temperature.toStringAsFixed(1)}');
    print('Humidity [%] ${r.humidity.toStringAsFixed(1)}');
    print('Pressure [hPa] ${r.pressure.toStringAsFixed(1)}');
  } finally {
    i2c.dispose();
  }
}

```

___

![alt text](https://raw.githubusercontent.com/pezi/dart_periphery_img/main/sht31.jpg "SHT31 Sensor")

``` dart
import 'package:dart_periphery/dart_periphery.dart';

/// Grove - Temp&Humi Sensor(SHT31) is a highly reliable, accurate,
/// quick response and integrated temperature & humidity sensor.
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspbery Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(1);
  try {
    var sht31 = SHT31(i2c);
    print(sht31.getStatus());
    print('Serial number ${sht31.getSerialNumber()}');
    print('Sensor heater active: ${sht31.isHeaterOn()}');

    var r = sht31.getValues();
    print('SHT31 [t°] ${r.temperature.toStringAsFixed(2)}');
    print('SHT31 [%°] ${r.humidity.toStringAsFixed(2)}');
  } finally {
    i2c.dispose();
  }
}
```

### SPI

``` dart
import 'package:dart_periphery/dart_periphery.dart';

void main() {
  var spi = SPI(0, 0, SPImode.mode0, 1000000);
  try {
    print('SPI info:' + spi.getSPIinfo());
    var bme280 = BME280.spi(spi);
    var r = bme280.getValues();
    print('Temperature [°] ${r.temperature.toStringAsFixed(1)}');
    print('Humidity [%] ${r.humidity.toStringAsFixed(1)}');
    print('Pressure [hPa] ${r.pressure.toStringAsFixed(1)}');
  } finally {
    spi.dispose();
  }
}
````

### Serial

![alt text](https://raw.githubusercontent.com/pezi/dart_periphery_img/main/cozir.jpg "CozIR Sensor")

``` dart
import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

///
/// [COZIR CO2 Sensor](https://co2meters.com/Documentation/Manuals/Manual_GC_0024_0025_0026_Revised8.pdf)
///
void main() {
  print('Serial test - COZIR CO2 Sensor');
  var s = Serial('/dev/serial0', Baudrate.b9600);
  try {
    print('Serial interface info: ' + s.getSerialInfo());

    // Return firmware version and sensor serial number - two lines
    s.writeString('Y\r\n');
    var event = s.read(256, 1000);
    print(event.toString());

    // Request temperature, humidity and CO2 level.
    s.writeString('M 4164\r\n');
    // Select polling mode
    s.writeString('K 2\r\n');
    // print any response
    event = s.read(256, 1000);
    print('Response ${event.toString()}');
    sleep(Duration(seconds: 1));
    for (var i = 0; i < 5; ++i) {
      s.writeString('Q\r\n');
      event = s.read(256, 1000);
      print(event.toString());
      sleep(Duration(seconds: 5));
    }
  } finally {
    s.dispose();
  }
}
```

### Led

![alt text](https://raw.githubusercontent.com/pezi/dart_periphery_img/main/led.jpg "Power led")

``` dart
import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

void main() {
  /// Nano Pi power led - see 'ls /sys/class/leds/'
  var led = Led('nanopi:red:pwr');
  try {
    print('Led handle: ${led.getLedInfo()}');
    print('Led name: ${led.getLedName()}');
    print('Led brightness: ${led.getBrightness()}');
    print('Led maximum brightness: ${led.getMaxBrightness()}');
    var inverse = !led.read();
    print('Original led status: ${(!inverse)}');
    print('Toggle led');
    led.write(inverse);
    sleep(Duration(seconds: 5));
    inverse = !inverse;
    print('Toggle led');
    led.write(inverse);
    sleep(Duration(seconds: 5));
    print('Toggle led');
    inverse = !inverse;
    led.write(inverse);
    sleep(Duration(seconds: 5));
    print('Toggle led');
    led.write(!inverse);
  } finally {
    led.dispose();
  }
}

```

### PWM

Ensure that PWM is correct enabled. e.g. see the following [documentation](https://jumpnowtek.com/rpi/Using-the-Raspberry-Pi-Hardware-PWM-timers.html) for the Raspberry Pi.

``` dart
import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

void main() {
  var pwm = PWM(0, 0);
  try {
    print(pwm.getPWMinfo());
    pwm.setPeriodNs(10000000);
    pwm.setDutyCycleNs(8000000);
    print(pwm.getPeriodNs());
    pwm.enable();
    print("Wait 20 seconds");
    sleep(Duration(seconds: 20));
    pwm.disable();
  } finally {
    pwm.dispose();
  }
}
```

### MMIO

**Memory Mapped I/O**: Turns on a led at pin 18 on a Raspberry Pi using MMIO. This direct register access example is derived from [elinux.org](https://elinux.org/RPi_GPIO_Code_Samples#Direct_register_access).

``` dart
import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

const int bcm2708PeriBase = 0x3F000000; // Raspberry Pi 3
const int gpioBase = bcm2708PeriBase + 0x200000;
const int blockSize = 4 * 1024;

class MemMappedGPIO {
  MMIO mmio;
  MemMappedGPIO(this.mmio);

  // #define INP_GPIO(g) *(gpio+((g)/10)) &= ~(7<<(((g)%10)*3))
  void setPinInput(final int pin) {
    var offset = (pin ~/ 10) * 4;
    var value = mmio[offset];
    value &= (~(7 << (((pin) % 10) * 3)));
    mmio[offset] = value;
  }

  // #define OUT_GPIO(g) *(gpio+((g)/10)) |=  (1<<(((g)%10)*3))
  void setPinOutput(final int pin) {
    setPinInput(pin);
    var offset = (pin ~/ 10) * 4;
    var value = mmio[offset];
    value |= (1 << (((pin) % 10) * 3));
    mmio[offset] = value;
  }

  // #define GPIO_SET *(gpio+7) - sets   bits which are 1 ignores bits which are 0
  void setPinHigh(int pin) {
    mmio[7 * 4] = 1 << pin;
  }

  // #define GPIO_CLR *(gpio+10) - clears bits which are 1 ignores bits which are 0
  void setPinLow(int pin) {
    mmio[10 * 4] = 1 << pin;
  }

  // #define GET_GPIO(g) (*(gpio+13)&(1<<g)) - 0 if LOW, (1<<g) if HIGH
  int getPin(int pin) {
    return mmio[13 * 4] & (1 << pin);
  }
}

void main() {
  // Needs root rights and the gpioBase must be correct!
  // var mmio = MMIO(gpioBase, blockSize);
  var mmio = MMIO.advanced(0, blockSize, '/dev/gpiomem');
  var gpio = MemMappedGPIO(mmio);
  try {
    print(mmio.getMMIOinfo());
    var pin = 18;
    print('Led (pin=18) on');
    gpio.setPinOutput(pin);
    gpio.setPinHigh(pin);
    sleep(Duration(seconds: 10));
    gpio.setPinLow(pin);
    print('Led (pin=18) off');
  } finally {
    mmio.dispose();
  }
}
```

## Install Dart on Raspian and Armbian

1.) Go to the home directory

``` bash
cd ~
```

2.) Download the last stable Dart SDK form [archiv](https://dart.dev/tools/sdk/archive) for your CPU architecture/OS.

### ARMv7

``` bash
wget https://storage.googleapis.com/dart-archive/channels/stable/release/2.16.2/sdk/dartsdk-linux-arm-release.zip
unzip dartsdk-linux-arm-release.zip
```

### ARMv8

``` bash
wget https://storage.googleapis.com/dart-archive/channels/stable/release/2.16.2/sdk/dartsdk-linux-arm64-release.zip
unzip dartsdk-linux-arm64-release.zip
```

### x86

``` bash
https://storage.googleapis.com/dart-archive/channels/stable/release/2.16.2/sdk/dartsdk-linux-ia32-release.zip
unzip dartsdk-linux-ia32-release.zip
```

### x86_64

``` bash
https://storage.googleapis.com/dart-archive/channels/stable/release/2.16.1/sdk/dartsdk-linux-x64-release.zip
unzip dartsdk-linux-x64-release.zip
```

3.) Unpack and install SDK

``` bash
sudo mv dart-sdk /opt/
sudo chmod -R +rx /opt/dart-sdk
```

4.) Add the Dart SDK to the path

``` bash
nano ~/.profile
```

following command

``` bash
export PATH=$PATH:/opt/dart-sdk/bin
```

at the end of the file and call

``` bash
source ~/.profile
```

to apply the changes.

Test the installion

``` bash
pi@raspberrypi:~ $ dart --version
Dart SDK version: 2.16.1 (stable) (Tue Feb 8 12:02:33 2022 +0100) on "linux_arm64"
```

## Native libraries

Currently **dart_periphery** ships with four prebuild native c-periphery libraries for

* ARMv7 - [libperiphery_arm.so](https://github.com/pezi/dart_periphery/raw/main/lib/src/native/libperiphery_arm.so)
* ARMv8 - [libperiphery_arm64.so](https://github.com/pezi/dart_periphery/raw/main/lib/src/native/libperiphery_arm64.so)
* X86 - [libperiphery_x86.so](https://github.com/pezi/dart_periphery/blob/main/lib/src/native/libperiphery_x86.so)
* X86_64 - [libperiphery_x86_64.so](https://github.com/pezi/dart_periphery/blob/main/lib/src/native/libperiphery_x86_64.so)

**dart_periphery** calls uname() function to detect the CPU architecture for loading the appropriate libray. This auto detection mechanism can fail. Internally the logic tries to match the `uname -m` value to predefined string values.

Following methods can be used to overwrite the auto loading of the prebuild library. But be aware, any of these methods to disable the auto detection must be called before any **dart_periphery** interface is used!

``` dart
// enum CPU_ARCHITECTURE { X86, X86_64, ARM, ARM64 }
void setCPUarchitecture(CPU_ARCHITECTURE arch)
```

sets explicit the CPU architecture, which loads a library according following mapping

* CPU_ARCHITECTURE.ARM → [libperiphery_arm.so](https://github.com/pezi/dart_periphery/raw/main/lib/src/native/libperiphery_arm.so)
* CPU_ARCHITECTURE.ARM64 → [libperiphery_arm64.so](https://github.com/pezi/dart_periphery/raw/main/lib/src/native/libperiphery_arm64.so)
* CPU_ARCHITECTURE.X86 → [libperiphery_x86.so](https://github.com/pezi/dart_periphery/blob/main/lib/src/native/libperiphery_x86.so)
* CPU_ARCHITECTURE.X86_64 → [libperiphery_x86_64.so](https://github.com/pezi/dart_periphery/blob/main/lib/src/native/libperiphery_x86_64.so)

``` dart
useSharedLibray();
```

If this method is called, **dart_periphery** loads the shared library. For this case c-periphery must be installed as a shared library. See for [section Shared Library](https://github.com/vsergeev/c-periphery#shared-library) for details.

To load a custom library call

``` dart
void setCustomLibrary(String absolutePath)
```

This method can also be helpful for a currently not supported platform.

For a dart native binary, which can be deployed

``` bash
dart compile exe i2c_example.dart
```

call

``` dart
// optional parameter enum CPU_ARCHITECTURE { X86, X86_64, ARM, ARM64 }
// to skip auto detection
void useLocalLibrary([CPU_ARCHITECTURE arch])
```

The appropriate [library](https://github.com/pezi/dart_periphery/blob/main/lib/src/native) should be in same directory as the exe.

## flutter-pi

**dart_periphery** works with flutter-pi, a light-weight [Flutter Engine Embedder](https://github.com/ardera/flutter-pi) for Raspberry Pi. For flutter-pi the appropriate library must be copied inside the flutter asset directory.

* In most cases the ARMv7 library: [libperiphery_arm.so](https://github.com/pezi/dart_periphery/raw/main/lib/src/native/libperiphery_arm.so) for Raspberry Pi OS 32-bit
* ARMv8 [libperiphery_aarch64.so](https://github.com/pezi/dart_periphery/raw/main/lib/src/native/libperiphery_aarch64.so) for Raspberry Pi OS 64-bit

The appropriate library is loaded by auto detection of the CPU architecture. If this way fails, the auto detection can be overruled by following two methods:

``` dart
// enum CPU_ARCHITECTURE { X86, X86_64, ARM, ARM64 }
void setCPUarchitecture(CPU_ARCHITECTURE arch)
void setCustomLibrary(String absolutePath)
```

These methods must be called before any **dart_periphery** interface is used! See last section, [native libraries](https://pub.dev/packages/dart_periphery#native-libraries) for details.

For flutter-pi the method

``` dart
List<String> getFlutterPiArgs();
```

returns the command line parameter list of the `flutter-pi` command. The last parameter contains the asset directory.

## Tested SoC hardware

* [Raspberry Pi 3 Model B](https://www.raspberrypi.org/products/raspberry-pi-3-model-b-plus/), OS: Raspberry Pi OS
* [Raspberry Pi 3 Zero 2 W](https://www.raspberrypi.com/products/raspberry-pi-zero-2-w/), OS: Raspberry Pi OS (32/64)
* [NanoPi](https://wiki.friendlyarm.com/wiki/index.php/NanoPi_NEO) with a Allwinner H3, Quad-core 32-bit CPU, OS: [Armbian](https://www.armbian.com/nanopi-neo-core-2-lts/)
* [NanoPi M1](https://wiki.friendlyarm.com/wiki/index.php/NanoPi_M1) with a Allwinner H3, Quad-core 32-bit CPU: OS [Armbian](https://www.armbian.com/nanopi-m1/)
* [NanoPi Neo2](https://wiki.friendlyarm.com/wiki/index.php/NanoPi_NEO2) with a Allwinner H5, Quad-core 64-bit CPU, OS: [Armbian](https://www.armbian.com/nanopi-neo-2/)
* [Banana Pi BPI-M1](https://en.wikipedia.org/wiki/Banana_Pi#Banana_Pi_BPI-M1) with a Allwinner A20 Dual-core, OS: [Armbian](https://www.armbian.com/bananapi/)

## Supported devices (sensors, actuators, expansion hats and displays)

* [SGP30](https://github.com/pezi/dart_periphery/blob/main/example/i2c_sgp30.dart): tVOC and eCO2 Gas Sensor
* [BME280](https://github.com/pezi/dart_periphery/blob/main/example/i2c_bme280.dart): Temperature, humidity and pressure sensor.
* [BME680](https://github.com/pezi/dart_periphery/blob/main/example/i2c_bme680.dart): Temperature, humidity pressure and gas (Indoor Airy Quality) sensor.
* [SHT31](https://github.com/pezi/dart_periphery/blob/main/example/i2c_sht31.dart): Temperature and humidity sensor.
* [CozIR](https://github.com/pezi/dart_periphery/blob/main/example/serial_cozir.dart): CO₂, temperature and humidity sensor.
* [Grove Gesture](https://github.com/pezi/dart_periphery/blob/main/example/i2c_gesture_sensor.dart) can recognize 9 basic gestures.
* [MPU-6050 Six-Axis](https://github.com/pezi/dart_periphery/blob/main/example/i2c_mpu6050.dart) (Gyro + Accelerometer) sensor.
* FriendlyARM [BakeBit Set](https://wiki.friendlyelec.com/wiki/index.php/BakeBit_-_NanoHat_Hub)
* [Grove Base Hat](https://wiki.seeedstudio.com/Grove_Base_Hat_for_Raspberry_Pi/)/[GrovePi Plus](https://wiki.seeedstudio.com/GrovePi_Plus)
* [PN532](https://github.com/pezi/dart_periphery/pull/6) NFC Reader Module, Thanks to UliPrantz!
* SSD1306 OLED (in progress)

## Next steps

* Add GPIO documentation for different SoCs.
* Port hardware devices from the [mattjlewis / diozero Java Project](https://github.com/mattjlewis/diozero/tree/master/diozero-core/src/main/java/com/diozero/devices) to **dart_periphery**

## Test matrix

[Test suite](https://github.com/pezi/dart_periphery/tree/main/test)

| Architecture  | GPIO  |GPIO<sub>sysfs</sub>   | I2C   | SPI   | Serial| MMIO¹  | PWM   | LED   |
| ------------- |:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|------:|
| **ARM** ²     |&#9989;|&#9989;|&#9989;|&#9989;|&#9989;|&#9744;|&#9989;|&#9989;|
| **AARCH64** ³ |&#10060;⁴|&#9989;|&#9989;|&#9989;|&#9989;|&#9744;|&#9989;|&#9989;|
| **X86** ⁵     |&#9744;|&#9744;|&#9744;|&#9744;|&#9744;|&#9744;|&#9744;|&#9744;|
| **X86_64** ⁵  |&#9744;|&#9744;|&#9744;|&#9744;|&#9744;|&#9744;|&#9744;|&#9744;|

&#9744; missing test | &#9989; test passed | &#10060; test failed

¹ Delayed until FFI inline @Array() support in Dart Version >=2.13 is [available](https://github.com/dart-lang/sdk/issues/35763)

² [Raspberry Pi 3 Model B](https://www.raspberrypi.org/products/raspberry-pi-3-model-b-plus/)

³ [NanoPi Neo2](https://wiki.friendlyarm.com/wiki/index.php/NanoPi_NEO2) with a Allwinner H5, Quad-core 64-bit CPU

⁴ Fails for NanoPi, NanoPi Neo2 and Banana Pi on Armbian- same behavior like the original c-periphery [test program](https://github.com/vsergeev/c-periphery/blob/master/tests/test_gpio.c). This is a point of deeper investigations

⁵ no X86/X86_64 SoC for testing available


## Help wanted

* Testing **dart_periphery** on different [SoC platforms](https://www.armbian.com/download/)
* Documentation review - I am not a native speaker.
* Code review - this is my first public Dart project. I am a Java developer and probably I tend to solve problems rather in the Java than in the Dart way.
