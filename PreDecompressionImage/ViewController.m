//
//  ViewController.m
//  PreDecompressionImage
//
//  Created by Aegaeon on 12/19/13.
//  Copyright (c) 2013 Aegaeon. All rights reserved.
//


#import "ViewController.h"
#import "ImagePreDeCompresser.h"


#define PREDECOMPRESSION_IMAGES 1 // 打开预解压功能

/**
 * 预加载图片数
 */
static const NSInteger kPreDecompressionImageCount= 4;

/**
 * 最大缓存图片数
 * 如果当前缓存数超载，根据滑动的方向，往下滑动则替换indexPath.row最小位置的缓存图片；
 * 如果往上滑动则替换indexPath.row最大位置的缓存图片
 */
static const NSUInteger kMaxCacheImageCount = 8;

@interface ViewController () <ImagePreDeCompresserDelegate> {
  NSArray             *_imagePaths;  // 图片路径数组
  NSInteger            _lastContentOffset; // 计算滑动方向的内容偏移量
  NSMutableDictionary *_cacheImagesMap;  // 缓存被异步解压缩后的图片
}

@property (weak, nonatomic) IBOutlet UITableView  *tableView;
@property (strong, nonatomic) NSOperationQueue    *preDecompressionQueue;
@property (nonatomic, strong) NSMutableDictionary *preDecompressionsInProgress;
@end

@implementation ViewController


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSBundle *mainBundle = [NSBundle mainBundle];
  _imagePaths = [mainBundle pathsForResourcesOfType:@"png" inDirectory:@"images"];
  _cacheImagesMap = [NSMutableDictionary dictionaryWithCapacity:kPreDecompressionImageCount];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSMutableDictionary *)preDecompressionsInProgress {
  if (!_preDecompressionsInProgress) {
    _preDecompressionsInProgress = [[NSMutableDictionary alloc] init];
  }
  
  return _preDecompressionsInProgress;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSOperationQueue *)preDecompressionQueue {
  if (!_preDecompressionQueue) {
    _preDecompressionQueue = [[NSOperationQueue alloc] init];
    _preDecompressionQueue.name = @"reDecompression Queue";
  }
  
  return _preDecompressionQueue;
}


/**
 * indexPath位置的图片尺寸
 */
///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGSize)imageSizeAtIndexPath:(NSIndexPath *)indexPath {
  NSString *path = _imagePaths[indexPath.row];
  UIImage *image = [UIImage imageWithContentsOfFile:path];
  
  return image.size;
}

/**
 * UITableViewDataSourceDelegate 实现方法
 */
///////////////////////////////////////////////////////////////////////////////////////////////////
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    imageView.tag = 1;
    [cell.contentView addSubview:imageView];
  }
  
#if PREDECOMPRESSION_IMAGES
  UIImage *image;
  if (_cacheImagesMap[indexPath]) {
    image = _cacheImagesMap[indexPath];
  } else {
    NSString *path = _imagePaths[indexPath.row];
    image = [UIImage imageWithContentsOfFile:path];
  }
#else
  NSString *path = _imagePaths[indexPath.row];
  UIImage *image = [UIImage imageWithContentsOfFile:path];
#endif
  
  UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
  imageView.frame = (CGRect){CGPointZero, [self imageSizeAtIndexPath:indexPath]};
  imageView.image = image;
  
  return cell;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  CGSize imageSize = [self imageSizeAtIndexPath:indexPath];
  
  return imageSize.height;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_imagePaths count];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidScroll:(UITableView *)tableView {
#if PREDECOMPRESSION_IMAGES
  
  // 获取滚动视图的滑动方向
  ScrollDirection scrollDirection = ScrollDirectionNone;
  
  if (_lastContentOffset < tableView.contentOffset.y) {
    scrollDirection = ScrollDirectionDown;
  } else if (_lastContentOffset > tableView.contentOffset.y) {
    scrollDirection = ScrollDirectionUp;
  }
  
  _lastContentOffset = tableView.contentOffset.y;
  
  NSArray *indexes = [tableView indexPathsForVisibleRows];
  NSIndexPath *topVisibleIndexPath = indexes[0];
  NSIndexPath *bottomVisibleIndexPath = [indexes lastObject];
  
  if (scrollDirection == ScrollDirectionUp) {
    for (NSInteger row = MAX(0, topVisibleIndexPath.row - 1); row >= MAX(0, topVisibleIndexPath.row - kPreDecompressionImageCount); row--) {
      NSIndexPath *requestIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
      
      UIImage *image = _cacheImagesMap[requestIndexPath];
      if (!image) {
        
        // 往上滑，移除最大的indexPath.row位置缓存图片
        NSArray *allKeys = [_cacheImagesMap allKeys];
        if([allKeys count] >= kMaxCacheImageCount) {
          NSNumber *maxRowNumber = [allKeys valueForKeyPath:@"@max.row"];
          NSIndexPath *maxIndexPathKey = [NSIndexPath indexPathForRow:[maxRowNumber intValue] inSection:0];
          [_cacheImagesMap removeObjectForKey:maxIndexPathKey];
        }
        
        // 查看是否已加入预解压图片操作队列
        if (![[self.preDecompressionsInProgress allKeys] containsObject:requestIndexPath]) {
          NSString *path = _imagePaths[requestIndexPath.row];
          ImagePreDeCompresser *deCompresser = [[ImagePreDeCompresser alloc] initWithFilePath:path
                                                                                    indexPath:requestIndexPath
                                                                                     delegate:self];
          
          self.preDecompressionsInProgress[requestIndexPath] = deCompresser;
          [self.preDecompressionQueue addOperation:deCompresser];
        }
      }
    }
  }
  
  if (scrollDirection == ScrollDirectionDown) {
    NSInteger startValue = MIN([tableView numberOfRowsInSection:0] - 1, bottomVisibleIndexPath.row + 1);
    NSInteger endValue = MIN([tableView numberOfRowsInSection:0] - 1, bottomVisibleIndexPath.row + kPreDecompressionImageCount);
    
    for (NSInteger row = startValue; row <= endValue; row++) {
      NSIndexPath *requestIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
      UIImage *image = _cacheImagesMap[requestIndexPath];
      
      if (!image) {
        
        // 往下滑，移除最小的indexPath.row位置缓存图片
        NSArray *allKeys = [_cacheImagesMap allKeys];
        if([allKeys count] >= kMaxCacheImageCount) {
          NSNumber *minRowNumber = [allKeys valueForKeyPath:@"@min.row"];
          NSIndexPath *minIndexPathKey = [NSIndexPath indexPathForRow:[minRowNumber intValue] inSection:0];
          [_cacheImagesMap removeObjectForKey:minIndexPathKey];
        }
        
        // 查看是否已加入预解压图片操作队列
        if (![[self.preDecompressionsInProgress allKeys] containsObject:requestIndexPath]) {
          NSString *path = _imagePaths[requestIndexPath.row];
          ImagePreDeCompresser *deCompresser = [[ImagePreDeCompresser alloc] initWithFilePath:path
                                                                                    indexPath:requestIndexPath
                                                                                     delegate:self];
          
          self.preDecompressionsInProgress[requestIndexPath] = deCompresser;
          [self.preDecompressionQueue addOperation:deCompresser];
        }
      }
    }
  }
#endif
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)imagePreDeCompresserDidFinish:(ImagePreDeCompresser *)imagePreDeCompresser {
  _cacheImagesMap[imagePreDeCompresser.indexPath] = imagePreDeCompresser.image;
  [self.preDecompressionsInProgress removeObjectForKey:imagePreDeCompresser.indexPath];
}

@end
