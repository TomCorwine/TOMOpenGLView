//
//  TOMOpenGLView.m
//  TOMOpenGLView
//
//  Created by Tom Corwine on 9/8/14.
//  Copyright (c) 2014 Tom's iPhone Apps. All rights reserved.
//

#import "TOMOpenGLView.h"

#import "Black_Throated_Green.h"
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
  self.context = self.context;
  //self.drawableMultisample = GLKViewDrawableMultisample4X;
  glEnable(GL_CULL_FACE);
  //glDisable(GL_CULL_FACE);
  //glCullFace(GL_FRONT);
  //glCullFace(GL_BACK);
  //glFrontFace(GL_CW);
  //glFrontFace(GL_CCW);

  return self;
}

- (void)setFilename:(NSString *)filename
{
  self.effect = [[GLKBaseEffect alloc] init];

  NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft: @YES};
  NSError *error;
  NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"jpg"];
  GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
  if (nil == textureInfo)
  {
    NSLog(@"Error loading file: %@", error.localizedDescription);
  }

  //self.effect.texture2d0.name = textureInfo.name;
  //self.effect.texture2d0.enabled = GL_TRUE;
  //self.effect.texture2d0.envMode = GLKTextureEnvModeReplace;

  //glBindTexture(GL_TEXTURE_2D, textureInfo.name);
  //glUniform1i(self.phongShader.uTexture, 0);

  self.effect.light0.enabled = GL_TRUE;
  self.effect.light0.position = GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f);
  self.effect.light0.specularColor = GLKVector4Make(0.25f, 0.25f, 0.25f, 1.0f);
  self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
  self.effect.lightingType = GLKLightingTypePerPixel;

  [self startRender];
}

- (void)startRender
{
  glClearColor(0.0, 0.0, 0.0, 0.0);

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
  GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -20.0);

  GLfloat xDegrees = rotation.x - (((long)rotation.x / 360) * 360);
  GLfloat yDegrees = rotation.y - (((long)rotation.y / 360) * 360);

  GLfloat yAxisX = yDegrees; // * ((90.0 - xDegrees) / 90.0);
  GLfloat yAxisZ = 0.0;

  NSLog(@"xDegrees: %f yAxisX: %f", xDegrees, yAxisX);

  modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, GLKMathDegreesToRadians(yAxisX));
  modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, GLKMathDegreesToRadians(xDegrees));
  modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, GLKMathDegreesToRadians(yAxisZ));
  self.effect.transform.modelviewMatrix = modelViewMatrix;

  float aspect = fabsf(self.bounds.size.width / self.bounds.size.height);
  GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(120.0 / zoomScale), aspect, 0.0, 100.0);
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

#pragma mark - GLKView Delegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
  glClear(GL_COLOR_BUFFER_BIT);

  // Positions
  glEnableVertexAttribArray(GLKVertexAttribPosition);
  glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, objPositions);

  // Normals
  glEnableVertexAttribArray(GLKVertexAttribNormal);
  glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, objNormals);

  //glEnableVertexAttribArray(GLKVertexAttribColor);
  //glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, 0, cubeNormals);

  // Textures
  glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
  glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, objTexels);

  // Render by parts
  for(int i = 0; i < objMaterials; i++)
  {
    // Set material
    self.effect.material.diffuseColor = GLKVector4Make(objDiffuses[i][0], objDiffuses[i][1], objDiffuses[i][2], 1.0f);
    self.effect.material.specularColor = GLKVector4Make(objSpeculars[i][0], objSpeculars[i][1], objSpeculars[i][2], 1.0f);

    // Prepare effect
    [self.effect prepareToDraw];

    // Draw vertices
    glDrawArrays(GL_TRIANGLES, objFirsts[i], objCounts[i]);
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
    self.inhibitRotation = NO;
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
