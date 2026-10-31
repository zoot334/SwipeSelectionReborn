THEOS_PACKAGE_SCHEME ?= rootless

TARGET = iphone:clang:latest:16.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SwipeSelectionReborn
SwipeSelectionReborn_FILES = Tweak.xm SSPanGestureRecognizer.m SSSelectionKeyArbitrator.m SSHapticManager.m SSSettings.m
SwipeSelectionReborn_FRAMEWORKS = UIKit Foundation CoreGraphics
SwipeSelectionReborn_CFLAGS = -fno-objc-arc -Wno-deprecated-declarations
SwipeSelectionReborn_LDFLAGS += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = SwipeSelectionRebornPrefs
SwipeSelectionRebornPrefs_FILES = SwipeSelectionRebornRootListController.m SSSettings.m SSSpeedSliderCell.m SSWelcomeViewController.m
SwipeSelectionRebornPrefs_FRAMEWORKS = UIKit Foundation
SwipeSelectionRebornPrefs_PRIVATE_FRAMEWORKS = Preferences
SwipeSelectionRebornPrefs_INSTALL_PATH = /Library/PreferenceBundles
SwipeSelectionRebornPrefs_CFLAGS = -fno-objc-arc -Wno-deprecated-declarations
SwipeSelectionRebornPrefs_LDFLAGS = -F$(THEOS)/sdks/iPhoneOS14.5.sdk/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
