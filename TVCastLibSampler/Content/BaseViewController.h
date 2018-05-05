//
//  BaseViewController.h


#import <TVCastLib/TVCastLib.h>
@interface BaseViewController : UIViewController

@property (nonatomic, assign) ConnectableDevice *device;

- (void) appDidBecomeActive:(NSNotification *)notification;
- (void) appDidEnterBackground:(NSNotification *)notification;

- (void) addSubscriptions;
- (void) removeSubscriptions;

@end
