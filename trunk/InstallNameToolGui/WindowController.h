#import <Cocoa/Cocoa.h>

@interface WindowController : NSWindowController<NSWindowDelegate, NSTableViewDelegate>
{
	IBOutlet NSButton* buttonSetId;
	//IBOutlet NSButton* buttonRevert;
	IBOutlet NSButton* buttonApply;
	IBOutlet NSButton* buttonBrowse;
	IBOutlet NSButton* buttonSetToCurrentPath;
	IBOutlet NSButton* buttonSetAllToPathToThis;
	IBOutlet NSTableView* tableView;
	
	IBOutlet NSTextField* fieldCurrentFile;
	IBOutlet NSTextField* fieldLibraryId;
	
	IBOutlet NSArrayController* tableContentArray;
@public
	BOOL isFirst;
}

-(void)loadFile:(NSString*)path;

@end
