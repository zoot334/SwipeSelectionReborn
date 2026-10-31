#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef NS_ENUM(NSInteger, SSHapticStyle) {
    SSHapticStyleOff = 0,
    SSHapticStyleLight = 1,
    SSHapticStyleMedium = 2,
    SSHapticStyleHeavy = 3,
    SSHapticStyleSoft = 4,
    SSHapticStyleRigid = 5
};

@interface SSSettings : NSObject

+ (id)valueForKey:(NSString *)key;
+ (void)setValue:(id)value forKey:(NSString *)key;

+ (BOOL)enabled;
+ (CGFloat)swipeSpeed;
+ (BOOL)dimKeyboard;
+ (BOOL)spaceShiftDeleteOnly;
+ (BOOL)hapticsEnabled;
+ (SSHapticStyle)hapticStyle;
+ (BOOL)welcomeShown;
+ (void)setWelcomeShown:(BOOL)shown;
+ (void)resetToDefaults;

+ (CGFloat)deadzone;
+ (CGFloat)pointsPerCharacterForSpeed:(CGFloat)speed;

@end
