export JAVA_HOME=/usr/lib/jvm/default-java
javac -cp ./lib/bsh-2.0b4.jar at/flutterdev/EmojiBMPGenerator.java
gcc -shared -o libjvmbridge.so -fPIC jvm_bridge.c  -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux" -L"$JAVA_HOME/lib/server" -ljvm
export LD_LIBRARY_PATH=$JAVA_HOME/lib/server:.
dart i2c_ssd1306_java_awt.dart