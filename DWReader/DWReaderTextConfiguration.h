//
//  DWReaderTextConfiguration.h
//  DWReader
//
//  Created by Wicky on 2019/2/16.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*
 页面文字配置
 */
@interface DWReaderTextConfiguration : NSObject

///文字字体(如果展示中文，建议采用中文字体。否则系统细算分页的时候存在问题)
@property (nonatomic ,copy) NSString * fontName;

///标题字号
@property (nonatomic ,assign) CGFloat titleFontSize;

///标题行间距
@property (nonatomic ,assign) CGFloat titleLineSpacing;

///标题距正文的距离
@property (nonatomic ,assign) CGFloat titleSpacing;

///正文字号
@property (nonatomic ,assign) CGFloat contentFontSize;

///行间距
@property (nonatomic ,assign) CGFloat contentLineSpacing;

///段落间距
@property (nonatomic ,assign) CGFloat paragraphSpacing;

///段首缩进
@property (nonatomic ,assign) CGFloat paragraphHeaderSpacing;

@end

NS_ASSUME_NONNULL_END
