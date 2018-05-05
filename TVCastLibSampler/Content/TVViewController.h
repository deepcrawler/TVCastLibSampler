//
//  TVViewController.h


#import "BaseViewController.h"

@interface TVViewController : BaseViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *powerOffButton;
@property (weak, nonatomic) IBOutlet UIButton *display3DButton;

- (IBAction)powerOff:(id)sender;
- (IBAction)display3D:(id)sender;

@property (weak, nonatomic) IBOutlet UIStepper *channelStepper;
@property (weak, nonatomic) IBOutlet UITableView *channels;

-(IBAction)channelStepperChange:(id)sender;

@end
