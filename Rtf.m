#include <AppKit/AppKit.h>
#import "Rtf.h"

@implementation Rtf

- (void) loadDocumentRtf: (NSString *)fileName view:(NSTextView *)buffer
{
	[buffer readRTFDFromFile: fileName];
}

- (void) saveDocumentRtf: (NSString *)fileName view:(NSTextView *)buffer
{
	NSRange range = NSMakeRange(0, [[buffer textStorage] length]);
	[[buffer RTFFromRange: range] writeToFile: 
		fileName atomically: YES];
}

@end
