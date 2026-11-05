#import <UIKit/UIKit.h>
#import "Tweak.h"
#import "DriftManager.h"
#import "DriftScrollController.h"
#import <objc/runtime.h>

#pragma mark - Model Hook (Allows dock model to hold up to 50 icons)

%hook SBIconListModel

- (NSUInteger)maxNumberOfIcons {
    @try {
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
    } @catch (NSException *e) {
        NSLog(@"[DriftDock] Error in maxNumberOfIcons: %@", e);
    }
    return %orig;
}

- (BOOL)isFull {
    @try {
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
    } @catch (NSException *e) {
        NSLog(@"[DriftDock] Error in isFull: %@", e);
    }
    return %orig;
}

%end

#pragma mark - Icon List View Hook

%hook SBIconListView

- (BOOL)allowsAddingIconCount:(NSUInteger)count {
    @try {
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
    } @catch (NSException *e) {
        NSLog(@"[DriftDock] Error in allowsAddingIconCount: %@", e);
    }
    return %orig;
}

%end

#pragma mark - SBDockIconListView Hook

%hook SBDockIconListView

- (void)layoutIconsNow {
    %orig;
    
    @try {
        if (![DriftManager sharedManager].enabled) return;
        
        UIView *parent = self.superview;
        if (parent) {
            DriftScrollController *ctrl = [DriftScrollController controllerForDockView:parent listView:self];
            [ctrl updateLayout];
        }
    } @catch (NSException *e) {
        NSLog(@"[DriftDock] Error in layoutIconsNow: %@", e);
    }
}

%end

#pragma mark - SBDockView Hook (Safe layout & gesture management)

%hook SBDockView

- (void)layoutSubviews {
    %orig;
    
    @try {
        if (![DriftManager sharedManager].enabled) return;
        
        static BOOL isLayoutRunning = NO;
        if (isLayoutRunning) return;
        isLayoutRunning = YES;
        
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
        
        isLayoutRunning = NO;
    } @catch (NSException *e) {
        NSLog(@"[DriftDock] Error in SBDockView layoutSubviews: %@", e);
    }
}

%end

#pragma mark - Constructor

%ctor {
    @autoreleasepool {
        [DriftManager sharedManager];
    }
}
