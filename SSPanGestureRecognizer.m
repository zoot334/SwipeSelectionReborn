#import "SSPanGestureRecognizer.h"
#import <UIKit/UIKit.h>

@implementation SSPanGestureRecognizer

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer {
    // Let the emoji keyboard's scroll view win, but do not let the keyboard's
    // own pan/cursor recognizers prevent SwipeSelection.
    return [preventingGestureRecognizer.view isKindOfClass:[UIScrollView class]];
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    return NO;
}

@end
