#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UITextInput.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

#import "SSSettings.h"

@class UITextInteractionAssistant;

@interface UIKBTree : NSObject
- (NSString *)representedString;
- (NSString *)name;
@end

@interface UIKeyboardLayout : UIView
- (UIKBTree *)keyHitTest:(CGPoint)point;
@end

@interface UIKeyboardLayoutStar : UIKeyboardLayout
- (BOOL)handwritingPlane;
- (BOOL)isTrackpadMode;
- (void)willBeginIndirectSelectionGesture:(BOOL)animated;
- (void)didEndIndirectSelectionGesture:(BOOL)animated;
@end

@interface UIKeyboardImpl : UIView
+ (UIKeyboardImpl *)activeInstance;
- (id<UITextInput>)inputDelegate;
- (UIKeyboardLayout *) _layout;
- (BOOL)isLongPress;
- (void)updateForChangedSelection;
- (UITextInteractionAssistant *)textInteractionAssistant;
- (void)setLayoutAllowsContinuousPath:(BOOL)allow;
@end

@interface UITextInteractionAssistant : NSObject
- (id)_editMenuAssistant;
@end

@interface _UITextInteractionEditMenuAssistant : NSObject
- (void)showSelectionCommands;
@end

@interface UIFieldEditor : NSObject
+ (UIFieldEditor *)sharedFieldEditor;
- (void)revealSelection;
@end

@interface UIView (SSPrivateText)
- (CGRect)caretRect;
- (void)_scrollRectToVisible:(CGRect)rect animated:(BOOL)animated;
- (void)scrollSelectionToVisible:(BOOL)animated;
@end

@interface NSObject (SSWebViewJavaScript)
- (void)evaluateJavaScript:(NSString *)javaScriptString
          completionHandler:(void (^)(id result, NSError *error))completionHandler;
@end

