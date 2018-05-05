//
//  MediaViewController.h


#import "BaseViewController.h"

@interface MediaViewController : BaseViewController

@property (weak, nonatomic) IBOutlet UIButton *displayPhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *displayVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *playAudioButton;
@property (weak, nonatomic) IBOutlet UIButton *closeMediaButton;
@property (weak, nonatomic) IBOutlet UISwitch *loopSwicth;

- (IBAction)displayPhoto:(id)sender;
- (IBAction)displayVideo:(id)sender;
- (IBAction)playAudio:(id)sender;
- (IBAction)closeMedia:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *rewindButton;
@property (weak, nonatomic) IBOutlet UIButton *fastForwardButton;

-(IBAction)playClicked:(id)sender;
-(IBAction)pauseClicked:(id)sender;
-(IBAction)stopClicked:(id)sender;
-(IBAction)rewindClicked:(id)sender;
-(IBAction)fastForwardClicked:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UISlider *seekSlider;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UILabel *mediaTitle;
@property (weak, nonatomic) IBOutlet UILabel *artistName;

@property (weak, nonatomic) IBOutlet UIImageView *mediaIcon;

- (IBAction)startSeeking:(id)sender;
- (IBAction)seekChanged:(id)sender;
- (IBAction)stopSeeking:(id)sender;
- (IBAction)volumeChanged:(id)sender;

//Playlist controls
@property (weak, nonatomic) IBOutlet UIButton *playListButton;
@property (weak, nonatomic) IBOutlet UIButton *playNextButton;
@property (weak, nonatomic) IBOutlet UIButton *playPreviousButton;
@property (weak, nonatomic) IBOutlet UIButton *jumpTrackButton;

-(IBAction)playListClicked:(id)sender;
-(IBAction)playNextClicked:(id)sender;
-(IBAction)playPreviousClicked:(id)sender;
-(IBAction)jumpTrackClicked:(id)sender;

@end
