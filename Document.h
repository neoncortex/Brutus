/* All rights reserved */

#include <AppKit/AppKit.h>
#import <AppKit/NSDocument.h>

@interface Document : NSDocument
{
	id buffer;
	id command;
	id keep;
	id historyWindow;
@private
	id fileToOpen;
	id argument;
	id stringContent;
	id stringRTFContent;
}

- (NSString *)loadContentFromFile: (NSString *)file;
- (void) openDocument: (id)sender;
- (void) saveDocument: (id)sender;
- (void) saveDocumentAs: (id)sender;
- (void) saved: (id)sender;
- (BOOL) isDocumentEdited;
- (id) getBuffer;
- (void) setDocumentPath: (NSString *)path;
- (NSString *) getDocumentPath;
- (void) name: (id) sender;

@end
