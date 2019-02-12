//
//  DWChapter.h
//  DWReader
//
//  Created by Wicky on 2019/2/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DWChapter : NSObject

#pragma mark --- 输入数据 ---
///远端获取的原始数据
@property (nonatomic ,copy ,readonly) NSString * originString;

///行间距
@property (nonatomic ,assign ,readonly) CGFloat lineSpacing;

///段落间距
@property (nonatomic ,assign ,readonly) CGFloat paragraphSpacing;

#pragma mark --- 解析数据 ---
///正文内容
@property (nonatomic ,copy ,readonly) NSString * content;

///标题
@property (nonatomic ,copy ,readonly) NSString * title;


/**
 初始化章节内容

 @param oriStr 原始数据
 @param lineSpacing 行间距
 @param paragraphSpacing 段落间距
 @return 章节内容
 */
+(instancetype)chapterWithOriginString:(NSString *)oriStr lineSpacing:(CGFloat)lineSpacing paragraphSpacing:(CGFloat)paragraphSpacing;
-(instancetype)initWithOriginString:(NSString *)oriStr lineSpacing:(CGFloat)lineSpacing paragraphSpacing:(CGFloat)paragraphSpacing;


/**
 解析内容
 
 当前解析方式定制为漫读小说项目，其中包括分段方式，段首缩进两项内容。后续应该暴露代理，提供扩展性。
 */
-(void)parseChapter;

@end

NS_ASSUME_NONNULL_END
