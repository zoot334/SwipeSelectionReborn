#import "SSSettings.h"
#import <UIKit/UIKit.h>
#import <dlfcn.h>

static NSString *const SSSettingsDomain = @"com.zoot334.swipeselectionreborn";
static NSString *const SSMobileUser = @"mobile";
static CFStringRef const SSNoContainer = CFSTR("kCFPreferencesNoContainer");

typedef CFPropertyListRef (*SSCopyValueWithContainerFunc)(CFStringRef key, CFStringRef appID,
                                                            CFStringRef user, CFStringRef host,
                                                            CFStringRef container);
typedef void (*SSSetValueWithContainerFunc)(CFStringRef key, CFPropertyListRef value,
                                             CFStringRef appID, CFStringRef user,
                                             CFStringRef host, CFStringRef container);

static SSCopyValueWithContainerFunc SSCopyValueWithContainer = NULL;
static SSSetValueWithContainerFunc SSSetValueWithContainer = NULL;

static void SSLoadPreferencesFunctions(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void *coreFoundation = dlopen("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation", RTLD_LAZY);
        if (coreFoundation) {
            SSCopyValueWithContainer = (SSCopyValueWithContainerFunc)dlsym(coreFoundation, "_CFPreferencesCopyValueWithContainer");
            SSSetValueWithContainer = (SSSetValueWithContainerFunc)dlsym(coreFoundation, "_CFPreferencesSetValueWithContainer");
        }
    });
}

@implementation SSSettings

+ (NSUserDefaults *)defaults {
    static NSUserDefaults *defaults = nil;
    if (!defaults) {
        defaults = [[NSUserDefaults alloc] initWithSuiteName:SSSettingsDomain];
        [defaults registerDefaults:@{
            @"Enabled": @YES,
            @"SwipeSpeed": @1.0,
            @"DimKeyboard": @YES,
            @"SpaceShiftDeleteOnly": @NO,
            @"HapticsEnabled": @YES,
            @"HapticStyle": @(SSHapticStyleLight),
            @"WelcomeShownVersion": @0
        }];
    }
    return defaults;
}

+ (id)valueForKey:(NSString *)key {
    SSLoadPreferencesFunctions();

    CFStringRef domain = (CFStringRef)SSSettingsDomain;
    CFStringRef user = (CFStringRef)SSMobileUser;
    CFPropertyListRef value = NULL;

    if (SSCopyValueWithContainer) {
        value = SSCopyValueWithContainer((CFStringRef)key, domain, user, kCFPreferencesAnyHost, SSNoContainer);
    } else {
        value = CFPreferencesCopyValue((CFStringRef)key, domain, user, kCFPreferencesAnyHost);
    }

    if (value) {
        return [(id)value autorelease];
    }
    return [[self defaults] objectForKey:key];
}

+ (void)setValue:(id)value forKey:(NSString *)key {
    SSLoadPreferencesFunctions();

    CFStringRef domain = (CFStringRef)SSSettingsDomain;
    CFStringRef user = (CFStringRef)SSMobileUser;

    if (SSSetValueWithContainer) {
        SSSetValueWithContainer((CFStringRef)key, (CFPropertyListRef)value, domain, user, kCFPreferencesAnyHost, SSNoContainer);
    } else {
        CFPreferencesSetValue((CFStringRef)key, (CFPropertyListRef)value, domain, user, kCFPreferencesAnyHost);
    }
    CFPreferencesSynchronize(domain, user, kCFPreferencesAnyHost);

    NSUserDefaults *defaults = [self defaults];
    if (value) {
        [defaults setObject:value forKey:key];
    } else {
        [defaults removeObjectForKey:key];
    }
    [defaults synchronize];
}

+ (BOOL)enabled {
    id value = [self valueForKey:@"Enabled"];
    return value ? [value boolValue] : YES;
}

+ (CGFloat)swipeSpeed {
    id value = [self valueForKey:@"SwipeSpeed"];
    CGFloat speed = value ? [value doubleValue] : 1.0;
    return MIN(2.0, MAX(0.0, speed));
}

+ (BOOL)dimKeyboard {
    id value = [self valueForKey:@"DimKeyboard"];
    return value ? [value boolValue] : YES;
}

+ (BOOL)spaceShiftDeleteOnly {
    id value = [self valueForKey:@"SpaceShiftDeleteOnly"];
    return value ? [value boolValue] : NO;
}

+ (BOOL)hapticsEnabled {
    id value = [self valueForKey:@"HapticsEnabled"];
    return value ? [value boolValue] : YES;
}

+ (SSHapticStyle)hapticStyle {
    id value = [self valueForKey:@"HapticStyle"];
    return value ? (SSHapticStyle)[value integerValue] : SSHapticStyleLight;
}

+ (BOOL)welcomeShown {
    id value = [self valueForKey:@"WelcomeShownVersion"];
    return value ? ([value integerValue] >= 3) : NO;
}

+ (void)setWelcomeShown:(BOOL)shown {
    [self setValue:@(shown ? 3 : 0) forKey:@"WelcomeShownVersion"];
    [self setValue:nil forKey:@"WelcomeShown"];
}

+ (void)resetToDefaults {
    NSArray *keys = @[@"Enabled", @"SwipeSpeed", @"DimKeyboard",
                      @"SpaceShiftDeleteOnly", @"HapticsEnabled", @"HapticStyle"];
    for (NSString *key in keys) {
        [self setValue:nil forKey:key];
    }
}

+ (CGFloat)deadzone {
    BOOL iPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    return iPad ? 30.0 : 18.0;
}

+ (CGFloat)pointsPerCharacterForSpeed:(CGFloat)speed {
    speed = MIN(2.0, MAX(0.0, speed));
    if (speed <= 1.0) {
        return 15.0 - (6.0 * speed);
    }
    return 9.0 - (4.0 * (speed - 1.0));
}

@end
