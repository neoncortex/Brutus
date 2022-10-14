#include "Service.h"

@implementation Service

+ (void) initialize
{
	NSArray *sendTypes = [NSArray 
		arrayWithObjects:NSStringPboardType,
		NSFilenamesPboardType, nil];
	NSArray *returnTypes = [NSArray 
		arrayWithObjects:NSStringPboardType,
		nil];
	[NSApp registerServicesMenuSendTypes:sendTypes
		returnTypes: returnTypes];
}

- (void) performService:(NSString *)service board:(NSPasteboard *)pboard
{
	NSPerformService(service, pboard);
}

@end
