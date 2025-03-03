# 

`export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64`

`javac -cp ./lib/bsh-2.0b4.jar at/flutterdev/EmojiBMPGenerator.java`

`gcc -shared -o libjvmbridge.so -fPIC jvm_bridge.c  -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux" -L"$JAVA_HOME/lib/server" -ljvm`

`export LD_LIBRARY_PATH=$JAVA_HOME/lib/server:.`

`dart dart_jvm_bridge.dart`



