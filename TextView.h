/* All rights reserved */

#include <AppKit/AppKit.h>

@interface TextView : NSTextView
{
@private
	BOOL isShiftPressed;
	BOOL edited;
}

- (BOOL) isDocumentEdited;
- (void) setDocumentEdited: (BOOL) flag;
@end
