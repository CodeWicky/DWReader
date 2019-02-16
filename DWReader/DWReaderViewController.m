//
//  DWReaderViewController.m
//  DWReader
//
//  Created by Wicky on 2019/2/16.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderViewController.h"
#import "DWReaderChapter.h"
#import "DWReaderPageViewController.h"

@interface DWReaderViewController ()<UIPageViewControllerDelegate ,UIPageViewControllerDataSource>

@property (nonatomic ,strong) DWReaderTextConfiguration * textConf;

@property (nonatomic ,strong) UIColor * textColor;

@property (nonatomic ,strong) DWReaderChapterInfo * info;

@property (nonatomic ,assign) CGRect renderFrame;

@property (nonatomic ,assign) BOOL waitingChangeNextChapter;

@property (nonatomic ,assign) BOOL waitingChangePreviousChapter;

@property (nonatomic ,strong) NSMutableSet * requestingChapterIDs;

@property (nonatomic ,strong) NSMutableDictionary * chapterTbl;

@property (nonatomic ,strong) DWReaderChapter * currentChapter;

@property (nonatomic ,strong) NSMutableArray <DWReaderPageViewController *>* pageVCs;

@property (nonatomic ,strong) DWReaderPageViewController * currentPageVC;

@end

@implementation DWReaderViewController

+(instancetype)readerWithTextConfiguration:(DWReaderTextConfiguration *)textConf displayConfiguration:(DWReaderDisplayConfiguration *)displayConf {
    if (CGRectEqualToRect(displayConf.renderFrame, CGRectNull) || CGRectEqualToRect(displayConf.renderFrame, CGRectZero)) {
        NSAssert(NO, @"DWReader can't initialize a reader with renderFrame is either CGRectNull or CGRectZero.");
        return nil;
    }
    __kindof DWReaderViewController * reader = [[[self class] alloc] initWithConfiguration:textConf renderFrame:displayConf.renderFrame textColor:displayConf.textColor transitionStyle:displayConf.transitionStyle];
    return reader;
}

-(void)configWithChapterInfo:(DWReaderChapterInfo *)chapterInfo {
    self.waitingChangeNextChapter = YES;
    [self requestChapter:chapterInfo nextChapter:YES preload:NO];
}

-(instancetype)initWithConfiguration:(DWReaderTextConfiguration *)conf renderFrame:(CGRect)renderFrame textColor:(UIColor *)textColor transitionStyle:(UIPageViewControllerTransitionStyle)transitionStyle {
    if (self = [super initWithTransitionStyle:transitionStyle navigationOrientation:(UIPageViewControllerNavigationOrientationHorizontal) options:nil]) {
        self.delegate = self;
        self.dataSource = self;
        _textConf = conf;
        _textColor = textColor;
        _renderFrame = renderFrame;
        [self configPages];
    }
    return self;
}

#pragma mark --- life cycle ---
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark --- tool method ---
-(void)configPages {
    DWReaderPageViewController * tmp1 = [DWReaderPageViewController pageWithRenderFrame:self.renderFrame];
    DWReaderPageViewController * tmp2 = [DWReaderPageViewController pageWithRenderFrame:self.renderFrame];
    [tmp1 configNextPage:tmp2];
    [tmp2 configNextPage:tmp1];
    [self.pageVCs addObject:tmp1];
    [self.pageVCs addObject:tmp2];
    self.currentPageVC = tmp1;
}

-(void)requestChapter:(DWReaderChapterInfo *)info nextChapter:(BOOL)next preload:(BOOL)preload {
    ///避免重复请求
    if ([self.requestingChapterIDs containsObject:info.chapter_id]) {
        if (!preload) {
            ///如果不是预加载但是还要避免重复请求说明是用户手动拖动导致的数据请求，这时虽然请求不重复做，但是要将用户需要切章的状态记下来。同时用户的切章状态只能有一个
            if (next) {
                self.waitingChangeNextChapter = YES;
                self.waitingChangePreviousChapter = NO;
            } else {
                self.waitingChangePreviousChapter = YES;
                self.waitingChangeNextChapter = NO;
            }
        }
        return;
    }
    
    ///优先使用代理模式，其次使用回调模式
    if (self.readerDelegate && [self.readerDelegate respondsToSelector:@selector(reader:requestBookDataForBook:chapterID:nextChapter:requestCompleteCallback:)]) {
        ///为请求做准备工作
        [self prepareForRequestData:info preload:preload];
        __weak typeof(self)weakSelf = self;
        [self.readerDelegate reader:self requestBookDataForBook:info.book_id chapterID:info.chapter_id nextChapter:next requestCompleteCallback:^(NSString * _Nonnull title, NSString * _Nonnull content, NSString * _Nonnull bookID, NSString * _Nonnull chapterID, CGFloat percent, NSInteger chapterIndex, BOOL nextChapter, id  _Nonnull userInfo) {
            [weakSelf requestCompleteWithInfo:info preload:preload title:title content:content bookID:bookID chapterID:chapterID percent:percent chapterIndex:chapterIndex nextChapter:nextChapter userInfo:userInfo];
        }];
    } else if (self.requestBookDataCallback) {
        __weak typeof(self)weakSelf = self;
        self.requestBookDataCallback(self, info.book_id, info.chapter_id, next, ^(NSString * _Nonnull title, NSString * _Nonnull content, NSString * _Nonnull bookID, NSString * _Nonnull chapterID, CGFloat percent, NSInteger chapterIndex, BOOL nextChapter, id  _Nonnull userInfo) {
            [weakSelf requestCompleteWithInfo:info preload:preload title:title content:content bookID:bookID chapterID:chapterID percent:percent chapterIndex:chapterIndex nextChapter:nextChapter userInfo:userInfo];
        });
    } else {
        ///如果没有请求方式就将等待至NO，实际没有请求方式这不就凉凉了么
        self.waitingChangePreviousChapter = NO;
        self.waitingChangeNextChapter = NO;
    }
}

