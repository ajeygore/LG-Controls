#ifndef _IOREGISTRY_H
#define _IOREGISTRY_H

#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <CoreGraphics/CoreGraphics.h>

#ifndef MAX_DISPLAYS
#define MAX_DISPLAYS 8
#endif

#define UUID_SIZE 37
#define DDC_CHIP_ADDRESS_DEFAULT  0x37
#define DDC_CHIP_ADDRESS_MCDP29XX 0xB7

// IOAVServiceRef is a private CoreDisplay / IOKit type
typedef CFTypeRef IOAVServiceRef;

typedef struct {
    IOAVServiceRef service;
    UInt32 chipAddress;
} DDCTransport;

typedef struct {
    CGDirectDisplayID id;
    io_service_t adapter;
    NSString *ioLocation;
    NSString *uuid;
    NSString *edid;
    NSString *productName;
    NSString *manufacturer;
    NSString *alphNumSerial;
    UInt32 serial;
    UInt32 model;
    UInt32 vendor;
} DisplayInfos;

CGDisplayCount getOnlineDisplayInfos(DisplayInfos *displayInfos);
DisplayInfos *selectDisplay(DisplayInfos *displays, int connectedDisplays, char *displayIdentifier);

IOAVServiceRef getDefaultDisplayAVService(void);
IOAVServiceRef getDisplayAVService(DisplayInfos *displayInfos);
DDCTransport getDisplayDDCTransport(DisplayInfos *displayInfos);

// External private functions from CoreDisplay
extern IOAVServiceRef IOAVServiceCreate(CFAllocatorRef allocator);
extern IOAVServiceRef IOAVServiceCreateWithService(CFAllocatorRef allocator, io_service_t service);
extern CFDictionaryRef CoreDisplay_DisplayCreateInfoDictionary(CGDirectDisplayID);

#endif
