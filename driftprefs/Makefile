TARGET := iphone:clang:latest:14.0
THEOS_PACKAGE_SCHEME ?= rootless
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = driftprefs

driftprefs_FILES = DriftRootListController.m
driftprefs_FRAMEWORKS = UIKit
driftprefs_PRIVATE_FRAMEWORKS = Preferences
driftprefs_INSTALL_PATH = /Library/PreferenceBundles
driftprefs_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/bundle.mk
