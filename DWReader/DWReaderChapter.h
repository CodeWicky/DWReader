//
//  DWReaderChapter.h
//  DWReader
//
//  Created by Wicky on 2019/2/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DWReaderPageInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class DWReaderPageInfoConfiguration;
@interface DWReaderChapter : NSObject

#pragma mark --- 输入数据 ---
///远端获取的原始数据
@property (nonatomic ,copy ,readonly) NSString * originString;

///标题
@property (nonatomic ,copy ,readonly) NSString * title;

///渲染尺寸
@property (nonatomic ,assign ,readonly) CGSize renderSize;

#pragma mark --- 可配置项 ---
///页面配置项
@property (nonatomic ,strong ,readonly) DWReaderPageInfoConfiguration * pageConf;

///字体颜色
@property (nonatomic ,strong ,readonly) UIColor * textColor;

#pragma mark --- 解析数据 ---
///正文内容
@property (nonatomic ,copy ,readonly) NSString * content;

///分页信息
@property (nonatomic ,strong ,readonly) NSArray <DWReaderPageInfo *>* pages;

/**
 初始化章节内容

 @param oriStr 原始数据
 @param title 标题
 @param renderSize 渲染尺寸
 @return 章节内容
 */
+(instancetype)chapterWithOriginString:(NSString *)oriStr title:(NSString *)title renderSize:(CGSize)renderSize;
-(instancetype)initWithOriginString:(NSString *)oriStr title:(NSString *)title renderSize:(CGSize)renderSize;


/**
 解析内容
 
 当前解析方式定制为漫读小说项目，其中包括分段方式、段首缩进、分页最大字数等内容。后续应该暴露代理，提供扩展性。
 */
-(void)parseChapter;



/**
 按给定配置分页

 @param conf 页面配置
 */
-(void)seperatePageWithPageConfiguration:(DWReaderPageInfoConfiguration *)conf;


/**
 设置文字颜色

 @param textColor 文字颜色
 */
-(void)configTextColor:(UIColor *)textColor;

@end

/*
 页面配置
 */
@interface DWReaderPageInfoConfiguration : NSObject

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
