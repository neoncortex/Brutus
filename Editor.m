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
	logCommands = @"";
	timer = nil;
	task = nil;
	selectedLines = @"";
	tempFileName = @"/tmp/.brutus_temp";
	tempResult = @"/tmp/.brutus_command_result";
	tempScript = @"/tmp/.brutus_script.sh";
	registers = [[NSMutableArray alloc] initWithCapacity:5];
	locations = [[NSMutableArray alloc] initWithCapacity:5];
	[registers addObjectsFromArray:[NSArray arrayWithObjects:
		@"",@"",@"",@"",@"",nil]];
	[locations addObjectsFromArray:[NSArray arrayWithObjects:
		@"",@"",@"",@"",@"",nil]];
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

	[lastResult release];
	[lastCommand release];
	[logCommands release];
	for (NSString *s in registers)
		[s release];

	for (NSString *s in locations)
		[s release];

	[registers release];
	[locations release];
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

			if (([[newLine stringValue] isEqualToString: @"1"])
			&& (i < ([a count] -1))) {
				lines = [lines stringByAppendingString:
					@"\n"];
			}
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

	[buffer setDocumentEdited:YES];
	[util release];
}

- (void) registerLog: (NSString *) entry
{
	NSString *content = logCommands;
	content = [content stringByAppendingString:@"========\n"];
	content = [content stringByAppendingString:entry];
	content = [content stringByAppendingString:@"\n"];
	[logCommands release];
	logCommands = content;
	[logCommands retain];
}

- (NSMutableString *) substituteForCommand: (NSMutableString *)cm string:(NSString *)a
	withString:(NSString *)b
{
	NSError *regexError = 0;
	NSRegularExpression *regex = [NSRegularExpression
		regularExpressionWithPattern: a
		options:0
		error:&regexError];
	if (regexError)
		return cm;

	NSUInteger n = [regex numberOfMatchesInString: cm
		options:0
		range:NSMakeRange(0, [cm length])];

	int i;
	for (i = 0; i < n; i++) {
		NSRange r = [regex rangeOfFirstMatchInString:cm
			options:0
			range:NSMakeRange(0, [cm length])];
		[cm replaceCharactersInRange:r withString:b];
	}

	return cm;
}

- (NSMutableString*) substitutions: (NSMutableString *)cm fileName:(NSString *)f dir:(NSString *)d
{
	cm = [self substituteForCommand:cm string:@"\%file\%" withString:f];
	cm = [self substituteForCommand:cm string:@"\%dir\%" withString:d];
	cm = [self substituteForCommand:cm string:@"\%sel\%" withString:selectedLines];
	cm = [self substituteForCommand:cm string:@"\%r1\%" withString:[registers objectAtIndex:0]];
	cm = [self substituteForCommand:cm string:@"\%r2\%" withString:[registers objectAtIndex:1]];
	cm = [self substituteForCommand:cm string:@"\%r3\%" withString:[registers objectAtIndex:2]];
	cm = [self substituteForCommand:cm string:@"\%r4\%" withString:[registers objectAtIndex:3]];
	cm = [self substituteForCommand:cm string:@"\%r5\%" withString:[registers objectAtIndex:4]];
	return cm;
}

- (void) assembleEdScript: (NSString *)c
{
	NSString *dir = @"";
	NSString *fileName = [[[NSDocumentController sharedDocumentController]
		currentDocument] getDocumentPath];
	if ((fileName != nil) && (![fileName isEqualToString:@"Window"]))
		dir = [fileName stringByDeletingLastPathComponent];
	else {
		dir = [tempFileName stringByDeletingLastPathComponent];
		fileName = tempFileName;
	}

	NSMutableString *cm = [[NSMutableString alloc] initWithString:c];
	cm = [self substitutions:cm fileName:fileName dir:dir];
	NSString *shell = [NSString stringWithFormat:
		@"cd '%@' ; ed %@ << EOF\n%@\nw\nEOF"
		,dir
		,tempFileName
		,cm];
	[self registerLog:cm];
	[shell writeToFile:tempScript atomically:YES];
	[cm release];
}

