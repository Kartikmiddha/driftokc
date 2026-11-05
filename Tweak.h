#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#define DRIFT_PREFS_CHANGED_NOTIFICATION @"com.kartik.driftdock.prefschanged"
#define DRIFT_PREFS_PATH @"/var/mobile/Library/Preferences/com.kartik.driftdock.plist"

// Forward declarations of SpringBoard private classes
@class SBIcon;
@class SBIconView;
@class SBIconListView;
@class SBDockIconListView;
@class SBDockView;
@class SBIconListModel;

typedef struct SBIconCoordinate {
    NSInteger row;
    NSInteger column;
} SBIconCoordinate;

@interface SBIcon : NSObject
@property (nonatomic, copy, readonly) NSString *displayName;
@property (nonatomic, copy, readonly) NSString *applicationBundleID;
@end

@interface SBIconView : UIView
@property (nonatomic, strong) SBIcon *icon;
@property (nonatomic, assign) BOOL isEditing;
- (void)setHighlighted:(BOOL)highlighted;
- (BOOL)isFolderIcon;
@end

@interface SBIconListModel : NSObject
@property (nonatomic, readonly) NSUInteger numberOfIcons;
@property (nonatomic, readonly) NSUInteger maxNumberOfIcons;
@property (nonatomic, copy, readonly) NSArray *icons;
- (BOOL)isFull;
- (NSUInteger)maxNumberOfIcons;
- (BOOL)isDock;
@end

@interface SBIconListView : UIView
@property (nonatomic, strong, readonly) SBIconListModel *model;
@property (nonatomic, readonly) NSArray *displayedIconViews;
@property (nonatomic, readonly) NSUInteger iconRowsForCurrentOrientation;
@property (nonatomic, readonly) NSUInteger iconColumnsForCurrentOrientation;
- (NSUInteger)maximumIconCount;
+ (NSUInteger)maxIcons;
- (NSUInteger)maxIcons;
- (BOOL)isFull;
- (BOOL)allowsAddingIconCount:(NSUInteger)count;
- (void)layoutIconsNow;
- (CGPoint)originForIconAtCoordinate:(SBIconCoordinate)coordinate numberOfIcons:(NSUInteger)count;
- (CGPoint)centerForIcon:(SBIcon *)icon;
- (SBIconView *)displayedIconViewForIcon:(SBIcon *)icon;
@end

@interface SBDockIconListView : SBIconListView
+ (NSUInteger)maxIcons;
- (NSUInteger)maxIcons;
- (NSUInteger)maximumIconCount;
- (NSUInteger)iconColumnsForCurrentOrientation;
- (NSUInteger)iconRowsForCurrentOrientation;
- (BOOL)allowsAddingIconCount:(NSUInteger)count;
- (BOOL)isFull;
@end

@interface SBDockView : UIView
@property (nonatomic, strong) SBDockIconListView *dockIconListView;
@property (nonatomic, strong) UIView *backgroundView;
- (SBDockIconListView *)dockIconListView;
- (UIView *)backgroundView;
- (void)layoutSubviews;
@end

@interface SBFloatingDockPlatterView : UIView
@end
