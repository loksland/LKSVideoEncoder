//
//  LKSVideoEncoder.m
//  LKSVideoEncoder

#import "LKSVideoEncoder.h"

@interface LKSVideoEncoder()

@property (nonatomic,strong) NSString *sourceAudioPath;

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *writerInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *bufferAdapter;

@property (nonatomic, strong) NSDictionary *videoSettings;
@property (nonatomic, assign) CMTime frameTime;

@property (nonatomic, strong) NSURL *outputVideoTmpURL;
@property (nonatomic, strong) NSURL *outputVideoURL;
@property (nonatomic, strong) NSString *outputVideoPath;

@property (nonatomic, copy) LKSVideoEncoderCompletion completionBlock;
@property (nonatomic, copy) LKSVideoEncoderProgress progressBlock;
@end

@implementation LKSVideoEncoder

-(instancetype) init {
    
    if (self = [super init]) {
        
        
    }
    
    return self;
    
}

-(id) encodeImages:(NSMutableArray*)images andSourceAudioPath:(NSString*)sourceAudioPath toOutputVideoPath:(NSString*)outputVideoPath width:(CGFloat)width height:(CGFloat)height fps:(NSUInteger)fps progress:(LKSVideoEncoderProgress)progress completion:(LKSVideoEncoderCompletion)completion {
    
    NSError *error;
    
    if ((int)width % 16 != 0) {
        NSLog(@"Warning: video settings width must be divisible by 16.");
    }
    
    self.sourceAudioPath = sourceAudioPath;
    self.outputVideoPath = outputVideoPath;
    
    self.completionBlock = completion;
    self.progressBlock = progress;
    
    // Configure
    // ---------
    
    NSString* outputVideoPathExt = [self.outputVideoPath pathExtension];
    NSString* outputVideoPathTmp = [[[self.outputVideoPath stringByDeletingPathExtension] stringByAppendingString:@"tmp"] stringByAppendingPathExtension:outputVideoPathExt];
    
    NSLog(@"outputVideoPathTmp %@", outputVideoPathTmp);
    NSLog(@"ext %@", outputVideoPathExt);
    
    // Delete existing files
    // ---------------------
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.outputVideoPath]) {
        error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:self.outputVideoPath error:&error];
        if (error) {
            NSLog(@"Error: %@", error.debugDescription);
        }
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputVideoPathTmp]) {
        error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:outputVideoPathTmp error:&error];
        if (error) {
            NSLog(@"Error: %@", error.debugDescription);
        }
    }
    
    error = nil;
    self.outputVideoTmpURL = [NSURL fileURLWithPath:outputVideoPathTmp];
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.outputVideoTmpURL
                                             fileType:AVFileTypeAppleM4V error:&error]; // AVFileTypeQuickTimeMovie
    if (error) {
        NSLog(@"Error: %@", error.debugDescription);
    }
    NSParameterAssert(self.assetWriter);
    
    self.videoSettings = @{AVVideoCodecKey : AVVideoCodecH264,
                           AVVideoWidthKey : [NSNumber numberWithInt:(int)width],
                           AVVideoHeightKey : [NSNumber numberWithInt:(int)height],
                           };
    self.writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                      outputSettings:self.videoSettings];
    NSParameterAssert(self.writerInput);
    NSParameterAssert([self.assetWriter canAddInput:self.writerInput]);
    
    [self.assetWriter addInput:self.writerInput];
    
    NSDictionary *bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    self.bufferAdapter = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:self.writerInput sourcePixelBufferAttributes:bufferAttributes];
    self.frameTime = CMTimeMake(1, (int)fps);
    
    // Ouput video
    // -----------
    
    [self.assetWriter startWriting];
    [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    
    __block NSInteger i = 0;
    
    NSInteger frameNumber = images.count;
    
    [self.writerInput requestMediaDataWhenReadyOnQueue:mediaInputQueue usingBlock:^{
        
        while (YES){
            if (i >= frameNumber) {
                break;
            }
            if ([self.writerInput isReadyForMoreMediaData]) {
                
                CGFloat progress = (i + 1)/(CGFloat)frameNumber;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self onProgress:progress];
                });
                
                UIImage *img;
                if ([[images objectAtIndex:i] isKindOfClass:[UIImage class]]){
                    img = [images objectAtIndex:i];
                } else if ([[images objectAtIndex:i] isKindOfClass:[NSString class]]) {
                    img =[UIImage imageWithContentsOfFile: [images objectAtIndex:i]];
                }
                
                if (img){
                    
                    CVPixelBufferRef sampleBuffer = [self newPixelBufferFromCGImage:[img CGImage]];
                    
                    if (sampleBuffer) {
                        if (i == 0) {
                            [self.bufferAdapter appendPixelBuffer:sampleBuffer withPresentationTime:kCMTimeZero];
                        }else{
                            CMTime lastTime = CMTimeMake(i, self.frameTime.timescale); // numerator and denominator Eg. (1, 25) = 1/25
                            CMTime presentTime = CMTimeAdd(lastTime, self.frameTime);
                            [self.bufferAdapter appendPixelBuffer:sampleBuffer withPresentationTime:presentTime];                        
                        }
                        CFRelease(sampleBuffer);
                        i++;
                    }
                }
            }
        }
        
        [self.writerInput markAsFinished];
        [self.assetWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
              
                [self mergeAudio];
            });
        }];
        
        CVPixelBufferPoolRelease(self.bufferAdapter.pixelBufferPool);
        
    }];
    
    return self;
}

-(void) mergeAudio {
    
    // Encode audio if any
    
    /*
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *outputFilePath = [documentsDirectory stringByAppendingFormat:@"/finalVideo.m4v"];
    NSLog(@"outputFilePath %@", outputFilePath);
    */
    
    self.outputVideoURL = [NSURL fileURLWithPath:self.outputVideoPath];
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
  
    NSURL *audio_inputFileUrl = [NSURL fileURLWithPath:self.sourceAudioPath];
    
    CMTime nextClipStartTime = kCMTimeZero;
    
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:self.outputVideoTmpURL options:nil];
    CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,videoAsset.duration);
    NSDictionary *settings =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
     [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
     [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
     [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
     [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
     [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
     nil];
    AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audio_inputFileUrl options:settings];
    //CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
    
    AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [a_compositionVideoTrack insertTimeRange:video_timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:nextClipStartTime error:nil];
    
    AVMutableCompositionTrack *b_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [b_compositionAudioTrack insertTimeRange:video_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:nextClipStartTime error:nil];
    
    AVAssetExportSession* assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality]; // AVAssetExportPresetMediumQuality];
    assetExport.outputFileType = @"com.apple.quicktime-movie";
    assetExport.outputURL = self.outputVideoURL;
    
    [assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         dispatch_async(dispatch_get_main_queue(), ^{             
             if (assetExport.status == AVAssetExportSessionStatusCompleted) {
                 
                 self.completionBlock(self.outputVideoURL);
                 
             } else {
                 //Write Fail Code here
                 NSLog(@"fail");
             }
         });
     }];
}

- (CVPixelBufferRef)newPixelBufferFromCGImage:(CGImageRef)image {
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = [[self.videoSettings objectForKey:AVVideoWidthKey] floatValue];
    CGFloat frameHeight = [[self.videoSettings objectForKey:AVVideoHeightKey] floatValue];
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 4 * frameWidth,
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           CGImageGetWidth(image),
                                           CGImageGetHeight(image)),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
    
}

-(void) onProgress: (CGFloat) progress {
    
    if (self.progressBlock != nil){
        self.progressBlock(progress);
    }
    
}

@end
