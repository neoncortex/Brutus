/* All rights reserved */

#include <AppKit/AppKit.h>

@interface Editor : NSObject
{
	id buffer;
	id command;
	id keep;
	id show;
	id newLine;
@private
	NSString *selectedLines;
	NSString *tempFileName;
	NSString *tempResult;
	NSString *tempScript;
	NSString *lastCommand;
	NSString *lastResult;
	NSString *logCommands;
	NSTimer *timer;
	NSTask *task;
	NSMutableArray *registers;
	NSMutableArray *locations;
}

- (void) editEd: (id)sender;
- (void) editCmd: (id)sender;
- (void) stop: (id)sender;
- (void) clean: (id)sender;
- (void) last: (id)sender;
- (void) result: (id)sender;
- (void) match: (id)sender;
- (void) log: (id)sender;
- (void) openFromCommandAreaSelection: (id)sender;
- (void) showRegisters: (id)sender;
- (void) getRegister: (id)sender;
- (void) setRegister: (id)sender;
- (void) showLocations: (id)sender;
- (void) goToLocation: (id)sender;
- (void) setLocation: (id)sender;
@end
