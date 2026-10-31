#import "Header.h"
#import "SSPanGestureRecognizer.h"
#import "SSSelectionKeyArbitrator.h"
#import "SSHapticManager.h"
#import "SSRuntime.h"
#import <objc/runtime.h>
#import <math.h>

#pragma mark - Shared state

static NSString *SSCurrentKeyValue = nil;
static UITextRange *SSStartTextRange = nil;
static UITextPosition *SSPivotPosition = nil;
static UITextPosition *SSStartPosition = nil;
static BOOL SSGestureActive = NO;

static BOOL SSHasStarted = NO;
static BOOL SSCancelled = NO;
static CGPoint SSStartPoint = CGPointZero;
static CGPoint SSPreviousPoint = CGPointZero;
static CGPoint SSCurrentPoint = CGPointZero;
static BOOL SSIsSelection = NO;
static CGFloat SSSpeed = 1.0;
static BOOL SSIsWebView = NO;
static CGFloat SSWebViewXOffset = 0;
static NSInteger SSLastOffset = NSIntegerMax;
static BOOL SSWebViewJSFailed = NO;

NSString *SSCurrentKey(void) {
    return SSCurrentKeyValue;
}

void SSSetCurrentKey(NSString *key) {
    [SSCurrentKeyValue release];
    SSCurrentKeyValue = [key copy];
}

BOOL SSIsSelectionKeyName(NSString *key) {
    return [key isEqualToString:@"delete"] ||
           [key isEqualToString:@"shift"] ||
           [key isEqualToString:@"ء"];
}

static BOOL SSIsActivationKeyName(NSString *key) {
    if (!key) {
        return NO;
    }
    NSString *lowercaseKey = [key lowercaseString];
    return [lowercaseKey isEqualToString:@" "] ||
           [lowercaseKey isEqualToString:@"space"] ||
           [lowercaseKey isEqualToString:@"spacebar"] ||
           SSIsSelectionKeyName(lowercaseKey);
}

static BOOL SSIsSelectionKey(void) {
    return SSIsSelectionKeyName(SSCurrentKey());
}

static void SSSetStartTextRange(UITextRange *range) {
    [SSStartTextRange release];
    SSStartTextRange = [range retain];
}

static void SSReleasePositions(void) {
    [SSPivotPosition release];
    SSPivotPosition = nil;
    [SSStartPosition release];
    SSStartPosition = nil;
}

static void SSResetGestureState(void) {
    SSHasStarted = NO;
    SSCancelled = NO;
    SSStartPoint = CGPointZero;
    SSPreviousPoint = CGPointZero;
    SSCurrentPoint = CGPointZero;
    SSIsSelection = NO;
    SSIsWebView = NO;
    SSWebViewXOffset = 0;
    SSLastOffset = NSIntegerMax;
    SSWebViewJSFailed = NO;
    SSReleasePositions();
}

static BOOL SSInputIsBlacklisted(id<UITextInput> input) {
    Class emoticonTextViewClass = NSClassFromString(@"VBEmoticonsContentTextView");
    return emoticonTextViewClass && [input isKindOfClass:emoticonTextViewClass];
}

static BOOL SSIsWebViewInput(id input) {
    Class contentViewClass = NSClassFromString(@"WKContentView");
    return contentViewClass && [input isKindOfClass:contentViewClass];
}

static id SSWebViewForInput(id input) {
    if (!input) {
        return nil;
    }

    @try {
        id webView = [input valueForKey:@"webView"];
        if (webView &&
            [webView respondsToSelector:@selector(evaluateJavaScript:completionHandler:)]) {
            return webView;
        }
    } @catch (__unused NSException *exception) {
    }

    if (![input isKindOfClass:[UIView class]]) {
        return nil;
    }

    Class webViewClass = NSClassFromString(@"WKWebView");
    UIView *view = (UIView *)input;
    while (view) {
        if (webViewClass && [view isKindOfClass:webViewClass]) {
            return view;
        }
        view = view.superview;
    }
    return nil;
}

