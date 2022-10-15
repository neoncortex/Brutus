/* All rights reserved */

#include <AppKit/AppKit.h>
#import "Editor.h"
#import "TextView.h"
#import "Util.h"
#import "Document.h"

@implementation Editor

- (id)init
{
	self = [super init];
	[NSApp setServicesProvider:self];
	lastCommand = @"";
	lastResult = @"";
	timer = nil;
	task = nil;
	tempFileName = @"/tmp/.brutus_temp";
	tempResult = @"/tmp/.brutus_command_result";
	tempScript = @"/tmp/.brutus_script.sh";
	return self;
}

- (void)dealloc
{
	if (task != nil) {
		[task terminate];
		[task release];
	}

	if (timer != nil)
		[timer invalidate];

	[super dealloc];
}

- (void) cleanCommand
{
	if (![[keep stringValue] isEqualToString: @"1"])
		[command setString: @""];
}

- (NSString *) filterContent: (id)area
{
	NSRange range = [area selectedRange];
	NSString *lines = @"";
	if (range.length == 0) {
		lines = [area string];
	} else {
		int i;
		NSArray *a = [[[area string]
			substringWithRange:
			NSMakeRange(range.location,
			range.length)]
			componentsSeparatedByString: @"\n"];
		for (i = 0; i < [a count]; ++i) {
			lines = [lines stringByAppendingString:
				[a objectAtIndex:i]];
			lines = [lines stringByAppendingString:
				@"\n"];
		}
	}

	return lines;
}

- (void) replaceContent:(NSString *)content
{
	if ([[show stringValue] isEqualToString: @"1"]) {
		if (![[keep stringValue] isEqualToString: @"1"])  {
			[keep setNextState];
		}

		[[command textStorage] beginEditing];
		[command setString: content];
		[[command textStorage] endEditing];
		return;
	}

	NSRange newRange = [buffer selectedRange];
	if (newRange.length == 0)  {
		newRange = NSMakeRange(0, [[buffer string] length]);
	}

	NSString *fileName = [[buffer window] representedFilename];
	Util *util = [[Util alloc] init];
	if (fileName != nil && [[util getFileExtension:fileName] isEqual: @"rtf" ]) {
		NSData *bufferContent = [[[NSData alloc] initWithData:
			[buffer RTFFromRange:NSMakeRange(0,
			[[buffer textStorage] length])]]
			autorelease];
		NSAttributedString *bufferContentStr = 
			[[[NSAttributedString alloc] initWithRTF:
			bufferContent documentAttributes:NULL]
			autorelease];
		NSUndoManager *undo = [buffer undoManager];
		[undo registerUndoWithTarget:[buffer textStorage]
			selector:@selector(setAttributedString:)
			object:bufferContentStr];
		NSData *newBufferContent = [[[NSData alloc] initWithData:
			[buffer RTFFromRange:NSMakeRange(0,
			[[buffer textStorage] length])]]
			autorelease];
		NSAttributedString *newBufferContentStr = 
			[[[NSAttributedString alloc] initWithRTF:
			newBufferContent documentAttributes:NULL]
			autorelease];
		NSMutableAttributedString *result = [[[NSMutableAttributedString alloc]
			init] autorelease];
		[result appendAttributedString: newBufferContentStr];
		[result replaceCharactersInRange: newRange withString: content];
		[[buffer textStorage] beginEditing];
		[[buffer textStorage] setAttributedString: result];
		[[buffer textStorage] endEditing];
	} else {
		NSString *oldContent = [[[NSString alloc] initWithString:[buffer string]]
			autorelease];
		NSUndoManager *undo = [buffer undoManager];
		[undo registerUndoWithTarget:self
			selector:@selector(replaceContent:)
			object:oldContent];
		[[buffer textStorage] beginEditing];
		[[buffer textStorage] replaceCharactersInRange:newRange
			withString:content];
		[[buffer textStorage] endEditing];
	}

	[[[buffer window] windowController] setDocumentEdited:YES];
	[buffer setDirty:YES];
	[util release];
}

- (void) assembleEdScript: (NSString *)c
{
	NSString *dir = @"";
	NSString *fileName = [[buffer window] representedFilename];
	if (fileName != nil)
		dir = fileName;
	else
		dir = tempFileName;

	NSString *shell = [NSString stringWithFormat:
		@"cd \"$(dirname %@)\" ; ed %@ << EOF\n%@\nw\nEOF"
		,dir
		,tempFileName
		,c
	];
	[shell writeToFile:tempScript atomically:YES];
}

