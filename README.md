PreDecompressionImage For iOS
=====================


当UIScrollView在滚动的过程中需要显示大量的图片，如果图片又特别大，App就会有明显的卡顿感。这主要是因为UIImage只在显示时才对图片进行解压缩操作。本项目代码给出了一种通过预解压缩图片，根据UIScrollView滚动的方向使用双向队列执行缓存图片的策略。预解压缩图片能有效地解决图片渲染卡顿问题，提升App的用户体验。
    
你可以通过修改如下代码来启用或者禁用预解压缩功能。使用预解压缩方案，能够让图片的浏览帧率保持在55FPS。
```Objective-C 
#define PREDECOMPRESSION_IMAGES 1
```
###测试环境
* iOS 7 及以上版本
* Xcode 5 
* iPad mini

###作者
<a href="http://weibo.com/xdream86">Follow @xdream86</a>
