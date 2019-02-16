//
//  DWReaderViewController.h
//  DWReader
//
//  Created by Wicky on 2019/2/16.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DWReaderChapterInfo.h"
#import "DWReaderTextConfiguration.h"
#import "DWReaderDisplayConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@class DWReaderViewController;

typedef void(^DWReaderRequestDataCompleteCallback)(NSString * title ,NSString * content ,NSString * bookID ,NSString * chapterID ,CGFloat percent,NSInteger chapterIndex ,BOOL nextChapter,_Nullable id userInfo);
typedef NSString *(^DWReaderQueryChapterIDCallback)(DWReaderViewController * reader ,NSString * bookID ,NSString * currentChapterID ,NSInteger chapterIndex);
typedef void(^DWReaderRequestBookDataCallback)(DWReaderViewController * reader ,NSString * bookID ,NSString * chapterID ,BOOL nextChapter ,DWReaderRequestDataCompleteCallback requestCompleteCallback);

@protocol DWReaderDataDelegate <NSObject>


/**
 根据给定信息返回下一章的章节ID

 @param reader 当前阅读器对象
 @param bookID 当前书籍的bookID
 @param chapterID 当前章节的chapterID
 @param chapterIndex 当前章节的index
 @return 返回下一章的章节ID
 
 注：chapterIndex由开发者自己维护，只是提供给开发者一个更快寻找chapterID的手段
 */
-(NSString *)reader:(DWReaderViewController *)reader queryNextChapterIdForBook:(NSString *)bookID currentChapterID:(NSString *)chapterID currentChapterIndex:(NSInteger)chapterIndex;


/**
 根据给定信息返回上一章的章节ID
 
 @param reader 当前阅读器对象
 @param bookID 当前书籍的bookID
 @param chapterID 当前章节的chapterID
 @param chapterIndex 当前章节的index
 @return 返回上一章的章节ID
 */
-(NSString *)reader:(DWReaderViewController *)reader queryPreviousChapterIdForBook:(NSString *)bookID currentChapterID:(NSString *)chapterID currentChapterIndex:(NSInteger)chapterIndex;

/**
 请求对应章节内容

 @param reader 当前阅读器对象
 @param bookID 请求的书籍ID
 @param chapterID 请求的章节ID
 @param callback 请求后回调数据给reader的callback
 */
-(void)reader:(DWReaderViewController *)reader requestBookDataForBook:(NSString *)bookID chapterID:(NSString *)chapterID nextChapter:(BOOL)next requestCompleteCallback:(DWReaderRequestDataCompleteCallback)callback;

@end

@interface DWReaderViewController : UIPageViewController

///获取书籍数据代理（如果指定代理且代理实现对应方法则优先是否代理方法，否则使用回调方法）
@property (nonatomic ,weak) id<DWReaderDataDelegate> readerDelegate;

///根据给定信息返回下一章的章节ID
@property (nonatomic ,copy) DWReaderQueryChapterIDCallback queryNextChapterIdCallback;

///根据给定信息返回上一章的章节ID
@property (nonatomic ,copy) DWReaderQueryChapterIDCallback queryPreviousChapterIdCallback;

///请求对应章节内容
@property (nonatomic ,copy) DWReaderRequestBookDataCallback requestBookDataCallback;

///展示Loading的回调
@property (nonatomic ,copy) dispatch_block_t showLoading;

///隐藏Loading的回调
@property (nonatomic ,copy) dispatch_block_t hideLoading;


/**
 初始化阅读器

 @param textConf 阅读器文字配置信息
 @param displayConf 阅读器展示配置信息

 @return 阅读器实例
 */
+(instancetype)readerWithTextConfiguration:(DWReaderTextConfiguration *)textConf displayConfiguration:(DWReaderDisplayConfiguration *)displayConf;


/**
 按章节信息配置阅读器

 @param chapterInfo 章节信息
 */
-(void)configWithChapterInfo:(DWReaderChapterInfo *)chapterInfo;

@end

NS_ASSUME_NONNULL_END
