//
//  TOMOpenGLView.m
//  TOMOpenGLView
//
//  Created by Tom Corwine on 9/8/14.
//  Copyright (c) 2014 Tom's iPhone Apps. All rights reserved.
//

#import "TOMOpenGLView.h"

#import <OpenGLES/EAGL.h>

typedef struct {
  float Position[3];
  float Color[4];
  float TexCoord[2];
} Vertex;

const Vertex Vertices[] = {
  // Front
  {{1, -1, 1}, {1, 0, 0, 1}, {1, 0}},
  {{1, 1, 1}, {0, 1, 0, 1}, {1, 1}},
  {{-1, 1, 1}, {0, 0, 1, 1}, {0, 1}},
  {{-1, -1, 1}, {0, 0, 0, 1}, {0, 0}},
  // Back
  {{1, 1, -1}, {1, 0, 0, 1}, {0, 1}},
  {{-1, -1, -1}, {0, 1, 0, 1}, {1, 0}},
  {{1, -1, -1}, {0, 0, 1, 1}, {0, 0}},
  {{-1, 1, -1}, {0, 0, 0, 1}, {1, 1}},
  // Left
  {{-1, -1, 1}, {1, 0, 0, 1}, {1, 0}},
  {{-1, 1, 1}, {0, 1, 0, 1}, {1, 1}},
  {{-1, 1, -1}, {0, 0, 1, 1}, {0, 1}},
  {{-1, -1, -1}, {0, 0, 0, 1}, {0, 0}},
  // Right
  {{1, -1, -1}, {1, 0, 0, 1}, {1, 0}},
  {{1, 1, -1}, {0, 1, 0, 1}, {1, 1}},
  {{1, 1, 1}, {0, 0, 1, 1}, {0, 1}},
  {{1, -1, 1}, {0, 0, 0, 1}, {0, 0}},
  // Top
  {{1, 1, 1}, {1, 0, 0, 1}, {1, 0}},
  {{1, 1, -1}, {0, 1, 0, 1}, {1, 1}},
  {{-1, 1, -1}, {0, 0, 1, 1}, {0, 1}},
  {{-1, 1, 1}, {0, 0, 0, 1}, {0, 0}},
  // Bottom
  {{1, -1, -1}, {1, 0, 0, 1}, {1, 0}},
  {{1, -1, 1}, {0, 1, 0, 1}, {1, 1}},
  {{-1, -1, 1}, {0, 0, 1, 1}, {0, 1}},
  {{-1, -1, -1}, {0, 0, 0, 1}, {0, 0}}
};

const GLubyte Indices[] = {
  // Front
  0, 1, 2,
  2, 3, 0,
  // Back
  4, 6, 5,
  4, 5, 7,
  // Left
  8, 9, 10,
  10, 11, 8,
  // Right
  12, 13, 14,
  14, 15, 12,
  // Top
  16, 17, 18,
  18, 19, 16,
  // Bottom
  20, 21, 22,
  22, 23, 20
};

@interface TOMOpenGLView () <GLKViewDelegate, UIScrollViewDelegate>
{
  GLuint _vertexBuffer;
  GLuint _indexBuffer;
  GLuint _vertexArray;
}

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKBaseEffect *effect;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *dummyView;
@property (nonatomic) BOOL shouldInhibitRotation;

@end

@implementation TOMOpenGLView

- (void)dealloc
{
  [self stopRender];

  if ([[EAGLContext currentContext] isEqual:self.context])
  {
    [EAGLContext setCurrentContext:nil];
  }
  self.context = nil;
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

  self.dummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, scrollView.contentSize.width, scrollView.contentSize.height)];
  [scrollView addSubview:self.dummyView];

  self.scrollView = scrollView;

  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

  if (nil == self.context)
  {
    NSLog(@"Failed to create ES context");
    return nil;
  }

  self.delegate = self;

  self.context = self.context;
  self.drawableMultisample = GLKViewDrawableMultisample4X;

  [self setupOpenGL];

  return self;
}