-(void)prepareForRequestData:(DWReaderChapterInfo *)info preload:(BOOL)preload {
    ///标志正在进行请求
    [self.requestingChapterIDs addObject:info.chapter_id];
    
    ///如果不是预加载应该有Loading，询问外部展示Loading
    if (!preload && self.showLoading) {
        self.showLoading();
    }
}

-(void)requestCompleteWithInfo:(DWReaderChapterInfo *)info preload:(BOOL)preload title:(NSString *)title content:(NSString *)content bookID:(NSString *)bookID chapterID:(NSString *)chapterID percent:(CGFloat)percent chapterIndex:(NSInteger)chapterIndex nextChapter:(BOOL)nextChapter userInfo:(id)userInfo {
    ///请求完成后先取消请求状态
    [self.requestingChapterIDs removeObject:info.chapter_id];
    
    ///配置章节信息
    DWReaderChapter * chapter = [DWReaderChapter chapterWithOriginString:content title:title renderFrame:self.renderFrame info:info];
    [self.chapterTbl setValue:chapter forKey:info.chapter_id];
    
    ///如果是预加载，分页等工作要异步完成
    if (preload) {
        ///如果是预加载，异步分页完成后应检测是否在等待切章
        [chapter asyncParseChapterToPageWithConfiguration:_textConf textColor:_textColor completion:^{
            [self changeChapterIfNeeded:chapter nextChapter:nextChapter];
        }];
    } else {
        [chapter parseChapterToPageWithConfiguration:_textConf textColor:_textColor];
    }
    
    
    ///如果不是预加载应询问外部隐藏Loading
    if (!preload && self.hideLoading) {
        self.hideLoading();
    }
    
    ///当不是预加载时，如果正在等待切章且与请求方向一致，应该切章
    if (!preload) {
        [self changeChapterIfNeeded:chapter nextChapter:nextChapter];
    }
}

-(void)changeChapterIfNeeded:(DWReaderChapter *)chapter nextChapter:(BOOL)nextChapter {
    ///如果没有等待切章需求则返回
    if (!self.waitingChangeNextChapter && !self.waitingChangePreviousChapter) {
        return;
    }
    ///如果等待切章与实际切章方向不同返回
    if (self.waitingChangeNextChapter && !nextChapter) {
        return;
    }
    if (self.waitingChangePreviousChapter && nextChapter) {
        return;
    }
    
    ///切换当前章节为指定章节
    self.currentChapter = chapter;
    
    ///找到当前未使用的页面控制器(当前采取复用模式，总共只有两个页面控制器)
    DWReaderPageViewController * availablePage = self.currentPageVC.nextPage;
    ///找到页面后配置页面信息(往后翻页则找到下一章的第一页，往前翻页则找到上一章的最后一页)
    DWReaderPageInfo * pageInfo = nextChapter ? chapter.pages.firstObject : chapter.pages.lastObject;
    [availablePage updateInfo:pageInfo];
    
    ///然后进行翻页即可
    [self setViewControllers:@[availablePage] direction:nextChapter?UIPageViewControllerNavigationDirectionForward:UIPageViewControllerNavigationDirectionReverse animated:YES completion:nil];
}

#pragma mark --- UIPageViewController Delegate ---
-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(DWReaderPageViewController *)viewController {
    return nil;
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(DWReaderPageViewController *)viewController {
    return nil;
}

#pragma mark --- setter/getter ---

-(NSMutableSet *)requestingChapterIDs {
    if (!_requestingChapterIDs) {
        _requestingChapterIDs = [NSMutableSet set];
    }
    return _requestingChapterIDs;
}

-(NSMutableDictionary *)chapterTbl {
    if (!_chapterTbl) {
        _chapterTbl = [NSMutableDictionary dictionary];
    }
    return _chapterTbl;
}

-(NSMutableArray<DWReaderPageViewController *> *)pageVCs {
    if (!_pageVCs) {
        _pageVCs = [NSMutableArray arrayWithCapacity:2];
    }
    return _pageVCs;
}

@end
