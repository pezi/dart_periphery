# Example for a Dart-Java-Bridge

This examples uses the JAVA awt class to generate graphics for the OLED SSD1306. 

This demos displays two images, an emoji and a sine curve created by a bsh (Java Bean Shell) script.

## 📖 Steps to start the demo - tested on a Raspberry Pi and Armbian

`apt install fonts-noto-color-emoji`

`sudo apt-get install openjdk-17-jdk`  

for Armbian supports higher JDK versione.g. `sudo apt-get install openjdk-21-jdk`  

Set the correct `JAVA_HOME` environment to the JDK

`export JAVA_HOME=/usr/lib/jvm/default-java`

Compile the Java code including the bean shell support.

`javac -cp ./lib/bsh-2.0b4.jar at/flutterdev/EmojiBMPGenerator.java`

Compile the C code as a shared library.

`gcc -shared -o libjvmbridge.so -fPIC jvm_bridge.c  -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux" -L"$JAVA_HOME/lib/server" -ljvm`

Set the `LD_LIBRARY_PATH` - jvm lib and `libjvmbridge.so` 

`export LD_LIBRARY_PATH=$JAVA_HOME/lib/server:.`

Start the program

`dart i2c_ssd1306_java_awt.dart`

## 📣 Additional infos for development and testing

Compile the C program as a executable:

### Test the Java layer  
`java -cp ./lib/bsh-2.0b4.jar at/flutterdev/EmojiBMPGenerator.java`

### Test the C layer

 Linux:  `gcc -o calljava -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/darwin" jvm_bridge.c -L"$JAVA_HOME/lib/server" -ljvm` 
 
 MacOS: `gcc -o calljava -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux" calljava.c -L"$JAVA_HOME/lib/server" -ljvm`

Additonal step for MacOS to set the `RPATH`

`install_name_tool -add_rpath $JAVA_HOME/lib/server/ ./calljava`

# Test the Dart layer

Under MacOS a Dart program invoking the JVM runs into the missing `RPATH` problem. You can apply `install_name_tool` to Dart souce file. But you can apply `install_name_tool` to the compiled `dart compile exe test.dart` version of the Dart porgramm.   
