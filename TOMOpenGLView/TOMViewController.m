//
//  TOMViewController.m
//  TOMOpenGLView
//
//  Created by Tom Corwine on 9/8/14.
//  Copyright (c) 2014 Tom's iPhone Apps. All rights reserved.
//

#import "TOMViewController.h"

#import "TOMOpenGLView.h"

@interface TOMViewController ()
@end

@implementation TOMViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
  imageView.contentMode = UIViewContentModeScaleAspectFill;
  imageView.image = [UIImage imageNamed:@"new_york_skyline"];
  [self.view addSubview:imageView];

  TOMOpenGLView *view = [[TOMOpenGLView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:view];

  view.maximumZoomScale = 2.0;
  [view setFilename:@"Black_Throated_Green"];
}

@end
