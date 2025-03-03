# Example for a Dart-Java-Bridge

This examples uses the JAVA awt class to generate graphics for the OLED SSD1306. 

This demos displays two images, an emoji and a sine curve created by bsh script.

Needed steps to start the demo - tested on a Raspberry Pi

Set the correct JAVA_HOME environment to a JDK

`export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64`

Compile the Java code

`javac -cp ./lib/bsh-2.0b4.jar at/flutterdev/EmojiBMPGenerator.java`

Compile the C code

`gcc -shared -o libjvmbridge.so -fPIC jvm_bridge.c  -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux" -L"$JAVA_HOME/lib/server" -ljvm`

Set the LD_LIBRARY_PATH 

`export LD_LIBRARY_PATH=$JAVA_HOME/lib/server:.`

Start the program

`dart dart_jvm_bridge.dart`



