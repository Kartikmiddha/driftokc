#import <UIKit/UIKit.h>

@interface PSListController : UIViewController
{
    NSArray *_specifiers;
}
- (NSArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
@end

@interface DriftRootListController : PSListController
- (void)respring;
@end
