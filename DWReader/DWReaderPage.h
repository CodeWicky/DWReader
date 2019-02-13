//
//  DWReaderPage.h
//  DWReader
//
//  Created by Wicky on 2019/2/13.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DWReaderPage : NSObject

///绘制范围
@property (nonatomic ,assign) NSRange range;

///当前页码
@property (nonatomic ,assign) NSUInteger page;

///绘制Y纵向偏移
@property (nonatomic ,assign) CGFloat offsetY;

@end

NS_ASSUME_NONNULL_END
