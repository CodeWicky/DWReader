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

@property (nonatomic ,assign) BOOL cancelableChangingPage;

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
    ///先查缓存
    
    ///获取到下章ID，先查询本地是否存在下一章，不存在直接请求下章即可，同时要将等待翻页置位真，让请求完成后自动翻页
    DWReaderChapter * nextChapter = [self.chapterTbl valueForKey:chapterInfo.chapter_id];
    if (nextChapter) {
        ///如果存在，若当前正在解析，则状态已经记录下来，回调中会自动切章，不需额外切章，如果不是正在解析说明是解析过的章节且没有跳转功能，现在开始跳转
        if (!nextChapter.parsing) {
            ///切换章节并找到章节中第一页
            self.waitingChangeNextChapter = YES;
            [self changeChapterIfNeeded:nextChapter nextChapter:YES];
        }
        return ;
    }
    
    self.waitingChangeNextChapter = YES;
    [self requestChapter:chapterInfo nextChapter:YES preload:NO];
}

-(void)preloadNextChapter {
    
    ///获取下一章章节ID，如果获取不到则返回
    NSString * chapterId = [self queryChapterId:YES];
    if (!chapterId.length) {
        return;
    }
    
    ///组装章节信息
    DWReaderChapterInfo * chapterInfo = [[DWReaderChapterInfo alloc] init];
    chapterInfo.book_id = self.currentChapter.chapterInfo.book_id;
    chapterInfo.chapter_id = chapterId;
    [self requestChapter:chapterInfo nextChapter:YES preload:YES];
}

-(void)showNextPage {
    ///首先取出下一页信息，在同一章中，页面信息存有链表关系，如果取到为nil说明这一章结束了，这时候要考虑下一章
    
    DWReaderPageViewController * currentVC = self.currentPageVC;
    DWReaderPageInfo * nextPage = currentVC.pageInfo.nextPageInfo;
    
    if (nextPage) {
        ///先取出可用于渲染下一页的页面控制器，在更新页面配置信息
        DWReaderPageViewController * nextPageVC = currentVC.nextPage;
        [nextPageVC updateInfo:nextPage];
        self.currentPageVC = nextPageVC;
        [self showPageVC:nextPageVC from:nextPageVC.previousPage nextPage:YES initial:NO];
        return;
    }
    
    ///如果当前无页面配置信息代表要切章了，首先找到下一章
    NSString * nextChapterID = [self queryChapterId:YES];
    ///如果获取不到章节ID则代表是最后一章了，询问外部动作,并返回
    if (!nextChapterID.length) {
        if (self.noMoreChapter) {
            self.noMoreChapter(YES);
        }
        return ;
    }
    ///获取到下章ID，先查询本地是否存在下一章，不存在直接请求下章即可，同时要将等待翻页置位真，让请求完成后自动翻页
    DWReaderChapter * nextChapter = [self.chapterTbl valueForKey:nextChapterID];
    if (nextChapter) {
        ///如果存在，若当前正在解析，则状态已经记录下来，回调中会自动切章，不需额外切章，如果不是正在解析说明是解析过的章节且没有跳转功能，现在开始跳转（由于直接返回vc的都是可以取消的翻页，所以如果翻页取消了，要将章节和控制器恢复成切章之前的状态）
        if (!nextChapter.parsing) {
            ///切换章节并找到章节中第一页
            ///记录当前进行的是可取消的切章状态
            self.currentChapter = nextChapter;
            nextPage = nextChapter.firstPageInfo;
            DWReaderPageViewController * nextPageVC = currentVC.nextPage;
            [nextPageVC updateInfo:nextPage];
            ///记录原始页面控制器
            self.currentPageVC = nextPageVC;
            [self showPageVC:nextPageVC from:nextPageVC.previousPage nextPage:YES initial:NO];
        }
        return ;
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
}

-(void)showPreviousPage {
    DWReaderPageViewController * currentVC = self.currentPageVC;
    DWReaderPageInfo * previousPage = currentVC.pageInfo.previousPageInfo;
    if (previousPage) {
        DWReaderPageViewController * previousPageVC = currentVC.previousPage;
        [previousPageVC updateInfo:previousPage];
        self.currentPageVC = previousPageVC;
        [self showPageVC:previousPageVC from:previousPageVC.nextPage nextPage:NO initial:NO];
        return ;
    }
    
    NSString * previousChapterID = [self queryChapterId:NO];
    if (!previousChapterID.length) {
        if (self.noMoreChapter) {
            self.noMoreChapter(YES);
        }
        return ;
    }
    
    DWReaderChapter * previousChapter = [self.chapterTbl valueForKey:previousChapterID];
    if (previousChapter) {
        if (!previousChapter.parsing) {
            self.currentChapter = previousChapter;
            previousPage = previousChapter.lastPageInfo;
            DWReaderPageViewController * previousPageVC = currentVC.previousPage;
            [previousPageVC updateInfo:previousPage];
            self.currentPageVC = previousPageVC;
            [self showPageVC:previousPageVC from:previousPageVC.nextPage nextPage:NO initial:NO];
        }
        return ;
    }
    
    DWReaderChapterInfo * chapterInfo = [[DWReaderChapterInfo alloc] init];
    chapterInfo.book_id = self.currentChapter.chapterInfo.book_id;
    chapterInfo.chapter_id = previousChapterID;
    self.waitingChangePreviousChapter = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self requestChapter:chapterInfo nextChapter:NO preload:NO];
    });
}

