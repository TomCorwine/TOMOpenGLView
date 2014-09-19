//
//  TOMObjImporter.m
//  TOMOpenGLView
//
//  Created by Tom Corwine on 9/19/14.
//  Copyright (c) 2014 Tom's iPhone Apps. All rights reserved.
//

#import "TOMObjImporter.h"

typedef struct {
  int vertices;
  int positions;
  int texels;
  int normals;
  int faces;
}
ModelSizes;

static NSMutableArray *materialNames;

@implementation TOMObjImporter

+ (NSError *)importObjFilename:(NSString *)filename
{
  filename = [filename stringByReplacingOccurrencesOfString:@".obj" withString:@""];
  NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"obj"];
  NSString *objString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
  NSError *error = [self extractOBJdata:objString];
  if (error)
  {
    return error;
  }

  return nil;
}

+ (NSError *)extractOBJdata:(NSString *)objString
{
  NSArray *lines = [objString componentsSeparatedByString:@"\n"];

  ModelSizes modelSizes = {0, 0, 0, 0, 0};
  for (NSString *line in lines)
  {
    if ([line hasPrefix:@"vt"])
    {
      modelSizes.texels++;
    }
    else if ([line hasPrefix:@"vn"])
    {
      modelSizes.normals++;
    }
    else if ([line hasPrefix:@"v"])
    {
      modelSizes.positions++;
    }
    else if ([line hasPrefix:@"f"])
    {
      modelSizes.faces++;
    }

    modelSizes.vertices = modelSizes.faces * 3;
  }

  float positions[modelSizes.positions][3];
  float texels[modelSizes.texels][2];
  float normals[modelSizes.normals][3];
  int faces[modelSizes.faces][10];

  int verticiesIndex = 0;
  int texelsIndex = 0;
  int normalsIndex = 0;
  int facesIndex = 0;

  int materialIndex = 0;

  for (NSString *line in lines)
  {
    if ([line hasPrefix:@"mtllib"])
    {
      NSString *subString = [line substringFromIndex:7];
      NSError *error = [self extractMTLdataFromFilename:subString];
      if (error)
      {
        return error;
      }
    }
    else if ([line hasPrefix:@"usemtl"])
    {
      NSString *subString = [line substringFromIndex:7];
      materialIndex = [materialNames indexOfObject:subString];
      if (NSNotFound == materialIndex)
      {
        NSString *errorString = [NSString stringWithFormat:@"Material %@ not found in mtl file.", subString];
        return [NSError errorWithDomain:errorString code:903 userInfo:nil];
      }
    }
    else if ([line hasPrefix:@"vt"])
    {
      NSString *subString = [line substringFromIndex:3];
      NSArray *items = [subString componentsSeparatedByString:@" "];

      for (int i = 0; i < 2; i++)
      {
        NSString *item = items[i];
        texels[texelsIndex][i] = item.floatValue;
      }

      texelsIndex++;
    }
    else if ([line hasPrefix:@"vn"])
    {
      NSString *subString = [line substringFromIndex:3];
      NSArray *items = [subString componentsSeparatedByString:@" "];

      for (int i = 0; i < 3; i++)
      {
        NSString *item = items[i];
        normals[normalsIndex][i] = item.floatValue;
      }

      normalsIndex++;
    }
    else if ([line hasPrefix:@"v"])
    {
      NSString *subString = [line substringFromIndex:3];
      NSArray *items = [subString componentsSeparatedByString:@" "];
      if (items.count != 3)
      {
        return [NSError errorWithDomain:@"Faces not triangular." code:900 userInfo:nil];
      }

      for (int i = 0; i < 3; i++)
      {
        NSString *item = items[i];
        positions[verticiesIndex][i] = item.floatValue;
      }

      verticiesIndex++;
    }
    else if ([line hasPrefix:@"f"])
    {
      NSString *subString = [line substringFromIndex:3];
      NSMutableArray *items = @[].mutableCopy;

      for (NSString *group in [subString componentsSeparatedByString:@" "])
      {
        NSArray *array = [group componentsSeparatedByString:@"/"];
        [items addObjectsFromArray:array];
      }

      for (int i = 0; i < 9; i++)
      {
        NSString *item = items[i];
        faces[facesIndex][i] = item.intValue;
      }

      facesIndex++;
    }
  }

  model.vertices = verticiesIndex + 1;

  int index = 0;
  int counts[model.materials];
  for (int j = 0; j < model.materials; j++)
  {
    counts[j] = 0;

    for (int i = 0; i < sizeof(faces); i++)
    {
      if (faces[i][9] == j)
      {
        counts[j] += 3;

        int vA = faces[i][0] - 1;
        int vtA = faces[i][1] - 1;
        int vnA = faces[i][2] - 1;
        int vB = faces[i][3] - 1;
        int vtB = faces[i][4] - 1;
        int vnB = faces[i][5] - 1;
        int vC = faces[i][6] - 1;
        int vtC = faces[i][7] - 1;
        int vnC = faces[i][8] - 1;

        model.positions[index][0] = positions[vA][0];
        model.positions[index][1] = positions[vA][1];
        model.positions[index][2] = positions[vA][2];
        model.texels[index][0] = texels[vtA][0];
        model.texels[index][1] = texels[vtA][1];
        model.normals[index][0] = normals[vnA][0];
        model.normals[index][1] = normals[vnA][1];
        model.normals[index][2] = normals[vnA][2];
        index++;
        model.positions[index][0] = positions[vB][0];
        model.positions[index][1] = positions[vB][1];
        model.positions[index][2] = positions[vB][2];
        model.texels[index][0] = texels[vtB][0];
        model.texels[index][1] = texels[vtB][1];
        model.normals[index][0] = normals[vnB][0];
        model.normals[index][1] = normals[vnB][1];
        model.normals[index][2] = normals[vnB][2];
        index++;
        model.positions[index][0] = positions[vC][0];
        model.positions[index][1] = positions[vC][1];
        model.positions[index][2] = positions[vC][2];
        model.texels[index][0] = texels[vtC][0];
        model.texels[index][1] = texels[vtC][1];
        model.normals[index][0] = normals[vnC][0];
        model.normals[index][1] = normals[vnC][1];
        model.normals[index][2] = normals[vnC][2];
        index++;
      }
    }
  }

  for (int i = 0; i < model.materials; i++)
  {
    if (i == 0)
    {
      model.firsts[i] = 0;
    }
    else
    {
      model.firsts[i] = model.firsts[i - 1] + counts[i - 1];
    }

    model.counts[i] = counts[i];
  }

  return nil;
}

