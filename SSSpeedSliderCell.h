#import <UIKit/UIKit.h>
#import <Preferences/PSTableCell.h>

@interface SSSpeedSliderCell : PSTableCell {
    UIView *_speedCenterTick;
    UISlider *_speedSlider;
    UILabel *_speedValueLabel;
    UIAlertAction *_speedEntrySetAction;
}

@end
