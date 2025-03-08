# see README for details
echo "Set Java Home - auto detect"
export JAVA_HOME=$(update-java-alternatives -l | awk '{print $3}')
echo $JAVA_HOME
echo "Compile Java"
javac -cp ./lib/bsh-2.0b4.jar at/flutterdev/EmojiBMPGenerator.java
echo "Compile C library"
gcc -shared -o libjvmbridge.so -fPIC jvm_bridge.c  -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux" -L"$JAVA_HOME/lib/server" -ljvm
export LD_LIBRARY_PATH=$JAVA_HOME/lib/server:.
echo "Start Dart script"
dart i2c_ssd1306_java_awt.dart
