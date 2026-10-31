#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "SSSettings.h"
#import "SSWelcomeViewController.h"

@interface PSSpecifier (SSValues)
- (void)setValues:(NSArray *)values titles:(NSArray *)titles;
@end

static NSString *const SSDefaultsDomain = @"com.zoot334.swipeselectionreborn";
static CFStringRef const SSPreferencesChangedNotification = CFSTR("com.zoot334.swipeselectionreborn/preferencesChanged");

static void SSPostPreferencesChanged(void) {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         SSPreferencesChangedNotification,
                                         NULL,
                                         NULL,
                                         YES);
}

@interface SwipeSelectionRebornRootListController : PSListController {
    NSArray *_cachedSpecifiers;
    BOOL _welcomeScheduled;
}
@end

@implementation SwipeSelectionRebornRootListController

- (void)publishSpecifiersToSuperclass {
    Ivar ivar = class_getInstanceVariable([PSListController class], "_specifiers");
    if (ivar) {
        object_setIvar(self, ivar, _cachedSpecifiers);
    }
}

- (void)clearPublishedSpecifiers {
    Ivar ivar = class_getInstanceVariable([PSListController class], "_specifiers");
    if (ivar) {
        object_setIvar(self, ivar, nil);
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (_welcomeScheduled || [SSSettings welcomeShown]) {
        return;
    }

    _welcomeScheduled = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.view.window || self.presentedViewController ||
            [SSSettings welcomeShown]) {
            _welcomeScheduled = NO;
            return;
        }

        SSWelcomeViewController *welcome = [[SSWelcomeViewController alloc] init];
        welcome.modalPresentationStyle = UIModalPresentationPageSheet;

        UISheetPresentationController *sheet = welcome.sheetPresentationController;
        if (sheet) {
            Class detentClass = NSClassFromString(@"UISheetPresentationControllerDetent");
            SEL largeDetentSelector = NSSelectorFromString(@"largeDetent");
            if (detentClass && [detentClass respondsToSelector:largeDetentSelector]) {
                id largeDetent = [detentClass performSelector:largeDetentSelector];
                if (largeDetent) {
                    sheet.detents = @[largeDetent];
                }
            }
            sheet.prefersGrabberVisible = YES;
            sheet.preferredCornerRadius = 24.0;
            sheet.prefersEdgeAttachedInCompactHeight = YES;
        }

        [self presentViewController:welcome animated:YES completion:^{
            [SSSettings setWelcomeShown:YES];
        }];
        [welcome release];
    });
}

