/* All rights reserved */

#include <AppKit/AppKit.h>
#import "Document.h"
#import "Rtf.h"
#import "Util.h"
#import "TextView.h"

@implementation Document

- (NSString *) windowNibName
{
	return @"Document.gorm";
}

- (id) init
{
	self = [super init];
	[historyWindow _setVisible:NO];
	return self;
}

- (BOOL) readFromData:(NSData *) data
	ofType:(NSString *) type 
	error:(NSError *) error
{
	return YES;
}

- (void) registerPasteboard
{
	[buffer registerForDraggedTypes:[NSArray arrayWithObjects:
		NSFilenamesPboardType
		,NSURLPboardType
		,NSDragPboard
		,NSStringPboardType
		,NSRTFDPboardType
		,NSRTFPboardType
		,nil]];
	[buffer draggingSourceOperationMaskForLocal:
		NSDragOperationCopy | NSDragOperationLink
		| NSDragOperationGeneric];
}

- (BOOL) readFromURL:(NSURL *) url
	ofType:(NSString *) type
	error:(NSError *) error
{
	Util *util = [[Util alloc] init];
	NSArray *parsedFile = [util parseFile: [url path]];
	fileToOpen = [parsedFile objectAtIndex:0];
	fileToOpen = [util validateFile:fileToOpen];
	argument = [parsedFile objectAtIndex:1];
	[util release];
	if (fileToOpen == nil)
		return NO;

	[self setDocumentPath:fileToOpen];
	return YES;
}

- (NSString *) loadContentFromFile: (NSString *)file
{
	Util *util = [[Util alloc] init];
	file = [util validateFile: file];
	[util release];
	if (file == nil)
		return nil;

	NSError *contentError = 0;
	NSString *content = [NSString
		stringWithContentsOfFile:file
		encoding:NSUTF8StringEncoding
		error:&contentError];
	if (contentError != nil) {
		contentError = 0;
		[NSString
			stringWithContentsOfFile:file
			encoding:NSNEXTSTEPStringEncoding
			error:&contentError];
	}

	if (contentError != nil) {
		return nil;
	}

	return content;
}

- (BOOL) loadDataRepresentation:(NSData *)data ofType:(NSString *)type
{
	if ([type isEqualToString:@"Rich Text"]) {
		NSData *newBufferContent = [[[NSData alloc] initWithData:
			data]
			autorelease];
		NSAttributedString *newBufferContentStr = 
			[[[NSAttributedString alloc] initWithRTF:
			newBufferContent documentAttributes:NULL]
			autorelease];
		stringRTFContent = [[NSMutableAttributedString alloc]
			init];
		[stringRTFContent appendAttributedString: newBufferContentStr];
	} else {
		stringContent = [[NSString alloc] initWithData:data
			encoding:NSUTF8StringEncoding];
		if (stringContent == nil) {
			stringContent = [[NSString alloc] initWithData:data
				encoding:NSNEXTSTEPStringEncoding];
		}
	}

	return YES;
}

- (void) awakeFromNib
{
	if (stringContent != nil) {
		[[buffer textStorage] beginEditing];
		[buffer setString: stringContent];
		[[buffer textStorage] endEditing];
		[stringContent release];
		stringContent = nil;
	}

	if (stringRTFContent != nil) {
		[[buffer textStorage] beginEditing];
		[[buffer textStorage] setAttributedString: stringRTFContent];
		[[buffer textStorage] endEditing];
		[stringRTFContent release];
		stringRTFContent = nil;
	}

	Util *util = [[Util alloc] init];
	if (fileToOpen != nil) {
		Rtf *rtf = [[Rtf alloc] init];
		[self setDocumentPath: fileToOpen];
		if ([[util getFileExtension:fileToOpen] isEqualToString:@"rtf"]) {
			[rtf loadDocumentRtf:[self getDocumentPath] view:buffer];
		} else {
			NSString *content = [self 
				loadContentFromFile:fileToOpen];
			if (content != nil) {
				[buffer setString:content];
			}
		}

		[rtf release];
	}

	if (![argument isEqualToString:@""]) {
		[util findContent:self content:argument];
	}

	[util release];
	if ([self getDocumentPath] != nil) {
		[[buffer window] setTitle: [self getDocumentPath]];
	}

	[[buffer window] makeFirstResponder:buffer];
	[[buffer window] setDocumentEdited:NO];
	[self registerPasteboard];
}

