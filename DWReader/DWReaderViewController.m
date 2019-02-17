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

-(void)fetchChapter:(DWReaderChapterInfo *)chapterInfo {
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
        NSAssert(NO, @"DWReader can't request book data.You must either implement -requestChapter:nextChapter:preload: or set requestBookDataCallback.");
    }
}

-(void)prepareForRequestData:(DWReaderChapterInfo *)info preload:(BOOL)preload {
    ///标志正在进行请求
    [self.requestingChapterIDs addObject:info.chapter_id];
    
    ///如果不是预加载应该有Loading，询问外部展示Loading
    if (!preload && self.loadingAction) {
        self.loadingAction(YES);
    }
}

-(void)requestCompleteWithInfo:(DWReaderChapterInfo *)info preload:(BOOL)preload title:(NSString *)title content:(NSString *)content bookID:(NSString *)bookID chapterID:(NSString *)chapterID percent:(CGFloat)percent chapterIndex:(NSInteger)chapterIndex nextChapter:(BOOL)nextChapter userInfo:(id)userInfo {
    ///请求完成后先取消请求状态
    [self.requestingChapterIDs removeObject:info.chapter_id];
    
    ///配置章节信息
    DWReaderChapter * chapter = [DWReaderChapter chapterWithOriginString:content title:title renderFrame:self.renderFrame info:info];
    
    
    ///如果是预加载，分页等工作要异步完成。由于异步自动跳转，同步不会，所以存入表中的时机要正确。按照下列的策略可以保证从表中获取的章节只有两种状态，一种是异步解析会自动跳转的状态，一种是同步解析不会自动跳转的状态
    if (preload) {
        ///如果是预加载是异步解析，且解析完成后会自动切章，所以在解析之前存储到章节表中
        [self.chapterTbl setValue:chapter forKey:info.chapter_id];
        ///如果是预加载，异步分页完成后应检测是否在等待切章
        [chapter asyncParseChapterToPageWithConfiguration:_textConf textColor:_textColor completion:^{
            [self changeChapterIfNeeded:chapter nextChapter:nextChapter];
        }];
    } else {
        ///如果不是预加载，是同步解析，当解析完成后再加入到章节表中
        [chapter parseChapterToPageWithConfiguration:_textConf textColor:_textColor];
        [self.chapterTbl setValue:chapter forKey:info.chapter_id];
    }
    
    
    ///如果不是预加载应询问外部隐藏Loading
    if (!preload && self.loadingAction) {
        self.loadingAction(NO);
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
    
    ///然后进行翻页即可(翻页操作必须在主线程)
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentPageVC = availablePage;
        ///关闭交互避免连续翻页
        self.view.userInteractionEnabled = NO;
        __weak typeof(self)weakSelf = self;
        [self setViewControllers:@[availablePage] direction:nextChapter?UIPageViewControllerNavigationDirectionForward:UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL finished) {
            weakSelf.view.userInteractionEnabled = YES;
        }];
    });
    
    if (nextChapter) {
        self.waitingChangeNextChapter = NO;
    } else {
        self.waitingChangePreviousChapter = NO;
    }
}

-(NSString *)queryNextChapterId {
    DWReaderChapterInfo * currentChapterInfo = self.currentChapter.chapterInfo;
    if (self.readerDelegate && [self.readerDelegate respondsToSelector:@selector(reader:queryNextChapterIdForBook:currentChapterID:)]) {
        return [self.readerDelegate reader:self queryNextChapterIdForBook:currentChapterInfo.book_id currentChapterID:currentChapterInfo.chapter_id];
    } else if (self.queryNextChapterIdCallback) {
        return self.queryNextChapterIdCallback(self,currentChapterInfo.book_id,currentChapterInfo.chapter_id);
    } else {
        NSAssert(NO, @"DWReader can't query next chapter_id.You must either implement -reader:queryNextChapterIdForBook:currentChapterID:currentChapterIndex: or set queryNextChapterIdCallback.");
        return nil;
    }
}

#pragma mark --- UIPageViewController Delegate ---
-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(DWReaderPageViewController *)viewController {
    
    ///首先取出下一页信息，在同一章中，页面信息存有链表关系，如果取到为nil说明这一章结束了，这时候要考虑下一章
    DWReaderPageInfo * nextPage = viewController.pageInfo.nextPageInfo;
    
    if (nextPage) {
        ///先取出可用于渲染下一页的页面控制器，在更新页面配置信息
        DWReaderPageViewController * nextPageVC = viewController.nextPage;
        [nextPageVC updateInfo:nextPage];
        self.currentPageVC = nextPageVC;
        return nextPageVC;
    }
    
    ///如果当前无页面配置信息代表要切章了，首先找到下一章
    NSString * nextChapterID = [self queryNextChapterId];
    ///如果获取不到章节ID则代表是最后一章了，询问外部动作,并返回
    if (!nextChapterID.length) {
        if (self.noMoreChapter) {
            self.noMoreChapter(YES);
        }
        return nil;
    }
    ///获取到下章ID，先查询本地是否存在下一章，不存在直接请求下章即可，同时要将等待翻页置位真，让请求完成后自动翻页
    DWReaderChapter * nextChapter = [self.chapterTbl valueForKey:nextChapterID];
    if (nextChapter) {
        ///如果存在，若当前正在解析，则状态已经记录下来，回调中会自动切章，不需额外切章，如果不是正在解析说明是解析过的章节且没有跳转功能，现在开始跳转
        if (!nextChapter.parsing) {
            ///切换章节并找到章节中第一页
            self.currentChapter = nextChapter;
            nextPage = nextChapter.pages.firstObject;
            DWReaderPageViewController * nextPageVC = viewController.nextPage;
            [nextPageVC updateInfo:nextPage];
            self.currentPageVC = nextPageVC;
            return nextPageVC;
        }
        return nil;
    }
    
    ///如果不存在下一章直接请求下一章即可
    DWReaderChapterInfo * chapterInfo = [[DWReaderChapterInfo alloc] init];
    chapterInfo.book_id = self.currentChapter.chapterInfo.book_id;
    chapterInfo.chapter_id = nextChapterID;
    self.waitingChangeNextChapter = YES;
    ///异步提交请求任务，如果同步的话会造成当整个数据获取过程是同步时（即读取本地缓存数据），同步设置了pageViewController的vc，然后又立刻返回了nil。UIPageViewController如果短时间内改变两次vc（在一个动画未完成即开始另一个动画）避险黑屏。所以分成两次提交。
    dispatch_async(dispatch_get_main_queue(), ^{
        [self requestChapter:chapterInfo nextChapter:YES preload:NO];
    });
    return nil;
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(DWReaderPageViewController *)viewController {
    return nil;
}

///避免连续翻页渲染失败
-(void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers {
    pageViewController.view.userInteractionEnabled = NO;
}

-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    pageViewController.view.userInteractionEnabled = YES;
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
