//
//  MediaViewController.m


#import "MediaViewController.h"
#import <TVCastLib/CastService.h>

@interface MediaViewController ()

@end

@implementation MediaViewController
{
    LaunchSession *_launchSession;
    id<MediaControl> _mediaControl;
    id<PlayListControl> _playListControl;
    ServiceSubscription *_playStateSubscription;
    ServiceSubscription *_volumeSubscription;

    NSTimeInterval _estimatedMediaPosition;
    NSTimeInterval _mediaDuration;

    NSTimer *_playTimer;
    NSTimer *_mediaInfoTimer;

    MediaPlayStateSuccessBlock _playStateHandler;
}

#pragma mark - UIViewController creation/destruction methods

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    __unsafe_unretained typeof(self) weakSelf = self;
    
    _playStateHandler = ^(MediaControlPlayState playState)
    {
        NSLog(@"play state change %@", @(playState));

        if (playState == MediaControlPlayStatePlaying)
        {
            if (weakSelf->_playTimer)
                [weakSelf->_playTimer invalidate];

            if (weakSelf->_mediaInfoTimer)
                [weakSelf->_mediaInfoTimer invalidate];

            if ([weakSelf.device hasCapability:kMediaControlDuration] && [weakSelf.device hasCapability:kMediaControlSeek])
                [weakSelf->_seekSlider setEnabled:YES];

            weakSelf->_mediaInfoTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:weakSelf selector:@selector(updateMediaInfo) userInfo:nil repeats:YES];
            weakSelf->_playTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:weakSelf selector:@selector(updatePlayerControls) userInfo:nil repeats:YES];
        } else if (playState == MediaControlPlayStateFinished)
        {
            [weakSelf resetMediaControlComponents];
        } else
        {
            if (weakSelf->_playTimer)
                [weakSelf->_playTimer invalidate];

            [weakSelf->_seekSlider setEnabled:NO];
        }
    };
}

- (void) addSubscriptions
{
    if (self.device)
    {
        if ([self.device hasCapability:kMediaPlayerDisplayImage]) [_displayPhotoButton setEnabled:YES];
        if ([self.device hasCapability:kMediaPlayerPlayVideo]) [_displayVideoButton setEnabled:YES];
        if ([self.device hasCapability:kMediaPlayerPlayAudio]) [_playAudioButton setEnabled:YES];
        if ([self.device hasCapability:kMediaPlayerPlayPlaylist]) [_playListButton setEnabled:YES];
        if ([self.device hasCapability:kMediaPlayerLoop]) [_loopSwicth setEnabled:YES];
        
         // You can set your own web app id for chromecast.
         // The default webapp id is kGCKMediaDefaultReceiverApplicationID.

         if ([self.device serviceWithName:kTVCastLibCastServiceId]) {
             CastService *service = (CastService *)[self.device serviceWithName:kTVCastLibCastServiceId];
             //service.castWebAppId = kGCKMediaDefaultReceiverApplicationID;
             service.castWebAppId=[[NSUserDefaults standardUserDefaults] stringForKey:@"castWebAppId"];
         }
        
    } else
    {
        [self removeSubscriptions];
    }
}

- (void) removeSubscriptions
{
    [self resetMediaControlComponents];
    
    [_displayPhotoButton setEnabled:NO];
    [_displayVideoButton setEnabled:NO];
    [_playAudioButton setEnabled:NO];
    [_playListButton setEnabled:NO];
    [_loopSwicth setEnabled:NO];
}

-(void)addMediaInfoSubscription {
    
    if ([self.device hasCapability:kMediaControlMetadataSubscribe]){
        [_mediaControl subscribeMediaInfoWithSuccess:^(NSDictionary *responseObject) {
            
            self.mediaTitle.text = [responseObject objectForKey:@"title"];
            self.artistName.text = [responseObject objectForKey:@"subtitle"];
            NSURL *url = [NSURL URLWithString:[responseObject objectForKey:@"iconURL"]];
            NSData *data = [NSData dataWithContentsOfURL:url];
            UIImage *img = [[UIImage alloc] initWithData:data];
            self.mediaIcon.image = img;
            
        }  failure:^(NSError *error)
         {
             NSLog(@"subscribe media info subscribe failure: %@", error.localizedDescription);
         }];
    }
}

