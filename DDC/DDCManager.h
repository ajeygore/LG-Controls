#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DDCDisplay : NSObject
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *serial;
@property (nonatomic, assign) BOOL isExternal;
@end

@interface DDCManager : NSObject

+ (instancetype)sharedManager;

- (NSArray<DDCDisplay *> *)getDisplays;

- (NSInteger)getLuminance:(NSInteger)displayIndex;
- (BOOL)setLuminance:(NSInteger)value forDisplay:(NSInteger)displayIndex;

- (NSInteger)getContrast:(NSInteger)displayIndex;
- (BOOL)setContrast:(NSInteger)value forDisplay:(NSInteger)displayIndex;

- (NSInteger)getVolume:(NSInteger)displayIndex;
- (BOOL)setVolume:(NSInteger)value forDisplay:(NSInteger)displayIndex;

- (BOOL)getMute:(NSInteger)displayIndex;
- (BOOL)setMute:(BOOL)muted forDisplay:(NSInteger)displayIndex;

@end

NS_ASSUME_NONNULL_END
