//
//  TOMAppDelegate.m
//  TOMOpenGLView
//
//  Created by Tom Corwine on 9/8/14.
//  Copyright (c) 2014 Tom's iPhone Apps. All rights reserved.
//

#import "TOMAppDelegate.h"

#import "TOMViewController.h"

@implementation TOMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.backgroundColor = [UIColor whiteColor];

  TOMViewController *viewController = [[TOMViewController alloc] init];
  self.window.rootViewController = viewController;

  [self.window makeKeyAndVisible];
  return YES;
}

@end