- (void) resetMediaControlComponents
{
    if (_playTimer)
    {
        [_playTimer invalidate];
        _playTimer = nil;
    }

    if (_mediaInfoTimer)
    {
        [_mediaInfoTimer invalidate];
        _mediaInfoTimer = nil;
    }

    if (_playStateSubscription) {
        [_playStateSubscription unsubscribe];
        _playStateSubscription = nil;
    }

    if (_volumeSubscription) {
        [_volumeSubscription unsubscribe];
        _volumeSubscription = nil;
    }
    
    _launchSession = nil;
    _mediaControl = nil;

    _estimatedMediaPosition = 0;
    _mediaDuration = 0;
    
    [_closeMediaButton setEnabled:NO];
    
    [_playButton setEnabled:NO];
    [_pauseButton setEnabled:NO];
    [_stopButton setEnabled:NO];
    [_rewindButton setEnabled:NO];
    [_fastForwardButton setEnabled:NO];
    [_playNextButton setEnabled:NO];
    [_playPreviousButton setEnabled:NO];
    [_jumpTrackButton setEnabled:NO];
    
    _currentTimeLabel.text = @"--:--";
    _durationLabel.text = @"--:--";
    
    [_seekSlider setEnabled:NO];
    [_volumeSlider setEnabled:NO];
    
    [_seekSlider setValue:0 animated:NO];
    [_volumeSlider setValue:0 animated:NO];
    _mediaTitle.text = @"";
    _artistName.text = @"";
    _mediaIcon.image = nil;
}

- (void) enableMediaControlComponents
{
    if ([self.device hasCapability:kMediaControlPlay]) [_playButton setEnabled:YES];
    if ([self.device hasCapability:kMediaControlPause]) [_pauseButton setEnabled:YES];
    if ([self.device hasCapability:kMediaControlStop]) [_stopButton setEnabled:YES];
    if ([self.device hasCapability:kMediaControlRewind]) [_rewindButton setEnabled:YES];
    if ([self.device hasCapability:kMediaControlFastForward]) [_fastForwardButton setEnabled:YES];
    
    if ([self.device hasCapability:kMediaControlPlayStateSubscribe])
    {
        [_mediaControl subscribePlayStateWithSuccess:_playStateHandler failure:^(NSError *error)
        {
            NSLog(@"subscribe play state failure: %@", error.localizedDescription);
        }];
    } else
    {
        _mediaInfoTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateMediaInfo) userInfo:nil repeats:YES];
        _playTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updatePlayerControls) userInfo:nil repeats:YES];
    }

    if ([self.device hasCapability:kVolumeControlVolumeSet]) {
        [_volumeSlider setEnabled:YES];
    }

    if ([self.device hasCapability:kVolumeControlVolumeSubscribe])
    {
        _volumeSubscription = [self.device.volumeControl subscribeVolumeWithSuccess:^(float volume)
        {
            [_volumeSlider setValue:volume];
            [_volumeSlider setEnabled:YES];
            NSLog(@"volume changed to %f", volume);
        } failure:^(NSError *error)
        {
            NSLog(@"Subscribe Vol Error %@", error.localizedDescription);
        }];
    } else if ([self.device hasCapability:kVolumeControlVolumeGet])
    {
        [self.device.volumeControl getVolumeWithSuccess:^(float volume)
        {
            [_volumeSlider setValue:volume];
            NSLog(@"Get vol %f", volume);
        } failure:^(NSError *error)
        {
            NSLog(@"Get Vol Error %@", error.localizedDescription);
        }];
    }
    [self addMediaInfoSubscription];
}

