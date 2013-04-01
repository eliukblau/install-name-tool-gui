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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self.controllers = [NSMutableArray array];
	
	// Insert code here to initialize your application
	WindowController* w = [[WindowController alloc] initWithWindowNibName:@"MainWindow"];
	[w showWindow:self];
	[self.controllers addObject:w];
	w->isFirst = YES;
}

-(void)openNewWindow:(NSString*)path
{
	WindowController* w = [[WindowController alloc] initWithWindowNibName:@"MainWindow"];
	[w showWindow:self];
	[w loadFile:path];
	[self.controllers addObject:w];
}

@end
