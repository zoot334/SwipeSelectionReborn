#import "SSSpeedSliderCell.h"
#import <Preferences/PSSpecifier.h>
#import <math.h>

static const CGFloat SSSpeedMinimum = 0.0;
static const CGFloat SSSpeedMaximum = 2.0;
static const CGFloat SSSpeedSnapValue = 1.0;
static const CGFloat SSSpeedSnapRadius = 0.05;

@implementation SSSpeedSliderCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier
                   specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _speedCenterTick = [[UIView alloc] initWithFrame:CGRectZero];
        _speedCenterTick.backgroundColor = [[UIColor secondaryLabelColor] colorWithAlphaComponent:0.55];
        _speedCenterTick.layer.cornerRadius = 0.5;
        _speedCenterTick.userInteractionEnabled = NO;
        [self.contentView addSubview:_speedCenterTick];

        _speedSlider = [[UISlider alloc] initWithFrame:CGRectZero];
        _speedSlider.minimumValue = SSSpeedMinimum;
        _speedSlider.maximumValue = SSSpeedMaximum;
        _speedSlider.continuous = YES;
        _speedSlider.accessibilityLabel = @"Cursor Speed";
        [_speedSlider addTarget:self
                         action:@selector(ss_sliderChanged:)
               forControlEvents:UIControlEventValueChanged];
        [_speedSlider addTarget:self
                         action:@selector(ss_sliderCommitted:)
               forControlEvents:(UIControlEventTouchUpInside |
                                 UIControlEventTouchUpOutside |
                                 UIControlEventTouchCancel)];
        [self.contentView addSubview:_speedSlider];

        _speedValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _speedValueLabel.textAlignment = NSTextAlignmentRight;
        _speedValueLabel.font = [UIFont monospacedDigitSystemFontOfSize:17.0
                                                                weight:UIFontWeightRegular];
        _speedValueLabel.textColor = [UIColor secondaryLabelColor];
        _speedValueLabel.userInteractionEnabled = YES;
        _speedValueLabel.accessibilityTraits = UIAccessibilityTraitButton;
        UITapGestureRecognizer *tap =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(ss_editSpeedValue:)];
        [_speedValueLabel addGestureRecognizer:tap];
        [tap release];
        [self.contentView addSubview:_speedValueLabel];

        self.titleLabel.hidden = YES;
        self.textLabel.hidden = YES;
        [self refreshCellContentsWithSpecifier:specifier];
    }
    return self;
}

- (void)dealloc {
    [_speedCenterTick release];
    [_speedSlider release];
    [_speedValueLabel release];
    [_speedEntrySetAction release];
    [super dealloc];
}

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
    [super refreshCellContentsWithSpecifier:specifier];

    self.titleLabel.hidden = YES;
    self.textLabel.hidden = YES;

    id value = [specifier performGetter];
    CGFloat sliderValue = value ? [value doubleValue] : 1.0;
    sliderValue = MIN(SSSpeedMaximum, MAX(SSSpeedMinimum, sliderValue));
    _speedSlider.value = sliderValue;
    [self ss_updateValueLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect bounds = self.contentView.bounds;
    CGFloat margin = 16.0;
    CGFloat valueWidth = 52.0;
    CGFloat gap = 8.0;
    CGFloat sliderWidth = MAX(0.0, bounds.size.width - (margin * 2.0) - valueWidth - gap);

    _speedSlider.frame = CGRectMake(margin,
                                    floorf((bounds.size.height - 31.0) / 2.0),
                                    sliderWidth,
                                    31.0);
    _speedValueLabel.frame = CGRectMake(bounds.size.width - margin - valueWidth,
                                        0.0,
                                        valueWidth,
                                        bounds.size.height);

    _speedCenterTick.frame = CGRectMake(floorf(CGRectGetMidX(_speedSlider.frame)),
                                        floorf(CGRectGetMidY(_speedSlider.frame) - 7.0),
                                        1.0,
                                        14.0);
}

