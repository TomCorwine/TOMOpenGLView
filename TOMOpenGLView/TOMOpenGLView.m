//
//  TOMOpenGLView.m
//  TOMOpenGLView
//
//  Created by Tom Corwine on 9/8/14.
//  Copyright (c) 2014 Tom's iPhone Apps. All rights reserved.
//

#import "TOMOpenGLView.h"

#import "TOMObjImporter.h"
#import <OpenGLES/EAGL.h>

@interface TOMOpenGLView () <GLKViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKBaseEffect *effect;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *dummyView;
@property (nonatomic, getter = shouldInhibitRotation) BOOL inhibitRotation;
@property (nonatomic, getter = isZooming) BOOL zooming;

@end

@implementation TOMOpenGLView

- (void)dealloc
{
  [self stopRender];
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  self.enableSetNeedsDisplay = NO;
  self.opaque = NO;

  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
  scrollView.delegate = self;
  scrollView.contentSize = CGSizeMake(100000, 100000);
  scrollView.contentOffset = CGPointMake(scrollView.contentSize.width / 2.0, scrollView.contentSize.height / 2.0);
  scrollView.showsHorizontalScrollIndicator = NO;
  scrollView.showsVerticalScrollIndicator = NO;
  scrollView.pagingEnabled = NO;
  [self addSubview:scrollView];

  self.dummyView = [[UIView alloc] initWithFrame:scrollView.bounds];
  [scrollView addSubview:self.dummyView];

  self.scrollView = scrollView;

  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

  if (nil == self.context)
  {
    NSLog(@"Failed to create ES context");
    return nil;
  }

  self.delegate = self;

  [EAGLContext setCurrentContext:self.context];

  self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
  glEnable(GL_CULL_FACE);
  glEnable(GL_DEPTH_TEST);

  return self;
}

- (void)renderWithObjFilename:(NSString *)objFilename
{
  NSError *error = [TOMObjImporter importObjFilename:objFilename];
  if (error)
  {
    NSLog(@"Error: %@ - %@", error, error.localizedDescription);
    return;
  }

  [self startRender];
}

- (void)startRender
{
  glClearColor(0.0, 0.0, 0.0, 0.0);
  
  self.effect = [[GLKBaseEffect alloc] init];
  self.effect.texture2d0.envMode = GLKTextureEnvModeReplace;

  [self setRotation:(TOMOpenGLViewRotation){0.0, 0.0, 0.0} andZoomScale:1.0];
}

- (void)stopRender
{
  [EAGLContext setCurrentContext:self.context];
  if ([[EAGLContext currentContext] isEqual:self.context])
  {
    [EAGLContext setCurrentContext:nil];
  }

  self.context = nil;
  self.effect = nil;
}

- (void)setRotation:(TOMOpenGLViewRotation)rotation
{
  [self setRotation:rotation andZoomScale:self.zoomScale];
}

- (void)setZoomScale:(CGFloat)zoomScale
{
  [self setRotation:self.rotation andZoomScale:zoomScale];
}

- (void)setRotation:(TOMOpenGLViewRotation)rotation andZoomScale:(CGFloat)zoomScale
{
  GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -40.0);

  GLfloat xDegrees = rotation.x - (((long)rotation.x / 360) * 360);
  GLfloat yDegrees = rotation.y - (((long)rotation.y / 360) * 360);

  //GLfloat yAxisX = yDegrees; // * ((90.0 - xDegrees) / 90.0);
  //GLfloat yAxisZ = 0.0;

  //NSLog(@"xDegrees: %f yAxisX: %f", xDegrees, yAxisX);

  modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, GLKMathDegreesToRadians(xDegrees));
  modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, GLKMathDegreesToRadians(yDegrees));
  //modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, GLKMathDegreesToRadians(yAxisX));
  //modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, GLKMathDegreesToRadians(xDegrees));
  //modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, GLKMathDegreesToRadians(yAxisZ));
  self.effect.transform.modelviewMatrix = modelViewMatrix;

  float aspect = fabsf(self.bounds.size.width / self.bounds.size.height);
  GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(60.0 / zoomScale), aspect, 1.0, 100.0);
  self.effect.transform.projectionMatrix = projectionMatrix;

  [self display];

  if (zoomScale != self.zoomScale
      && [self.moveDelegate respondsToSelector:@selector(openGLViewDidZoom:)])
  {
    [self.moveDelegate openGLViewDidZoom:self];
  }

  if ((rotation.x != self.rotation.x || rotation.y != self.rotation.y || rotation.z != self.rotation.z)
      && [self.moveDelegate respondsToSelector:@selector(openGLViewDidRotate:)])
  {
    [self.moveDelegate openGLViewDidRotate:self];
  }

  _rotation = rotation;
  _zoomScale = zoomScale;
}