#pragma mark --- life cycle ---
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark --- tool method ---
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

-(void)configPages {
    ///建立一个重用池，降低内存中VC数量
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
    if (info.chapter_id) {
        [self.requestingChapterIDs addObject:info.chapter_id];
    }
    ///如果不是预加载应该有Loading，询问外部展示Loading
    if (!preload && self.loadingAction) {
        self.loadingAction(YES);
    }
}

-(void)requestCompleteWithInfo:(DWReaderChapterInfo *)info preload:(BOOL)preload title:(NSString *)title content:(NSString *)content bookID:(NSString *)bookID chapterID:(NSString *)chapterID percent:(CGFloat)percent chapterIndex:(NSInteger)chapterIndex nextChapter:(BOOL)nextChapter userInfo:(id)userInfo {
    info.percent = percent;
    info.chapter_id = chapterID;
    ///请求完成后先取消请求状态
    if (info.chapter_id) {
        [self.requestingChapterIDs removeObject:info.chapter_id];
    }
    
    ///配置章节信息
    DWReaderChapter * chapter = [DWReaderChapter chapterWithOriginString:content title:title renderFrame:self.renderFrame info:info];
    
    
    ///如果是预加载，分页等工作要异步完成。由于异步自动跳转，同步不会，所以存入表中的时机要正确。按照下列的策略可以保证从表中获取的章节只有两种状态，一种是异步解析会自动跳转的状态，一种是同步解析不会自动跳转的状态
    if (preload) {
        ///如果是预加载是异步解析，且解析完成后会自动切章，所以在解析之前存储到章节表中
        if (info.chapter_id) {
            [self.chapterTbl setValue:chapter forKey:info.chapter_id];
        }
        ///如果是预加载，异步分页完成后应检测是否在等待切章
        [chapter asyncParseChapterToPageWithConfiguration:_textConf textColor:_textColor reprocess:^{
            [self reprocessChapterIfNeeded:chapter];
        } completion:^{
            [self changeChapterIfNeeded:chapter nextChapter:nextChapter];
        }];
    } else {
        ///如果不是预加载，是同步解析，当解析完成后再加入到章节表中
        [chapter parseChapterToPageWithConfiguration:_textConf textColor:_textColor reprocess:^{
            [self reprocessChapterIfNeeded:chapter];
        }];
        if (info.chapter_id) {
            [self.chapterTbl setValue:chapter forKey:info.chapter_id];
        }
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
    
    ///获取到首次加载和正常加载的状态（因为如果是首次加载代表阅读器初始化，此时如果远端进度为50%，应该跳转至50%，如果不是首次加载，切章发生在翻页过程中，切章过程中均应该保证连续性，故进度不为50%。self.currentChapter为nil刚好可以标志阅读器初始化的状态）
    BOOL initializeReader = (self.currentChapter == nil);
    
    ///找到当前未使用的页面控制器(当前采取复用模式，总共只有两个页面控制器)
    DWReaderPageViewController * availablePage = self.currentPageVC.nextPage;
    ///找到页面后配置页面信息(往后翻页则找到下一章的第一页，往前翻页则找到上一章的最后一页)
    DWReaderPageInfo * pageInfo = nil;
    NSLog(@"availabelPage %@",availablePage);
    ///如果有百分比，调到对应页
    if (chapter.chapterInfo.percent > 0 && initializeReader) {
        NSUInteger page = floor(MIN(chapter.chapterInfo.percent, 1)  * chapter.totalPage);
        pageInfo = [chapter pageInfoOnPage:page];
        ///如果取不到则采用默认数据
        if (!pageInfo) {
            pageInfo = nextChapter ? chapter.firstPageInfo : chapter.lastPageInfo;
        }
    } else {
        ///否则直接跳至首页或者尾页
        pageInfo = nextChapter ? chapter.firstPageInfo : chapter.lastPageInfo;
    }
    
    [availablePage updateInfo:pageInfo];
    
    ///然后进行翻页即可(翻页操作必须在主线程)
    dispatch_async(dispatch_get_main_queue(), ^{
        ///切换当前使用的控制器
        self.currentPageVC = availablePage;
        ///切换当前章节为指定章节
        self.currentChapter = chapter;
        ///切换页面控制器
        [self showPageVC:availablePage from:availablePage.nextPage nextPage:nextChapter initial:initializeReader];
    });
    
    if (nextChapter) {
        self.waitingChangeNextChapter = NO;
    } else {
        self.waitingChangePreviousChapter = NO;
    }
}

-(void)reprocessChapterIfNeeded:(DWReaderChapter *)chapter {
    if (self.readerDelegate && [self.readerDelegate respondsToSelector:@selector(reader:reprocessChapter:configChapterCallback:)]) {
        [self.readerDelegate reader:self reprocessChapter:chapter configChapterCallback:^(DWReaderPageInfo * _Nonnull newFirstPage, DWReaderPageInfo * _Nonnull newLastPage, NSUInteger fixTotalPage) {
            [chapter reprocessChapterWithFirstPageInfo:newFirstPage lastPageInfo:newLastPage totalPage:fixTotalPage];
        }];
    } else if (self.reprocessChapterCallback) {
        self.reprocessChapterCallback(self, chapter, ^(DWReaderPageInfo * _Nonnull newFirstPage, DWReaderPageInfo * _Nonnull newLastPage, NSUInteger fixTotalPage) {
            [chapter reprocessChapterWithFirstPageInfo:newFirstPage lastPageInfo:newLastPage totalPage:fixTotalPage];
        });
    }
}

-(NSString *)queryChapterId:(BOOL)nextChapter {
    DWReaderChapterInfo * currentChapterInfo = self.currentChapter.chapterInfo;
    if (self.readerDelegate && [self.readerDelegate respondsToSelector:@selector(reader:queryChapterIdForBook:currentChapterID:nextChapter:)]) {
        return [self.readerDelegate reader:self queryChapterIdForBook:currentChapterInfo.book_id currentChapterID:currentChapterInfo.chapter_id nextChapter:nextChapter];
    } else if (self.queryChapterIdCallback) {
        return self.queryChapterIdCallback(self,currentChapterInfo.book_id,currentChapterInfo.chapter_id,nextChapter);
    } else {
        NSAssert(NO, @"DWReader can't query chapter_id.You must either implement -reader:queryChapterIdForBook:currentChapterID:currentChapterIndex:nextChapter or set queryChapterIdCallback.");
        return nil;
    }
}

-(void)willDisplayPage:(DWReaderPageViewController *)page {
    if (self.readerDelegate && [self.readerDelegate respondsToSelector:@selector(reader:willDisplayPage:)]) {
        [self.readerDelegate reader:self willDisplayPage:page];
    } else if (self.willDisplayPageCallback) {
        self.willDisplayPageCallback(self,page);
    }
}

-(void)didEndDisplayingPage:(DWReaderPageViewController *)page {
    if (self.readerDelegate && [self.readerDelegate respondsToSelector:@selector(reader:didEndDisplayingPage:)]) {
        [self.readerDelegate reader:self didEndDisplayingPage:page];
    } else if (self.didEndDisplayingPageCallback) {
        self.didEndDisplayingPageCallback(self, page);
    }
}

-(void)showPageVC:(DWReaderPageViewController *)desVC from:(DWReaderPageViewController *)srcVC nextPage:(BOOL)nextPage initial:(BOOL)initial {
    ///关闭交互避免连续翻页
    self.view.userInteractionEnabled = NO;
    __weak typeof(self)weakSelf = self;
    [self willDisplayPage:desVC];
    [self setViewControllers:@[desVC] direction:nextPage?UIPageViewControllerNavigationDirectionForward:UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL finished) {
        weakSelf.view.userInteractionEnabled = YES;
        if (!initial) {
            [weakSelf didEndDisplayingPage:srcVC];
        }
    }];
}

