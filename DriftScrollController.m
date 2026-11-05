#import "DriftScrollController.h"
#import "DriftManager.h"
#import <objc/runtime.h>

static char kDriftControllerKey;

static NSArray<UIView *> *getDockIconViews(UIView *listView) {
    if (!listView) return @[];
    NSMutableArray *icons = [NSMutableArray array];
    Class iconViewClass = objc_getClass("SBIconView");
    for (UIView *subview in listView.subviews) {
        if ([subview isKindOfClass:iconViewClass]) {
            [icons addObject:subview];
        }
    }
    return icons;
}

@implementation DriftScrollController

+ (instancetype)controllerForDockView:(UIView *)dockView listView:(UIView *)listView {
    DriftScrollController *ctrl = objc_getAssociatedObject(dockView, &kDriftControllerKey);
    if (!ctrl) {
        ctrl = [[DriftScrollController alloc] initWithDockView:dockView listView:listView];
        objc_setAssociatedObject(dockView, &kDriftControllerKey, ctrl, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return ctrl;
}

- (instancetype)initWithDockView:(UIView *)dockView listView:(UIView *)listView {
    self = [super init];
    if (self) {
        _dockView = dockView;
        _dockListView = listView;
        _currentOffset = 0.0;
        _maxOffset = 0.0;
        _iconWidth = 60.0;
        _itemSpacing = [DriftManager sharedManager].itemSpacing;
        _lastHapticSlot = -1;
        
        _feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        [_feedbackGenerator prepare];
        
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        _panGesture.delegate = self;
        _panGesture.cancelsTouchesInView = NO;
        _panGesture.delaysTouchesBegan = NO;
        [_dockView addGestureRecognizer:_panGesture];
        
        _dockView.clipsToBounds = YES;
        _dockListView.clipsToBounds = NO;
    }
    return self;
}

- (void)updateLayout {
    @try {
        if (!self.dockListView || !self.dockView) return;
        
        static BOOL isUpdating = NO;
        if (isUpdating) return;
        isUpdating = YES;
        
        NSArray<UIView *> *icons = getDockIconViews(self.dockListView);
        NSUInteger count = icons.count;
        if (count == 0) {
            isUpdating = NO;
            return;
        }
        
        DriftManager *manager = [DriftManager sharedManager];
        self.itemSpacing = manager.itemSpacing;
        
        UIView *first = icons.firstObject;
        if (first && first.frame.size.width > 0) {
            self.iconWidth = first.frame.size.width;
        }
        
        CGFloat dockWidth = self.dockView.bounds.size.width;
        CGFloat dockHeight = self.dockView.bounds.size.height;
        CGFloat padding = 15.0;
        
        // Calculate total content width for all dock icons
        CGFloat totalWidth = padding * 2.0 + (count * self.iconWidth) + ((count - 1) * self.itemSpacing);
        self.maxOffset = MAX(0.0, totalWidth - dockWidth);
        
        // Only override icon layout when icons exceed dock width
        if (totalWidth > dockWidth || count > 4) {
            CGFloat currentX = padding;
            for (UIView *iconView in icons) {
                CGRect f = iconView.frame;
                f.origin.x = currentX;
                f.origin.y = (dockHeight - f.size.height) / 2.0;
                iconView.frame = f;
                currentX += self.iconWidth + self.itemSpacing;
            }
            [self setScrollOffset:MIN(self.currentOffset, self.maxOffset)];
        } else {
            // Under standard 4 icons, reset bounds
            CGRect b = self.dockListView.bounds;
            if (b.origin.x != 0) {
                b.origin.x = 0;
                self.dockListView.bounds = b;
            }
        }
        
        isUpdating = NO;
    } @catch (NSException *e) {
        NSLog(@"[DriftDock] Error in updateLayout: %@", e);
    }
}

- (void)setScrollOffset:(CGFloat)offset {
    self.currentOffset = offset;
    
    // Shift dock list view's bounds without modifying the view hierarchy
    CGRect b = self.dockListView.bounds;
    b.origin.x = offset;
    self.dockListView.bounds = b;
    
    [self applyEdgeEffects];
    [self checkHapticTick];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    if (!self.dockListView || !self.dockView) return;
    if (self.maxOffset <= 0) return;
    
    CGPoint translation = [pan translationInView:self.dockView];
    CGPoint velocity = [pan velocityInView:self.dockView];
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        [self.feedbackGenerator prepare];
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        CGFloat proposed = self.currentOffset - translation.x;
        
        // Rubber-band resistance at edges
        if (proposed < 0) {
            proposed = proposed * 0.35;
        } else if (proposed > self.maxOffset) {
            proposed = self.maxOffset + (proposed - self.maxOffset) * 0.35;
        }
        
        [self setScrollOffset:proposed];
        [pan setTranslation:CGPointZero inView:self.dockView];
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        DriftManager *manager = [DriftManager sharedManager];
        CGFloat stride = self.iconWidth + self.itemSpacing;
        CGFloat target = self.currentOffset;
        
        if (manager.snapEnabled && stride > 0) {
            CGFloat projected = self.currentOffset - (velocity.x * 0.22);
            CGFloat slot = round(projected / stride);
            target = slot * stride;
        } else {
            target = self.currentOffset - (velocity.x * 0.15);
        }
        
        // Clamp bounds
        target = MAX(0.0, MIN(target, self.maxOffset));
        
        [UIView animateWithDuration:0.38
                              delay:0
             usingSpringWithDamping:0.84
              initialSpringVelocity:fabs(velocity.x) / 800.0
                            options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
            [self setScrollOffset:target];
        } completion:nil];
    }
}

