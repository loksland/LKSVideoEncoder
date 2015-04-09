
#import <Foundation/Foundation.h>

@interface PathUtils : NSObject

+(NSString*) docPathWithComponents: (NSString*) component, ...
NS_REQUIRES_NIL_TERMINATION;

+(NSString*) tmpPathWithComponents: (NSString*) component, ...
NS_REQUIRES_NIL_TERMINATION;

+(NSString*) bundlePath: (NSString*)fileName;

+(NSString*) uniqueTmpFilePath: (NSString*)proposedFilename;

@end