#pragma mark --- UIPageViewController Delegate ---
-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(DWReaderPageViewController *)viewController {
    
    ///首先取出下一页信息，在同一章中，页面信息存有链表关系，如果取到为nil说明这一章结束了，这时候要考虑下一章
    DWReaderPageInfo * nextPage = viewController.pageInfo.nextPageInfo;
    
    if (nextPage) {
        ///先取出可用于渲染下一页的页面控制器，在更新页面配置信息
        DWReaderPageViewController * nextPageVC = viewController.nextPage;
        [nextPageVC updateInfo:nextPage];
        ///直接返回vc的都是可取消的翻页，要标记可取消状态
        self.cancelableChangingPage = YES;
        self.currentPageVC = nextPageVC;
        return nextPageVC;
    }
    
    ///如果当前无页面配置信息代表要切章了，首先找到下一章
    NSString * nextChapterID = [self queryChapterId:YES];
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
        ///如果存在，若当前正在解析，则状态已经记录下来，回调中会自动切章，不需额外切章，如果不是正在解析说明是解析过的章节且没有跳转功能，现在开始跳转（由于直接返回vc的都是可以取消的翻页，所以如果翻页取消了，要将章节和控制器恢复成切章之前的状态）
        if (!nextChapter.parsing) {
            ///切换章节并找到章节中第一页
            ///记录当前进行的是可取消的切章状态
            self.cancelableChangingPage = YES;
            self.currentChapter = nextChapter;
            nextPage = nextChapter.firstPageInfo;
            DWReaderPageViewController * nextPageVC = viewController.nextPage;
            [nextPageVC updateInfo:nextPage];
            ///记录原始页面控制器
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
    
    DWReaderPageInfo * previousPage = viewController.pageInfo.previousPageInfo;
    if (previousPage) {
        DWReaderPageViewController * previousPageVC = viewController.previousPage;
        [previousPageVC updateInfo:previousPage];
        self.cancelableChangingPage = YES;
        self.currentPageVC = previousPageVC;
        return previousPageVC;
    }
    
    NSString * previousChapterID = [self queryChapterId:NO];
    if (!previousChapterID.length) {
        if (self.noMoreChapter) {
            self.noMoreChapter(NO);
        }
        return nil;
    }
    
    DWReaderChapter * previousChapter = [self.chapterTbl valueForKey:previousChapterID];
    if (previousChapter) {
        if (!previousChapter.parsing) {
            self.cancelableChangingPage = YES;
            self.currentChapter = previousChapter;
            previousPage = previousChapter.lastPageInfo;
            DWReaderPageViewController * previousPageVC = viewController.previousPage;
            [previousPageVC updateInfo:previousPage];
            self.currentPageVC = previousPageVC;
            return previousPageVC;
        }
        return nil;
    }
    
    DWReaderChapterInfo * chapterInfo = [[DWReaderChapterInfo alloc] init];
    chapterInfo.book_id = self.currentChapter.chapterInfo.book_id;
    chapterInfo.chapter_id = previousChapterID;
    self.waitingChangePreviousChapter = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self requestChapter:chapterInfo nextChapter:NO preload:NO];
    });
    return nil;
}

///避免连续翻页渲染失败（翻页开始时关闭交互防止二次翻页，翻页结束时再打开交互）
-(void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<DWReaderPageViewController *> *)pendingViewControllers {
    pageViewController.view.userInteractionEnabled = NO;
    [self willDisplayPage:pendingViewControllers.firstObject];
}

-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<DWReaderPageViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    pageViewController.view.userInteractionEnabled = YES;
    
    ///如果动画完成，则上一个控制器结束展示，否则刚刚出现的控制器结束展示
    DWReaderPageViewController * previousPageVC = previousViewControllers.firstObject;
    if (completed) {
        [self didEndDisplayingPage:previousPageVC];
    } else {
        [self didEndDisplayingPage:previousPageVC.nextPage];
    }
    
    ///如果进行的是可取消的切章且的确取消切章的话，要恢复原始章节及页面控制器
    if (!completed && self.cancelableChangingPage) {
        self.currentChapter = previousPageVC.pageInfo.chapter;
        self.currentPageVC = previousPageVC;
    }
    self.cancelableChangingPage = NO;
    
    NSLog(@"finish %@",self.currentPageVC);
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
