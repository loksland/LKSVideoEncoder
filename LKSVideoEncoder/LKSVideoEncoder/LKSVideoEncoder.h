//
//  LKSVideoEncoder.h
//  LKSVideoEncoder
//

@import AVFoundation;
@import Foundation;
@import UIKit;

typedef void(^LKSVideoEncoderCompletion)(NSURL *fileURL);

@interface LKSVideoEncoder : NSObject

-(id) encodeImages:(NSMutableArray*)images andSourceAudioPath:(NSString*)sourceAudioPath toOutputVideoPath:(NSString*)outputVideoPath width:(CGFloat)width height:(CGFloat)height fps:(NSUInteger)fps completion:(LKSVideoEncoderCompletion)completion;

@end