- (void) updateMediaInfo
{
    if (![self.device hasCapability:kMediaControlPlayStateSubscribe])
        [_mediaControl getPlayStateWithSuccess:_playStateHandler failure:nil];

    if ([self.device hasCapabilities:@[kMediaControlDuration, kMediaControlPosition]])
    {
        [_mediaControl getDurationWithSuccess:^(NSTimeInterval duration)
        {
            _mediaDuration = duration;
        } failure:nil];

        [_mediaControl getPositionWithSuccess:^(NSTimeInterval position)
        {
            _estimatedMediaPosition = position;
        } failure:nil];
    }
    
    if ([self.device hasCapability:kMediaControlMetadata]){
        
        if([_mediaControl respondsToSelector:@selector(getMediaMetaDataWithSuccess:failure:)]){
        [_mediaControl getMediaMetaDataWithSuccess:^(NSDictionary* responseObject) {
        
            self.mediaTitle.text = [responseObject objectForKey:@"title"];
            self.artistName.text = [responseObject objectForKey:@"subtitle"];
            NSURL *url = [NSURL URLWithString:[responseObject objectForKey:@"iconURL"]];
            NSData *data = [NSData dataWithContentsOfURL:url];
            UIImage *img = [[UIImage alloc] initWithData:data];
            self.mediaIcon.image = img;
        }failure:nil];
        }
        
    }
}

- (void) updatePlayerControls
{
    _estimatedMediaPosition += 1;

    if (_mediaDuration <= 0)
        return;

    float progress = (float) (_estimatedMediaPosition / _mediaDuration);

    if (progress < 0.0f || progress > 1.0f)
        return;

    _seekSlider.value = progress;

    [_currentTimeLabel setText:[self stringForTimeInterval:_estimatedMediaPosition]];
    [_durationLabel setText:[self stringForTimeInterval:_mediaDuration]];
}

- (NSString *) stringForTimeInterval:(NSTimeInterval)timeInterval
{
    NSInteger ti = (NSInteger) timeInterval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);

    NSString *time;

    if (hours > 0)
        time = [NSString stringWithFormat:@"%02li:%02li:%02li", (long)hours, (long)minutes, (long)seconds];
    else
        time = [NSString stringWithFormat:@"%02li:%02li", (long)minutes, (long)seconds];

    return time;
}

#pragma mark - TVCastLib sampler methods

- (IBAction)displayPhoto:(id)sender {
    
    [self resetMediaControlComponents];
    
    NSURL *mediaURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"imagePath"]];
    NSURL *iconURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"imageThumbPath"]];
    NSString *title = [[NSUserDefaults standardUserDefaults] stringForKey:@"imageTitle"];
    NSString *description = [[NSUserDefaults standardUserDefaults] stringForKey:@"imageDescription"];
    NSString *mimeType = [[NSUserDefaults standardUserDefaults] stringForKey:@"imageMimeType"];
    
    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:mediaURL mimeType:mimeType];
    mediaInfo.title = title;
    mediaInfo.description = description;
    ImageInfo *imageInfo = [[ImageInfo alloc] initWithURL:iconURL type:ImageTypeThumb];
    [mediaInfo addImage:imageInfo];
    
    [self.device.mediaPlayer displayImageWithMediaInfo:mediaInfo
                                  success:^(MediaLaunchObject *launchObject) {
                                      NSLog(@"display photo success");
                                      _launchSession = launchObject.session;
                                      if ([self.device hasCapability:kMediaPlayerClose])
                                          [_closeMediaButton setEnabled:YES];
                                  } failure:^(NSError *error) {
                                      NSLog(@"display photo failure: %@", error.localizedDescription);
                                      
                                  }];
}

