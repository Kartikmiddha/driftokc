#import <UIKit/UIKit.h>
#import "Tweak.h"

NS_ASSUME_NONNULL_BEGIN

@interface DriftScrollView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) SBDockIconListView *dockIconListView;
@property (nonatomic, assign) CGFloat iconWidth;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) NSInteger lastHapticIndex;
@property (nonatomic, strong) UISelectionFeedbackGenerator *feedbackGenerator;

- (instancetype)initWithFrame:(CGRect)frame dockIconListView:(SBDockIconListView *)listView;
- (void)updateContentLayout;
- (void)applyEdgeEffects;

@end

NS_ASSUME_NONNULL_END
