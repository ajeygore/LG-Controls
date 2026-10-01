#ifndef _I2C_H
#define _I2C_H

#import "ioregistry.h"

#define DEFAULT_INPUT_ADDRESS    0x51
#define ALTERNATE_INPUT_ADDRESS  0x50

#define LUMINANCE   0x10
#define CONTRAST    0x12
#define VOLUME      0x62
#define MUTE        0x8D
#define INPUT       0x60
#define INPUT_ALT   0xF4
#define STANDBY     0xD6
#define RED         0x16
#define GREEN       0x18
#define BLUE        0x1A

#define DDC_WAIT           10000
#define DDC_ITERATIONS     2
#define DDC_MCDP_READ_WAIT 50000
#define DDC_BUFFER_SIZE    256

typedef struct {
    UInt8 data[DDC_BUFFER_SIZE];
    UInt8 inputAddr;
} DDCPacket;

typedef struct {
    signed int curValue;
    signed int maxValue;
} DDCValue;

DDCPacket createDDCPacket(UInt8 attrCode);
void prepareDDCRead(UInt8 *data);
void prepareDDCWrite(DDCPacket *packet, UInt16 setValue);

IOReturn performDDCWrite(IOAVServiceRef avService, DDCPacket *packet);
IOReturn performDDCRead(IOAVServiceRef avService, DDCPacket *packet);
IOReturn performDDCWriteAtChipAddress(IOAVServiceRef avService, UInt32 chipAddress, DDCPacket *packet);
IOReturn performDDCReadAtChipAddress(IOAVServiceRef avService, UInt32 chipAddress, DDCPacket *packet);

DDCValue convertI2CtoDDC(const char *i2cBytes);

// External functions
extern IOReturn IOAVServiceReadI2C(IOAVServiceRef service, uint32_t chipAddress, uint32_t offset, void *outputBuffer, uint32_t outputBufferSize);
extern IOReturn IOAVServiceWriteI2C(IOAVServiceRef service, uint32_t chipAddress, uint32_t dataAddress, void *inputBuffer, uint32_t inputBufferSize);

#endif