- (IBAction)displayVideo:(id)sender {
    
    [self resetMediaControlComponents];

    NSURL *mediaURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"videoPath"]];
    NSURL *iconURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"videoThumbPath"]];
    NSString *title = [[NSUserDefaults standardUserDefaults] stringForKey:@"videoTitle"];
    NSString *description = [[NSUserDefaults standardUserDefaults] stringForKey:@"videoDescription"];
    NSString *mimeType = [[NSUserDefaults standardUserDefaults] stringForKey:@"videoMimeType"];
    BOOL shouldLoop = self.loopSwicth.on;

    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:mediaURL mimeType:mimeType];
    mediaInfo.title = title;
    mediaInfo.description = description;
    ImageInfo *imageInfo = [[ImageInfo alloc] initWithURL:iconURL type:ImageTypeThumb];
    [mediaInfo addImage:imageInfo];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"subtitlesEnabled"] &&
        [self.device hasAnyCapability:@[kMediaPlayerSubtitleSRT,
                                        kMediaPlayerSubtitleWebVTT]]) {
        NSURL *subtitlesURL = [NSURL URLWithString:[defaults stringForKey:@"subtitlesURL"]];
        SubtitleInfo *subtitleInfo = [SubtitleInfo infoWithURL:subtitlesURL
                                                      andBlock:^(SubtitleInfoBuilder *builder) {
                                                          builder.mimeType = [defaults stringForKey:@"subtitlesMimeType"];
                                                          builder.language = [defaults stringForKey:@"subtitlesLanguage"];
                                                          builder.label = [defaults stringForKey:@"subtitlesLabel"];
                                                      }];
        mediaInfo.subtitleInfo = subtitleInfo;
    }
    
    [self.device.mediaPlayer playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop
                               success:^(MediaLaunchObject *launchObject) {
                                   NSLog(@"display video success");
                                   _launchSession = launchObject.session;
                                   _mediaControl = launchObject.mediaControl;

                                   if ([self.device hasCapability:kMediaPlayerClose])
                                       [_closeMediaButton setEnabled:YES];

                                   [self enableMediaControlComponents];
                               } failure:^(NSError *error) {
                                   NSLog(@"display video failure: %@", error.localizedDescription);
                               }];
}

- (IBAction)playAudio:(id)sender {
    
    [self resetMediaControlComponents];

    NSURL *mediaURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"audioPath"]];
    NSURL *iconURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"audioThumbPath"]];
    NSString *title = [[NSUserDefaults standardUserDefaults] stringForKey:@"audioTitle"];
    NSString *description = [[NSUserDefaults standardUserDefaults] stringForKey:@"audioDescription"];
    NSString *mimeType = [[NSUserDefaults standardUserDefaults] stringForKey:@"audioMimeType"];
    BOOL shouldLoop = self.loopSwicth.on;
    
    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:mediaURL mimeType:mimeType];
    mediaInfo.title = title;
    mediaInfo.description = description;
    ImageInfo *imageInfo = [[ImageInfo alloc] initWithURL:iconURL type:ImageTypeThumb];
    [mediaInfo addImage:imageInfo];
    
    [self.device.mediaPlayer playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop
                               success:^(MediaLaunchObject *launchObject) {
                                   NSLog(@"display audio success");
                                   
                                   _launchSession = launchObject.session;
                                   _mediaControl = launchObject.mediaControl;
                                   
                                   if ([self.device hasCapability:kMediaPlayerClose])
                                       [_closeMediaButton setEnabled:YES];
                                   
                                   [self enableMediaControlComponents];
                               } failure:^(NSError *error) {
                                   NSLog(@"display audio failure: %@", error.localizedDescription);
                               }];
}

- (IBAction)closeMedia:(id)sender
{
    if (!_launchSession)
    {
        [self resetMediaControlComponents];
        return;
    }
    
    [_launchSession closeWithSuccess:^(id responseObject) {
        NSLog(@"close media success");
        [self resetMediaControlComponents];
    } failure:^(NSError *error) {
        NSLog(@"close media failure: %@", error.localizedDescription);
    }];
}

