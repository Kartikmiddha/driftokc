#import <UIKit/UIKit.h>

#if __has_include(<Preferences/PSListController.h>)
#import <Preferences/PSListController.h>
#else
@interface PSListController : UIViewController
{
    NSArray *_specifiers;
}
- (NSArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
@end
#endif

@interface DriftRootListController : PSListController
- (void)respring;
@end
