#import "DriftManager.h"
#import "Tweak.h"

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[DriftManager sharedManager] loadPreferences];
}

@implementation DriftManager

+ (instancetype)sharedManager {
    static DriftManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadPreferences];
        
        // Listen for instant preference changes without requiring respring
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            PreferencesChangedCallback,
            (CFStringRef)DRIFT_PREFS_CHANGED_NOTIFICATION,
            NULL,
            CFNotificationSuspensionBehaviorCoalesce
        );
    }
    return self;
}

- (void)loadPreferences {
    NSString *plistPath = DRIFT_PREFS_PATH;
    
    // Check rootless path if standard path does not exist
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        NSString *rootlessPath = [@"/var/jb" stringByAppendingPathComponent:DRIFT_PREFS_PATH];
        if ([[NSFileManager defaultManager] fileExistsAtPath:rootlessPath]) {
            plistPath = rootlessPath;
        }
    }
    
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    // Default values if preference key is missing
    self.enabled = prefs[@"enabled"] ? [prefs[@"enabled"] boolValue] : YES;
    self.maxIcons = prefs[@"maxIcons"] ? [prefs[@"maxIcons"] unsignedIntegerValue] : 50;
    self.snapEnabled = prefs[@"snapEnabled"] ? [prefs[@"snapEnabled"] boolValue] : YES;
    self.hapticsEnabled = prefs[@"hapticsEnabled"] ? [prefs[@"hapticsEnabled"] boolValue] : YES;
    self.edgeEffectsEnabled = prefs[@"edgeEffectsEnabled"] ? [prefs[@"edgeEffectsEnabled"] boolValue] : YES;
    self.edgeScaleMin = prefs[@"edgeScaleMin"] ? [prefs[@"edgeScaleMin"] doubleValue] : 0.70;
    self.edgeAlphaMin = prefs[@"edgeAlphaMin"] ? [prefs[@"edgeAlphaMin"] doubleValue] : 0.35;
    self.edgeFadeDistance = prefs[@"edgeFadeDistance"] ? [prefs[@"edgeFadeDistance"] doubleValue] : 45.0;
    self.itemSpacing = prefs[@"itemSpacing"] ? [prefs[@"itemSpacing"] doubleValue] : 14.0;
}

@end
