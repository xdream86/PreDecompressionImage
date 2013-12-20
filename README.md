PreDecompressionImage For iOS
=====================


当App需要在短时间内显示大量图片时，App就会出现明显的卡顿。这主要是因为UIImage只在显示时才对图片进行解压缩操作。本项目代码给出了一种通过预解压缩图片，使用双向队列根据UIScrollView滚动的方向执行缓存图片策略。有效地解决图片渲染卡顿问题，有效的提升了app的用户体验与质量。
    
通过启用或者禁用如下代码，你可以预解压缩功能带来的提升。使用预解压缩方案，能够让图片的浏览帧率保持在55FPS。
```Objective-C 
#define PREDECOMPRESSION_IMAGES 1
```
###测试环境
* iOS 7 及以上版本
* Xcode 5 
* iPad mini

###作者
<a href="http://weibo.com/xdream86">Follow @xdream86</a>
