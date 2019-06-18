//
//  DWReaderLayouter.h
//  DWReader
//
//  Created by Wicky on 2019/6/7.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

@class DWReaderCTLineWraper;
@interface DWReaderCTLineWraper : NSObject

///对应CTLine
@property (nonatomic ,assign ,readonly) CTLineRef ctLine;

///系统坐标系原点（若要使用需转换成屏幕坐标系原点）
@property (nonatomic ,assign ,readonly) CGPoint lineOrigin;

///对应的系统尺寸
@property (nonatomic ,assign ,readonly) CGRect lineRect;

///对应的屏幕尺寸
@property (nonatomic ,assign ,readonly) CGRect frame;

///起始位置(包含)
@property (nonatomic ,assign ,readonly) NSUInteger startIndex;

///结束位置(不包含)
@property (nonatomic ,assign ,readonly) NSUInteger endIndex;

///上一行
@property (nonatomic ,weak ,readonly) DWReaderCTLineWraper * previousLine;

///下一行
@property (nonatomic ,weak ,readonly) DWReaderCTLineWraper * nextLine;

///行数
@property (nonatomic ,assign ,readonly) NSUInteger row;

@end



@interface DWReaderLayouter : NSObject

///包含的CTLine数组
@property (nonatomic ,strong ,readonly) NSArray <DWReaderCTLineWraper *>* lines;

/**
 生成布局计算类
 
 @param ctFrame 需要绘制的CTFrame
 @param height 需要绘制CTFrame对应的屏幕坐标与系统坐标转换高度（即控件尺寸，包含空白、缩进等）
 
 @return 返回对应的绘制layout类
 */
+(instancetype)layoutWithCTFrame:(CTFrameRef)ctFrame containerHeight:(CGFloat)height;

@end


