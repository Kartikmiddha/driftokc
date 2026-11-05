TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

# Set rootless as default for modern iOS (iOS 15 - 18)
THEOS_PACKAGE_SCHEME ?= rootless
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DriftDock

DriftDock_FILES = Tweak.x DriftScrollView.m DriftManager.m
DriftDock_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-deprecated-declarations
DriftDock_FRAMEWORKS = UIKit CoreGraphics QuartzCore AudioToolbox

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += driftprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
