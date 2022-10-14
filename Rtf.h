#include <AppKit/AppKit.h>

@interface Rtf: NSObject
{
}
- (void) loadDocumentRtf: (NSString *)fileName view:(NSTextView *)buffer;
- (void) saveDocumentRtf: (NSString *)fileName view:(NSTextView *)buffer;

@end
