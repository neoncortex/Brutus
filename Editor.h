/* All rights reserved */

#include <AppKit/AppKit.h>

@interface Editor : NSObject
{
	id buffer;
	id command;
	id keep;
	id show;
@private
	NSString *tempFileName;
	NSString *tempResult;
	NSString *tempScript;
	NSString *lastCommand;
	NSString *lastResult;
	NSTimer *timer;
	NSTask *task;
}

- (void) editEd: (id)sender;
- (void) editCmd: (id)sender;
- (void) stop: (id)sender;
- (void) clean: (id)sender;
- (void) last: (id)sender;
- (void) result: (id)sender;
- (void) match: (id)sender;
- (void) openFromCommandAreaSelection: (id)sender;

@end