-(void)playClicked:(id)sender
{
    if (!_mediaControl)
    {
        [self resetMediaControlComponents];
        return;
    }
    
    [_mediaControl playWithSuccess:^(id responseObject)
    {
        NSLog(@"play success");
    } failure:^(NSError *error)
    {
        NSLog(@"play failure: %@", error.localizedDescription);
    }];
}

-(void)pauseClicked:(id)sender
{
    if (!_mediaControl)
    {
        [self resetMediaControlComponents];
        return;
    }
    
    [_mediaControl pauseWithSuccess:^(id responseObject)
    {
        NSLog(@"pause success");
    } failure:^(NSError *error)
    {
        NSLog(@"pause failure: %@", error.localizedDescription);
    }];
}

-(void)stopClicked:(id)sender
{
    if (!_mediaControl)
    {
        [self resetMediaControlComponents];
        return;
    }
    
    [_mediaControl stopWithSuccess:^(id responseObject)
    {
        NSLog(@"stop success");
        [self resetMediaControlComponents];
    } failure:^(NSError *error)
    {
        NSLog(@"stop failure: %@", error.localizedDescription);
    }];
}

-(void)rewindClicked:(id)sender
{
    if (!_mediaControl)
    {
        [self resetMediaControlComponents];
        return;
    }
    
    [_mediaControl rewindWithSuccess:^(id responseObject)
    {
        NSLog(@"rewind success");
    } failure:^(NSError *error)
    {
        NSLog(@"rewind failure: %@", error.localizedDescription);
    }];
}

-(void)fastForwardClicked:(id)sender
{
    if (!_mediaControl)
    {
        [self resetMediaControlComponents];
        return;
    }
    
    [_mediaControl fastForwardWithSuccess:^(id responseObject)
    {
        NSLog(@"fast forward success");
    } failure:^(NSError *error)
    {
        NSLog(@"fast forward failure: %@", error.localizedDescription);
    }];
}

- (IBAction)startSeeking:(id)sender
{
    NSLog(@"start seeking");

    if (_playTimer)
        [_playTimer invalidate];

    if (_mediaInfoTimer)
        [_mediaInfoTimer invalidate];
}

- (IBAction)seekChanged:(id)sender
{
    NSTimeInterval time = _seekSlider.value * _mediaDuration;
    NSString *timeString = [self stringForTimeInterval:time];

    _currentTimeLabel.text = timeString;
}

- (IBAction)stopSeeking:(id)sender
{
    if (!_mediaControl)
    {
        [self resetMediaControlComponents];
        return;
    }

    [_seekSlider setEnabled:NO];

    [_mediaControl getDurationWithSuccess:^(NSTimeInterval duration)
    {
        _mediaDuration = duration;

        [_mediaControl getPositionWithSuccess:^(NSTimeInterval position)
        {
            _estimatedMediaPosition = position;
        } failure:nil];

        NSTimeInterval newTime = duration * _seekSlider.value;

        [_mediaControl seek:newTime success:^(id responseObject)
        {
            NSLog(@"seek success");

            _estimatedMediaPosition = newTime;

            if (![self.device hasCapability:kMediaControlPlayStateSubscribe])
                _mediaInfoTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateMediaInfo) userInfo:nil repeats:YES];

            // we don't receive a PLAYING state notification on xbox, so fake it
            // to reenable the seekSlider
            self->_playStateHandler(MediaControlPlayStatePlaying);
        } failure:^(NSError *error)
        {
            NSLog(@"seek failure: %@", error.localizedDescription);
        }];
    } failure:^(NSError *error)
    {
        NSLog(@"get duration failure: %@", error.localizedDescription);
    }];
}

