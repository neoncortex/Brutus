/* All rights reserved */

#include <AppKit/AppKit.h>

@interface NSTextViewCustom : NSTextView
{
@private
	BOOL edited;
	BOOL isShiftPressed;
}
- (BOOL) dirty;
- (void) setDirty:(BOOL) flag;

@end
