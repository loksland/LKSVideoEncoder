//
//  ViewController.m
//  LKSVideoEncoder
//
//  Created by Lachlan Nuttall on 3/04/2015.
//  Copyright (c) 2015 Loksland. All rights reserved.
//

#import "ViewController.h"
#import "MBProgressHUD.h"
#import "LKSVideoEncoder.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()

@property (nonatomic,strong) LKSVideoEncoder *videoEncoder;
@property (nonatomic,strong) AVAudioPlayer *myAudioPlayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
   
}

- (IBAction)process:(id)sender {
    
    NSUInteger startFrame = 514;
    NSUInteger endFrame = 638;
    CGFloat outputPerc = 1.0;
    
    NSUInteger _endFrame = startFrame + roundf((endFrame - startFrame)*outputPerc);
    NSMutableArray *framePics = [NSMutableArray arrayWithCapacity:_endFrame-startFrame];
    
    for (NSUInteger i = startFrame; i <= _endFrame; i++){
        //[framePics addObject:[UIImage imageNamed:[NSString stringWithFormat:@"test-frame-%05lu.png", (unsigned long)i]]];
        [framePics addObject:[NSString stringWithFormat:@"test-frame-%05lu.png", (unsigned long)i]];
    }
  
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSString *sourceAudioPath = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"m4a"];
    NSLog(@"SOURCE AUDIO PATH %@", sourceAudioPath);
    [self.myAudioPlayer stop];
    
  

    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *outputVideoPath = [documentsDirectory stringByAppendingFormat:@"/_output.m4v"];
    
    self.videoEncoder = [[[LKSVideoEncoder alloc] init] encodeImages:framePics andSourceAudioPath:sourceAudioPath toOutputVideoPath:outputVideoPath width:640 height:480 fps:22 completion:^(NSURL *fileURL) {
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self viewVideoAtUrl:fileURL];

    }];
    
}

- (void)viewVideoAtUrl:(NSURL *)fileURL {
    
    NSLog(@"%@", fileURL.path);
    
    MPMoviePlayerViewController *playerController = [[MPMoviePlayerViewController alloc] initWithContentURL:fileURL];
    [playerController.view setFrame:self.view.bounds];
    [self presentMoviePlayerViewControllerAnimated:playerController];
    [playerController.moviePlayer prepareToPlay];
    [playerController.moviePlayer play];
    [self.view addSubview:playerController.view];
    
}
@end
