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
  float positions[133704];
  float texels[89136];
  float normals[133704];
  int firsts[3];
  int counts[3];
  int materials;
  char textures[3][128];
  float diffuses[3][3];
  float speculars[3][3];
} TOMModel;

@interface TOMObjImporter : NSObject

TOMModel objectModel();
+ (NSError *)importObjFilename:(NSString *)filename;

@end
