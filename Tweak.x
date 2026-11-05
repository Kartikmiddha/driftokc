#import <UIKit/UIKit.h>
#import "Tweak.h"
#import "DriftManager.h"
#import "DriftScrollView.h"
#import <objc/runtime.h>

static char kDriftScrollViewKey;

%hook SBDockIconListView

+ (NSUInteger)maxIcons {
    if ([DriftManager sharedManager].enabled) {
        return [DriftManager sharedManager].maxIcons;
    }
    return %orig;
}

- (NSUInteger)maxIcons {
    if ([DriftManager sharedManager].enabled) {
        return [DriftManager sharedManager].maxIcons;
    }
    return %orig;
}

- (NSUInteger)maximumIconCount {
    if ([DriftManager sharedManager].enabled) {
        return [DriftManager sharedManager].maxIcons;
    }
    return %orig;
}

- (NSUInteger)iconColumnsForCurrentOrientation {
    if ([DriftManager sharedManager].enabled) {
        return [DriftManager sharedManager].maxIcons;
    }
    return %orig;
}

- (NSUInteger)iconRowsForCurrentOrientation {
    // Dock is strictly 1 single horizontal scrolling row
    return 1;
}

- (BOOL)allowsAddingIconCount:(NSUInteger)count {
    if ([DriftManager sharedManager].enabled) {
        NSUInteger current = [self displayedIconViews].count;
        return (current + count <= [DriftManager sharedManager].maxIcons);
    }
    return %orig;
}

- (BOOL)isFull {
    if ([DriftManager sharedManager].enabled) {
        return ([self displayedIconViews].count >= [DriftManager sharedManager].maxIcons);
    }
    return %orig;
}

- (void)layoutIconsNow {
    %orig;
    
    if (![DriftManager sharedManager].enabled) return;
    
    NSArray *iconViews = [self displayedIconViews];
    if (iconViews.count == 0) return;
    
    CGFloat padding = 15.0;
    CGFloat spacing = [DriftManager sharedManager].itemSpacing;
    CGFloat currentX = padding;
    CGFloat dockHeight = self.bounds.size.height;
    
    // Position every dock icon in a clean horizontal strip
    for (UIView *iconView in iconViews) {
        CGRect frame = iconView.frame;
        frame.origin.x = currentX;
        frame.origin.y = (dockHeight - frame.size.height) / 2.0;
        iconView.frame = frame;
        
        currentX += frame.size.width + spacing;
    }
    
    // Notify parent scroll view to adjust content size and edge effects
    DriftScrollView *scrollView = (DriftScrollView *)objc_getAssociatedObject(self, &kDriftScrollViewKey);
    if (scrollView) {
        [scrollView updateContentLayout];
    }
}

%end

#pragma mark - SBDockView Hook

%hook SBDockView

- (void)layoutSubviews {
    %orig;
    
    DriftManager *manager = [DriftManager sharedManager];
    if (!manager.enabled) return;
    
    SBDockIconListView *dockList = nil;
    if ([self respondsToSelector:@selector(dockIconListView)]) {
        dockList = [self dockIconListView];
    } else {
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:%c(SBDockIconListView)]) {
                dockList = (SBDockIconListView *)subview;
                break;
            }
        }
    }
    
    if (!dockList) return;
    
    DriftScrollView *scrollView = (DriftScrollView *)objc_getAssociatedObject(dockList, &kDriftScrollViewKey);
    
    if (!scrollView) {
        // Embed the dock icon list view inside our DriftScrollView
        CGRect scrollFrame = dockList.frame;
        scrollView = [[DriftScrollView alloc] initWithFrame:scrollFrame dockIconListView:dockList];
        
        // Retain association
        objc_setAssociatedObject(dockList, &kDriftScrollViewKey, scrollView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [dockList removeFromSuperview];
        [scrollView addSubview:dockList];
        [self addSubview:scrollView];
        
        // Clip to dock bounds so icons do not bleed outside the dock platter
        self.clipsToBounds = YES;
    }
    
    // Ensure the scroll view tracks dock bounds accurately
    CGRect targetFrame = dockList.bounds;
    targetFrame.origin = CGPointZero;
    targetFrame.size.width = self.bounds.size.width;
    targetFrame.size.height = self.bounds.size.height;
    scrollView.frame = targetFrame;
    
    [scrollView updateContentLayout];
}

%end

#pragma mark - SBIconListModel Hook (Bypass Model Limits)

%hook SBIconListModel

- (NSUInteger)maxNumberOfIcons {
    // Only expand icon limit when model is attached to the dock
    if ([DriftManager sharedManager].enabled) {
        BOOL isDockModel = NO;
        if ([self respondsToSelector:@selector(isDock)]) {
            isDockModel = [((id)self) isDock];
        }
        if (isDockModel) {
            return [DriftManager sharedManager].maxIcons;
        }
    }
    return %orig;
}

%end

#pragma mark - Constructor

%ctor {
    @autoreleasepool {
        // Initialize preferences manager
        [DriftManager sharedManager];
    }
}
