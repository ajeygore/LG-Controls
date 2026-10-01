#import <Foundation/Foundation.h>
#import "i2c.h"
#import "utils.h"

static int getBytesUsed(UInt8 *data) {
    int bytes = 0;
    for (int i = 0; i < DDC_BUFFER_SIZE; ++i) {
        if (data[i] != 0) {
            bytes = i + 1;
        }
    }
    return bytes;
}

DDCPacket createDDCPacket(UInt8 attrCode) {
    DDCPacket packet = {};
    packet.data[2] = attrCode;
    packet.inputAddr = (packet.data[2] == INPUT_ALT) ? ALTERNATE_INPUT_ADDRESS : DEFAULT_INPUT_ADDRESS;
    return packet;
}

void prepareDDCRead(UInt8 *data) {
    data[0] = 0x82;
    data[1] = 0x01;
    data[3] = 0x6e ^ data[0] ^ data[1] ^ data[2] ^ data[3];
}

void prepareDDCWrite(DDCPacket *packet, UInt16 newValue) {
    UInt8 *data = packet->data;
    data[0] = 0x84;
    data[1] = 0x03;
    data[3] = (newValue) >> 8;
    data[4] = newValue & 255;
    data[5] = 0x6E ^ packet->inputAddr ^ data[0] ^ data[1] ^ data[2] ^ data[3] ^ data[4];
}

IOReturn performDDCReadAtChipAddress(IOAVServiceRef avService, UInt32 chipAddress, DDCPacket *packet) {
    memset(packet->data, 0, sizeof(UInt8) * DDC_BUFFER_SIZE);
    usleep(chipAddress == DDC_CHIP_ADDRESS_MCDP29XX ? DDC_MCDP_READ_WAIT : DDC_WAIT);
    return IOAVServiceReadI2C(avService, chipAddress, packet->inputAddr, packet->data, 12);
}

IOReturn performDDCWriteAtChipAddress(IOAVServiceRef avService, UInt32 chipAddress, DDCPacket *packet) {
    IOReturn ret = kIOReturnSuccess;
    for (int i = 0; i < DDC_ITERATIONS; ++i) {
        usleep(DDC_WAIT);
        ret = IOAVServiceWriteI2C(avService, chipAddress, packet->inputAddr, packet->data, getBytesUsed(packet->data));
        if (ret != kIOReturnSuccess) {
            return ret;
        }
    }
    return ret;
}

IOReturn performDDCRead(IOAVServiceRef avService, DDCPacket *packet) {
    return performDDCReadAtChipAddress(avService, DDC_CHIP_ADDRESS_DEFAULT, packet);
}

IOReturn performDDCWrite(IOAVServiceRef avService, DDCPacket *packet) {
    return performDDCWriteAtChipAddress(avService, DDC_CHIP_ADDRESS_DEFAULT, packet);
}

DDCValue convertI2CtoDDC(const char *i2cBytes) {
    DDCValue displayAttr = {-1, -1};
    if (!i2cBytes) return displayAttr;
    const unsigned char *data = (const unsigned char *)i2cBytes;
    
    // In DDC/CI standard: byte 3 is result (0 = success).
    // If not success or response looks invalid, return -1.
    if (data[3] != 0x00 && data[0] != 0x6E) {
        return displayAttr;
    }
    
    displayAttr.maxValue = ((int)data[6] << 8) | (int)data[7];
    displayAttr.curValue = ((int)data[8] << 8) | (int)data[9];
    return displayAttr;
}
