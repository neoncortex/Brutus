/* All rights reserved */

#include <AppKit/AppKit.h>
#import <AppKit/NSDocument.h>

@interface Document : NSDocument
{
	id buffer;
	id command;
	id keep;
	id editor;
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
- (void) showRegisters: (id)sender;
- (void) getRegister: (id)sender;
- (void) setRegister: (id)sender;
- (void) showLocations: (id)sender;
- (void) goToLocation: (id)sender;
- (void) setLocation: (id)sender;

@end
