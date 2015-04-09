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
#import "PathUtils.h"

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
    
    // Loader
    // ------
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeAnnularDeterminate;
    hud.labelText = @"Encoding";
    
    
    // Frames
    // ------
    
    NSUInteger startFrame = 514;
    NSUInteger endFrame = 638;
    CGFloat outputPerc = 1.0;
    
    NSUInteger _endFrame = startFrame + roundf((endFrame - startFrame)*outputPerc);
    NSMutableArray *framePics = [NSMutableArray arrayWithCapacity:_endFrame-startFrame];
    
    for (NSUInteger i = startFrame; i <= _endFrame; i++){
        [framePics addObject:[PathUtils bundlePath:[NSString stringWithFormat:@"test-frame-%05lu.png", (unsigned long)i]]];
    }
  
    // Audio
    // -----
    
    NSString *sourceAudioPath = [PathUtils bundlePath:@"sample.m4a"];
    
    // Process
    // -------

    NSString *outputVideoPath = [PathUtils tmpPathWithComponents:@"_output.m4v", nil];
    
    self.videoEncoder = [[[LKSVideoEncoder alloc] init] encodeImages:framePics andSourceAudioPath:sourceAudioPath toOutputVideoPath:outputVideoPath width:640 height:480 fps:22 progress:^(CGFloat progress) {
        
        hud.progress = progress;
        
    } completion:^(NSURL *fileURL) {
        
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
