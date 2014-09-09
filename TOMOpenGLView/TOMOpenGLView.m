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

@interface TOMOpenGLView () <GLKViewDelegate>
{
  BOOL _increasing;
  GLuint _vertexBuffer;
  GLuint _indexBuffer;
  GLuint _vertexArray;
  //float _rotation;
}

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKBaseEffect *effect;
@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation TOMOpenGLView

- (void)dealloc
{
  [self.displayLink invalidate];
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

  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

  if (nil == self.context)
  {
    NSLog(@"Failed to create ES context");
    return nil;
  }

  self.delegate = self;

  self.context = self.context;
  self.drawableMultisample = GLKViewDrawableMultisample4X;

  return self;
}

- (void)startRender
{
  [EAGLContext setCurrentContext:self.context];
  glEnable(GL_CULL_FACE);

  self.effect = [[GLKBaseEffect alloc] init];

  NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft: @YES};
  NSError *error;
  NSString *path = [[NSBundle mainBundle] pathForResource:@"tile_floor" ofType:@"png"];
  GLKTextureInfo * info = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
  if (nil == info)
  {
    NSLog(@"Error loading file: %@", [error localizedDescription]);
  }

  self.effect.texture2d0.name = info.name;
  self.effect.texture2d0.enabled = true;

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

  self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update:)];
  [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
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
}

- (void)setTextureFilename:(NSString *)textureFilename
{
  _textureFilename = textureFilename;
}

- (void)setRotation:(TOMOpenGLViewRotation)rotation
{
  _rotation = rotation;

  float aspect = fabsf(self.bounds.size.width / self.bounds.size.height);
  GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 4.0f, 10.0f);
  self.effect.transform.projectionMatrix = projectionMatrix;

  GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -6.0f);
  modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(25), 1, 0, 0);
  modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(self.rotation.x), 0, 1, 0);
  self.effect.transform.modelviewMatrix = modelViewMatrix;
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

- (void)update:(CADisplayLink *)sender
{
  /*
  static NSDate *previousTime;
  NSTimeInterval timeSinceLastUpdate;

  if (previousTime)
  {
    timeSinceLastUpdate = [[NSDate date] timeIntervalSinceDate:previousTime];
  }
  else
  {
    timeSinceLastUpdate = 0;
  }

  previousTime = [NSDate date];

  float aspect = fabsf(self.bounds.size.width / self.bounds.size.height);
  GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 4.0f, 10.0f);
  self.effect.transform.projectionMatrix = projectionMatrix;

  GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -6.0f);
  _rotation += 90 * timeSinceLastUpdate;
  modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(25), 1, 0, 0);
  modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotation), 0, 1, 0);
  self.effect.transform.modelviewMatrix = modelViewMatrix;
*/
  [self display];
}

@end
