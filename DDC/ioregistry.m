#import <Foundation/Foundation.h>
#import "ioregistry.h"
#import "utils.h"

static CFTypeRef getCFStringRef(io_service_t entry, const char *key) {
    CFStringRef cfKey = CFStringCreateWithCString(kCFAllocatorDefault, key, kCFStringEncodingUTF8);
    CFTypeRef result = IORegistryEntrySearchCFProperty(entry,
                                                      kIOServicePlane,
                                                      cfKey,
                                                      kCFAllocatorDefault,
                                                      kIORegistryIterateRecursively);
    if (cfKey) CFRelease(cfKey);
    return result;
}

static Boolean isMCDP29XXProxy(io_service_t service) {
    CFTypeRef modelName = getCFStringRef(service, "Model");
    if (!modelName) {
        return false;
    }
    Boolean result = CFGetTypeID(modelName) == CFStringGetTypeID() &&
                     CFStringCompare(CFSTR("MCDP29XX"), (CFStringRef)modelName, 0) == kCFCompareEqualTo;
    CFRelease(modelName);
    return result;
}

CGDisplayCount getOnlineDisplayInfos(DisplayInfos *displayInfos) {
    CGDirectDisplayID onlineDisplays[MAX_DISPLAYS];
    CGDisplayCount displayCount = 0;
    CGGetOnlineDisplayList(MAX_DISPLAYS, onlineDisplays, &displayCount);

    CGDisplayCount validDisplayCount = 0;
    for (CGDisplayCount i = 0; i < displayCount; i++) {
        DisplayInfos *currDisplay = displayInfos + validDisplayCount;
        currDisplay->id = onlineDisplays[i];
        currDisplay->serial = CGDisplaySerialNumber(currDisplay->id);
        currDisplay->model = CGDisplayModelNumber(currDisplay->id);
        currDisplay->vendor = CGDisplayVendorNumber(currDisplay->id);

        CFDictionaryRef displayDict = CoreDisplay_DisplayCreateInfoDictionary(currDisplay->id);
        if (displayDict) {
            NSDictionary *nsDict = (__bridge NSDictionary *)displayDict;
            currDisplay->ioLocation = nsDict[@"IODisplayLocation"];
            currDisplay->uuid = nsDict[@"kCGDisplayUUID"] ?: nsDict[@"DisplayAttributesUUID"];
            
            id nameObj = nsDict[@"DisplayProductName"];
            if ([nameObj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *nameDict = (NSDictionary *)nameObj;
                currDisplay->productName = nameDict[@"en_US"] ?: nameDict[@"en"] ?: [nameDict allValues].firstObject;
            } else if ([nameObj isKindOfClass:[NSString class]]) {
                currDisplay->productName = (NSString *)nameObj;
            }
            
            CFRelease(displayDict);
        }

        if (currDisplay->ioLocation == nil) {
            continue;
        }

        currDisplay->adapter = IORegistryEntryCopyFromPath(kIOMainPortDefault, (__bridge CFStringRef)currDisplay->ioLocation);
        if (currDisplay->adapter == MACH_PORT_NULL) {
            continue;
        }

        CFTypeRef edidRef = getCFStringRef(currDisplay->adapter, "EDID UUID");
        if (edidRef) {
            currDisplay->edid = (__bridge NSString *)edidRef;
            CFRelease(edidRef);
        }
        
        if (currDisplay->productName == nil || [currDisplay->productName length] == 0) {
            CFTypeRef displayAttrs = getCFStringRef(currDisplay->adapter, "DisplayAttributes");
            if (displayAttrs) {
                NSDictionary *displayAttrsNS = (__bridge NSDictionary *)displayAttrs;
                NSDictionary *productAttrs = [displayAttrsNS objectForKey:@"ProductAttributes"];
                if (productAttrs) {
                    currDisplay->productName = [productAttrs objectForKey:@"ProductName"];
                    currDisplay->manufacturer = [productAttrs objectForKey:@"ManufacturerID"];
                    currDisplay->alphNumSerial = [productAttrs objectForKey:@"AlphanumericSerialNumber"];
                }
                CFRelease(displayAttrs);
            }
        }
        
        if (currDisplay->productName == nil) {
            currDisplay->productName = @"External Display";
        }

        validDisplayCount++;
    }

    return validDisplayCount;
}

static kern_return_t getIORegistryRootIterator(io_iterator_t *iter) {
    io_registry_entry_t root = IORegistryGetRootEntry(kIOMainPortDefault);
    kern_return_t ret = IORegistryEntryCreateIterator(root, kIOServicePlane, kIORegistryIterateRecursively, iter);
    if (ret != KERN_SUCCESS) {
        IOObjectRelease(*iter);
    }
    return ret;
}

IOAVServiceRef getDefaultDisplayAVService(void) {
    return IOAVServiceCreate(kCFAllocatorDefault);
}

DDCTransport getDisplayDDCTransport(DisplayInfos *displayInfos) {
    DDCTransport transport = {
        .service = NULL,
        .chipAddress = DDC_CHIP_ADDRESS_DEFAULT,
    };
    if (displayInfos == NULL || displayInfos->adapter == MACH_PORT_NULL) {
        return transport;
    }

    uint64_t selectedAdapterID = 0;
    if (IORegistryEntryGetRegistryEntryID(displayInfos->adapter, &selectedAdapterID) != KERN_SUCCESS) {
        return transport;
    }

    io_iterator_t iter;
    if (getIORegistryRootIterator(&iter) != KERN_SUCCESS) {
        return transport;
    }

    Boolean framebufferMatchesDisplay = false;
    io_service_t service;

    while ((service = IOIteratorNext(iter)) != MACH_PORT_NULL) {
        if (IOObjectConformsTo(service, "IOMobileFramebuffer")) {
            uint64_t framebufferID = 0;
            framebufferMatchesDisplay =
                IORegistryEntryGetRegistryEntryID(service, &framebufferID) == KERN_SUCCESS &&
                framebufferID == selectedAdapterID;
            IOObjectRelease(service);
            continue;
        }

        io_name_t name;
        IORegistryEntryGetName(service, name);
        if (!framebufferMatchesDisplay || !STR_EQ(name, "DCPAVServiceProxy")) {
            IOObjectRelease(service);
            continue;
        }

        IOAVServiceRef avService = IOAVServiceCreateWithService(kCFAllocatorDefault, service);
        if (avService == NULL) {
            IOObjectRelease(service);
            continue;
        }

        CFTypeRef locationRef = getCFStringRef(service, "Location");
        Boolean isExternal = locationRef != NULL &&
            CFGetTypeID(locationRef) == CFStringGetTypeID() &&
            CFStringCompare(CFSTR("External"), (CFStringRef)locationRef, 0) == kCFCompareEqualTo;
        if (locationRef != NULL) {
            CFRelease(locationRef);
        }

        if (!isExternal) {
            CFRelease(avService);
            IOObjectRelease(service);
            continue;
        }

        transport.service = avService;
        transport.chipAddress = isMCDP29XXProxy(service)
            ? DDC_CHIP_ADDRESS_MCDP29XX
            : DDC_CHIP_ADDRESS_DEFAULT;
        IOObjectRelease(service);
        IOObjectRelease(iter);
        return transport;
    }

    IOObjectRelease(iter);
    return transport;
}

IOAVServiceRef getDisplayAVService(DisplayInfos *displayInfos) {
    return getDisplayDDCTransport(displayInfos).service;
}