- (void)setMaximumZoomScale:(CGFloat)maximumZoomScale
{
  _maximumZoomScale = maximumZoomScale;
  self.scrollView.maximumZoomScale = self.maximumZoomScale;
}

#pragma mark - Accessors

- (GLKTextureInfo *)textureForFilename:(NSString *)filename
{
  if (0 == filename.length)
  {
    return nil;
  }

  static NSMutableDictionary *textureDictionary;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    textureDictionary = @{}.mutableCopy;
  });
  
  GLKTextureInfo *textureInfo = textureDictionary[filename];
  if (nil == textureInfo)
  {
    NSError *error;
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft: @YES};
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"jpg"];
    textureInfo = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
    if (textureInfo && nil == error)
    {
      textureDictionary[filename] = textureInfo;
    }
    else
    {
      NSLog(@"Error loading file: %@", error.localizedDescription);
    }
  }
  
  return textureInfo;
}

#pragma mark - GLKView Delegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  // Positions
  glEnableVertexAttribArray(GLKVertexAttribPosition);
  glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, model.positions);

  // Normals
  glEnableVertexAttribArray(GLKVertexAttribNormal);
  glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, model.normals);

  //glEnableVertexAttribArray(GLKVertexAttribColor);
  //glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, 0, cubeNormals);

  // Textures
  glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
  glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, model.texels);

  // Render by parts
  for (int i = 0; i < model.materials; i++)
  {
    // Set material
    self.effect.material.diffuseColor = GLKVector4Make(model.diffuses[i][0], model.diffuses[i][1], model.diffuses[i][2], 1.0f);
    self.effect.material.specularColor = GLKVector4Make(model.speculars[i][0], model.speculars[i][1], model.speculars[i][2], 1.0f);

    NSString *filename = [NSString stringWithUTF8String:model.textures[i]];
    GLKTextureInfo *textureInfo = [self textureForFilename:filename];
    self.effect.texture2d0.name = textureInfo.name;

    [self.effect prepareToDraw];

    // Draw vertices
    glDrawArrays(GL_TRIANGLES, model.firsts[i], model.counts[i]);
  }
}

#pragma mark - UIScrollView Delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  if (self.zooming)
  {
    return;
  }

  if (self.shouldInhibitRotation)
  {
    return;
  }

  static CGPoint previousPoint;
  CGPoint point = scrollView.contentOffset;
  if (0 == previousPoint.x && 0 == previousPoint.y)
  {
    previousPoint = point;
  }

  TOMOpenGLViewRotation currentRotation = self.rotation;
  CGFloat xOffset = (point.x - previousPoint.x) * 0.5;
  CGFloat yOffset = (point.y - previousPoint.y) * 0.5;
  self.rotation = (TOMOpenGLViewRotation){currentRotation.x - xOffset, currentRotation.y - yOffset, 0.0};

  previousPoint = point;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  self.inhibitRotation = YES;
  scrollView.contentOffset = CGPointMake(scrollView.contentSize.width / 2.0, scrollView.contentSize.height / 2.0);
  self.inhibitRotation = NO;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
  self.zooming = YES;
  self.zoomScale = scrollView.zoomScale;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
  self.zooming = NO;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
  return self.dummyView;
}

@end
