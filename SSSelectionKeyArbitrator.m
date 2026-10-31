#import "SSSelectionKeyArbitrator.h"
#import "Header.h"
#import "SSRuntime.h"

static const NSTimeInterval SSSelectionKeyHoldDelay = 0.30;

@interface SSSelectionKeyArbitrator ()
@property (nonatomic, assign) BOOL trackingSelectionKey;
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, retain) NSTimer *holdTimer;
@end

@implementation SSSelectionKeyArbitrator

- (instancetype)init {
    self = [super initWithTarget:nil action:nil];
    if (self) {
        self.delaysTouchesBegan = YES;
        self.cancelsTouchesInView = YES;
        self.delegate = self;
    }
    return self;
}

- (void)dealloc {
    [_holdTimer invalidate];
    [_holdTimer release];
    [super dealloc];
}

- (UIKeyboardLayout *)keyboardLayout {
    UIKeyboardImpl *keyboard = (UIKeyboardImpl *)self.view;
    if ([keyboard respondsToSelector:@selector(_layout)]) {
        return [keyboard _layout];
    }
    return nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    if (self.state != UIGestureRecognizerStatePossible || self.trackingSelectionKey) {
        return;
    }

    if (![SSSettings enabled]) {
        self.state = UIGestureRecognizerStateFailed;
        return;
    }

    UIKeyboardLayout *layout = [self keyboardLayout];
    UITouch *touch = [touches anyObject];
    if (!layout || !touch) {
        self.state = UIGestureRecognizerStateFailed;
        return;
    }

    CGPoint point = [touch locationInView:layout];
    UIKBTree *key = [layout keyHitTest:point];
    NSString *name = [[key representedString] lowercaseString];

    if (!SSIsSelectionKeyName(name)) {
        self.state = UIGestureRecognizerStateFailed;
        return;
    }

    self.trackingSelectionKey = YES;
    self.startPoint = point;
    SSSetCurrentKey(name);

    [self.holdTimer invalidate];
    self.holdTimer = [NSTimer scheduledTimerWithTimeInterval:SSSelectionKeyHoldDelay
                                                      target:self
                                                    selector:@selector(holdElapsed:)
                                                    userInfo:nil
                                                     repeats:NO];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];

    if (!self.trackingSelectionKey || self.state == UIGestureRecognizerStateFailed ||
        self.state == UIGestureRecognizerStateCancelled) {
        return;
    }

    UIKeyboardLayout *layout = [self keyboardLayout];
    UITouch *touch = [touches anyObject];
    if (!layout || !touch) {
        return;
    }

    CGPoint point = [touch locationInView:layout];
    CGFloat dx = point.x - self.startPoint.x;
    CGFloat dy = point.y - self.startPoint.y;
    CGFloat deadzone = [SSSettings deadzone];

    if (fabs(dx) >= deadzone && fabs(dx) > fabs(dy)) {
        [self.holdTimer invalidate];
        self.holdTimer = nil;
        self.trackingSelectionKey = NO;
        self.state = UIGestureRecognizerStateBegan;
        self.state = UIGestureRecognizerStateChanged;
    } else if (fabs(dy) >= deadzone && fabs(dy) > fabs(dx)) {
        [self failAndReleaseKey];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];

    [self.holdTimer invalidate];
    self.holdTimer = nil;

    if (self.state == UIGestureRecognizerStatePossible) {
        self.state = UIGestureRecognizerStateFailed;
    } else if (self.state == UIGestureRecognizerStateBegan ||
               self.state == UIGestureRecognizerStateChanged) {
        self.state = UIGestureRecognizerStateEnded;
    }

    self.trackingSelectionKey = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];

    [self.holdTimer invalidate];
    self.holdTimer = nil;
    self.trackingSelectionKey = NO;
    self.state = UIGestureRecognizerStateCancelled;
}

- (void)holdElapsed:(NSTimer *)timer {
    if (self.state == UIGestureRecognizerStatePossible && self.trackingSelectionKey) {
        [self failAndReleaseKey];
    }
}

- (void)failAndReleaseKey {
    [self.holdTimer invalidate];
    self.holdTimer = nil;
    self.trackingSelectionKey = NO;
    self.state = UIGestureRecognizerStateFailed;
}

- (void)reset {
    [super reset];
    [self.holdTimer invalidate];
    self.holdTimer = nil;
    self.trackingSelectionKey = NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer {
    return NO;
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer {
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
