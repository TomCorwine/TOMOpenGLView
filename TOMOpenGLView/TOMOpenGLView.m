//
//  TOMOpenGLView.m
//  TOMOpenGLView
//
//  Created by Tom Corwine on 9/8/14.
//  Copyright (c) 2014 Tom's iPhone Apps. All rights reserved.
//

#import "TOMOpenGLView.h"

#import "Black_Throated_Gray.h"
#import <OpenGLES/EAGL.h>

/*
typedef struct {
  float Position[3];
  float Color[4];
  float TexCoord[2];
} Vertex;

const Vertex Vertices[] = {
  // Front
  {{1, -1, 1}, {1, 1, 1, 1}, {1, 0}},
  {{1, 1, 1}, {1, 1, 1, 1}, {1, 1}},
  {{-1, 1, 1}, {1, 1, 1, 1}, {0, 1}},
  {{-1, -1, 1}, {1, 1, 1, 1}, {0, 0}},
  // Back
  {{1, 1, -1}, {1, 1, 1, 1}, {0, 1}},
  {{-1, -1, -1}, {1, 1, 1, 1}, {1, 0}},
  {{1, -1, -1}, {1, 1, 1, 1}, {0, 0}},
  {{-1, 1, -1}, {1, 1, 1, 1}, {1, 1}},
  // Left
  {{-1, -1, 1}, {1, 1, 1, 1}, {1, 0}},
  {{-1, 1, 1}, {1, 1, 1, 1}, {1, 1}},
  {{-1, 1, -1}, {1, 1, 1, 1}, {0, 1}},
  {{-1, -1, -1}, {1, 1, 1, 1}, {0, 0}},
  // Right
  {{1, -1, -1}, {1, 1, 1, 1}, {1, 0}},
  {{1, 1, -1}, {1, 1, 1, 1}, {1, 1}},
  {{1, 1, 1}, {1, 1, 1, 1}, {0, 1}},
  {{1, -1, 1}, {1, 1, 1, 1}, {0, 0}},
  // Top
  {{1, 1, 1}, {1, 1, 1, 1}, {1, 0}},
  {{1, 1, -1}, {1, 1, 1, 1}, {1, 1}},
  {{-1, 1, -1}, {1, 1, 1, 1}, {0, 1}},
  {{-1, 1, 1}, {1, 1, 1, 1}, {0, 0}},
  // Bottom
  {{1, -1, -1}, {1, 1, 1, 1}, {1, 0}},
  {{1, -1, 1}, {1, 1, 1, 1}, {1, 1}},
  {{-1, -1, 1}, {1, 1, 1, 1}, {0, 1}},
  {{-1, -1, -1}, {1, 1, 1, 1}, {0, 0}}
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
*/

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

- (void)setupOpenGL
{
  [EAGLContext setCurrentContext:self.context];
  glEnable(GL_CULL_FACE);
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

  self.effect.texture2d0.name = textureInfo.name;
  self.effect.texture2d0.enabled = true;
  //self.effect.texture2d0.envMode = GLKTextureEnvModeReplace;
/*
  self.effect.light0.enabled = GL_TRUE;
  self.effect.light0.position = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
  self.effect.light0.specularColor = GLKVector4Make(0.25f, 0.25f, 0.25f, 1.0f);
  self.effect.light0.diffuseColor = GLKVector4Make(0.75f, 0.75f, 0.75f, 1.0f);
  self.effect.lightingType = GLKLightingTypePerPixel;
 */
  //glBindTexture(GL_TEXTURE_2D, textureInfo.name);
  //glUniform1i(self.phongShader.uTexture, 0);

  [self startRender];
}

- (void)startRender
{
  glClearColor(0.0, 0.0, 0.0, 0.0);
/*
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
*/
  [self setRotation:(TOMOpenGLViewRotation){0.0, 0.0, 0.0} andZoomScale:1.0];
}

- (void)stopRender
{
  [EAGLContext setCurrentContext:self.context];

  glDeleteBuffers(1, &_vertexBuffer);
  glDeleteBuffers(1, &_indexBuffer);
  //glDeleteVertexArraysOES(1, &_vertexArray);

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
  GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(105.0 / zoomScale), aspect, 0.0, 100.0);
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

  [self.effect prepareToDraw];

  //glBindVertexArrayOES(_vertexArray);
  //glDrawElements(GL_TRIANGLES, sizeof(Indices) / sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
  
  // Positions
  glEnableVertexAttribArray(GLKVertexAttribPosition);
  glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, Black_Throated_GrayPositions);
  
  // Normals
  glEnableVertexAttribArray(GLKVertexAttribNormal);
  glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, Black_Throated_GrayNormals);

  //glEnableVertexAttribArray(GLKVertexAttribColor);
  //glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, 0, cubeNormals);

  // Textures
  glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
  glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, Black_Throated_GrayTexels);
  
  // Render by parts
  for(int i=0; i<Black_Throated_GrayMaterials; i++)
  {
    // Set material
    self.effect.material.diffuseColor = GLKVector4Make(Black_Throated_GrayDiffuses[i][0], Black_Throated_GrayDiffuses[i][1], Black_Throated_GrayDiffuses[i][2], 1.0f);
    self.effect.material.specularColor = GLKVector4Make(Black_Throated_GraySpeculars[i][0], Black_Throated_GraySpeculars[i][1], Black_Throated_GraySpeculars[i][2], 1.0f);
    
    // Prepare effect
    //[self.effect prepareToDraw];
    
    // Draw vertices
    glDrawArrays(GL_TRIANGLES, Black_Throated_GrayFirsts[i], Black_Throated_GrayCounts[i]);
    
    //GL_API void GL_APIENTRY glDrawElements (GLenum mode, GLsizei count, GLenum type, const GLvoid *indices);
    //GL_API void GL_APIENTRY glDrawArrays (GLenum mode, GLint first, GLsizei count);
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