- (void) windowControllerDidLoadNib: (NSWindowController *) controller
{
	[buffer centerSelectionInVisibleArea:nil];
	[[buffer window] setTitle: [self getDocumentPath]];
	[self registerPasteboard];
	[[buffer window] makeFirstResponder:buffer];
}

- (void) openDocument: (id)sender
{
	Rtf *rtf = [[Rtf alloc] init];
	NSOpenPanel *openDialog = [NSOpenPanel openPanel];
	[openDialog runModal];
	NSString *res = [[openDialog filenames] objectAtIndex:0];
	if (res == nil)
		return;

	Util *util = [[Util alloc] init];
	res = [util validateFile:res];
	if (res == nil)
		return;

	[self setDocumentPath:res];
	if ([[util getFileExtension:[self getDocumentPath]] isEqualToString:@"rtf"]) {
		[rtf loadDocumentRtf:[self getDocumentPath] view:buffer];
	} else {
		NSString *content = [self loadContentFromFile:[self getDocumentPath]];
		if (content != nil) {
			[buffer setString:content];
		}
	}

	[[buffer window] makeFirstResponder:buffer];
	[[buffer window] setTitle: [self getDocumentPath]];
	[rtf release];
	[util release];
	[[buffer window] setDocumentEdited:NO];

}

- (void) saveDocument: (id)sender
{
	//[buffer breakUndoCoalescing];
	if ([self getDocumentPath] != nil) {
		Rtf *rtf = [[Rtf alloc] init];
		Util *util = [[Util alloc] init];
		if (![[util getFileExtension: [self getDocumentPath]] isEqualToString:@"rtf"]) {
			NSString *content = [buffer string];
			[content writeToFile:[self getDocumentPath] atomically:YES];
			[[buffer window] setTitle: [self getDocumentPath]];
		} else {
			[rtf saveDocumentRtf:[self getDocumentPath]
				view:buffer];
		}

		[rtf release];
		[util release];
	} else {
		[self saveDocumentAs:self];
	}

	[[buffer window] setDocumentEdited:NO];
}

- (void) saveDocumentAs: (id)sender
{
//	[buffer breakUndoCoalescing];
	NSSavePanel *openDialog = [NSSavePanel savePanel];
	[openDialog setCanCreateDirectories: YES];
	[openDialog runModal];
	NSURL *res = [openDialog URL];
	NSString *path = [res pathWithEscapes];
	Rtf *rtf = [[Rtf alloc] init];
	Util *util = [[Util alloc] init];
	if (![[util getFileExtension: [self getDocumentPath]] isEqualToString:@"rtf"]) {
		NSString *content = [buffer string];
		[content writeToFile:path atomically:YES];
	} else {
		[rtf saveDocumentRtf:path view:buffer];
	}

	[rtf release];
	[util release];
	[self setDocumentPath:path];
	[[buffer window] setTitle: [self getDocumentPath]];
	[[buffer window] setDocumentEdited:NO];
}

- (void) saved: (id)sender
{
	if ([self getDocumentPath] != nil) {
		NSString *content = [self loadContentFromFile:[self getDocumentPath]];
		if (content != nil) {
			[[buffer textStorage] beginEditing];
			[buffer setString: content];
			[[buffer textStorage] endEditing];
			[[buffer window] setDocumentEdited:NO];
		}
	} else {
		NSRunAlertPanel(_(@"Error"),
			_(@"Error: Document is not saved."),
			_(@"OK"), nil, nil);
	}
}

- (void) revertDocumentToSaved: (id)sender
{
	[self saved:sender];
}

- (BOOL)isDocumentEdited
{
	return [buffer isDocumentEdited];
}

- (id) getBuffer
{
	return buffer;
}

- (void)setDocumentPath:(NSString *)path
{
	[[buffer window] setRepresentedFilename: path];
}

- (NSString *)getDocumentPath
{
	return [[buffer window] representedFilename];
}

- (void) name: (id)sender
{
	NSString *name = [self getDocumentPath];
	if (name == nil) {
		NSRunAlertPanel(_(@"Error"),
			_(@"Error: Document have no name."),
			_(@"OK"), nil, nil);
		return;
	}
 
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	[pboard declareTypes: [NSArray arrayWithObjects: NSStringPboardType
		,NSFilenamesPboardType, nil]
		owner: nil];
	[pboard setString: name forType:NSStringPboardType];
	[pboard setString: name forType:NSFilenamesPboardType];
}

@end
