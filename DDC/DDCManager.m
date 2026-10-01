#import "DDCManager.h"
#import "ioregistry.h"
#import "i2c.h"

@implementation DDCDisplay
@end

@implementation DDCManager {
    DisplayInfos _displays[MAX_DISPLAYS];
    CGDisplayCount _displayCount;
    NSLock *_ddcLock;
}

+ (instancetype)sharedManager {
    static DDCManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[DDCManager alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _ddcLock = [[NSLock alloc] init];
        [self refreshDisplaysInternal];
    }
    return self;
}

- (void)refreshDisplaysInternal {
    memset(_displays, 0, sizeof(_displays));
    _displayCount = getOnlineDisplayInfos(_displays);
}

- (NSArray<DDCDisplay *> *)getDisplays {
    [_ddcLock lock];
    [self refreshDisplaysInternal];
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 0; i < _displayCount; i++) {
        DDCDisplay *d = [[DDCDisplay alloc] init];
        d.index = i + 1;
        d.name = _displays[i].productName ?: @"Unknown Display";
        d.uuid = _displays[i].uuid ?: @"";
        d.serial = _displays[i].alphNumSerial ?: @"";
        DDCTransport transport = getDisplayDDCTransport(&_displays[i]);
        d.isExternal = (transport.service != NULL);
        [arr addObject:d];
    }
    [_ddcLock unlock];
    return arr;
}

- (NSInteger)readVCP:(UInt8)vcp forDisplay:(NSInteger)displayIndex {
    [_ddcLock lock];
    [self refreshDisplaysInternal];
    if (displayIndex < 1 || displayIndex > _displayCount) {
        [_ddcLock unlock];
        return -1;
    }
    
    DDCTransport transport = getDisplayDDCTransport(&_displays[displayIndex - 1]);
    if (!transport.service) {
        [_ddcLock unlock];
        return -1;
    }
    
    DDCPacket packet = createDDCPacket(vcp);
    prepareDDCRead(packet.data);
    IOReturn ret = performDDCWriteAtChipAddress(transport.service, transport.chipAddress, &packet);
    if (ret != kIOReturnSuccess) {
        [_ddcLock unlock];
        return -1;
    }
    
    DDCPacket readPacket = {};
    readPacket.inputAddr = packet.inputAddr;
    ret = performDDCReadAtChipAddress(transport.service, transport.chipAddress, &readPacket);
    [_ddcLock unlock];
    
    if (ret != kIOReturnSuccess) return -1;
    
    DDCValue val = convertI2CtoDDC((const char *)readPacket.data);
    return val.curValue;
}

- (BOOL)writeVCP:(UInt8)vcp value:(NSInteger)value forDisplay:(NSInteger)displayIndex {
    [_ddcLock lock];
    [self refreshDisplaysInternal];
    if (displayIndex < 1 || displayIndex > _displayCount) {
        [_ddcLock unlock];
        return NO;
    }
    
    DDCTransport transport = getDisplayDDCTransport(&_displays[displayIndex - 1]);
    if (!transport.service) {
        [_ddcLock unlock];
        return NO;
    }
    
    DDCPacket packet = createDDCPacket(vcp);
    prepareDDCWrite(&packet, (UInt16)value);
    IOReturn ret = performDDCWriteAtChipAddress(transport.service, transport.chipAddress, &packet);
    [_ddcLock unlock];
    
    return ret == kIOReturnSuccess;
}

- (NSInteger)getLuminance:(NSInteger)displayIndex {
    return [self readVCP:LUMINANCE forDisplay:displayIndex];
}

- (BOOL)setLuminance:(NSInteger)value forDisplay:(NSInteger)displayIndex {
    return [self writeVCP:LUMINANCE value:value forDisplay:displayIndex];
}

- (NSInteger)getContrast:(NSInteger)displayIndex {
    return [self readVCP:CONTRAST forDisplay:displayIndex];
}

- (BOOL)setContrast:(NSInteger)value forDisplay:(NSInteger)displayIndex {
    return [self writeVCP:CONTRAST value:value forDisplay:displayIndex];
}

- (NSInteger)getVolume:(NSInteger)displayIndex {
    return [self readVCP:VOLUME forDisplay:displayIndex];
}

- (BOOL)setVolume:(NSInteger)value forDisplay:(NSInteger)displayIndex {
    return [self writeVCP:VOLUME value:value forDisplay:displayIndex];
}

- (BOOL)getMute:(NSInteger)displayIndex {
    NSInteger val = [self readVCP:MUTE forDisplay:displayIndex];
    return (val == 1);
}

- (BOOL)setMute:(BOOL)muted forDisplay:(NSInteger)displayIndex {
    // 1 = Mute ON, 2 = Mute OFF
    return [self writeVCP:MUTE value:(muted ? 1 : 2) forDisplay:displayIndex];
}

@end
