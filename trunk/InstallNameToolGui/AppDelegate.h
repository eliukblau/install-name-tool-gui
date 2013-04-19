//
//  AppDelegate.h
//  InstallNameToolGui
//
//  Created by avenza on 2013-03-27.
//  Copyright (c) 2013 avenza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>
-(WindowController*)openNewWindowWithFile:(NSString*)path;

@end
