//
//  AppsViewController.h


#import "BaseViewController.h"

@interface AppsViewController : BaseViewController<UITableViewDataSource, UITableViewDelegate>


@property (weak, nonatomic) IBOutlet UIButton *browserButton;
@property (weak, nonatomic) IBOutlet UIButton *toastButton;
@property (weak, nonatomic) IBOutlet UIButton *netflixButton;
@property (weak, nonatomic) IBOutlet UIButton *appStoreButton;
@property (weak, nonatomic) IBOutlet UIButton *youtubeButton;
@property (weak, nonatomic) IBOutlet UIButton *myAppButton;

@property (weak, nonatomic) IBOutlet UITableView *apps;

- (IBAction)browserPressed:(id)sender;
- (IBAction)toastPressed:(id)sender;
- (IBAction)netflixPressed:(id)sender;
- (IBAction)appStorePressed:(id)sender;
- (IBAction)youtubePressed:(id)sender;
- (IBAction)myAppPressed:(id)sender;

@end
