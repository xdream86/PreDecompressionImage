//
//  ImagePreDeCompresser.h
//  PreDecompressionImage
//
//  Created by Aegaeon on 12/20/13.
//  Copyright (c) 2013 Aegaeon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ImagePreDeCompresser;


@protocol ImagePreDeCompresserDelegate <NSObject>
- (void)imagePreDeCompresserDidFinish:(ImagePreDeCompresser *)imagePreDeCompresser;
@end

@interface ImagePreDeCompresser : NSOperation

@property (nonatomic, copy)   NSString    *filePath;
@property (nonatomic, strong) UIImage     *image;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, assign) id<ImagePreDeCompresserDelegate> delegate;

- (id)initWithFilePath:(NSString *)aFilePath indexPath:(NSIndexPath *)indexPath delegate:(id<ImagePreDeCompresserDelegate>) deleagate;

@end
