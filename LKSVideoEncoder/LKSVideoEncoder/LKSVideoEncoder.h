//
//  LKSVideoEncoder.h
//  LKSVideoEncoder
//

@import AVFoundation;
@import Foundation;
@import UIKit;

typedef void(^LKSVideoEncoderCompletion)(NSURL *fileURL);
typedef void(^LKSVideoEncoderProgress)(CGFloat progress);

@interface LKSVideoEncoder : NSObject

-(id) encodeImages:(NSMutableArray*)images andSourceAudioPath:(NSString*)sourceAudioPath toOutputVideoPath:(NSString*)outputVideoPath width:(CGFloat)width height:(CGFloat)height fps:(NSUInteger)fps progress:(LKSVideoEncoderProgress)progress completion:(LKSVideoEncoderCompletion)completion;

@end
