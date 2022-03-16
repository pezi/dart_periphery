const List<int> pn532Ack = [0x00, 0x00, 0xFF, 0x00, 0xFF, 0x00];
const List<int> pn532FirmwareVersions = [0x00, 0x00, 0xFF, 0x06, 0xFA, 0xD5];

const int pn532I2CAddress = 0x48 >> 1;
const int pn532I2CReadByte = 0x01;
const int pn532I2CBusy = 0x00;
const int pn532I2CReady = 0x01;
const int pn532I2CReadytimeout = 20;

const int pn532SpiStartRead = 0x02;
const int pn532SpiDataWrite = 0x01;
const int pn532SpiDataRead = 0x03;
const int pn532SpiReady = 0x01;
const int pn532SpiChannel = 0;

const int pn532Preamble = 0x00;
const int pn532StartCode1 = 0x00;
const int pn532StartCode2 = 0xFF;
const int pn532Postamble = 0x00;

const int pn532HostToPn532 = 0xD4;
const int pn532Pn532ToHost = 0xD5;

const int pn532CommandDiagnose = 0x00;
const int pn532CommandGetFirmwareVersion = 0x02;
const int pn532CommandGetGeneralStatus = 0x04;
const int pn532CommandReadRegister = 0x06;
const int pn532CommandWriteRegister = 0x08;
const int pn532CommandReadGpio = 0x0C;
const int pn532CommandWriteGpio = 0x0E;
const int pn532CommandSetSerialbaudrate = 0x10;
const int pn532CommandSetParameters = 0x12;
const int pn532CommandSamConfiguration = 0x14;
const int pn532CommandPowerDown = 0x16;
const int pn532CommandRfConfiguration = 0x32;
const int pn532CommandRfRegulationTest = 0x58;
const int pn532CommandInJumpForDep = 0x56;
const int pn532CommandInJumpForPsl = 0x46;
const int pn532CommandInListPassiveTarget = 0x4A;
const int pn532CommandInAtr = 0x50;
const int pn532CommandInPsl = 0x4E;
const int pn532CommandInDataExchange = 0x40;
const int pn532CommandInCommunicateThru = 0x42;
const int pn532CommandInDeselect = 0x44;
const int pn532CommandInRelease = 0x52;
const int pn532CommandInSelect = 0x54;
const int pn532CommandInAutoPoll = 0x60;
const int pn532CommandTgInitAsTarget = 0x8C;
const int pn532CommandTgSetGeneralBytes = 0x92;
const int pn532CommandTgGetData = 0x86;
const int pn532CommandTgSetData = 0x8E;
const int pn532CommandTgSetMetaData = 0x94;
const int pn532CommandTgGetInitiatorcommand = 0x88;
const int pn532CommandTgResponseToInitiator = 0x90;
const int pn532CommandTgGetTargetStatus = 0x8A;

const int pn532ResponseInDataExchange = 0x41;
const int pn532ResponseInListPassiveTarget = 0x4B;

const int pn532Wakeup = 0x5;

const int pn532StandardTimeout = 1000;
const int pn532MifareIso14443A = 0;
