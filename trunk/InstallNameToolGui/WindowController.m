#import "WindowController.h"
#import "AppDelegate.h"

@interface WindowController()
@property (assign) BOOL observerIsSet;
@property (retain) NSMutableArray* cachedContent;

@end

@implementation WindowController

@synthesize observerIsSet, cachedContent=_cachedContent;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
//		[window setReleasedWhenClosed:YES];
	}
    
    return self;
}

-(void)windowWillClose:(NSNotification *)notification
{
	if (isFirst)
	[NSApp terminate:nil];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	assert(self.window);
	self.window.delegate = self;

	[buttonBrowse setTarget:self];
	[buttonBrowse setAction:@selector(onBrowse)];
	
	/*[buttonRevert setTarget:self];
	 [buttonRevert setAction:@selector(onRevert)];*/
	
	[tableView setTarget:self];
	[tableView setDoubleAction:@selector(doubleClick:)];
	
	[buttonSetId setTarget:self];
	[buttonSetId setAction:@selector(onSetId)];
	
	NSMutableDictionary* bindingOptions = [NSMutableDictionary dictionary];
	[bindingOptions setObject:[NSNumber numberWithBool:NO] forKey:NSCreatesSortDescriptorBindingOption];
	
	NSTableColumn* c1 = [tableView tableColumnWithIdentifier:@"path"];
	assert(c1);
	[c1 bind:@"value" toObject:tableContentArray withKeyPath:@"arrangedObjects.path" options:bindingOptions];
	
}

-(void)doubleClick:(id)object
{
	NSInteger row = [tableView clickedRow];
	NSLog(@"clicked %d", (int)row);
	[tableView editColumn:0 row:row withEvent:nil select:YES];
}

-(NSString*)extractLibPath:(NSString*)line
{
	NSString* result = [[line componentsSeparatedByString:@"("] objectAtIndex:0];
	return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}


-(void)onSetId
{
	if (fieldLibraryId.stringValue.length < 1)
		return;
	
	NSString* cmd = [NSString stringWithFormat:@"install_name_tool -id %@ %@", fieldLibraryId.stringValue,
																			fieldCurrentFile.stringValue];
	system(cmd.UTF8String);
	
	[self loadFile:fieldCurrentFile.stringValue];
}

-(void)loadFile:(NSString*)path
{
	fieldCurrentFile.stringValue = path;
	
	[tableContentArray removeObjects:[tableContentArray arrangedObjects]];
	
	//[tableView setNeedsDisplay];
	NSString* outFile = @"/tmp/otool_out.txt";
	
	system("rm -f /tmp/otool_out.txt");
	
	NSString* cmd = [NSString stringWithFormat:@"otool -L '%@' > %@", path, outFile];
	system(cmd.UTF8String);
	
	NSString* filestring = [NSString stringWithContentsOfFile:outFile encoding:NSUTF8StringEncoding error:nil];
	NSArray* lines = [filestring componentsSeparatedByString:@"\n"];
	
	if (observerIsSet) {
		[tableContentArray removeObserver:self forKeyPath:@"arrangedObjects"];
		[tableContentArray removeObserver:self forKeyPath:@"arrangedObjects.path"];
	}
	
	BOOL isDylib = [path hasSuffix:@"dylib"];
	
	[fieldLibraryId setEnabled:isDylib];
	[buttonSetToCurrentPath setEnabled:isDylib];
	[buttonSetAllToPathToThis setEnabled:isDylib];
	[buttonSetId setEnabled:isDylib];
	
	if (isDylib) {
		NSString* libid = [lines objectAtIndex:1];
		fieldLibraryId.stringValue = [self extractLibPath:libid];
	}
	
	if (!self.cachedContent)
		self.cachedContent = [NSMutableArray array];
	
	[self.cachedContent removeAllObjects];
	
	for (int i = (isDylib)? 2 : 1; i < lines.count; i++) {
		NSString* p = [self extractLibPath:[lines objectAtIndex:i]];
		if (p.length > 1) {
			NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:p, @"path", nil];
			[tableContentArray addObject: dict];
			[self.cachedContent addObject:p];
		}
	}
	
	//NSLog(@"%@", filestring);
	
	[tableContentArray addObserver:self forKeyPath:@"arrangedObjects" options:0 context:nil];
    [tableContentArray addObserver:self forKeyPath:@"arrangedObjects.path" options:0 context:nil];
	observerIsSet = YES;
}

/*-(void)onRevert
{
	[self loadFile:fieldCurrentFile.stringValue ];
}
*/

-(void)onBrowse
{		
	NSOpenPanel* p = [NSOpenPanel openPanel];
	[p setTreatsFilePackagesAsDirectories:YES];
	[p setAllowsMultipleSelection:YES];
	if ([p runModal] == NSOKButton) {
		
		NSArray* files = [p URLs];
		NSURL* file = [files objectAtIndex:0];
		fieldCurrentFile.stringValue = file.path;
		[self loadFile:file.path];

		int i = 0;
		for (NSURL* url in files) {
			if (i++ < 1)
				continue;
			
			[((AppDelegate*)[NSApp delegate]) openNewWindow:url.path];
		}
	}
}

-(void)installNameChangeFile:(NSString*)file from:(NSString*)oldPath to:(NSString*)newPath
{
	if (file.length < 1 || oldPath.length < 1 || newPath.length < 1)
		return;
	
	if ([oldPath isEqualToString:newPath])
		return;
	
	NSString* cmd = [NSString stringWithFormat:@"install_name_tool -change '%@' '%@' '%@' ", oldPath, newPath, file];
	system(cmd.UTF8String);
	[self loadFile:file];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
 	if ([tableContentArray selectionIndex] == NSNotFound)
		return;
	
	NSDictionary* dict = [tableContentArray.arrangedObjects objectAtIndex:[tableContentArray selectionIndex]];
	NSString* newPath = [dict objectForKey:@"path"];
	NSLog(@" %@ ", newPath);

	NSString* old = [self.cachedContent objectAtIndex:[tableContentArray selectionIndex]];
	NSLog(@" old %@ ", old);
	
	[self installNameChangeFile:fieldCurrentFile.stringValue from:old to:newPath];
}

@end
