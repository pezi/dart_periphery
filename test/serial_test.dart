// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

// https://github.com/vsergeev/c-periphery/blob/master/tests/test_serial.c

import 'package:dart_periphery/dart_periphery.dart';
import 'util.dart';
import 'dart:io';

void test_arguments() {
  // Invalid data bits (4 and 9)
  // ppassert(serial_open_advanced(serial, device, 115200, 4, PARITY_NONE, 1, false, false) == SERIAL_ERROR_ARG);
  // ppassert(serial_open_advanced(serial, device, 115200, 9, PARITY_NONE, 1, false, false) == SERIAL_ERROR_ARG);
  // Invalid parity
  // ppassert(serial_open_advanced(serial, device, 115200, 8, PARITY_EVEN+1, 1, false, false) == SERIAL_ERROR_ARG);
  //  Invalid stopbits
  // ppassert(serial_open_advanced(serial, device, 115200, 8, PARITY_NONE, 0, false, false) == SERIAL_ERROR_ARG);
  // ppassert(serial_open_advanced(serial, device, 115200, 8, PARITY_NONE, 3, false, false) == SERIAL_ERROR_ARG);
  // Due the usage of enums this invald parameter can not be mapped
}

void test_open_config_close(String device) {
  var serial = Serial(device, Baudrate.B115200);
  try {
    passert(serial.getBaudrate() == Baudrate.B115200);
    passert(serial.getDataBits() == DataBits.DB8);
    passert(serial.getParity() == Parity.PARITY_NONE);
    passert(serial.getStopBits() == StopBits.SB1);
    passert(serial.getXONXOFF() == false);
    passert(serial.getRTSCTS() == false);
    passert(serial.getVMIN() == 0);
    passert(serial.getVTIME() == 0);

    // Change some stuff around
    for (var b in [Baudrate.B4800, Baudrate.B9600]) {
      serial.setBaudrate(b);
      passert(serial.getBaudrate() == b);
    }
    serial.setDataBits(DataBits.DB7);
    passert(serial.getDataBits() == DataBits.DB7);
    serial.setParity(Parity.PARITY_ODD);
    passert(serial.getParity() == Parity.PARITY_ODD);
    serial.setStopBits(StopBits.SB2);
    passert(serial.getStopBits() == StopBits.SB2);
    serial.setXONXOFF(true);
    passert(serial.getXONXOFF() == true);
    // Test serial port may not support rtscts
    // serial.setRTSCTS(true);
    // passert(serial.getRTSCTS() == true);
    serial.setVMIN(50);
    passert(serial.getVMIN() == 50);
    serial.setVTIME(15.3);
    passert((serial.getVTIME() - 15.3).abs() < 0.1);
  } finally {
    serial.dispose();
  }
}

const String loreIpsum =
    'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';

void test_loopback(String device) {
  var serial = Serial(device, Baudrate.B115200);
  try {
    passert(serial.writeString(loreIpsum) == loreIpsum.length);
    serial.flush();
    passert(serial.read(loreIpsum.length, -1).count == loreIpsum.length);

    // Test poll/write/flush/poll/input waiting/read
    passert(serial.poll(500) == false);
    passert(serial.writeString(loreIpsum) == loreIpsum.length);
    serial.flush();
    passert(serial.poll(500) == true);
    sleep(Duration(microseconds: 500000));
    passert(serial.getInputWaiting() == loreIpsum.length);
    passert(serial.read(loreIpsum.length, -1).count == loreIpsum.length);

    // Test non-blocking poll
    passert(serial.poll(0) == false);

    // Test a very large read-write (likely to exceed internal buffer size (~4096))
    var buf = List<int>.filled(4096 * 3, 0xAA);
    passert(serial.write(buf) == buf.length);
    serial.flush();
    passert(serial.read(buf.length, -1).count == buf.length);
    serial.flush();

    // Test read timeout
    var start = DateTime.now().millisecondsSinceEpoch;
    serial.read(buf.length, 2000);
    var stop = DateTime.now().millisecondsSinceEpoch;
    passert(((stop - start) / 1000.0) > 1);

    // Test non-blocking read
    start = DateTime.now().millisecondsSinceEpoch;
    serial.read(buf.length, 0);
    stop = DateTime.now().millisecondsSinceEpoch;
    // Assuming we weren't context switched out for a second and weren't on  thin time boundary ;)
    passert(((stop - start) / 1000.0) == 0);

    //  Test blocking read with vmin=5 termios timeout
    serial.setVMIN(5);
    passert(serial.writeString(loreIpsum.substring(0, 5)) == 5);
    serial.flush();
    passert(serial.read(5, -1).count == 5);

    // Test blocking read with vmin=5, vtime=2 termios timeout
    serial.setVTIME(2);
    passert(serial.writeString(loreIpsum.substring(0, 3)) == 3);
    serial.flush();
    start = DateTime.now().millisecondsSinceEpoch;
    passert(serial.read(3, -1).count == 3);
    stop = DateTime.now().millisecondsSinceEpoch;

//    passert(((stop - start) / 1000.0) > 1);
  } finally {
    serial.dispose();
  }
}

void test_interactive(String device) {
  var serial = Serial(device, Baudrate.B4800);
  var buf = '"Hello World';
  try {
    print('Starting interactive test. Get out your logic analyzer, buddy!');
    print('Press enter to continue...');
    pressKey();
    print('Serial description: ${serial.getSerialInfo()}');
    print('Serial description looks OK? y/n');
    pressKeyYes();

    print('Press enter to start transfer...');
    pressKey();

    for (var brate in [Baudrate.B4800, Baudrate.B9600, Baudrate.B115200]) {
      serial.setBaudrate(brate);
      serial.writeString(buf);
      print('Serial transfer baudrate $brate, 8n1 occurred? y/n');
      pressKeyYes();
    }
  } finally {
    serial.dispose();
  }
}

void main(List<String> argv) {
  if (argv.length != 1) {
    print('Usage: dart serial_test <serial port device>');
    print('[1/4] Arguments test: No requirements.');
    print('[2/4] Open/close test: Serial port device should be real.');
    print(
        '[3/4] Loopback test: Serial TX and RX should be connected with a wire.');
    print(
        '[4/4] Interactive test: Serial TX should be observed with an oscilloscope or logic analyzer.');
    print('Hint: for Raspberry Pi 3, enable UART0 with:');
    print(
        '   \$ echo \"dtoverlay=pi3-disable-bt\" | sudo tee -a /boot/config.txt');
    print('   \$ sudo systemctl disable hciuart');
    print('   \$ sudo reboot');
    print('   (Note that this will disable Bluetooth)');
    print('Use pins UART0 TXD (header pin 8) and UART0 RXD (header pin 10),');
    print('connect a loopback between TXD and RXD, and run this test with:');
    print('    dart serial_test /dev/ttyAMA0');
    exit(1);
  }

  var device = argv[0];
  test_arguments();

  print('Arguments test passed.');
  test_open_config_close(device);
  print('Open/close test passed.');
  test_loopback(device);
  print('Loopback test passed.');
  test_interactive(device);
  print('Interactive test passed.');

  print('All tests passed!\n');
}
