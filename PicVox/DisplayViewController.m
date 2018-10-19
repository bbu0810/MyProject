//
//  DisplayViewController.m
//  PicVoxScan
//
//  Created by topworld on 5/16/17.
//  Copyright © 2017 topworld. All rights reserved.
//

#import "DisplayViewController.h"
#import "AudioSessionManager.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

NSString *audioFilePath, *imageFilePath, *webSiteURL, *twitterURL, *facebookURL, *itunesURL;
NSTimer *audioTimer;
BOOL play;

BOOL ispaused;
BOOL isstopped;
NSDate *pauseStart, *previousFireDate;

@interface DisplayViewController () <AVAudioRecorderDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *img;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentProgress;
@property (weak, nonatomic) IBOutlet UISlider *audioSlider;
@property(nonatomic) AVAudioPlayer *player;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(nonatomic) NSData *audioData;

@end

@implementation DisplayViewController
{
    NSTimer *animation_timer;
}

@synthesize audioSlider;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.playButton.hidden = YES;
    self.pauseButton.hidden = YES;
    self.stopButton.hidden = YES;
    self.audioSlider.hidden = YES;
    
    // Do any additional setup after loading the view.
    NSString *barcodeid = [[NSUserDefaults standardUserDefaults] valueForKey:@"BARCODEID"];
    NSString *queryString = [NSString stringWithFormat:@"http://thepicvox.com/websuperboy/fetch.php?barcode_id=%@", barcodeid];
    
    
    animation_timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       target:self
                                                     selector:@selector(running)
                                                     userInfo:nil
                                                      repeats:YES];
    NSURL *url = [NSURL URLWithString:queryString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSArray *tempArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    audioFilePath = [[tempArray objectAtIndex:0] objectForKey:@"audio_path"];
    imageFilePath = [[tempArray objectAtIndex:0] objectForKey:@"image_path"];
    twitterURL = [[tempArray objectAtIndex:0] objectForKey:@"twitter"];
    facebookURL = [[tempArray objectAtIndex:0] objectForKey:@"facebook"];
    webSiteURL = [[tempArray objectAtIndex:0] objectForKey:@"website"];
    itunesURL = [[tempArray objectAtIndex:0] objectForKey:@"itunes"];
    
    imageFilePath = [@"http://thepicvox.com/uploads/" stringByAppendingString:imageFilePath];
    NSURL *url1 = [NSURL URLWithString:imageFilePath];
    NSData *data1 = [NSData dataWithContentsOfURL:url1];
    UIImage *img1 = [[UIImage alloc] initWithData:data1];
    _img.image = img1;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //Start Activity Indicator
    [self.activityIndicator startAnimating];
    
    //Download Audio
    audioFilePath = [@"http://thepicvox.com/Audios/" stringByAppendingString:audioFilePath];
    NSURL *audioUrl= [NSURL URLWithString:audioFilePath];
    _audioData = [NSData dataWithContentsOfURL:audioUrl];
    
    //Stop Activity Indicator
    self.playButton.hidden = NO;
    self.pauseButton.hidden = NO;
    self.stopButton.hidden = NO;
    self.audioSlider.hidden = NO;
    [self.activityIndicator stopAnimating];
}

- (IBAction)sliderChaged:(id)sender {
    
    if (_player.isPlaying) {
        float currentValue = audioSlider.value;
        float currentTime = currentValue * [_player duration];
        [_player setCurrentTime:currentTime];
    }
    
    
}
- (IBAction)fileSave:(id)sender {
    NSLog(@"Downloading Started");
    NSURL  *url = [NSURL URLWithString:audioFilePath];
    NSData *urlData = [NSData dataWithContentsOfURL:url];
    if ( urlData )
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSArray<NSString *> *fileNameArray = [audioFilePath componentsSeparatedByString:@"/"];
        NSString *fileName = fileNameArray[fileNameArray.count-1];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,fileName];
        
        //saving is done on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [urlData writeToFile:filePath atomically:YES];
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"File Saved"
                                         message:@""
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            //Add Buttons
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"Ok"
                                        style:UIAlertActionStyleDefault
                                        handler:nil];
            
            //Add your buttons to alert controller
            [alert addAction:yesButton];
            
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
    
    
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [_player stop];
}

-(void)running
{
    if (_player.isPlaying) {
        double total_size = _player.duration;
        double current_time = _player.currentTime;
        float value = (float)current_time/total_size;
        audioSlider.value = value;
        //        _timeLabel.text = [[NSString alloc] initWithFormat:@"%d", total_size];
        //        _currentProgress.text = [[NSString alloc] initWithFormat:@"%d", current_time];
    }
    
}
- (IBAction)PlayAudioFile:(id)sender {
    [_playButton setBackgroundImage:[UIImage imageNamed:@"11.png"] forState:UIControlStateNormal];
    [_stopButton setBackgroundImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
    [_pauseButton setBackgroundImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
    
    if (!_player)
    {
        
        //where you are about to add sound
        [AudioSessionManager setAudioSessionCategory:AVAudioSessionCategoryPlayback];
        NSError *audioError;
        
        _player = [[AVAudioPlayer alloc] initWithData:_audioData error:&audioError];
        if (_player == nil) {
            NSLog(@"%@",audioError);
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Invalid Barcode Id Detected"
                                         message:@"There is no audio present with this Barcode.\n Please scan the updated barcode."
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            //Add Buttons
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"Ok"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            //Handle your yes please button action here
                                            [self.navigationController popViewControllerAnimated:YES];
                                        }];
            
            //Add your buttons to alert controller
            [alert addAction:yesButton];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        
        [_player setVolume:0.1];
        [_player prepareToPlay];
        [_player play];
    }
    else {
        [_player play];
    }
}
- (IBAction)StopAudioFile:(id)sender {
    
    if([_player play])
    {
        audioSlider.value = 0.0;
        [_playButton setBackgroundImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
        [_stopButton setBackgroundImage:[UIImage imageNamed:@"12.png"] forState:UIControlStateNormal];
        [_pauseButton setBackgroundImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
        [_player setCurrentTime:0.0 ];
        [_player stop];
        isstopped = YES;
    }
    
}
- (IBAction)PauseAudioFile:(id)sender {
    
    [_playButton setBackgroundImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
    [_stopButton setBackgroundImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
    
    [_pauseButton setBackgroundImage:[UIImage imageNamed:@"13.png"] forState:UIControlStateNormal];
    
    
    if([_player isPlaying])
    {
        [_player pause];
        ispaused = YES;
    }else{
        [_player play];
        ispaused = NO;
    }
    
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)openWebSite:(id)sender {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.google.com"]];
        exit(0);
    });
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:webSiteURL]];
}
- (IBAction)openFaceBook:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:facebookURL]];
}
- (IBAction)openTwitter:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:twitterURL]];
}
- (IBAction)openItunes:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:itunesURL]];
}

- (IBAction)homeButtonPressed:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
