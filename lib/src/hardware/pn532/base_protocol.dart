import 'dart:io';

import 'package:meta/meta.dart';
import 'package:dart_periphery/dart_periphery.dart';

import 'package:dart_periphery/src/hardware/pn532/constants.dart';
import 'package:dart_periphery/src/hardware/pn532/exceptions.dart';

typedef PN532ReadyFunction = bool Function(int attemptCount);

abstract class PN532BaseProtocol {
  final GPIO? resetGpio;
  final GPIO? irqGpio;

  late final bool useIrq;
  late final PN532ReadyFunction pn532ReadyFunction;

  PN532BaseProtocol({
    int? resetPin,
    int? irqPin,
  })  : resetGpio = resetPin == null
            ? null
            : GPIO(resetPin, GPIOdirection.GPIO_DIR_OUT),
        irqGpio =
            irqPin == null ? null : GPIO(irqPin, GPIOdirection.GPIO_DIR_IN) {
    pn532ReadyFunction = getCorrectReadyFunction();
    reset();
    wakeUp();
  }

  PN532ReadyFunction getCorrectReadyFunction() {
    if (irqGpio != null) {
      useIrq = true;
      return (_) => isReadyUsingInterrupt();
    }

    useIrq = false;
    return isReady;
  }

  void waitReady({int timeout = pn532StandardTimeout}) {
    int attemptCount = 0;

    final int timeStart = DateTime.now().millisecondsSinceEpoch;
    sleep(const Duration(milliseconds: 10));

    bool pn532IsReady = pn532ReadyFunction(attemptCount);
    while (!pn532IsReady) {
      // this sleep is extremly important! (when we don't use the irqPin)
      // without you read the pn532 to often which curses to many interrupts
      // on the pn532 board which results in to little execution time for the
      // actual command/firmware on the pn532 which ends up in only getting
      // PN532TimeoutException because the pn532 can't process the actual command
      // (this can be avoided by only using the IRQ pin!)
      if (!useIrq) {
        sleep(const Duration(milliseconds: 20));
      }

      final int timeDelta = DateTime.now().millisecondsSinceEpoch - timeStart;
      if (timeDelta >= timeout) {
        throw PN532TimeoutExcepiton(timeout: timeout);
      }

      attemptCount++;
      pn532IsReady = pn532ReadyFunction(attemptCount);
    }
  }

  bool isReadyUsingInterrupt() {
    assert(irqGpio != null,
        "isReadyUsingInterrupt() was called even though the irqPin/irqGpio wasn't provided");
    return !irqGpio!.read();
  }

  /// The implementation is protocol based. Just check if the PN532 is ready
  /// based on the used protocol (if an `irqPin`) was specified
  /// the `PN532BaseProtocol` will use the `irqPin` instead of this funciton!
  ///
  /// The parameter `attemptCount` will provide you with a count that refelcts
  /// how often this function was already called in this `waitReady` cyclus.
  /// Starting with 0!
  bool isReady(int attemptCount);

  void wakeUp();

  void reset() {
    resetGpio?.write(true);
    sleep(const Duration(milliseconds: 100));
    resetGpio?.write(false);
    sleep(const Duration(milliseconds: 500));
    resetGpio?.write(true);
    sleep(const Duration(milliseconds: 100));
  }

  void writeData(List<int> data);

  List<int> readData(int length);

  @mustCallSuper
  void dispose() {
    resetGpio?.dispose();
    irqGpio?.dispose();
  }
}
