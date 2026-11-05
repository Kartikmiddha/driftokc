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

@interface SBIconListGridLayoutConfiguration : NSObject
@property (nonatomic, assign) NSUInteger numberOfPortraitRows;
@property (nonatomic, assign) NSUInteger numberOfPortraitColumns;
@property (nonatomic, assign) NSUInteger numberOfLandscapeRows;
@property (nonatomic, assign) NSUInteger numberOfLandscapeColumns;
@end

@interface SBIconListView : UIView
@property (nonatomic, strong, readonly) SBIconListModel *model;
- (BOOL)isFull;
- (BOOL)allowsAddingIconCount:(NSUInteger)count;
- (void)layoutIconsNow;
@end

@interface SBDockIconListView : SBIconListView
@end

@interface SBDockView : UIView
@property (nonatomic, strong) UIView *backgroundView;
- (UIView *)dockIconListView;
- (UIView *)backgroundView;
- (void)layoutSubviews;
@end