- (void)applyEdgeEffects {
    DriftManager *manager = [DriftManager sharedManager];
    NSArray<UIView *> *icons = getDockIconViews(self.dockListView);
    
    if (!manager.edgeEffectsEnabled || self.maxOffset <= 0) {
        for (UIView *icon in icons) {
            icon.transform = CGAffineTransformIdentity;
            icon.alpha = 1.0;
        }
        return;
    }
    
    CGFloat visibleLeft = self.currentOffset;
    CGFloat visibleRight = visibleLeft + self.dockView.bounds.size.width;
    CGFloat fadeDist = manager.edgeFadeDistance;
    CGFloat minScale = manager.edgeScaleMin;
    CGFloat minAlpha = manager.edgeAlphaMin;
    
    for (UIView *icon in icons) {
        CGFloat centerX = icon.center.x;
        CGFloat distLeft = centerX - visibleLeft;
        CGFloat distRight = visibleRight - centerX;
        CGFloat edgeDist = MIN(distLeft, distRight);
        
        if (edgeDist < fadeDist) {
            CGFloat progress = MAX(0.0, edgeDist / fadeDist);
            CGFloat smooth = progress * progress * (3.0 - 2.0 * progress);
            CGFloat scale = minScale + (1.0 - minScale) * smooth;
            CGFloat alpha = minAlpha + (1.0 - minAlpha) * smooth;
            
            icon.transform = CGAffineTransformMakeScale(scale, scale);
            icon.alpha = alpha;
        } else {
            icon.transform = CGAffineTransformIdentity;
            icon.alpha = 1.0;
        }
    }
}

- (void)checkHapticTick {
    DriftManager *manager = [DriftManager sharedManager];
    if (!manager.hapticsEnabled) return;
    
    CGFloat stride = self.iconWidth + self.itemSpacing;
    if (stride <= 0) return;
    
    NSInteger currentSlot = (NSInteger)round(self.currentOffset / stride);
    if (currentSlot != self.lastHapticSlot && currentSlot >= 0) {
        self.lastHapticSlot = currentSlot;
        [self.feedbackGenerator selectionChanged];
        [self.feedbackGenerator prepare];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
