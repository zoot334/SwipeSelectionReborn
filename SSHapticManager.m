#import "SSHapticManager.h"
#import "SSSettings.h"
#import <UIKit/UIKit.h>

static UIImpactFeedbackGenerator *SSHapticGenerator = nil;

@implementation SSHapticManager

+ (UIImpactFeedbackStyle)feedbackStyleForSetting:(SSHapticStyle)style {
    switch (style) {
        case SSHapticStyleMedium: return UIImpactFeedbackStyleMedium;
        case SSHapticStyleHeavy: return UIImpactFeedbackStyleHeavy;
        case SSHapticStyleSoft: return UIImpactFeedbackStyleSoft;
        case SSHapticStyleRigid: return UIImpactFeedbackStyleRigid;
        case SSHapticStyleLight:
        default: return UIImpactFeedbackStyleLight;
    }
}

+ (void)begin {
    [self end];

    if (![SSSettings hapticsEnabled]) {
        return;
    }

    SSHapticStyle style = [SSSettings hapticStyle];
    if (style == SSHapticStyleOff) {
        return;
    }

    SSHapticGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:[self feedbackStyleForSetting:style]];
    [SSHapticGenerator prepare];
}

+ (void)tick {
    if (SSHapticGenerator) {
        [SSHapticGenerator impactOccurred];
    }
}

+ (void)end {
    if (SSHapticGenerator) {
        [SSHapticGenerator release];
        SSHapticGenerator = nil;
    }
}

@end
