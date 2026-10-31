#import "SSWelcomeViewController.h"

@implementation SSWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemBackgroundColor];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    UIImage *welcomeImage = [UIImage imageNamed:@"WelcomeIcon"
                                      inBundle:bundle
                   compatibleWithTraitCollection:nil];
    UIImageView *logoView = [[UIImageView alloc] initWithImage:welcomeImage];
    logoView.translatesAutoresizingMaskIntoConstraints = NO;
    logoView.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *eyebrowLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    eyebrowLabel.translatesAutoresizingMaskIntoConstraints = NO;
    eyebrowLabel.text = @"WELCOME TO";
    eyebrowLabel.textAlignment = NSTextAlignmentCenter;
    eyebrowLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
    eyebrowLabel.textColor = [UIColor systemBlueColor];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"SwipeSelection Reborn";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;

    UIFont *titleFont = [UIFont systemFontOfSize:28.0 weight:UIFontWeightBold];
    UIFontDescriptor *roundedDescriptor =
        [titleFont.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
    if (roundedDescriptor) {
        titleFont = [UIFont fontWithDescriptor:roundedDescriptor size:28.0];
    }
    titleLabel.font = titleFont;
    titleLabel.textColor = [UIColor labelColor];

    UILabel *bodyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    bodyLabel.numberOfLines = 0;

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineSpacing = 3.0;
    bodyLabel.attributedText =
        [[[NSAttributedString alloc] initWithString:@"Swipe across the keyboard to move the cursor. Swipe from Shift or Delete to select text."
                                          attributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:16.0],
                                              NSForegroundColorAttributeName: [UIColor secondaryLabelColor],
                                              NSParagraphStyleAttributeName: paragraphStyle
                                          }] autorelease];
    [paragraphStyle release];

    UIStackView *contentStack = [[UIStackView alloc] initWithArrangedSubviews:
                                      @[logoView, eyebrowLabel, titleLabel, bodyLabel]];
    contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    contentStack.axis = UILayoutConstraintAxisVertical;
    contentStack.alignment = UIStackViewAlignmentCenter;
    contentStack.spacing = 16.0;
    [contentStack setCustomSpacing:4.0 afterView:eyebrowLabel];
    [contentStack setCustomSpacing:12.0 afterView:titleLabel];
    [self.view addSubview:contentStack];

    UIButton *continueButton = [UIButton buttonWithType:UIButtonTypeSystem];
    continueButton.translatesAutoresizingMaskIntoConstraints = NO;
    [continueButton setTitle:@"Continue" forState:UIControlStateNormal];
    continueButton.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
    [continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    continueButton.backgroundColor = [UIColor systemBlueColor];
    continueButton.layer.cornerRadius = 14.0;
    continueButton.layer.cornerCurve = kCACornerCurveContinuous;
    continueButton.clipsToBounds = YES;
    [continueButton addTarget:self
                       action:@selector(ss_dismissWelcome)
             forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:continueButton];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [contentStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [contentStack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-24.0],
        [contentStack.leadingAnchor constraintGreaterThanOrEqualToAnchor:safeArea.leadingAnchor constant:24.0],
        [contentStack.trailingAnchor constraintLessThanOrEqualToAnchor:safeArea.trailingAnchor constant:-24.0],

        [logoView.widthAnchor constraintEqualToConstant:96.0],
        [logoView.heightAnchor constraintEqualToConstant:96.0],

        [titleLabel.widthAnchor constraintLessThanOrEqualToAnchor:safeArea.widthAnchor constant:-48.0],
        [bodyLabel.widthAnchor constraintLessThanOrEqualToAnchor:safeArea.widthAnchor constant:-48.0],

        [continueButton.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:24.0],
        [continueButton.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-24.0],
        [continueButton.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-16.0],
        [continueButton.heightAnchor constraintEqualToConstant:52.0]
    ]];

    [logoView release];
    [eyebrowLabel release];
    [titleLabel release];
    [bodyLabel release];
    [contentStack release];
}

- (void)ss_dismissWelcome {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
