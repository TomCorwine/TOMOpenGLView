//
//  TOMObjImporter.m
//  TOMOpenGLView
//
//  Created by Tom Corwine on 9/19/14.
//  Copyright (c) 2014 Tom's iPhone Apps. All rights reserved.
//

#import "TOMObjImporter.h"

static TOMModel model;
static NSMutableArray *materialNames;

@implementation TOMObjImporter

TOMModel objectModel()
{
  return model;
}

+ (NSError *)importObjFilename:(NSString *)filename
{
  NSError *error;
  filename = [filename stringByReplacingOccurrencesOfString:@".obj" withString:@""];
  NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"obj"];
  NSString *objString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];

  //model = (TOMModel){0};

  if (nil == error)
  {
    error = [self extractOBJdata:objString];
  }

  if (error)
  {
    return error;
  }

  return nil;
}

+ (NSError *)extractOBJdata:(NSString *)objString
{
  NSArray *lines = [objString componentsSeparatedByString:@"\n"];

  int verticesCount = 0;
  int positionsCount = 0;
  int texelsCount = 0;
  int normalsCount = 0;
  int facesCount = 0;

  for (NSString *line in lines)
  {
    if ([line hasPrefix:@"vt"])
    {
      texelsCount++;
    }
    else if ([line hasPrefix:@"vn"])
    {
      normalsCount++;
    }
    else if ([line hasPrefix:@"v"])
    {
      positionsCount++;
    }
    else if ([line hasPrefix:@"f"])
    {
      facesCount++;
    }

    verticesCount = facesCount * 3;
  }

  float positions[positionsCount][3];
  float texels[texelsCount][2];
  float normals[normalsCount][3];
  int faces[facesCount][10];

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
        texels[texelsIndex][i] = item.doubleValue;
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
        normals[normalsIndex][i] = item.doubleValue;
      }

      normalsIndex++;
    }
    else if ([line hasPrefix:@"v"])
    {
      NSString *subString = [line substringFromIndex:2];
      NSArray *items = [subString componentsSeparatedByString:@" "];
      if (items.count != 3)
      {
        return [NSError errorWithDomain:@"Faces not triangular." code:900 userInfo:nil];
      }

      for (int i = 0; i < 3; i++)
      {
        NSString *item = items[i];
        positions[verticiesIndex][i] = item.doubleValue;
      }

      verticiesIndex++;
    }
    else if ([line hasPrefix:@"f"])
    {
      NSString *subString = [line substringFromIndex:2];
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
      
      faces[facesIndex][9] = materialIndex;
      facesIndex++;
    }
  }

  model.vertices = (verticiesIndex * 3) + 1;

  verticiesIndex = 0;
  texelsIndex = 0;
  normalsIndex = 0;
  int counts[model.materials];
  for (int j = 0; j < model.materials; j++)
  {
    counts[j] = 0;

    for (int i = 0; i < facesIndex; i++)
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

        model.positions[verticiesIndex] = positions[vA][0];
        verticiesIndex++;
        model.positions[verticiesIndex] = positions[vA][1];
        verticiesIndex++;
        model.positions[verticiesIndex] = positions[vA][2];
        verticiesIndex++;
        
        model.texels[texelsIndex] = texels[vtA][0];
        texelsIndex++;
        model.texels[texelsIndex] = texels[vtA][1];
        texelsIndex++;
        
        model.normals[normalsIndex] = normals[vnA][0];
        normalsIndex++;
        model.normals[normalsIndex] = normals[vnA][1];
        normalsIndex++;
        model.normals[normalsIndex] = normals[vnA][2];
        normalsIndex++;
        
        model.positions[verticiesIndex] = positions[vB][0];
        verticiesIndex++;
        model.positions[verticiesIndex] = positions[vB][1];
        verticiesIndex++;
        model.positions[verticiesIndex] = positions[vB][2];
        verticiesIndex++;
        
        model.texels[texelsIndex] = texels[vtB][0];
        texelsIndex++;
        model.texels[texelsIndex] = texels[vtB][1];
        texelsIndex++;
        
        model.normals[normalsIndex] = normals[vnB][0];
        normalsIndex++;
        model.normals[normalsIndex] = normals[vnB][1];
        normalsIndex++;
        model.normals[normalsIndex] = normals[vnB][2];
        normalsIndex++;
        
        model.positions[verticiesIndex] = positions[vC][0];
        verticiesIndex++;
        model.positions[verticiesIndex] = positions[vC][1];
        verticiesIndex++;
        model.positions[verticiesIndex] = positions[vC][2];
        verticiesIndex++;
        
        model.texels[texelsIndex] = texels[vtC][0];
        texelsIndex++;
        model.texels[texelsIndex] = texels[vtC][1];
        texelsIndex++;
        
        model.normals[normalsIndex] = normals[vnC][0];
        normalsIndex++;
        model.normals[normalsIndex] = normals[vnC][1];
        normalsIndex++;
        model.normals[normalsIndex] = normals[vnC][2];
        normalsIndex++;
      }
    }
  }

  for (int i = 0; i < model.materials; i++)
  {
    if (0 == i)
    {
      model.firsts[i] = 0;
    }
    else
    {
      model.firsts[i] = model.firsts[i - 1] + counts[i - 1];
    }

    model.counts[i] = counts[i];
  }
  
  NSMutableString *debugString = @"".mutableCopy;
  
  [debugString stringByAppendingString:@"// This is a .c file for the model: Black_Throated_Green\n\n#include  \"Black_Throated_Green.h\"\n\n"];

  [debugString appendString:[NSString stringWithFormat:@"const int objVertices = %d;\n\n", model.vertices]];
  
  [debugString appendString:[NSString stringWithFormat:@"const float objPositions[%d] = \n{\n", verticiesIndex]];
  for (int i = 0; i < verticiesIndex / 3; i++)
  {
    [debugString appendString:[NSString stringWithFormat:@"%f, %f, %f,\n", model.positions[i], model.positions[i + 1], model.positions[i + 2]]];
  }
  [debugString appendString:@"};\n"];
  
  [debugString appendString:[NSString stringWithFormat:@"\nconst float objTexels[%d] = \n{\n", texelsIndex]];
  for (int i = 0; i < texelsIndex / 2; i++)
  {
    [debugString appendString:[NSString stringWithFormat:@"%f, %f\n", model.texels[i], model.texels[i + 1]]];
  }
  [debugString appendString:@"};\n"];
  
  [debugString appendString:[NSString stringWithFormat:@"\nconst float objNormals[%d] = \n{", normalsIndex]];
  for (int i = 0; i < normalsIndex / 3; i++)
  {
    [debugString appendString:[NSString stringWithFormat:@"%f, %f, %f,\n", model.normals[i], model.normals[i + 1], model.normals[i + 2]]];
  }
  [debugString appendString:@"};\n"];

  //NSString *urlString = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
  //[debugString writeToFile:[urlString stringByAppendingString:@"/blah.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
  [debugString writeToFile:@"/Users/tcorwine/Desktop/blah.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];

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
    else if ([line hasPrefix:@"Kd"])
    {
      NSString *subString = [line substringFromIndex:3];
      NSArray *items = [subString componentsSeparatedByString:@" "];

      for (int i = 0; i < 3; i++)
      {
        NSString *item = items[i];
        model.diffuses[materialIndex][i] = item.doubleValue;
      }
    }
    else if ([line hasPrefix:@"Ks"])
    {
      NSString *subString = [line substringFromIndex:3];
      NSArray *items = [subString componentsSeparatedByString:@" "];

      for (int i = 0; i < 3; i++)
      {
        NSString *item = items[i];
        model.speculars[materialIndex][i] = item.doubleValue;
      }
    }
    else if ([line hasPrefix:@"map_Kd"])
    {
      NSString *subString = [line substringFromIndex:7];
      const char *str = subString.UTF8String;
      for (int i = 0; i < subString.length; i++)
      {
        model.textures[materialIndex][i] = str[i];
      }
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
