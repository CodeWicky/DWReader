//
//  DWReaderDisplayConfiguration.h
//  DWReader
//
//  Created by Wicky on 2019/2/17.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

///阅读器展示配置
@interface DWReaderDisplayConfiguration : NSObject

///渲染尺寸
@property (nonatomic ,assign) CGRect renderFrame;

///翻页效果
@property (nonatomic ,assign) UIPageViewControllerTransitionStyle transitionStyle;

///文字颜色
@property (nonatomic ,strong) UIColor * textColor;

@end

NS_ASSUME_NONNULL_END