static void SSMoveWebViewSelection(id webView, NSInteger direction, NSInteger steps, BOOL extendSelection) {
    if (!webView || steps <= 0) {
        return;
    }
    if (![webView respondsToSelector:@selector(evaluateJavaScript:completionHandler:)]) {
        return;
    }

    NSString *alter = extendSelection ? @"extend" : @"move";
    NSString *directionName = (direction > 0) ? @"forward" : @"backward";
    NSString *script = [NSString stringWithFormat:
        @"(function(){var s=window.getSelection();if(!s||!s.rangeCount||typeof s.modify!=='function'){return false;}for(var i=0;i<%ld;i++){s.modify('%@','%@','character');}return true;})();",
        (long)steps, alter, directionName];
    [webView evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        if (error || !result || ![result boolValue]) {
            SSWebViewJSFailed = YES;
        }
    }];
}

static BOOL SSKeyboardIsHandwriting(UIKeyboardLayout *layout) {
    if ([layout respondsToSelector:@selector(handwritingPlane)]) {
        return [(UIKeyboardLayoutStar *)layout handwritingPlane];
    }
    return NO;
}

static BOOL SSKeyboardIsTrackpad(UIKeyboardLayout *layout) {
    if ([layout respondsToSelector:@selector(isTrackpadMode)]) {
        return [(UIKeyboardLayoutStar *)layout isTrackpadMode];
    }
    return NO;
}

static BOOL SSAppleContinuousPathEnabled(BOOL *found) {
    static CFStringRef const domains[] = {
        CFSTR("com.apple.keyboard.ContinuousPath"),
        CFSTR("com.apple.keyboard.preferences"),
        CFSTR("com.apple.Preferences")
    };

    if (found) {
        *found = NO;
    }

    for (size_t index = 0; index < sizeof(domains) / sizeof(domains[0]); index++) {
        CFPropertyListRef value = CFPreferencesCopyValue(
            CFSTR("KeyboardContinuousPathEnabled"),
            domains[index],
            CFSTR("mobile"),
            kCFPreferencesAnyHost);
        if (!value) {
            continue;
        }

        BOOL enabled = YES;
        if (CFGetTypeID(value) == CFBooleanGetTypeID()) {
            enabled = CFBooleanGetValue((CFBooleanRef)value);
        } else if ([(id)value respondsToSelector:@selector(boolValue)]) {
            enabled = [(id)value boolValue];
        }
        CFRelease(value);
        if (found) {
            *found = YES;
        }
        return enabled;
    }

    return NO;
}

static void SSApplyContinuousPathSetting(UIKeyboardImpl *keyboard) {
    if (![keyboard respondsToSelector:@selector(setLayoutAllowsContinuousPath:)]) {
        return;
    }

    BOOL allow = NO;
    if (![SSSettings enabled] || [SSSettings spaceShiftDeleteOnly]) {
        BOOL found = NO;
        allow = SSAppleContinuousPathEnabled(&found);
        if (!found) {
            return;
        }
    }
    [keyboard setLayoutAllowsContinuousPath:allow];
}

static void SSPreferencesChanged(CFNotificationCenterRef center,
                                 void *observer,
                                 CFStringRef name,
                                 const void *object,
                                 CFDictionaryRef userInfo) {
    UIKeyboardImpl *keyboard = [UIKeyboardImpl activeInstance];
    if (!keyboard) {
        return;
    }
    if ([NSThread isMainThread]) {
        SSApplyContinuousPathSetting(keyboard);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIKeyboardImpl *activeKeyboard = [UIKeyboardImpl activeInstance];
            if (activeKeyboard) {
                SSApplyContinuousPathSetting(activeKeyboard);
            }
        });
    }
}

static UIKeyboardLayoutStar *SSStarLayoutForKeyboard(UIKeyboardImpl *keyboard) {
    UIKeyboardLayout *layout = [keyboard _layout];
    if ([layout respondsToSelector:@selector(willBeginIndirectSelectionGesture:)]) {
        return (UIKeyboardLayoutStar *)layout;
    }
    return nil;
}

