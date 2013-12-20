//
//  ImagePreDeCompresser.m
//  PreDecompressionImage
//
//  Created by Aegaeon on 12/20/13.
//  Copyright (c) 2013 Aegaeon. All rights reserved.
//

#import "ImagePreDeCompresser.h"

@implementation ImagePreDeCompresser


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFilePath:(NSString *)aFilePath indexPath:(NSIndexPath *)indexPath delegate:(id<ImagePreDeCompresserDelegate>) deleagate{
  if (self = [super init]) {
    _filePath = aFilePath;
    _indexPath = indexPath;
    _delegate = deleagate;
  }
  
  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)main {
  @autoreleasepool {
    self.image = [self preDecompressedImage];
    if (self.delegate) {
      [self.delegate imagePreDeCompresserDidFinish:self];
    }
  }
}


/**
 * 预解压缩图片
 */
///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIImage *)preDecompressedImage{
  UIImage *image = [UIImage imageWithContentsOfFile:self.filePath];
  
  UIGraphicsBeginImageContextWithOptions(image.size, NO, 0);
  [image drawAtPoint:CGPointZero];
  UIImage *decompressedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return decompressedImage;
}

@end
