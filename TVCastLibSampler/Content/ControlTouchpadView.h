//
//  ControlTouchpadView.h


#import <TVCastLib/TVCastLib.h>

@interface ControlTouchpadView : UIView

@property (nonatomic, strong) id<MouseControl> mouseControl;

-(IBAction)tapDetected:(id)sender;

@end