static BOOL SSKeyboardFadeActive = NO;

static void SSBeginKeyboardFade(UIKeyboardLayoutStar *layout) {
    if (!layout || ![SSSettings dimKeyboard]) {
        return;
    }
    if (![layout respondsToSelector:@selector(willBeginIndirectSelectionGesture:)]) {
        return;
    }

    SSKeyboardFadeActive = YES;
    [layout willBeginIndirectSelectionGesture:YES];
}

static void SSEndKeyboardFade(UIKeyboardImpl *keyboard) {
    if (!SSKeyboardFadeActive) {
        return;
    }

    UIKeyboardLayoutStar *layout = SSStarLayoutForKeyboard(keyboard);
    if (layout && [layout respondsToSelector:@selector(didEndIndirectSelectionGesture:)]) {
        [layout didEndIndirectSelectionGesture:YES];
    }
    SSKeyboardFadeActive = NO;
}

static BOOL SSShouldRunForKey(void) {
    NSString *key = SSCurrentKey();

    if ([SSSettings spaceShiftDeleteOnly]) {
        return SSIsActivationKeyName(key);
    }

    if (!key) {
        return YES;
    }

    if ([key isEqualToString:@"more"] || [key isEqualToString:@"international"]) {
        return NO;
    }

    return YES;
}

static void SSShowEditMenu(UIKeyboardImpl *keyboard, UITextRange *range) {
    if (!keyboard || !range || range.empty) {
        return;
    }

    if ([keyboard respondsToSelector:@selector(updateForChangedSelection)]) {
        [keyboard updateForChangedSelection];
    }

    UITextInteractionAssistant *assistant = nil;
    if ([keyboard respondsToSelector:@selector(textInteractionAssistant)]) {
        assistant = [keyboard textInteractionAssistant];
    }
    if ([assistant respondsToSelector:@selector(_editMenuAssistant)]) {
        id editMenu = [assistant _editMenuAssistant];
        if ([editMenu respondsToSelector:@selector(showSelectionCommands)]) {
            [editMenu showSelectionCommands];
        }
    }
}

static void SSSetSelectedTextRange(id<UITextInput> input, UITextRange *range) {
    if (!input || !range) {
        return;
    }

    [input setSelectedTextRange:range];

    UIFieldEditor *fieldEditor = [objc_getClass("UIFieldEditor") sharedFieldEditor];
    if (fieldEditor && [fieldEditor respondsToSelector:@selector(revealSelection)]) {
        [fieldEditor revealSelection];
    }

    if ([input respondsToSelector:@selector(_scrollRectToVisible:animated:)] &&
        [input respondsToSelector:@selector(caretRect)]) {
        CGRect caretRect = [(UIView *)input caretRect];
        [(UIView *)input _scrollRectToVisible:caretRect animated:YES];
    } else if ([input respondsToSelector:@selector(scrollSelectionToVisible:)]) {
        [(UIView *)input scrollSelectionToVisible:YES];
    }
}

static void SSInstallGestures(UIKeyboardImpl *keyboard) {
    BOOL hasPan = NO;
    BOOL hasArbitrator = NO;
    for (UIGestureRecognizer *recognizer in keyboard.gestureRecognizers) {
        if ([recognizer isKindOfClass:[SSPanGestureRecognizer class]]) {
            hasPan = YES;
        } else if ([recognizer isKindOfClass:[SSSelectionKeyArbitrator class]]) {
            hasArbitrator = YES;
        }
    }

    if (!hasPan) {
        SSPanGestureRecognizer *pan = [[SSPanGestureRecognizer alloc] initWithTarget:keyboard
                                                                            action:@selector(SS_KeyboardGestureDidPan:)];
        pan.cancelsTouchesInView = NO;
        [keyboard addGestureRecognizer:pan];
        [pan release];
    }

    if (!hasArbitrator) {
        SSSelectionKeyArbitrator *arbitrator = [[SSSelectionKeyArbitrator alloc] init];
        [keyboard addGestureRecognizer:arbitrator];
        [arbitrator release];
    }


}

