#import "WindowController.h"
#import "AppDelegate.h"
#import <objc/runtime.h>

@interface WindowController()<NSTableViewDelegate, NSTextFieldDelegate>
@property (assign) BOOL observerIsSet;
@property (strong) NSMutableArray* cachedContent;
@property (strong) NSMutableArray* loaderRPaths;

@end

@implementation WindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
		self.loaderRPaths = [NSMutableArray array];
	}
    
    return self;
}

-(void)windowWillClose:(NSNotification *)notification
{
	[[NSApp delegate] close:self]; // the app delegate has the window list
}

-(NSString*)get_AtLoaderPath
{
	return [fieldCurrentFile.stringValue stringByDeletingLastPathComponent];
}

-(NSString*)get_AtExecutablePath
{
	return (self.executablePath) ? self.executablePath : [self get_AtLoaderPath];
}

-(void)extractLoaderRPaths:(NSString*)file
{
	NSString* cmd = [NSString stringWithFormat:@"otool -l '%@' | grep -A 3 LC_RPATH | grep path | perl -lane 'print $F[1]'", file];
	NSString* output = runCommand(cmd);
	NSArray* lines = [output componentsSeparatedByString:@"\n"];
	for (__strong NSString* line in lines) {
		if ([line rangeOfString:@"/"].location == NSNotFound)
			continue;
		
		line = [line stringByReplacingOccurrencesOfString:@"@loader_path" withString:[self get_AtLoaderPath]];
		line = [line stringByReplacingOccurrencesOfString:@"@executable_path" withString:[self get_AtExecutablePath]];
		
		[self.loaderRPaths addObject:[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
	}
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	assert(self.window);
	self.window.delegate = self;
	fieldCurrentFile.delegate = self;
	tableView.delegate = self;
	
	[buttonBrowse setTarget:self];
	[buttonBrowse setAction:@selector(onBrowse)];

	[tableView setTarget:self];
	[tableView setDoubleAction:@selector(doubleClick:)];
	
	[buttonSetId setTarget:self];
	[buttonSetId setAction:@selector(onSetId)];
	
	NSMutableDictionary* bindingOptions = [NSMutableDictionary dictionary];
	[bindingOptions setObject:[NSNumber numberWithBool:NO] forKey:NSCreatesSortDescriptorBindingOption];
	
	NSTableColumn* c1 = [tableView tableColumnWithIdentifier:@"path"];
	assert(c1);
	[c1 bind:@"value" toObject:tableContentArray withKeyPath:@"arrangedObjects.path" options:bindingOptions];

	NSTableColumn* c2 = [tableView tableColumnWithIdentifier:@"open"];
	assert(c2);

}

NSString* runCommand(NSString *commandToRun)
{
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
	
    NSArray *arguments = [NSArray arrayWithObjects:
                          @"-c" ,
                          [NSString stringWithFormat:@"%@", commandToRun],
                          nil];
    NSLog(@"run command: %@",commandToRun);
    [task setArguments: arguments];
	
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
	
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
	
    [task launch];
	
    NSData *data;
    data = [file readDataToEndOfFile];
	
    NSString *output;
    output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    return output;
}

-(void)rowButtonOpenFile:(id)sender
{
	NSInteger row = [sender clickedRow];
	NSDictionary* dict = [tableContentArray.arrangedObjects objectAtIndex:row];
	NSString* path = [dict objectForKey:@"path"];
	
	path = [path stringByReplacingOccurrencesOfString:@"@executable_path" withString:[self get_AtExecutablePath]];
	path = [path stringByReplacingOccurrencesOfString:@"@loader_path" withString:[self get_AtLoaderPath]];
	
	if ([path hasPrefix:@"@rpath/"]) {
		for (NSString* rpath in self.loaderRPaths) {
			NSString* newPath = [path stringByReplacingOccurrencesOfString:@"@rpath/" withString:rpath];
			if ([[NSFileManager defaultManager] fileExistsAtPath:newPath]) {
				path = newPath;
				break;
			}
		}
	}
	
	NSLog(@"%@", path);
	if (path && path.length > 1) {
		
		NSMutableDictionary* dict = [NSMutableDictionary dictionary];
		[dict setObject:path forKey:@"file"];
		if (self.executablePath)
			[dict setObject:self.executablePath forKey:@"exec_path"];

		[[NSApp delegate] openDocument:dict];
	}
}

-(NSCell*)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if ([[tableColumn identifier] isEqualTo:@"open"]) {
		NSButtonCell* cell = [[NSButtonCell alloc] init];
		[cell setButtonType:NSMomentaryPushInButton];
		[cell setTitle:@"Open"];
		[cell setTag:row];
		[cell setTarget:self];
		[cell setAction:@selector(rowButtonOpenFile:)];
		return cell;
	}
	return [tableColumn dataCell];
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
	runCommand(cmd);
	
	[self loadFile:fieldCurrentFile.stringValue];
}

-(void)loadFile:(NSString*)path
{
	fieldCurrentFile.stringValue = path;

	NSString* output = runCommand([NSString stringWithFormat:@"file '%@'", path]);
	if ([output rangeOfString:@" executable "].location != NSNotFound) {
		self.executablePath = [path stringByDeletingLastPathComponent];
	}
	
	[self extractLoaderRPaths:path];
	
	[tableContentArray removeObjects:[tableContentArray arrangedObjects]];

	NSString* cmd = [NSString stringWithFormat:@"otool -L '%@'", path];
	output = runCommand(cmd);
	NSArray* lines = [output componentsSeparatedByString:@"\n"];
	
	if (self.observerIsSet) {
		[tableContentArray removeObserver:self forKeyPath:@"arrangedObjects"];
		[tableContentArray removeObserver:self forKeyPath:@"arrangedObjects.path"];
	}
	
	BOOL isDylib = [path hasSuffix:@"dylib"];
	
	[fieldLibraryId setEnabled:isDylib];
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
	self.observerIsSet = YES;
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
			
			[((AppDelegate*)[NSApp delegate]) openNewWindowWithFile:url.path executablePath:self.executablePath];
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
	runCommand(cmd);
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

-(void)controlTextDidChange:(NSNotification *)notification
{
	NSTextField* tf = [notification object];
	if (tf == fieldCurrentFile)
		[self loadFile:[tf stringValue]];
}

@end
