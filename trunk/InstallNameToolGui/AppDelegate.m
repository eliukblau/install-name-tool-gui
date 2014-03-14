//
//  AppDelegate.m
//  InstallNameToolGui
//
//  Created by avenza on 2013-03-27.
//  Copyright (c) 2013 avenza. All rights reserved.
//

#import "AppDelegate.h"
#import	"WindowController.h"

@interface AppDelegate ()
@property (retain) NSMutableArray* controllers;
@end

@implementation AppDelegate

@synthesize controllers=_controllers;

- (void)dealloc
{
	//[super dealloc];
}

NSMutableArray* controllers;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotificationis
{
	self.controllers = [NSMutableArray array];
	
	[self newDocument:nil];
}

-(WindowController*)openNewWindowWithFile:(NSString*)path executablePath:(NSString*)execPath
{
	WindowController* w = [[WindowController alloc] initWithWindowNibName:@"MainWindow"];
	w.executablePath = execPath;
	[w showWindow:self];
	[self.controllers addObject:w];
	if (path)
		[w loadFile:path];
	return w;
}

-(void)newDocument:(id)obj
{
	[self openNewWindowWithFile:nil executablePath:nil];
}

-(void)openDocument:(id)obj
{
	if ([obj isKindOfClass:[NSMenuItem class]]) {
		WindowController* w = [self openNewWindowWithFile:nil executablePath:nil];
		[w onBrowse];
	}
	else if ([obj isKindOfClass:[NSDictionary class]]) {
		NSDictionary* dict = obj;
		[self openNewWindowWithFile:[dict objectForKey:@"file"] executablePath:[dict objectForKey:@"exec_path"]];
	}
}

-(void)close:(id)sender
{
	[self.controllers removeObject:sender];
}

@end