#pragma mark - Hook interface

@interface UIKeyboardImpl (SwipeSelectionReborn)
- (void)SS_KeyboardGestureDidPan:(UIPanGestureRecognizer *)gesture;
@end

#pragma mark - UIKeyboardImpl

%hook UIKeyboardImpl

- (id)initWithFrame:(CGRect)frame {
    id result = %orig;
    if (result) {
        SSInstallGestures(self);
        SSApplyContinuousPathSetting(self);
    }
    return result;
}

- (id)initWithFrame:(CGRect)frame forCustomInputView:(UIView *)view {
    id result = %orig;
    if (result) {
        SSInstallGestures(self);
        SSApplyContinuousPathSetting(self);
    }
    return result;
}

%new
- (void)SS_KeyboardGestureDidPan:(UIPanGestureRecognizer *)gesture {
    UIKeyboardImpl *keyboard = self;
    id<UITextInput> input = [keyboard inputDelegate];
    UIKeyboardLayout *layout = [keyboard _layout];
    UIKeyboardLayoutStar *starLayout = (UIKeyboardLayoutStar *)layout;

    if (gesture.state == UIGestureRecognizerStateEnded ||
        gesture.state == UIGestureRecognizerStateCancelled) {
        SSEndKeyboardFade(keyboard);

        if (SSHasStarted && !SSIsWebView) {
            UITextRange *range = [input selectedTextRange];
            if (range && !range.empty) {
                SSShowEditMenu(keyboard, range);
            }
        }

        [SSHapticManager end];
        SSSetStartTextRange(nil);
        SSSetCurrentKey(nil);
        SSResetGestureState();
        SSGestureActive = NO;
        gesture.cancelsTouchesInView = NO;
        return;
    }

    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (SSKeyboardFadeActive) {
            SSEndKeyboardFade(keyboard);
        }
        SSResetGestureState();
        SSGestureActive = YES;
        SSSetStartTextRange([input selectedTextRange]);
        [SSHapticManager end];

        if (![SSSettings enabled] ||
            !input ||
            SSKeyboardIsHandwriting(layout) ||
            SSKeyboardIsTrackpad(layout) ||
            [keyboard isLongPress] ||
            !SSShouldRunForKey() ||
            SSInputIsBlacklisted(input) ||
            ([input respondsToSelector:@selector(markedTextRange)] && [input markedTextRange] != nil)) {
            SSSetStartTextRange(nil);
            SSGestureActive = NO;
            return;
        }

        SSStartPoint = [gesture locationInView:keyboard];
        return;
    }

    if (gesture.state != UIGestureRecognizerStateChanged || !SSGestureActive || !input) {
        return;
    }

    CGPoint position = [gesture locationInView:keyboard];
    CGFloat differenceX = position.x - SSStartPoint.x;
    CGFloat differenceY = position.y - SSStartPoint.y;
    CGFloat deadzone = [SSSettings deadzone];

    if (!SSHasStarted) {
        if (fabs(differenceX) < deadzone) {
            return;
        }
        if (fabs(differenceY) > fabs(differenceX)) {
            SSCancelled = YES;
            return;
        }

        SSHasStarted = YES;
        gesture.cancelsTouchesInView = YES;

        SSStartPoint = position;
        SSPreviousPoint = position;
        SSCurrentPoint = CGPointZero;
        SSIsSelection = SSIsSelectionKey();
        SSSpeed = [SSSettings swipeSpeed];
        SSIsWebView = SSIsWebViewInput(input);
        id activeWebView = SSIsWebView ? SSWebViewForInput(input) : nil;
        if (SSIsWebView && !activeWebView) {
            SSHasStarted = NO;
            SSCancelled = YES;
            SSGestureActive = NO;
            return;
        }
        SSWebViewXOffset = 0;
        SSLastOffset = 0;

        UITextRange *startRange = SSStartTextRange;
        if (!startRange) {
            SSHasStarted = NO;
            SSCancelled = YES;
            return;
        }

        UITextPosition *pivot = nil;
        UITextPosition *start = nil;
        if (SSIsSelection) {
            pivot = (differenceX > 0) ? startRange.start : startRange.end;
        }
        start = (differenceX > 0) ? startRange.end : startRange.start;

        if (!start) {
            SSHasStarted = NO;
            SSCancelled = YES;
            return;
        }

        SSPivotPosition = [pivot retain];
        SSStartPosition = [start retain];

        [SSHapticManager begin];
    }

    if (SSCancelled) {
        return;
    }

    if (SSIsWebView && SSWebViewJSFailed) {
        gesture.cancelsTouchesInView = NO;
        SSEndKeyboardFade(keyboard);
        [SSHapticManager end];
        SSSetStartTextRange(nil);
        SSSetCurrentKey(nil);
        SSResetGestureState();
        SSGestureActive = NO;
        return;
    }

    if (SSHasStarted) {
        SSBeginKeyboardFade(starLayout);
    }

    CGFloat diffX = position.x - SSPreviousPoint.x;
    SSCurrentPoint.x += diffX;

    CGFloat pointsPerCharacter = [SSSettings pointsPerCharacterForSpeed:SSSpeed];
    CGFloat offset = SSCurrentPoint.x / pointsPerCharacter;
    NSInteger offsetX = (NSInteger)offset;

    UITextLayoutDirection direction = UITextLayoutDirectionRight;
    if (offsetX < 0) {
        direction = UITextLayoutDirectionLeft;
        offsetX = -offsetX;
    }

    if (SSIsWebView) {
        id webView = SSWebViewForInput(input);
        SSWebViewXOffset += diffX;
        if (fabs(SSWebViewXOffset) >= pointsPerCharacter) {
            NSInteger steps = (NSInteger)(fabs(SSWebViewXOffset) / pointsPerCharacter);
            NSInteger directionStep = (SSWebViewXOffset > 0) ? 1 : -1;
            SSMoveWebViewSelection(webView, directionStep, steps, SSIsSelection);
            SSWebViewXOffset -= (directionStep * steps * pointsPerCharacter);
            [SSHapticManager tick];
        }
    } else if (offsetX != SSLastOffset) {
        UITextPosition *positionOne = [input positionFromPosition:SSStartPosition
                                                      inDirection:direction
                                                           offset:offsetX];
        if (!positionOne) {
            positionOne = (offset > 0) ? input.endOfDocument : input.beginningOfDocument;
        }

        UITextPosition *positionTwo = SSPivotPosition ? SSPivotPosition : positionOne;
        UITextRange *textRange = [input textRangeFromPosition:positionOne toPosition:positionTwo];

        if (textRange) {
            SSSetSelectedTextRange(input, textRange);
        }

        [SSHapticManager tick];
        SSLastOffset = offsetX;
    }

    SSPreviousPoint = position;
}

%end

#pragma mark - UIKeyboardLayoutStar

%hook UIKeyboardLayoutStar

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!SSCurrentKey()) {
        UITouch *touch = [touches anyObject];
        UIKBTree *key = [self keyHitTest:[touch locationInView:self]];
        NSString *represented = [[key representedString] lowercaseString];
        if (represented.length == 0 && [key respondsToSelector:@selector(name)]) {
            represented = [[key name] lowercaseString];
        }
        SSSetCurrentKey(represented);
    }
    %orig;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    if (!SSGestureActive) {
        SSSetCurrentKey(nil);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    SSSetCurrentKey(nil);
}

%end


%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    SSPreferencesChanged,
                                    CFSTR("com.zoot334.swipeselectionreborn/preferencesChanged"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorCoalesce);
}