- (void)setMaximumZoomScale:(CGFloat)maximumZoomScale
{
  _maximumZoomScale = maximumZoomScale;
  self.scrollView.maximumZoomScale = self.maximumZoomScale;
}

- (void)setupOpenGL
{
  [EAGLContext setCurrentContext:self.context];
  glEnable(GL_CULL_FACE);
}

- (void)startRender
{
  // New lines
  glGenVertexArraysOES(1, &_vertexArray);
  glBindVertexArrayOES(_vertexArray);

  // Old stuff
  glGenBuffers(1, &_vertexBuffer);
  glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);

  glGenBuffers(1, &_indexBuffer);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);

  // New lines (were previously in draw)
  glEnableVertexAttribArray(GLKVertexAttribPosition);
  glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, Position));
  glEnableVertexAttribArray(GLKVertexAttribColor);
  glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, Color));
  glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
  glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, TexCoord));

  // New line
  glBindVertexArrayOES(0);

  self.zoomScale = 1.0;
  self.rotation = (TOMOpenGLViewRotation){0.0, 0.0, 0.0};
}

- (void)stopRender
{
  [EAGLContext setCurrentContext:self.context];

  glDeleteBuffers(1, &_vertexBuffer);
  glDeleteBuffers(1, &_indexBuffer);
  //glDeleteVertexArraysOES(1, &_vertexArray);

  self.effect = nil;
}

- (void)setObjFilename:(NSString *)objFilename
{
  _objFilename = objFilename;

  // TODO: Implement
}

- (void)setTextureFilename:(NSString *)textureFilename
{
  _textureFilename = textureFilename;

  self.effect = [[GLKBaseEffect alloc] init];

  NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft: @YES};
  NSError *error;
  NSString *path = [[NSBundle mainBundle] pathForResource:self.textureFilename ofType:@"png"];
  GLKTextureInfo *info = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
  if (nil == info)
  {
    NSLog(@"Error loading file: %@", [error localizedDescription]);
  }

  self.effect.texture2d0.name = info.name;
  self.effect.texture2d0.enabled = true;
}

- (void)setRotation:(TOMOpenGLViewRotation)rotation
{
  _rotation = rotation;

  GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -6.0);
  modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(self.rotation.x), 0, 1, 0);
  modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(self.rotation.y), 1, 0, 0);
  self.effect.transform.modelviewMatrix = modelViewMatrix;

  [self display];

  if ([self.moveDelegate respondsToSelector:@selector(openGLViewDidRotate:)])
  {
    [self.moveDelegate openGLViewDidRotate:self];
  }
}

- (void)setZoomScale:(CGFloat)zoomScale
{
  _zoomScale = zoomScale;

  float aspect = fabsf(self.bounds.size.width / self.bounds.size.height);
  GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0 / self.zoomScale), aspect, 4.0, 10.0);
  self.effect.transform.projectionMatrix = projectionMatrix;

  [self display];

  if ([self.moveDelegate respondsToSelector:@selector(openGLViewDidZoom:)])
  {
    [self.moveDelegate openGLViewDidZoom:self];
  }
}

#pragma mark - GLKView Delegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT);

  [self.effect prepareToDraw];

  glBindVertexArrayOES(_vertexArray);
  glDrawElements(GL_TRIANGLES, sizeof(Indices) / sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);

}

#pragma mark - UIScrollView Delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  if (self.shouldInhibitRotation)
  {
    self.shouldInhibitRotation = NO;
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
  self.shouldInhibitRotation = YES;
  scrollView.contentOffset = CGPointMake(scrollView.contentSize.width / 2.0, scrollView.contentSize.height / 2.0);
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
  self.shouldInhibitRotation = YES;
  self.zoomScale = scrollView.zoomScale;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
  return self.dummyView;
}

@end
