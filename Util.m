#include <AppKit/AppKit.h>
#import "Util.h"
#import "Document.h"

@implementation Util

- (NSString *) getFileExtension:(NSString *)fileName
{
	int i = 0;
	for (i = [fileName length] - 1; i > 0; --i) {
		if ([fileName characterAtIndex:i] == '.') {
			break;
		}
	}

	if (i != 0) {
		return [fileName substringFromIndex:i+1];
	}

	return @"no extension";
}

- (NSString *) validateFile:(NSString *) file
{
	if (file == nil)
		return nil;

	if ([file substringFromIndex:[file length] -1] == @"\n")
		file = [file substringToIndex:[file length] -1];

	if ([file substringToIndex:1] == @"~")
		file = [file stringByExpandingTildeInPath];

	NSFileManager *fm = [NSFileManager defaultManager];
	if (!([fm fileExistsAtPath:file])
		|| (![[file substringToIndex:1] isEqualToString: @"/"]))
	{
		NSString *documentPath = [[[NSDocumentController
			sharedDocumentController] currentDocument]
			getDocumentPath];
		if (documentPath != nil) {
			NSString *dir = [documentPath
				stringByDeletingLastPathComponent];
			dir = [dir stringByAppendingString: @"/"];
			file = [dir stringByAppendingString: file];
		}
	}

	if (![fm fileExistsAtPath:file]) {
		NSRunAlertPanel(_(@"Error"),
			_(@"Error: File does not exist."),
			_(@"OK"), nil, nil);
		return nil;
	}

	if (![fm isReadableFileAtPath:file]) {
		NSRunAlertPanel(_(@"Error"),
			_(@"Error: File can't be read."),
			_(@"OK"), nil, nil);
		return nil;
	}

	NSError *fileError = 0;
	NSDictionary *dict = [fm attributesOfItemAtPath:file
		error:&fileError];
	if (fileError) {
		NSRunAlertPanel(_(@"Error"),
			_(@"Error: Error while loading file attributes."),
			_(@"OK"), nil, nil);
		return nil;
	}

	if ([dict fileType] != NSFileTypeRegular) {
		NSRunAlertPanel(_(@"Error"),
			_(@"Error: Invalid file."),
			_(@"OK"), nil, nil);
		return nil;
	}

	NSError *contentError = 0;
	[NSString
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
		NSLog(@"%@", [contentError localizedDescription]);
		NSRunAlertPanel(_(@"Error"),
			_(@"Error: Unrecognized file encoding."),
			_(@"OK"), nil, nil);
		return nil;
	}

	return file;
}

- (NSArray *)parseFile:(NSString *)input
{
	if (input == nil)
		return nil;

	NSString *argument = @"";
	NSString *filePath = input;
	int i, dotIndex = 0, escape = 0;
	for (i = 0; i < [input length] -1; ++i) {
		if ([input characterAtIndex:i] == '\\') {
			escape = 1;
		}

		if ([input characterAtIndex:i] == ':') {
			if (escape == 0) {
				dotIndex=i;
				break;
			}

			escape = 0;
		}
	}

	if (dotIndex != 0) {
		NSString *filePathNoDot = [filePath substringToIndex:i];
		argument = [filePath substringFromIndex:i + 1];
		filePath = filePathNoDot;
	} 

	return [NSArray arrayWithObjects: filePath, argument, nil];
}

- (void) goToLine:(id)buf number:(NSString *)argument
{
	NSArray *a = [[buf string]
		componentsSeparatedByString: @"\n"];
	int argumentInt = [argument intValue];
	NSUInteger offset = 0;
	int i;
	for (i = 0; i < [a count]; ++i) {
		if (i == (argumentInt - 1)) {
			NSRange lineRange = NSMakeRange(offset,
				[[a objectAtIndex:i] length]);
 			 [buf setSelectedRange: lineRange];
 			 [buf scrollRangeToVisible: lineRange];
			break;
		} else {
			offset += [[a objectAtIndex:i] length] + 1;
		}
	}
}

- (void) goToContent:(id)buf content:(NSString *)argument
{
	NSString *content = [buf string];
	int i;
	for (i = 0; i < [content length] - [argument length]; ++i) {
		NSRange r = NSMakeRange(i
			,[argument length]);
		NSString *s = [content substringFromRange:r];
		if ([s isEqualToString: argument]) {
			[buf setSelectedRange: r];
			[buf scrollRangeToVisible: r];
			break;
		}
	}

}

- (void) findContent:(id)document content:(NSString *)argument
{
	if (argument == nil)
		return;

	id buf = [document getBuffer];
	NSError *regexError = 0;
	NSRegularExpression *argumentIsNumber = [NSRegularExpression
		regularExpressionWithPattern: @"^[0-9]+$"
		options:0
		error:&regexError];
	if (regexError)
		return;

	NSUInteger match = [argumentIsNumber numberOfMatchesInString:argument
		options:0
		range:NSMakeRange(0, [argument length])];
	if (match) {
		[self goToLine:buf number:argument];
	} else {
		[self goToContent:buf content:argument];
	}
}
@end
