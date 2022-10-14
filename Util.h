#include <AppKit/AppKit.h>

@interface Util : NSObject
{
}

- (NSString *) getFileExtension:(NSString *)fileName;
- (NSString *) validateFile:(NSString *)file;
- (NSArray *) parseFile:(NSString *)input;
- (void) goToLine:(id)buf number:(NSString *)argument;
- (void) goToContent:(id)buf content:(NSString *)argument;
- (void) findContent:(id)document content:(NSString *)argument;

@end
