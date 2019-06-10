//
//  DWReaderChapter.h
//  DWReader
//
//  Created by Wicky on 2019/2/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DWReaderPageInfo.h"
#import "DWReaderRenderConfiguration.h"
#import "DWReaderChapterInfo.h"



NS_ASSUME_NONNULL_BEGIN

@interface DWReaderChapter : NSObject

#pragma mark --- 输入数据 ---
///远端获取的原始数据
@property (nonatomic ,copy ,readonly) NSString * originString;

///标题
@property (nonatomic ,copy ,readonly) NSString * title;

///要过滤的字符或字符串
@property (nonatomic ,strong ,readonly) NSCharacterSet * charactersToBeFiltered;

///章节信息
@property (nonatomic ,strong) DWReaderChapterInfo * chapterInfo;

#pragma mark --- 可配置项 ---
///页面配置项
@property (nonatomic ,strong ,readonly) DWReaderRenderConfiguration * pageConf;

///字体颜色
@property (nonatomic ,strong ,readonly) UIColor * textColor;

#pragma mark --- 解析数据 ---
///正文内容
@property (nonatomic ,copy ,readonly) NSString * content;

///第一页信息
@property (nonatomic ,strong) DWReaderPageInfo * firstPageInfo;

///当前页面信息
@property (nonatomic ,strong) DWReaderPageInfo * curretnPageInfo;

///最后一页信息
@property (nonatomic ,weak) DWReaderPageInfo * lastPageInfo;

///正在异步解析
@property (nonatomic ,assign ,readonly) BOOL parsing;

///总页数
@property (nonatomic ,assign ,readonly) NSUInteger totalPage;

/**
 初始化章节内容

 @param oriStr 原始数据
 @param title 标题
 @param filtered 正文数据中，会被过滤的字符或字符串
 @return 章节内容
 */
+(instancetype)chapterWithOriginString:(NSString *)oriStr title:(NSString *)title charactersToBeFiltered:(NSCharacterSet *)filtered info:(DWReaderChapterInfo *)info;
-(instancetype)initWithOriginString:(NSString *)oriStr title:(NSString *)title charactersToBeFiltered:(NSCharacterSet *)filtered info:(DWReaderChapterInfo *)info;


/**
 解析内容
 
 当前解析方式定制为漫读小说项目，其中包括分段方式、段首缩进、分页最大字数等内容。后续应该暴露代理，提供扩展性。
 */
-(void)parseChapter;



/**
 按需以给定配置分页

 @param conf 页面配置
 @return 返回是否重新设置了属性
 */
-(BOOL)seperatePageWithPageConfiguration:(DWReaderRenderConfiguration *)conf;


/**
 按需设置文字颜色

 @param textColor 文字颜色
 @return 返回是否重新设置了颜色
 */
-(BOOL)configTextColor:(UIColor *)textColor;


/**
 解析内容并分段

 @param conf 页面配置
 @param reprocess 分页完成后想做的额外操作
 @param completion 异步完成回调
 */
-(void)asyncParseChapterToPageWithConfiguration:(DWReaderRenderConfiguration *)conf reprocess:(nullable dispatch_block_t)reprocess completion:(dispatch_block_t)completion;
-(void)parseChapterToPageWithConfiguration:(DWReaderRenderConfiguration *)conf reprocess:(nullable dispatch_block_t)reprocess;


/**
 二次处理chapter，重新配置首页、尾页及总页数

 @param first 新的首页
 @param last 新的尾页
 @param totalPage 新的总页数
 */
-(void)reprocessChapterWithFirstPageInfo:(DWReaderPageInfo *)first lastPageInfo:(DWReaderPageInfo *)last totalPage:(NSInteger)totalPage;


/**
 找到指定页码的页面信息

 @param pageIndex 指定页码
 @return 对应的页面信息
 */
-(DWReaderPageInfo *)pageInfoOnPage:(NSUInteger)pageIndex;

@end

NS_ASSUME_NONNULL_END