- (IBAction)volumeChanged:(UISlider *)sender
{
    float vol = [_volumeSlider value];

    [self.device.volumeControl setVolume:vol success:^(id responseObject)
    {
        NSLog(@"Vol Change Success %f", vol);
    } failure:^(NSError *setVolumeError)
    {
        // For devices which don't support setVolume, we'll disable
        // slider and should encourage volume up/down instead

        NSLog(@"Vol Change Error %@", setVolumeError.description);

        sender.enabled = NO;
        sender.userInteractionEnabled = NO;

        [self.device.volumeControl getVolumeWithSuccess:^(float volume)
        {
            NSLog(@"Vol rolled back to actual %f", volume);

            sender.value = volume;
        } failure:^(NSError *getVolumeError)
        {
            NSLog(@"Vol serious error: %@", getVolumeError.localizedDescription);
        }];
    }];
}

- (IBAction)playListClicked:(id)sender {
    
    [self resetMediaControlComponents];
    
    NSURL *mediaURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"playlistPath"]];
    NSURL *iconURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"playlistThumbPath"]];
    NSString *title = [[NSUserDefaults standardUserDefaults] stringForKey:@"playlistTitle"];
    NSString *description = [[NSUserDefaults standardUserDefaults] stringForKey:@"playlistDescription"];
    NSString *mimeType = [[NSUserDefaults standardUserDefaults] stringForKey:@"playlistMimeType"];
    BOOL shouldLoop = self.loopSwicth.on;
    
    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:mediaURL mimeType:mimeType];
    mediaInfo.title = title;
    mediaInfo.description = description;
    ImageInfo *imageInfo = [[ImageInfo alloc] initWithURL:iconURL type:ImageTypeThumb];
    [mediaInfo addImage:imageInfo];
    
    [self.device.mediaPlayer playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop
                               success:^(MediaLaunchObject *launchObject) {
                                   NSLog(@"display audio success");
                                   
                                   _launchSession = launchObject.session;
                                   _mediaControl = launchObject.mediaControl;
                                   _playListControl = launchObject.playListControl;
                                   
                                   if ([self.device hasCapability:kMediaPlayerClose])
                                       [_closeMediaButton setEnabled:YES];
                                  
                                   if ([self.device hasCapability:kPlayListControlNext]) [_playNextButton setEnabled:YES];
                                   if ([self.device hasCapability:kPlayListControlPrevious]) [_playPreviousButton setEnabled:YES];
                                   if ([self.device hasCapability:kPlayListControlJumpTrack]) [_jumpTrackButton setEnabled:YES];
                                   
                                   [self enableMediaControlComponents];
                               } failure:^(NSError *error) {
                                   NSLog(@"display audio failure: %@", error.localizedDescription);
                               }];
}

-(IBAction)playNextClicked:(id)sender{
    if (!_playListControl)
    {
        [self resetMediaControlComponents];
        return;
    }
    
    [_playListControl playNextWithSuccess:^(id responseObject)
     {
         NSLog(@"next success");
     } failure:^(NSError *error)
     {
         NSLog(@"next failure: %@", error.localizedDescription);
     }];
}

-(IBAction)playPreviousClicked:(id)sender{
    if (!_playListControl)
    {
        [self resetMediaControlComponents];
        return;
    }
    
    [_playListControl playPreviousWithSuccess:^(id responseObject)
     {
         NSLog(@"previous success");
     } failure:^(NSError *error)
     {
         NSLog(@"previous failure: %@", error.localizedDescription);
     }];
}

-(IBAction)jumpTrackClicked:(id)sender{
    
    NSInteger trackIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"playListJumpToTrackNumber"];
    if (!_playListControl)
    {
        [self resetMediaControlComponents];
        return;
    }
    
    [_playListControl jumpToTrackWithIndex:trackIndex success:^(id responseObject)
     {
         NSLog(@"jump success");
     } failure:^(NSError *error)
     {
         NSLog(@"jump failure: %@", error.localizedDescription);
     }];
}

@end