- (void)ss_sliderChanged:(UISlider *)slider {
    CGFloat value = slider.value;
    if (fabs(value - SSSpeedSnapValue) <= SSSpeedSnapRadius) {
        value = SSSpeedSnapValue;
    } else {
        value = round(value * 100.0) / 100.0;
    }
    slider.value = value;

    [self ss_updateValueLabel];
    if (!slider.isTracking) {
        [self.specifier performSetterWithValue:@(value)];
    }
}

- (void)ss_sliderCommitted:(UISlider *)slider {
    [self.specifier performSetterWithValue:@(slider.value)];
}

- (void)ss_editSpeedValue:(UITapGestureRecognizer *)gesture {
    UIViewController *controller = [self ss_viewController];
    if (!controller || controller.presentedViewController) {
        return;
    }

    NSString *currentText = [NSString stringWithFormat:@"%.2f", _speedSlider.value];
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Cursor Speed"
                                            message:@"Enter a value from 0.00 to 2.00."
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = currentText;
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.textAlignment = NSTextAlignmentCenter;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [textField addTarget:self
                      action:@selector(ss_speedTextChanged:)
            forControlEvents:UIControlEventEditingChanged];
    }];

    __unsafe_unretained SSSpeedSliderCell *weakSelf = self;
    __unsafe_unretained UIAlertController *weakAlert = alert;

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf ss_clearEntryAction];
                                                   }];

    UIAlertAction *set = [UIAlertAction actionWithTitle:@"Set"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    UITextField *textField = weakAlert.textFields.firstObject;
                                                    CGFloat parsedValue = 0.0;
                                                    if ([weakSelf ss_parseSpeed:textField.text
                                                                          value:&parsedValue]) {
                                                        [weakSelf ss_applyManualSpeed:parsedValue];
                                                    }
                                                    [weakSelf ss_clearEntryAction];
                                                }];
    set.enabled = [self ss_parseSpeed:currentText value:NULL];

    [_speedEntrySetAction release];
    _speedEntrySetAction = [set retain];

    [alert addAction:cancel];
    [alert addAction:set];
    [controller presentViewController:alert animated:YES completion:nil];
}

- (void)ss_speedTextChanged:(UITextField *)textField {
    _speedEntrySetAction.enabled = [self ss_parseSpeed:textField.text value:NULL];
}

- (void)ss_applyManualSpeed:(CGFloat)value {
    value = MIN(SSSpeedMaximum, MAX(SSSpeedMinimum, value));
    _speedSlider.value = value;
    [self ss_updateValueLabel];
    [self.specifier performSetterWithValue:@(value)];
}

- (BOOL)ss_parseSpeed:(NSString *)text value:(CGFloat *)outValue {
    if (![text isKindOfClass:[NSString class]]) {
        return NO;
    }

    NSString *normalized = [text stringByTrimmingCharactersInSet:
                                [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    normalized = [normalized stringByReplacingOccurrencesOfString:@"," withString:@"."];
    if (normalized.length == 0) {
        return NO;
    }

    NSScanner *scanner = [NSScanner scannerWithString:normalized];
    double parsed = 0.0;
    if (![scanner scanDouble:&parsed] || !scanner.isAtEnd) {
        return NO;
    }
    if (parsed < SSSpeedMinimum || parsed > SSSpeedMaximum) {
        return NO;
    }

    CGFloat rounded = round(parsed * 100.0) / 100.0;
    if (outValue) {
        *outValue = rounded;
    }
    return YES;
}

- (void)ss_clearEntryAction {
    [_speedEntrySetAction release];
    _speedEntrySetAction = nil;
}

- (void)ss_updateValueLabel {
    NSString *valueText = [NSString stringWithFormat:@"%.2f", _speedSlider.value];
    _speedValueLabel.text = valueText;
    _speedValueLabel.accessibilityValue = valueText;
}

- (UIViewController *)ss_viewController {
    UIResponder *responder = self;
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

@end
