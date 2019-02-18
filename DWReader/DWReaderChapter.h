//
//  DWReaderChapter.h
//  DWReader
//
//  Created by Wicky on 2019/2/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DWReaderPageInfo.h"
#import "DWReaderTextConfiguration.h"
#import "DWReaderChapterInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWReaderChapter : NSObject

#pragma mark --- 输入数据 ---
///远端获取的原始数据
@property (nonatomic ,copy ,readonly) NSString * originString;

///标题
@property (nonatomic ,copy ,readonly) NSString * title;

///渲染尺寸
@property (nonatomic ,assign ,readonly) CGRect renderFrame;

///章节信息
@property (nonatomic ,strong) DWReaderChapterInfo * chapterInfo;

#pragma mark --- 可配置项 ---
///页面配置项
@property (nonatomic ,strong ,readonly) DWReaderTextConfiguration * pageConf;

///字体颜色
@property (nonatomic ,strong ,readonly) UIColor * textColor;

#pragma mark --- 解析数据 ---
///正文内容
@property (nonatomic ,copy ,readonly) NSString * content;

///分页信息
@property (nonatomic ,strong ,readonly) NSArray <DWReaderPageInfo *>* pages;

///正在异步解析
@property (nonatomic ,assign ,readonly) BOOL parsing;

///总页数
@property (nonatomic ,assign ,readonly) NSUInteger totalPage;

/**
 初始化章节内容

 @param oriStr 原始数据
 @param title 标题
 @param renderFrame 渲染尺寸
 @return 章节内容
 */
+(instancetype)chapterWithOriginString:(NSString *)oriStr title:(NSString *)title renderFrame:(CGRect)renderFrame info:(DWReaderChapterInfo *)info;
-(instancetype)initWithOriginString:(NSString *)oriStr title:(NSString *)title renderFrame:(CGRect)renderFrame info:(DWReaderChapterInfo *)info;


/**
 解析内容
 
 当前解析方式定制为漫读小说项目，其中包括分段方式、段首缩进、分页最大字数等内容。后续应该暴露代理，提供扩展性。
 */
-(void)parseChapter;



/**
 按给定配置分页

 @param conf 页面配置
 */
-(void)seperatePageWithPageConfiguration:(DWReaderTextConfiguration *)conf;


/**
 设置文字颜色

 @param textColor 文字颜色
 */
-(void)configTextColor:(UIColor *)textColor;


/**
 解析内容并分段

 @param conf 页面配置
 @param textColor 文字颜色
 @param completion 异步完成回调
 */
-(void)asyncParseChapterToPageWithConfiguration:(DWReaderTextConfiguration *)conf textColor:(UIColor *)textColor completion:(dispatch_block_t)completion;
-(void)parseChapterToPageWithConfiguration:(DWReaderTextConfiguration *)conf textColor:(UIColor *)textColor;


@end

NS_ASSUME_NONNULL_END