- (void) assembleCommandScript: (NSString *)c
{
	NSString *dir = @"";
	NSString *fileName = [[buffer window] representedFilename];
	if (fileName != nil)
		dir = fileName;
	else
		dir = tempFileName;

	NSString *shell = [NSString stringWithFormat:
		@"cd \"$(dirname %@)\"; cat '%@' | %@ 1> %@ 2>> %@ ; mv %@ %@"
		,dir
		,tempFileName
		,c
		,tempResult
		,tempResult
		,tempResult
		,tempFileName
	];
	[shell writeToFile:tempScript atomically:YES];
 }

- (void) isTaskFinished
{
	if(![task isRunning]) {
		[task release];
		[timer invalidate];
		task = nil;
		timer = nil;
		id document = [[NSDocumentController sharedDocumentController]
			currentDocument];
		NSString *content = [document loadContentFromFile: tempFileName];
		if (content != nil) {
			[lastResult release];
			[content retain];
			lastResult = content;
			[self replaceContent:content];
		}

		[command setEditable:YES];
		[command setTextColor:[NSColor blackColor]];
		[self cleanCommand];
	}
}

- (void) editText: (int) action
{
	[command setEditable:NO];
	[command setTextColor:[NSColor lightGrayColor]];
	NSString *c = [command string];
	[lastCommand release];
	lastCommand = [[NSString alloc] initWithString: c];
	NSString *shell = @"/usr/bin/bash";
	NSString *lines = [self filterContent:buffer];
	[lines writeToFile:tempFileName atomically:YES];
	if (action == 1)
		[self assembleEdScript:c];
	else if (action == 2)
		[self assembleCommandScript:c];
	else
		return;

	task = [[NSTask alloc] init];
 	NSArray *arg = [NSArray arrayWithObjects:
		tempScript
		,nil];
	[task setLaunchPath:shell];
	[task setArguments:arg];
	[task launch];
	timer = [NSTimer scheduledTimerWithTimeInterval:0.5
		target:self
		selector:@selector(isTaskFinished)
		userInfo:nil
		repeats:YES];
}

- (void) editEd: (id)sender
{
	[self editText: 1];
}

- (void) editCmd: (id)sender
{
	[self editText: 2];
}

- (void) stop: (id)sender
{
	if((task != nil) && ([task isRunning])) {
		[task terminate];
		[task release];
		[timer invalidate];
		task = nil;
		timer = nil;
		[self cleanCommand];
		[command setEditable:YES];
		[command setTextColor: [NSColor blackColor]];
	}
}

- (void) clean: (id)sender
{
	[command setString: @""];
}

- (void) last: (id)sender
{
	[command setString: lastCommand];
}

- (void) result: (id)sender
{
	[command setString: lastResult];
}

- (void) performService:(NSArray *)a
{
	int i;
	for (i = 0; i < [a count]; ++i) {
		if ([[a objectAtIndex:i] isEqualToString: @""])
			break;

		NSPasteboard *p = [NSPasteboard pasteboardWithUniqueName];
		[p declareTypes: [NSArray arrayWithObject: NSStringPboardType]
			owner: nil];
		[p setString: [a objectAtIndex:i] forType:NSStringPboardType];
		NSPerformService(@"Brutus", p);
	}
}

- (void) openFromCommandAreaSelection: (id)sender
{
	NSRange range = [command selectedRange];
	NSArray *a = [[[command string]
		substringWithRange:
		NSMakeRange(range.location,
		range.length)]
		componentsSeparatedByString: @"\n"];
	[self performService:a];
}

- (void) match:(id)sender
{
	NSRange range = [command selectedRange];
	NSString *selection = [[command string]
		substringWithRange:
		NSMakeRange(range.location,
		range.length)];
	id d = [[NSDocumentController sharedDocumentController]
		currentDocument];
	Util *util = [[Util alloc] init];
	[util findContent:d content:selection];
	[util release];
}

- (void) openFileWithPattern:(NSPasteboard *)pboard userData:(NSString *)
	userData error:(NSString **)error
{
	id input = [pboard
		stringForType:NSStringPboardType];

	if (input == nil) {
		input = [pboard
			propertyListForType: NSFilenamesPboardType];
		if (input == nil)
			return;

		[self performService:input];
		return;
	}

	Util *util = [[Util alloc] init];
	NSArray *parsedFile = [util parseFile:input];
	if (parsedFile == nil)
		return;

	NSString *filePath = [parsedFile objectAtIndex:0];
	NSString *argument = [parsedFile objectAtIndex:1];
	filePath = [util validateFile:filePath];
	if (filePath == nil)
		return;

	id d = [[NSDocumentController sharedDocumentController]
		openDocumentWithContentsOfFile:filePath
		display:YES];
	[d setDocumentPath: filePath];
	if (![argument isEqualToString:@""]) {
		[util findContent:d content:argument];
	}

	[util release];
}

@end
