#import "DriftScrollView.h"
#import "DriftManager.h"

@implementation DriftScrollView

- (instancetype)initWithFrame:(CGRect)frame dockIconListView:(SBDockIconListView *)listView {
    self = [super initWithFrame:frame];
    if (self) {
        _dockIconListView = listView;
        _iconWidth = 60.0; // standard iOS icon width
        _itemSpacing = [DriftManager sharedManager].itemSpacing;
        _lastHapticIndex = -1;
        
        self.delegate = self;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.alwaysBounceHorizontal = YES;
        self.alwaysBounceVertical = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast; // snappy scroll like Drift
        self.clipsToBounds = YES;
        self.delaysContentTouches = NO;
        self.canCancelContentTouches = YES;
        
        _feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        [_feedbackGenerator prepare];
    }
    return self;
}

- (void)updateContentLayout {
    if (!self.dockIconListView) return;
    
    NSArray *iconViews = [self.dockIconListView displayedIconViews];
    NSUInteger count = iconViews.count;
    if (count == 0) return;
    
    DriftManager *manager = [DriftManager sharedManager];
    self.itemSpacing = manager.itemSpacing;
    
    // Determine icon dimensions dynamically if available
    UIView *firstIcon = iconViews.firstObject;
    if (firstIcon && firstIcon.frame.size.width > 0) {
        self.iconWidth = firstIcon.frame.size.width;
    }
    
    CGFloat totalWidth = count * self.iconWidth + (count - 1) * self.itemSpacing + 30.0; // 15pt padding on sides
    CGFloat height = self.bounds.size.height;
    
    // Set content size of the scroll view
    self.contentSize = CGSizeMake(MAX(totalWidth, self.bounds.size.width), height);
    
    // Resize dockIconListView frame to fit all icons horizontally
    CGRect listFrame = self.dockIconListView.frame;
    listFrame.size.width = self.contentSize.width;
    listFrame.size.height = height;
    self.dockIconListView.frame = listFrame;
    
    [self applyEdgeEffects];
}

#pragma mark - Edge Effects (Scale & Fade)

- (void)applyEdgeEffects {
    DriftManager *manager = [DriftManager sharedManager];
    if (!manager.edgeEffectsEnabled) {
        // Reset transforms if disabled
        for (UIView *view in [self.dockIconListView displayedIconViews]) {
            view.transform = CGAffineTransformIdentity;
            view.alpha = 1.0;
        }
        return;
    }
    
    CGFloat visibleLeft = self.contentOffset.x;
    CGFloat visibleRight = visibleLeft + self.bounds.size.width;
    CGFloat fadeDist = manager.edgeFadeDistance;
    CGFloat minScale = manager.edgeScaleMin;
    CGFloat minAlpha = manager.edgeAlphaMin;
    
    for (UIView *iconView in [self.dockIconListView displayedIconViews]) {
        CGFloat iconCenterX = iconView.center.x;
        
        // Distance to left edge of visible viewport
        CGFloat distLeft = iconCenterX - visibleLeft;
        // Distance to right edge of visible viewport
        CGFloat distRight = visibleRight - iconCenterX;
        
        CGFloat edgeDist = MIN(distLeft, distRight);
        
        if (edgeDist < fadeDist) {
            // Normalized factor between 0.0 (at the edge) and 1.0 (fully inside)
            CGFloat progress = MAX(0.0, edgeDist / fadeDist);
            
            // Calculate smooth cubic ease
            CGFloat smooth = progress * progress * (3.0 - 2.0 * progress);
            
            CGFloat scale = minScale + (1.0 - minScale) * smooth;
            CGFloat alpha = minAlpha + (1.0 - minAlpha) * smooth;
            
            iconView.transform = CGAffineTransformMakeScale(scale, scale);
            iconView.alpha = alpha;
        } else {
            iconView.transform = CGAffineTransformIdentity;
            iconView.alpha = 1.0;
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self applyEdgeEffects];
    
    // Haptic feedback tick when scrolling across icon boundaries
    DriftManager *manager = [DriftManager sharedManager];
    if (manager.hapticsEnabled) {
        CGFloat stride = self.iconWidth + self.itemSpacing;
        if (stride > 0) {
            NSInteger currentIndex = (NSInteger)round(scrollView.contentOffset.x / stride);
            if (currentIndex != self.lastHapticIndex && currentIndex >= 0) {
                self.lastHapticIndex = currentIndex;
                [self.feedbackGenerator selectionChanged];
                [self.feedbackGenerator prepare];
            }
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {
    DriftManager *manager = [DriftManager sharedManager];
    if (!manager.snapEnabled) return;
    
    CGFloat stride = self.iconWidth + self.itemSpacing;
    if (stride <= 0) return;
    
    // Snap physics calculation
    CGFloat projectedX = targetContentOffset->x;
    CGFloat nearestIndex = round(projectedX / stride);
    
    // Dampen flick velocity into discrete slot
    if (velocity.x > 0.4) {
        nearestIndex = ceil(projectedX / stride);
    } else if (velocity.x < -0.4) {
        nearestIndex = floor(projectedX / stride);
    }
    
    CGFloat snappedX = nearestIndex * stride;
    CGFloat maxOffsetX = MAX(0.0, self.contentSize.width - self.bounds.size.width);
    
    // Clamp within bounds
    targetContentOffset->x = MAX(0.0, MIN(snappedX, maxOffsetX));
}

#pragma mark - Gesture Conflict Handling

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // Allow simultaneous gestures with SpringBoard's tap and long-press (3D touch / icon reordering)
    return YES;
}

@end
