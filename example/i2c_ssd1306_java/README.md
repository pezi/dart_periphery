# Example for a Dart-Java-Bridge

This example uses the Java AWT class to generate graphics for the OLED SSD1306.

The demo displays two images: an emoji and a sine curve, both created using a bsh (Java BeanShell) script.


## 📖 Steps to Start the Demo (Tested on Raspberry OS and Armbian)

1.	Install the required font package:

`apt install fonts-noto-color-emoji`

2.	Install OpenJDK:

`sudo apt-get install openjdk-17-jdk`  

Armbian supports higher JDK versions e.g. 

`sudo apt-get install openjdk-21-jdk`  

3.	Set the `JAVA_HOME` environment variable:

`export JAVA_HOME=/usr/lib/jvm/default-java`

4.	Compile the Java code, including BeanShell support:

`javac -cp ./lib/bsh-2.0b4.jar at/flutterdev/EmojiBMPGenerator.java`

5.	Compile the C code as a shared library:

`gcc -shared -o libjvmbridge.so -fPIC jvm_bridge.c  -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux" -L"$JAVA_HOME/lib/server" -ljvm`

6.Set the `LD_LIBRARY_PATH` to include the JVM library and `libjvmbridge.so` 

`export LD_LIBRARY_PATH=$JAVA_HOME/lib/server:.`

7.	Start the program:

`dart i2c_ssd1306_java_awt.dart`

## 📣 Additional Information for Development and Testing

Compile the C Program as an Executable

### Test the Java layer  
`java -cp ./lib/bsh-2.0b4.jar at/flutterdev/EmojiBMPGenerator.java`

### Test the C layer

 Linux:  `gcc -o calljava -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/darwin" jvm_bridge.c -L"$JAVA_HOME/lib/server" -ljvm` 
 
 macOS: `gcc -o calljava -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux" calljava.c -L"$JAVA_HOME/lib/server" -ljvm`

Additonal step for macOS to set the `RPATH`

`install_name_tool -add_rpath $JAVA_HOME/lib/server/ ./calljava`

### Test the Dart layer

On macOS, a Dart program invoking the JVM may encounter a missing RPATH issue. Since you cannot apply `install_name_tool` directly to a Dart source file, you need to apply it to the compiled executable version of the Dart program:

```
dart compile exe test.dart
install_name_tool -add_rpath $JAVA_HOME/lib/server/ test
```