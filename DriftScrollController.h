#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DriftScrollController : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIView *dockView;
@property (nonatomic, weak) UIView *dockListView;
@property (nonatomic, assign) CGFloat currentOffset;
@property (nonatomic, assign) CGFloat maxOffset;
@property (nonatomic, assign) CGFloat iconWidth;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) NSInteger lastHapticSlot;
@property (nonatomic, strong) UISelectionFeedbackGenerator *feedbackGenerator;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

+ (instancetype)controllerForDockView:(UIView *)dockView listView:(UIView *)listView;
- (void)updateLayout;
- (void)applyEdgeEffects;
- (void)setScrollOffset:(CGFloat)offset;

@end

NS_ASSUME_NONNULL_END