- (void) assembleCommandScript: (NSString *)c
{
	BOOL noPipe = NO;
	if ([[c substringToIndex:1] isEqualToString: @"!"]) {
		c = [c substringFromIndex:1];
		noPipe = YES;
	}

	NSMutableString *cm = [[NSMutableString alloc] initWithString:c];
	NSString *dir = @"";
	NSString *fileName = [[[NSDocumentController sharedDocumentController]
		currentDocument] getDocumentPath];
	if ((fileName != nil) && (![fileName isEqualToString:@"Window"]))
		dir = [fileName stringByDeletingLastPathComponent];
	else {
		dir = [tempFileName stringByDeletingLastPathComponent];
		fileName = tempFileName;
	}

	cm = [self substitutions:cm fileName:fileName dir:dir];
	NSString *cmd = @"cd '%@'; cat '%@' | %@ 1> '%@' 2>> '%@' ; mv '%@' '%@'";
	NSString *shell = [NSString stringWithFormat:
		cmd
		,dir
		,tempFileName
		,cm
		,tempResult
		,tempResult
		,tempResult
		,tempFileName];

	if (noPipe) {
		cmd = @"cd '%@'; %@ 1> '%@' 2>> '%@' ; mv '%@' '%@'";
		shell = [NSString stringWithFormat:
			cmd
			,dir
			,cm
			,tempResult
			,tempResult
			,tempResult
			,tempFileName];
	}

	[self registerLog:cm];
	[shell writeToFile:tempScript atomically:YES];
	[cm release];
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
			[self registerLog:content];
		}

		[command setEditable:YES];
		[command setTextColor:[NSColor blackColor]];
		[self cleanCommand];
	}
}

- (void) editText: (int) action
{
	NSString *c = [command string];
	if ([c isEqualToString:@""])
		return;

	[command setEditable:NO];
	[command setTextColor:[NSColor lightGrayColor]];
	[lastCommand release];
	lastCommand = [[NSString alloc] initWithString: c];
	NSString *shell = @"/usr/bin/bash";
	[selectedLines release];
	selectedLines = [self filterContent:buffer];
	[selectedLines retain];
	[selectedLines writeToFile:tempFileName atomically:YES];
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

- (void) log: (id) sender
{
	[command setString:logCommands];
}

- (void) setValue:(id)sender for:(int)item
{
	NSRange range = [command selectedRange];
	NSString *selection = [[command string]
		substringWithRange:
		NSMakeRange(range.location,
		range.length)];
	if (selection.length == 0) {
		range = [buffer selectedRange];
		selection = [[buffer string]
			substringWithRange:
			NSMakeRange(range.location,
			range.length)];
	}

	NSMutableArray *a = nil;
	switch(item) {
	case 0:
		a = registers;
		break;
	case 1:
		a = locations;
		break;
	}

	if (a != nil) {
		[[a objectAtIndex:[sender tag]] release];
		[a replaceObjectAtIndex:[sender tag] withObject:selection];
		[[a objectAtIndex:[sender tag]] retain];
	}
}

- (void) showRegisters: (id)sender
{
	[command setString:[NSString stringWithFormat:
		@"registers:\n1:%@\n2:%@\n3:%@\n4:%@\n5:%@\n"
		,[registers objectAtIndex:0]
		,[registers objectAtIndex:1]
		,[registers objectAtIndex:2]
		,[registers objectAtIndex:3]
		,[registers objectAtIndex:4]]];
}

- (void) setRegister: (id)sender
{
	[self setValue:sender for:0];
}

- (void) getRegister: (id)sender
{
	[self replaceContent:[registers objectAtIndex:[sender tag]]];
}

- (void) showLocations: (id)sender
{
	[command setString:[NSString stringWithFormat:
		@"locations:\n1:%@\n2:%@\n3:%@\n4:%@\n5:%@\n"
		,[locations objectAtIndex:0]
		,[locations objectAtIndex:1]
		,[locations objectAtIndex:2]
		,[locations objectAtIndex:3]
		,[locations objectAtIndex:4]]];
}

- (void) setLocation: (id)sender
{
	[self setValue:sender for:1];
}

- (void) goToLocation: (id)sender
{
	Util *util = [[Util alloc] init];
	id d = [[NSDocumentController sharedDocumentController]
		currentDocument];
	[util findContent:d content:[locations objectAtIndex:[sender tag]]];
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
