#!/bin/zsh

# script for macOS

base64 -i libperiphery_arm.so | tr -d \\n > libperiphery_arm.so.base64
base64 -i libperiphery_arm64.so | tr -d \\n > libperiphery_arm64.so.base64
base64 -i libperiphery_ia32.so | tr -d \\n > libperiphery_ia32.so.base64
base64 -i libperiphery_x64.so | tr -d \\n > libperiphery_x64.so.base64

echo "// created by create_libbase64.sh" > lib.dart

echo "String arm ='\c" >> lib.dart
cat libperiphery_arm.so.base64 >> lib.dart
echo "';" >> lib.dart

echo "String arm64 ='\c" >> lib.dart
cat libperiphery_arm64.so.base64 >> lib.dart
echo "';" >> lib.dart

echo "String ia32 ='\c" >> lib.dart
cat libperiphery_ia32.so.base64 >> lib.dart
echo "';" >> lib.dart

echo "String x64 ='\c" >> lib.dart
cat libperiphery_x64.so.base64 >> lib.dart
echo "';" >> lib.dart

mv lib.dart lib_base64.dart

rm *.base64

  


