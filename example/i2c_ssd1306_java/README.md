# Example for a Dart-Java-Bridge

This examples uses the JAVA awt class to generate graphics for the OLED SSD1306. 

This demos displays two images, an emoji and a sine curve created by bsh script.

Needed steps to start the demo - tested on a Raspberry Pi and Armbian


Raspberry Pi

apt install fonts-noto-color-emoji

`sudo apt-get install openjdk-17-jdk`  

for Armbian a higher JDK version is possible

`sudo apt-get install openjdk-21-jdk`  

Set the correct JAVA_HOME environment to a JDK


`export JAVA_HOME=/usr/lib/jvm/default-java`

Compile the Java code

`javac -cp ./lib/bsh-2.0b4.jar at/flutterdev/EmojiBMPGenerator.java`

Compile the C code

`gcc -shared -o libjvmbridge.so -fPIC jvm_bridge.c  -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux" -L"$JAVA_HOME/lib/server" -ljvm`

Set the LD_LIBRARY_PATH 

`export LD_LIBRARY_PATH=$JAVA_HOME/lib/server:.`

Start the program

`dart i2c_ssd1306_java_awt.dart`

// install_name_tool -add_rpath $JAVA_HOME/lib/server/ ./cjava
// install_name_tool -add_rpath /Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home/lib/server/ ./cjava
// gcc  -o  calljava -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/darwin" jvm_bridge.c   -L"$JAVA_HOME/lib/server" -ljvm
//  gcc  -o  calljava -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux" calljava.c -L"$JAVA_HOME/lib/server" -ljvm