- (NSArray *)specifiers {
    if (!_cachedSpecifiers) {
        NSMutableArray *specifiers = [NSMutableArray array];

        PSSpecifier *general = [PSSpecifier groupSpecifierWithName:@"SwipeSelection Reborn"];
        [general setProperty:@"Swipe the keyboard to move the caret. Swipe from Shift or Delete to select text."
                      forKey:PSFooterTextGroupKey];
        [specifiers addObject:general];

        PSSpecifier *enabled = [PSSpecifier preferenceSpecifierNamed:@"Enable SwipeSelection Reborn"
                                                              target:self
                                                                 set:@selector(setPreferenceValue:specifier:)
                                                                 get:@selector(readPreferenceValue:)
                                                              detail:nil
                                                                cell:PSSwitchCell
                                                                edit:nil];
        [enabled setProperty:@"Enabled" forKey:PSKeyNameKey];
        [enabled setProperty:SSDefaultsDomain forKey:PSDefaultsKey];
        [enabled setProperty:@YES forKey:PSEnabledKey];
        [enabled setIdentifier:@"enabled"];
        [specifiers addObject:enabled];

        PSSpecifier *feedback = [PSSpecifier groupSpecifierWithName:@"Haptic Feedback"];
        [feedback setProperty:@"A short haptic tick when the caret crosses a character."
                       forKey:PSFooterTextGroupKey];
        [specifiers addObject:feedback];

        PSSpecifier *hapticsEnabled = [PSSpecifier preferenceSpecifierNamed:@"Haptic Feedback"
                                                                     target:self
                                                                        set:@selector(setPreferenceValue:specifier:)
                                                                        get:@selector(readPreferenceValue:)
                                                                     detail:nil
                                                                       cell:PSSwitchCell
                                                                       edit:nil];
        [hapticsEnabled setProperty:@"HapticsEnabled" forKey:PSKeyNameKey];
        [hapticsEnabled setProperty:SSDefaultsDomain forKey:PSDefaultsKey];
        [hapticsEnabled setProperty:@YES forKey:PSEnabledKey];
        [hapticsEnabled setIdentifier:@"hapticsEnabled"];
        [specifiers addObject:hapticsEnabled];

        PSSpecifier *strength = [PSSpecifier preferenceSpecifierNamed:@"Strength"
                                                               target:self
                                                                  set:@selector(setPreferenceValue:specifier:)
                                                                  get:@selector(readPreferenceValue:)
                                                               detail:nil
                                                                 cell:PSSegmentCell
                                                                 edit:nil];
        [strength setProperty:@"HapticStyle" forKey:PSKeyNameKey];
        [strength setProperty:SSDefaultsDomain forKey:PSDefaultsKey];
        [strength setValues:@[@1, @2, @3, @4, @5]
                     titles:@[@"Light", @"Medium", @"Heavy", @"Soft", @"Rigid"]];
        [strength setProperty:@([SSSettings hapticsEnabled]) forKey:PSEnabledKey];
        [strength setIdentifier:@"hapticStrength"];
        [specifiers addObject:strength];

        PSSpecifier *speedGroup = [PSSpecifier groupSpecifierWithName:@"Cursor Speed"];
        [specifiers addObject:speedGroup];

        PSSpecifier *speed = [PSSpecifier preferenceSpecifierNamed:@"Cursor Speed"
                                                            target:self
                                                               set:@selector(setPreferenceValue:specifier:)
                                                               get:@selector(readPreferenceValue:)
                                                            detail:nil
                                                              cell:PSSliderCell
                                                              edit:nil];
        [speed setProperty:@"SwipeSpeed" forKey:PSKeyNameKey];
        [speed setProperty:SSDefaultsDomain forKey:PSDefaultsKey];
        [speed setProperty:@0 forKey:PSControlMinimumKey];
        [speed setProperty:@2 forKey:PSControlMaximumKey];
        [speed setProperty:@1.0 forKey:PSDefaultValueKey];
        [speed setProperty:NSClassFromString(@"SSSpeedSliderCell") forKey:PSCellClassKey];
        [speed setProperty:@YES forKey:PSEnabledKey];
        [speed setIdentifier:@"speed"];
        [specifiers addObject:speed];

        PSSpecifier *appearance = [PSSpecifier groupSpecifierWithName:@"Appearance"];
        [appearance setProperty:@"The keyboard enters its trackpad presentation while the caret is moving."
                         forKey:PSFooterTextGroupKey];
        [specifiers addObject:appearance];

        PSSpecifier *dim = [PSSpecifier preferenceSpecifierNamed:@"Dim keyboard while swiping"
                                                          target:self
                                                             set:@selector(setPreferenceValue:specifier:)
                                                             get:@selector(readPreferenceValue:)
                                                          detail:nil
                                                            cell:PSSwitchCell
                                                            edit:nil];
        [dim setProperty:@"DimKeyboard" forKey:PSKeyNameKey];
        [dim setProperty:SSDefaultsDomain forKey:PSDefaultsKey];
        [dim setProperty:@YES forKey:PSEnabledKey];
        [dim setIdentifier:@"dim"];
        [specifiers addObject:dim];

        PSSpecifier *activation = [PSSpecifier groupSpecifierWithName:@"Activation"];
        [activation setProperty:@"When enabled, only swipes starting on Space, Shift, or Delete control the cursor. Swipes from other keys follow your Apple Slide to Type setting. SwipeSelection does not change that setting. If Slide to Type is off in Apple Settings, swiping from other keys will not type."
                        forKey:PSFooterTextGroupKey];
        [specifiers addObject:activation];

        PSSpecifier *spaceShiftDeleteOnly = [PSSpecifier preferenceSpecifierNamed:@"Space, Shift & Delete Only"
                                                                           target:self
                                                                              set:@selector(setPreferenceValue:specifier:)
                                                                              get:@selector(readPreferenceValue:)
                                                                           detail:nil
                                                                             cell:PSSwitchCell
                                                                             edit:nil];
        [spaceShiftDeleteOnly setProperty:@"SpaceShiftDeleteOnly" forKey:PSKeyNameKey];
        [spaceShiftDeleteOnly setProperty:SSDefaultsDomain forKey:PSDefaultsKey];
        [spaceShiftDeleteOnly setProperty:@NO forKey:PSDefaultValueKey];
        [spaceShiftDeleteOnly setProperty:@YES forKey:PSEnabledKey];
        [spaceShiftDeleteOnly setIdentifier:@"spaceShiftDeleteOnly"];
        [specifiers addObject:spaceShiftDeleteOnly];

        PSSpecifier *about = [PSSpecifier groupSpecifierWithName:@"About"];
        [about setProperty:@"SwipeSelection Reborn 1.0.0\nOriginal SwipeSelection by Kyle Howells.\nMaintained by zoot334."
                     forKey:PSFooterTextGroupKey];
        [specifiers addObject:about];

        PSSpecifier *reset = [PSSpecifier preferenceSpecifierNamed:@"Reset to Defaults"
                                                            target:self
                                                               set:nil
                                                               get:nil
                                                            detail:nil
                                                              cell:PSButtonCell
                                                              edit:nil];
        [reset setButtonAction:@selector(resetDefaults)];
        [reset setProperty:@YES forKey:PSEnabledKey];
        [specifiers addObject:reset];

        _cachedSpecifiers = [specifiers copy];
    }

    [self publishSpecifiersToSuperclass];
    return _cachedSpecifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:PSKeyNameKey];
    if ([key isEqualToString:@"Enabled"]) {
        return @([SSSettings enabled]);
    }
    if ([key isEqualToString:@"SwipeSpeed"]) {
        return @([SSSettings swipeSpeed]);
    }
    if ([key isEqualToString:@"DimKeyboard"]) {
        return @([SSSettings dimKeyboard]);
    }
    if ([key isEqualToString:@"SpaceShiftDeleteOnly"]) {
        return @([SSSettings spaceShiftDeleteOnly]);
    }
    if ([key isEqualToString:@"HapticsEnabled"]) {
        return @([SSSettings hapticsEnabled]);
    }
    if ([key isEqualToString:@"HapticStyle"]) {
        return @([SSSettings hapticStyle]);
    }
    if (!key) {
        return nil;
    }
    return [SSSettings valueForKey:key];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:PSKeyNameKey];
    if (!key) {
        return;
    }

    [SSSettings setValue:value forKey:key];
    SSPostPreferencesChanged();

    if ([key isEqualToString:@"HapticsEnabled"]) {
        PSSpecifier *strength = [self specifierForID:@"hapticStrength"];
        if (strength) {
            [strength setProperty:@([value boolValue]) forKey:PSEnabledKey];
            [self reloadSpecifier:strength animated:YES];
        } else {
            [self reloadSpecifiers];
        }
    }
}

- (void)resetDefaults {
    [SSSettings resetToDefaults];
    SSPostPreferencesChanged();

    [self clearPublishedSpecifiers];
    [_cachedSpecifiers release];
    _cachedSpecifiers = nil;
    [self reloadSpecifiers];
}

- (void)dealloc {
    [self clearPublishedSpecifiers];
    [_cachedSpecifiers release];
    [super dealloc];
}

@end
