#import <Cocoa/Cocoa.h>

@interface WindowController : NSWindowController<NSWindowDelegate>
{
	IBOutlet NSButton* buttonSetId;
	IBOutlet NSButton* buttonApply;
	IBOutlet NSButton* buttonBrowse;
	IBOutlet NSTableView* tableView;
	
	IBOutlet NSTextField* fieldCurrentFile;
	IBOutlet NSTextField* fieldLibraryId;
	
	IBOutlet NSArrayController* tableContentArray;
}

-(void)loadFile:(NSString*)path;
-(void)onBrowse;
@end