+ (NSError *)extractMTLdataFromFilename:(NSString *)filename
{
  static BOOL isFileLoaded = NO;
  if (isFileLoaded)
  {
    return [NSError errorWithDomain:@"Only one mtl file supported." code:901 userInfo:nil];
  }
  isFileLoaded = YES;

  filename = [filename stringByReplacingOccurrencesOfString:@".mtl" withString:@""];
  NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"mtl"];
  NSString *objString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
  NSArray *lines = [objString componentsSeparatedByString:@"\n"];

  materialNames = @[].mutableCopy;
  int materialIndex = 0;
  int materialCount = 0;
  for (NSString *line in lines)
  {
    if ([line hasPrefix:@"newmtl"])
    {
      NSString *subString = [line substringFromIndex:7];
      materialNames[materialCount] = subString;
      materialIndex = materialCount;
      materialCount++;
    }
    else if ([line hasPrefix:@"kd"])
    {
      NSString *subString = [line substringFromIndex:3];
      NSArray *items = [subString componentsSeparatedByString:@" "];

      for (int i = 0; i < 3; i++)
      {
        NSString *item = items[i];
        model.diffuses[materialIndex][i] = item.floatValue;
      }
    }
    else if ([line hasPrefix:@"ks"])
    {
      NSString *subString = [line substringFromIndex:3];
      NSArray *items = [subString componentsSeparatedByString:@" "];

      for (int i = 0; i < 3; i++)
      {
        NSString *item = items[i];
        model.speculars[materialIndex][i] = item.floatValue;
      }
    }
    else if ([line hasPrefix:@"map_Kd"])
    {
      NSString *subString = [line substringFromIndex:7];
      const char str = *(subString.UTF8String);
      model.textures[materialIndex][sizeof(str)] = str;
    }
  }

  if (0 == materialCount)
  {
    return [NSError errorWithDomain:@"No materials found in mtl file." code:902 userInfo:nil];
  }

  model.materials = materialCount;

  return nil;
}

@end
