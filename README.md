
# Introduction

**dart_periphery** is a Dart port of the native [c-periphery library](https://github.com/vsergeev/c-periphery).

![alt text](https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Raspberry_Pi_4_Model_B_-_Side.jpg/220px-Raspberry_Pi_4_Model_B_-_Side.jpg "Logo Title Text 1")

## What is c-periphery?  

Abstract from the project web site:

>c-periphery is a small C library for 
>* GPIO, 
>* LED, 
>* PWM, 
>* SPI, 
>* I2C, 
>* MMIO
>* Serial peripheral I/O 
>
>interface access in userspace Linux. c-periphery simplifies and consolidates the native Linux APIs to these interfaces. c-periphery is useful in embedded Linux environments (including Raspberry Pi, BeagleBone, etc. platforms) for interfacing with external peripherals. c-periphery is re-entrant, has no dependencies outside the standard C library and Linux, compiles into a static library for easy integration with other projects, and is MIT licensed

**dart_periphery** binds the c-periphery library with the help of the [dart:ffi](https://dart.dev/guides/libraries/c-interop) mechanism. A glue library handles the Dart specfic parts. Nevertheless **dart_periphery** tries to be close as possible to the orginal library. See following [documentation](https://github.com/vsergeev/c-periphery/tree/master/docs). Thanks to **Vanya Sergeev** for his great job!

## Why c-periphery?

The number of GPIO libraries/interfaces is becoming increasingly smaller.

* The famous wiringpi library is [deprected](http://wiringpi.com/wiringpi-deprecated/).
* GPIO sysfs is [deprected](https://www.raspberrypi.org/forums/viewtopic.php?t=274416).

**dart_periphery** currently has beta status. Following interfaces are ported:

* GPIO
* I2C
* Serial
* Led (onboard leds) 

## Examples

### GPIO

``` dart
void main() {
  GPIOconfig config = GPIOconfig();
  config.direction = GPIOdirection.GPIO_DIR_OUT;

  print("GPIO test");
  GPIO gpio = GPIO(18, GPIOdirection.GPIO_DIR_OUT);
  GPIO gpio2 = GPIO(16, GPIOdirection.GPIO_DIR_OUT);
  GPIO gpio3 = GPIO.advanced(5, config);

  print("GPIO info: " + gpio.getGPIOinfo());

  print("GPIO native file handle: " + gpio.getGPIOfd().toString());
  print("GPIO chip name: " + gpio.getGPIOchipName());
  print("GPIO chip label: " + gpio.getGPIOchipLabel());
  print("GPIO chip name: " + gpio.getGPIOchipName());
  print("CPIO chip label: " + gpio.getGPIOchipLabel());

  for (int i = 0; i < 10; ++i) {
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

``` dart
import 'package:dart_periphery/dart_periphery.dart';

/// https://wiki.seeedstudio.com/Grove-Barometer_Sensor-BME280/
/// Grove - Temp&Humi&Barometer Sensor (BME280) is a breakout board for Bosch BMP280 high-precision,
/// low-power combined humidity, pressure, and temperature sensor
void main() {
  // Select the right I2C bus number /dev/i2c-0
  // 1 for Raspbery Pi, 0 for NanoPi
  I2C i2c = I2C(1);
  try {
    print("I2C info:" + i2c.getI2Cinfo());
    BME280 bme280 = BME280(i2c);
    bme280.init();
    BME280result r = bme280.get();
    print("Temperature [°] " + r.temperature.toStringAsFixed(1));
    print("Humidity [%] " + r.humidity.toStringAsFixed(1));
    print("Pressure [hPa] " + r.pressure.toStringAsFixed(1));
  } finally {
    i2c.dispose();
  }
}
```

### Serial

``` dart
import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

///
/// [COZIR CO2 Sensor](https://co2meters.com/Documentation/Manuals/Manual_GC_0024_0025_0026_Revised8.pdf)
///
void main() {
  print("Serial test - COZIR CO2 Sensor");
  Serial s = new Serial("/dev/serial0", Baudrate.B9600);
  try {
    print("Serial interface info: " + s.getSerialInfo());

    // Return firmware version and sensor serialnumber - two line
    s.writeString("Y\r\n");
    SerialReadEvent event = s.read(256, 1000);
    print(event.toString());

    // Request temperature, humidity and CO2 level.
    s.writeString("M 4164\r\n");
    // Select polling mode
    s.writeString("K 2\r\n");
    // print any response
    event = s.read(256, 1000);
    print("Response " + event.toString());
    sleep(Duration(seconds: 1));
    for (int i = 0; i < 5; ++i) {
      s.writeString("Q\r\n");
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

``` dart
import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

void main() {
  /// Nano Pi power led  - see 'ls /sys/class/leds/'
  Led led = Led('nanopi:red:pwr');
  try {
    print("Led handle: " + led.getLedInfo());
    print("Led name: " + led.getLedName());
    print("Led brightness: " + led.getBrightness().toString());
    print("Led maximum brightness: " + led.getMaxBrightness().toString());
    bool inverse = !led.read();
    print("Original led status: " + (!inverse).toString());
    print("Toggle led");
    led.write(inverse);
    sleep(Duration(seconds: 5));
    inverse = !inverse;
    print("Toggle led");
    led.write(inverse);
    sleep(Duration(seconds: 5));
    print("Toggle led");
    inverse = !inverse;
    led.write(inverse);
    sleep(Duration(seconds: 5));
    print("Toggle led");
    led.write(!inverse);
  } finally {
    led.dispose();
  }
}

```
## Install dart on Raspian and Armbian

###  ARMv7 

```
cd ~
wget https://storage.googleapis.com/dart-archive/channels/stable/release/2.10.5/sdk/dartsdk-linux-arm-release.zip
unzip dartsdk-linux-arm-release.zip
sudo mv dart-sdk /opt/
sudo chmod +rx /opt/dart-sdk
```

### ARMv8

```
wget https://storage.googleapis.com/dart-archive/channels/stable/release/2.10.5/sdk/dartsdk-linux-arm64-release.zip
unzip dartsdk-linux-arm64-release.zip
sudo mv dart-sdk /opt/
sudo chmod +rx /opt/dart-sdk
```



```
nano ~/.profile
```

add for bash as default 

```
nano ~/.profile
```

following command

```
export PATH=$PATH:/opt/dart-sdk/bin
```

at the end of the file and call

```
source ~/.profile
```

to apply the changes.

Test the installion

```
root@nanopineo2:~# dart --version
Dart SDK version: 2.10.5 (stable) (Tue Jan 19 13:05:37 2021 +0100) on "linux_arm64"
```

## Native library

Currently **dart_perphery** ships with prebuild native libraries for Armv7 and Armv8 in two flavours - static and dynamic linking.

* `dart_periphery_32.1.0.0.so` ➔ `/usr/local/lib/libperiphery.so`
* `dart_periphery_static_32.1.0.0.so` (includes libperiphery.a)
* `dart_periphery_64.1.0.0.so` ➔ `/usr/local/lib/libperiphery.so`
* `dart_periphery_static_64.1.0.0.so`  (includes libperiphery.a)

These **glue** libraries contain the Dart specific part to the **c-periphery** library. As default **dart_perphery** loads the static linked library.

Following methods can be used to overwite the loading of the static linked library.
But be aware, any of these methods must be called before any **dart_perphery** interface is used!

```
useSharedLibray();
```

If this method is called, **dart_perphery** loads the shadred library. For this case c-pheriphery must be installed as a shared library. See for [details](https://github.com/vsergeev/c-periphery) - section Shared Library. 

The glue library, flavour shared, can be rebuild with following command:

```
pub global activate dart_periphery
```

```
pub global run dart_periphery:build_lib
```

To load a custom libaray call 

```
setCustomLibrary(String absolutePath)
```
This method can be helpful in any case of a problem and for a currently not supporetd platform - e.g x86 based SoC

For building a custom libray please review following information
* [make file](https://github.com/pezi/dart_periphery/blob/main/lib/src/native/build_all.sh) 
*  [c-periphery](https://github.com/vsergeev/c-periphery) - section Static or Shared Library. 



For a dart native binary, which can be deployed
```
dart compile exe i2c_example.dart
```

call

```
void useLocalLibrary([bool staticLib = true])
```

to use the static or shared glue library with the correct bitness. The appropriate [library](https://github.com/pezi/dart_periphery/blob/main/lib/src/native) should be in same dirctory as the exe.



## Tested hardware 

Raspbery Pi 3 Model B (Raspian)


[Nano Pi](http://wiki.friendlyarm.com/wiki/index.php/NanoPi_NEO)
with [Armbian](https://www.armbian.com/)


[Nano Pi Neo2](http://wiki.friendlyarm.com/wiki/index.php/NanoPi_NEO2) with a Allwinner H5, Quad-core 64-bit CPU with [Armbian](https://www.armbian.com/)


## Next steps

Port the missing c-periphery bindings

* PWM (ported, but not tested)
* SPI
* MMIO
* Add GPIO documentation for different SoCs
* Writing API test cases
* Improve build process of the native libraries

## Future steps

* If possible, developing a flutter desktop app for the Raspberry Pi with bindings to **dart_perphery**.
* Port hardware devices from the [ mattjlewis / diozero Java Project](https://github.com/mattjlewis/diozero/tree/master/diozero-core/src/main/java/com/diozero/devices) to **dart_periphery**: e.g.BME680, SGP30 etc.
In most cases it is easy to find code snippets for the most sensors, but the implementations of the diozero Project have a high level.

## Help wanted

* Testing **dart_periphery** on different [SoC platforms](https://www.armbian.com/download/)
* Documentation review - I am not a native speaker.
* Code review - this is my first public Dart project, I am a Java developer and probably I tend to solve problems rather in the Java than in the Dart way.

