//
//  TOMOpenGLView.h
//  TOMOpenGLView
//
//  Created by Tom Corwine on 9/8/14.
//  Copyright (c) 2014 Tom's iPhone Apps. All rights reserved.
//

#import <GLKit/GLKit.h>

typedef struct {
  double x;
  double y;
  double z;
} TOMOpenGLViewRotation;

@interface TOMOpenGLView : GLKView

@property (nonatomic, strong) NSString *objFilename;
@property (nonatomic, strong) NSString *textureFilename;

@property (nonatomic) TOMOpenGLViewRotation rotation;

- (void)startRender;
- (void)stopRender;

@end
