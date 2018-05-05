//
//  WebAppViewController.h


#import "BaseViewController.h"

@interface WebAppViewController : BaseViewController

@property (weak, nonatomic) IBOutlet UIButton *launchButton;
@property (weak, nonatomic) IBOutlet UIButton *joinButton;
@property (weak, nonatomic) IBOutlet UIButton *leaveButton;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *sendJSONButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *pinButton;
@property (weak, nonatomic) IBOutlet UIButton *unPinButton;
@property (weak, nonatomic) IBOutlet UITextView *statusTextView;

- (IBAction)launchWebApp:(id)sender;
- (IBAction)joinWebApp:(id)sender;
- (IBAction)sendMessage:(id)sender;
- (IBAction)leaveWebApp:(id)sender;
- (IBAction)closeWebApp:(id)sender;
- (IBAction)pinWebApp:(id)sender;
- (IBAction)unPinWebApp:(id)sender;

@end
