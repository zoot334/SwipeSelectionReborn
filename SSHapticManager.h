#import <Foundation/Foundation.h>

@interface SSHapticManager : NSObject
+ (void)begin;
+ (void)tick;
+ (void)end;
@end
