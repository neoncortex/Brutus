#include <AppKit/AppKit.h>

@interface Service : NSObject
{
}

+ (void) initialize;
- (void) performService:(NSString *)service board: (NSPasteboard *)pboard;

@end