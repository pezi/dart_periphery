#!/bin/zsh

# script for macOS

gzip -v9 -c libperiphery_arm.so > libperiphery_arm.so.gz
gzip -v9 -c libperiphery_arm64.so > libperiphery_arm64.so.gz
gzip -v9 -c libperiphery_ia32.so > libperiphery_ia32.so.gz
gzip -v9 -c libperiphery_x64.so > libperiphery_x64.so.gz
gzip -v9 -c libperiphery_riscv64.so > libperiphery_riscv64.so.gz

base64 -i libperiphery_arm.so.gz | tr -d \\n > libperiphery_arm.so.base64
base64 -i libperiphery_arm64.so.gz | tr -d \\n > libperiphery_arm64.so.base64
base64 -i libperiphery_ia32.so.gz | tr -d \\n > libperiphery_ia32.so.base64
base64 -i libperiphery_x64.so.gz | tr -d \\n > libperiphery_x64.so.base64
base64 -i libperiphery_riscv64.so.gz | tr -d \\n > libperiphery_riscv64.so.base64

rm *.so.gz

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

echo "String riscv64 ='\c" >> lib.dart
cat libperiphery_riscv64.so.base64 >> lib.dart
echo "';" >> lib.dart

mv lib.dart lib_base64.dart

rm *.base64

  


