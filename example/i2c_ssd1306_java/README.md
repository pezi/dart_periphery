# Example for a Dart-Java-Bridge

This example uses the Java AWT class to generate graphics for the OLED SSD1306.

The demo displays two images: an emoji and a sine curve, both created using a BSH (Java BeanShell) script.


## 📋 Prerequisites

- Raspberry Pi or compatible SBC with I2C support
- SSD1306 OLED display connected via I2C
- OpenJDK 17 or higher
- Dart SDK installed
- `dart_periphery` package


## 📖 Steps to Start the Demo (Tested on Raspberry OS and Armbian)

### Step 1.	Install OpenJDK:

`sudo apt-get install openjdk-17-jdk`  

Armbian supports higher JDK versions e.g. 

```bash
sudo apt install openjdk-21-jre-headless
```

### Step 2.	Set the `JAVA_HOME` environment variable:

Try autodetection:

```bash
export JAVA_HOME=$(update-java-alternatives -l | awk '{print $3}')
echo $JAVA_HOME
```

### Step 3. Compile the Java code, including BeanShell support:

```bash
javac -cp ./lib/bsh-2.0b4.jar at/flutterdev/EmojiBMPGenerator.java
```

### Step 4.	Compile the C code as a shared library:

```bash
gcc -shared -o libjvmbridge.so -fPIC jvm_bridge.c  -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux" -L"$JAVA_HOME/lib/server" -ljvm
```

### Step 5.  Set the `LD_LIBRARY_PATH` to include the JVM library and `libjvmbridge.so` 

```bash
export LD_LIBRARY_PATH=$JAVA_HOME/lib/server:.
```

### Step 6.	Start the program:

```bash
dart i2c_ssd1306_java_awt.dart
```

## 📣 Additional Information for Development and Testing

### Test the Java layer - main method with test code
```bash
java -cp ./lib/bsh-2.0b4.jar at/flutterdev/EmojiBMPGenerator.java
```

### Test the C layer - main method with test code

macOS:   

```bash
gcc -o calljava -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/darwin" jvm_bridge.c -L"$JAVA_HOME/lib/server" -ljvm
```

Linux:

```bash
gcc -o calljava -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux" jvm_bridge.c -L"$JAVA_HOME/lib/server" -ljvm
```

Additional step for macOS to set the `RPATH`

```bash
install_name_tool -add_rpath $JAVA_HOME/lib/server/ ./calljava
```

### Test the Dart layer

On macOS, a Dart program invoking the JVM may encounter a missing `RPATH` issue. Since you cannot apply `install_name_tool` directly to a Dart source file, you need to apply it to the compiled executable version of the Dart program:

```bash
dart compile exe test.dart
install_name_tool -add_rpath $JAVA_HOME/lib/server/ test
```