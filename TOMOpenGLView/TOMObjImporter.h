//
//  TOMObjImporter.h
//  TOMOpenGLView
//
//  Created by Tom Corwine on 9/19/14.
//  Copyright (c) 2014 Tom's iPhone Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
  int vertices;
  float positions[0][3];
  float texels[0][2];
  float normals[0][9];
  int firsts[0];
  int counts[0];
  int materials;
  char textures[0][128];
  float diffuses[0][3];
  float speculars[0][3];
} TOMModel;

static TOMModel model;

@interface TOMObjImporter : NSObject

+ (NSError *)importObjFilename:(NSString *)filename;

@end
