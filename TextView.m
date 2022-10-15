/* All rights reserved */

#include <AppKit/AppKit.h>
#import "TextView.h"
#import "Util.h"
#import "Editor.h"

@implementation TextView

- (id)init
{
	self = [super init];
	edited = NO;
	isShiftPressed = NO;
	return self;
}

- (BOOL) isOpaque
{
	return YES;
}

- (NSString *) assemblePlainDroppedFilesString: (NSArray *) files
{
	int i;
	NSString *result = @"";
	for (i = 0; i < [files count]; ++i) {
		NSLog([files objectAtIndex:i]);
		NSRange selection = [self selectedRange];
		NSString *content = nil;
		if (isShiftPressed == YES) {
			content = [files objectAtIndex:i];
		} else {
			content = [NSString stringWithContentsOfFile:
				[files objectAtIndex:i]];
		}

		NSString *bufferContent = [self string];
		NSString *head = [bufferContent substringToIndex:selection.location];
		NSString *tail = [bufferContent substringFromIndex:selection.location];
		result = [result stringByAppendingString:
			 [NSString stringWithFormat: @"%@%@%@"
				,head
				,content
				,tail]];
	}

	return result;
}

- (NSMutableAttributedString *) assembleRtfDroppedFilesString: files
{
	NSRange selection = [self selectedRange];
	NSData *bufferContent = [[[NSData alloc] initWithData:
		[self RTFFromRange:NSMakeRange(0, [[self textStorage] length])]]
		autorelease];
	NSData *content = nil;
	NSAttributedString *bufferContentStr = [[[NSAttributedString alloc] initWithRTF:
		bufferContent documentAttributes:NULL] autorelease];
	NSAttributedString *contentStr = nil;
	int i;
	Util *util = [[Util alloc] init];
	for (i = 0; i < [files count]; ++i) {
		if (isShiftPressed == YES) {
 			contentStr = [[[NSAttributedString alloc]
				initWithString: [files objectAtIndex:i]]
				autorelease];
		} else {
			content = [[[NSData alloc] initWithContentsOfFile:
				[files objectAtIndex:i]] autorelease];
	
			if (![[util getFileExtension:[files objectAtIndex:i]] isEqual: @"rtf" ]) {
				NSString *c = [[[NSString alloc] initWithData:
				content encoding:NSUTF8StringEncoding]
				autorelease]; 
	
				contentStr = [[[NSAttributedString alloc]
				initWithString: c] autorelease];
			} else {
				contentStr = [[[NSAttributedString alloc]
				initWithRTF: content
				documentAttributes:NULL] autorelease];
			}
		}
	}

	[util release];
	NSMutableAttributedString *result = [[[NSMutableAttributedString alloc] init]
		autorelease];
	[result appendAttributedString: bufferContentStr];
	[result replaceCharactersInRange: selection withAttributedString: contentStr];
	return result;
}

- (void) copyToPlainBuffer: (NSArray *) files
{
	[[self textStorage] beginEditing];
	[self setString: [self assemblePlainDroppedFilesString: files]];
	[[self textStorage] endEditing];
}

- (void) copyToRtfBuffer: (NSArray *) files
{
	[[self textStorage] beginEditing];
	[[self textStorage] setAttributedString: [self assembleRtfDroppedFilesString:files]];
	[[self textStorage] endEditing];
}

- (void) copyToBuffer: (NSArray *) files
{
	NSString *fileName = [[self window] representedFilename];
	Util *util = [[Util alloc] init];
	if ([[util getFileExtension:fileName] isEqual: @"rtf" ]) {
		[self copyToRtfBuffer:files];
	} else {
		[self copyToPlainBuffer:files];
	}

	[util release];
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
	NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	NSPasteboard *pboard = [sender draggingPasteboard];
	if (([[pboard types] containsObject:NSFilenamesPboardType])
		&& (sourceDragMask & NSDragOperationCopy))
	{
		NSArray *files = [pboard propertyListForType:
			NSFilenamesPboardType];
		NSUndoManager *undo = [self undoManager];
/*
		NSString *oldContent = [[[NSString alloc]
			initWithString:[self string]] autorelease];
*/
		NSData *bufferContent = [[[NSData alloc] initWithData:
			[self RTFFromRange:NSMakeRange(0,
			[[self textStorage] length])]]
			autorelease];
		NSAttributedString *bufferContentStr = 
			[[[NSAttributedString alloc] initWithRTF:
			bufferContent documentAttributes:NULL]
			autorelease];
/*
		[undo registerUndoWithTarget:self
			selector:@selector(setString:)
			object:oldContent];
*/
		[undo registerUndoWithTarget:[self textStorage]
			selector:@selector(setAttributedString:)
			object:bufferContentStr];
		[self copyToBuffer:files];
	} else if (sourceDragMask & NSDragOperationGeneric) {
		[super performDragOperation:sender];
	}

	edited=YES;
	[[self window] setDocumentEdited:YES];
	return YES;
}

- (BOOL) dirty
{
	return edited;
}

- (void) setDirty:(BOOL) flag
{
	edited=flag;
}

- (void) insertText: (id)sender
{
	edited=YES;
	[super insertText:sender];
}

- (void) deleteBackward:(id)sender
{
	edited=YES;
	[super deleteBackward:sender];
}

- (void) deleteForward:(id)sender
{
	edited=YES;
	[super deleteForward:sender];
}

- (void) cut:(id)sender
{
	edited=YES;
	[super cut:sender];
}

- (void) paste:(id)sender
{
	edited = YES;
	[super paste:sender];
}

- (void) flagsChanged:(NSEvent *)event
{
	if ([event modifierFlags] & NSShiftKeyMask) {	
		isShiftPressed = YES;
	} else {
		isShiftPressed = NO;
	}
}

@end
