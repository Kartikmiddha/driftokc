#import <UIKit/UIKit.h>
#import "Tweak.h"
#import "DriftManager.h"
#import "DriftScrollController.h"
#import <objc/runtime.h>

#pragma mark - Grid Layout Hook (Allows up to 50 icons in dock)

%hook SBIconListGridLayoutConfiguration

- (NSUInteger)numberOfPortraitColumns {
    if ([DriftManager sharedManager].enabled) {
        if ([self respondsToSelector:@selector(numberOfPortraitRows)]) {
            if ([self numberOfPortraitRows] == 1) {
                return [DriftManager sharedManager].maxIcons;
            }
        }
    }
    return %orig;
}

- (NSUInteger)numberOfLandscapeColumns {
    if ([DriftManager sharedManager].enabled) {
        if ([self respondsToSelector:@selector(numberOfLandscapeRows)]) {
            if ([self numberOfLandscapeRows] == 1) {
                return [DriftManager sharedManager].maxIcons;
            }
        }
    }
    return %orig;
}

%end

#pragma mark - Model Hook (Prevent icon limit rejection)

%hook SBIconListModel

- (NSUInteger)maxNumberOfIcons {
    if ([DriftManager sharedManager].enabled) {
        BOOL isDockModel = NO;
        SEL isDockSel = NSSelectorFromString(@"isDock");
        if ([self respondsToSelector:isDockSel]) {
            BOOL (*isDockFunc)(id, SEL) = (BOOL (*)(id, SEL))[self methodForSelector:isDockSel];
            if (isDockFunc) {
                isDockModel = isDockFunc(self, isDockSel);
            }
        }
        if (isDockModel) {
            return [DriftManager sharedManager].maxIcons;
        }
    }
    return %orig;
}

- (BOOL)isFull {
    if ([DriftManager sharedManager].enabled) {
        BOOL isDockModel = NO;
        SEL isDockSel = NSSelectorFromString(@"isDock");
        if ([self respondsToSelector:isDockSel]) {
            BOOL (*isDockFunc)(id, SEL) = (BOOL (*)(id, SEL))[self methodForSelector:isDockSel];
            if (isDockFunc) {
                isDockModel = isDockFunc(self, isDockSel);
            }
        }
        if (isDockModel) {
            return (self.numberOfIcons >= [DriftManager sharedManager].maxIcons);
        }
    }
    return %orig;
}

%end

#pragma mark - Icon List View Hook

%hook SBIconListView

- (BOOL)allowsAddingIconCount:(NSUInteger)count {
    if ([DriftManager sharedManager].enabled) {
        BOOL isDock = NO;
        SEL isDockSel = NSSelectorFromString(@"isDock");
        if ([self respondsToSelector:isDockSel]) {
            BOOL (*isDockFunc)(id, SEL) = (BOOL (*)(id, SEL))[self methodForSelector:isDockSel];
            if (isDockFunc) {
                isDock = isDockFunc(self, isDockSel);
            }
        } else if ([self isKindOfClass:objc_getClass("SBDockIconListView")]) {
            isDock = YES;
        }
        
        if (isDock && self.model) {
            return (self.model.numberOfIcons + count <= [DriftManager sharedManager].maxIcons);
        }
    }
    return %orig;
}

%end

#pragma mark - SBDockIconListView Hook

%hook SBDockIconListView

- (void)layoutIconsNow {
    %orig;
    
    if (![DriftManager sharedManager].enabled) return;
    
    UIView *parent = self.superview;
    if (parent) {
        DriftScrollController *ctrl = [DriftScrollController controllerForDockView:parent listView:self];
        [ctrl updateLayout];
    }
}

%end

#pragma mark - SBDockView Hook (Safe layout & gesture management)

%hook SBDockView

- (void)layoutSubviews {
    %orig;
    
    if (![DriftManager sharedManager].enabled) return;
    
    UIView *dockList = nil;
    if ([self respondsToSelector:@selector(dockIconListView)]) {
        dockList = [self dockIconListView];
    } else {
        Class dockListClass = objc_getClass("SBDockIconListView");
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:dockListClass]) {
                dockList = subview;
                break;
            }
        }
    }
    
    if (dockList) {
        DriftScrollController *ctrl = [DriftScrollController controllerForDockView:self listView:dockList];
        [ctrl updateLayout];
    }
}

%end

#pragma mark - Constructor

%ctor {
    @autoreleasepool {
        [DriftManager sharedManager];
    }
}
