#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DriftManager : NSObject

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) NSUInteger maxIcons;
@property (nonatomic, assign) BOOL snapEnabled;
@property (nonatomic, assign) BOOL hapticsEnabled;
@property (nonatomic, assign) BOOL edgeEffectsEnabled;
@property (nonatomic, assign) CGFloat edgeScaleMin;
@property (nonatomic, assign) CGFloat edgeAlphaMin;
@property (nonatomic, assign) CGFloat edgeFadeDistance;
@property (nonatomic, assign) CGFloat itemSpacing;

+ (instancetype)sharedManager;
- (void)loadPreferences;

@end

NS_ASSUME_NONNULL_END
