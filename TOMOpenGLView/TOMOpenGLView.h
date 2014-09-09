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

@class TOMOpenGLView;
@protocol TOMOpenGLViewDelegate <NSObject>
- (void)openGLViewDidRotate:(TOMOpenGLView *)view;
- (void)openGLViewDidZoom:(TOMOpenGLView *)view;
@end

@interface TOMOpenGLView : GLKView

@property (nonatomic, weak) id<TOMOpenGLViewDelegate> moveDelegate; // self.delegate property already taken by GLKView

@property (nonatomic, strong) NSString *objFilename; // Filename of obj file
@property (nonatomic, strong) NSString *textureFilename; // Filename of PNG texture
@property (nonatomic) CGFloat maximumZoomScale; // Range that view can zoom from 1.0 to n.n - defaults to 1.0

@property (nonatomic) TOMOpenGLViewRotation rotation;
@property (nonatomic) CGFloat zoomScale; // Range: 1.0 to self.zoomScale. Does nothing if self.zoomScale == 1.0

- (void)startRender; // Must be called before obj object will appear
- (void)stopRender; // Causes obj object to disappear

@end
