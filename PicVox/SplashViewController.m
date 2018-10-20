//
//  SplashViewController.m
//  PicVox
//
//  Created by topworld on 8/20/17.
//  Copyright © 2017 Georgy Beckham. All rights reserved.
//

#import "SplashViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface SplashViewController ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@end

@implementation SplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.loadingIndicator startAnimating];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //Here your non-main thread.
        [NSThread sleepForTimeInterval:3.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            //Here you returns to main thread.
            [self.loadingIndicator stopAnimating];
            [self performSegueWithIdentifier:@"displayHome" sender:self];
        });
    });
    
    }

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
