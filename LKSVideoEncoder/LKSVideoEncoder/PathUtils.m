//
//  UIViewController+Container.m
//  UIViewController+Container
//
//  Created by Peter Paulis on 20.4.2013.
//  Copyright (c) 2013 Peter Paulis. All rights reserved.
//  min:60 - Building perfect apps - https://min60.com


#import "PathUtils.h"

@implementation PathUtils

+(NSString*) docPathWithComponents: (NSString*) component, ... {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSMutableArray *components = [NSMutableArray arrayWithObject:documentsDirectory];
    
    va_list args;
    va_start(args, component);
    for (NSString *arg = component; arg != nil; arg = va_arg(args, NSString*)) {
        
        [components addObject:arg];
        
    }
    va_end(args);
    
    return [NSString pathWithComponents:components];
}

+(NSString*) bundlePath: (NSString*)filename {
    
    return [[NSBundle mainBundle] pathForResource:[filename stringByDeletingPathExtension] ofType:[filename pathExtension]];

}

+(NSString*) tmpPathWithComponents: (NSString*) component, ... {
    
    NSString *tmpDirectory = NSTemporaryDirectory();
    
    NSMutableArray *components = [NSMutableArray arrayWithObject:tmpDirectory];
    
    va_list args;
    va_start(args, component);
    for (NSString *arg = component; arg != nil; arg = va_arg(args, NSString*)) {
        
        [components addObject:arg];
        
    }
    va_end(args);
    
    return [NSString pathWithComponents:components];
}


+(NSString*) uniqueTmpFilePath: (NSString*)proposedFilename {
    
    NSString *baseFileName = [proposedFilename stringByDeletingPathExtension];
    NSString *ext = [proposedFilename pathExtension];
    
    NSUInteger i = 1;
    BOOL isDir = NO;
    
    NSString *proposedPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", baseFileName, ext]];
    
    while ([[NSFileManager defaultManager] fileExistsAtPath:proposedPath isDirectory:&isDir]) {
        
        i++;
        proposedPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%lu.%@", baseFileName, (unsigned long)i, ext]];
        
    }
   
    return proposedPath;

}

@end
