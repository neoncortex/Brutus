#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#include "Service.h"

int
main(int argc, const char *argv[])
{
	id pool = [[NSAutoreleasePool alloc] init];
	NSApplication *app = [NSApplication sharedApplication];
	Service *s = [[Service alloc] init];
	NSPasteboard *p = [NSPasteboard pasteboardWithUniqueName];
	NSString *arg = [NSString stringWithCString: argv[1]];
	[p declareTypes: [NSArray arrayWithObject: NSStringPboardType]
		owner: nil];
	[p setString: arg forType:NSStringPboardType];
	[s performService: @"Brutus" board: p];
	[s release];
	[app stop:nil];
	[pool release];
	return 0;
}

