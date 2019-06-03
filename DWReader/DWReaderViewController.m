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

@interface DWReaderReuseInternal : NSObject

@property (nonatomic ,strong) Class registClass;

@property (nonatomic ,weak) __kindof DWReaderPageViewController * availablePage;

@property (nonatomic ,strong) NSMutableArray * reusePool;

+(instancetype)registClass:(Class)class;

@end

@interface DWReaderPageViewController ()

@property (nonatomic ,weak) DWReaderReuseInternal * reuseInternal;

@end

@implementation DWReaderPageViewController (Private)

///切换currentVC
-(void)configCurrentVCInUsing {
    self.reuseInternal.availablePage = self.nextPage;
}

@end

@implementation DWReaderReuseInternal

+(instancetype)registClass:(Class)class {
    if (!class) {
        return nil;
    }
    DWReaderReuseInternal * reuseInternal = [[self alloc] init];
    reuseInternal.registClass = class;
    reuseInternal.reusePool = [NSMutableArray arrayWithCapacity:2];
    [reuseInternal configPages];
    return reuseInternal;
}

-(void)configPages {
    ///建立一个重用池，降低内存中VC数量
    __kindof DWReaderPageViewController * tmp1 = [self.registClass new];
    tmp1.reuseInternal = self;
    __kindof DWReaderPageViewController * tmp2 = [self.registClass new];
    tmp2.reuseInternal = self;
    [tmp1 configNextPage:tmp2];
    [tmp2 configNextPage:tmp1];
    [self.reusePool addObject:tmp1];
    [self.reusePool addObject:tmp2];
    self.availablePage = tmp1;
}

@end

@interface DWReaderGestureProxy : NSObject<UIGestureRecognizerDelegate>

@end

@implementation DWReaderGestureProxy

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    UIView * view = gestureRecognizer.view;
    CGPoint point = [gestureRecognizer locationInView:view];
    CGFloat width = view.bounds.size.width;
    if (point.x < width / 3.0 || point.x > width * 2.0 / 3.0) {
        return NO;
    } else {
        return YES;
    }
}

@end

@interface DWReaderViewController ()<UIPageViewControllerDelegate ,UIPageViewControllerDataSource>

@property (nonatomic ,strong) DWReaderRenderConfiguration * renderConf;

@property (nonatomic ,strong) DWReaderDisplayConfiguration * displayConf;

@property (nonatomic ,strong) DWReaderRenderConfiguration * internalRenderConf;

@property (nonatomic ,strong) DWReaderDisplayConfiguration * internalDisplayConf;

@property (nonatomic ,assign) BOOL isTransitioning;

@property (nonatomic ,assign) BOOL waitingChangeNextChapter;

@property (nonatomic ,assign) BOOL waitingChangePreviousChapter;

@property (nonatomic ,assign) BOOL cancelableChangingPage;

@property (nonatomic ,assign) BOOL changingPageOnChangingChapter;

@property (nonatomic ,strong) NSMutableSet * requestingChapterIDs;

@property (nonatomic ,strong) NSCache * chapterTbl;

@property (nonatomic ,strong) DWReaderChapter * currentChapter;

@property (nonatomic ,strong) DWReaderReuseInternal * defaultReusePool;

@property (nonatomic ,strong) DWReaderPageViewController * currentPageVC;

@property (nonatomic ,strong) DWReaderPageViewController * lastPageVC;

@property (nonatomic ,strong) NSMutableDictionary * reusePoolContainer;

@property (nonatomic ,strong) UITapGestureRecognizer * tapGes;

@property (nonatomic ,strong) DWReaderGestureProxy * tapGesProxy;

@property (nonatomic ,strong) DWReaderPageViewController * defaultPage;

@end

@implementation DWReaderViewController

+(instancetype)readerWithRenderConfiguration:(DWReaderRenderConfiguration *)renderConf displayConfiguration:(DWReaderDisplayConfiguration *)displayConf defaultPage:(__kindof DWReaderPageViewController *)defaultPage {
    if (CGRectEqualToRect(renderConf.renderFrame, CGRectNull) || CGRectEqualToRect(renderConf.renderFrame, CGRectZero)) {
        NSAssert(NO, @"DWReader can't initialize a reader with renderFrame is either CGRectNull or CGRectZero.");
        return nil;
    }
    __kindof DWReaderViewController * reader = [[[self class] alloc] initWithRenderConfiguration:renderConf displayConfiguration:displayConf defaultPage:defaultPage];
    return reader;
}

-(void)fetchChapter:(DWReaderChapterInfo *)chapterInfo nextChapter:(BOOL)nextChapter animated:(BOOL)animated {
    ///先查缓存
    ///获取到下章ID，先查询本地是否存在下一章，不存在直接请求下章即可，同时要将等待翻页置位真，让请求完成后自动翻页
    DWReaderChapter * chapter = [self.chapterTbl objectForKey:chapterInfo.chapter_id];
    if (chapter) {
        ///若取出缓存，先配置颜色等相关配置，以免当前主题已经发生改变
        [self changeChapterConfigurationIfNeeded:chapter]; ///如果存在，若当前正在解析，则状态已经记录下来，回调中会自动切章，不需额外切章，如果不是正在解析说明是解析过的章节且没有跳转功能，现在开始跳转
        if (!chapter.parsing) {
            ///切换章节并找到章节中第一页
            if (nextChapter) {
                self.waitingChangeNextChapter = YES;
                self.waitingChangePreviousChapter = NO;
            } else {
                self.waitingChangePreviousChapter = YES;
                self.waitingChangeNextChapter = NO;
            }
            ///直接切章强制从章首开始
            [self changeChapterIfNeeded:chapter nextChapter:nextChapter forceSeekingStart:YES animated:animated];
        }
        return ;
    }
    
    if (nextChapter) {
        self.waitingChangeNextChapter = YES;
        self.waitingChangePreviousChapter = NO;
    } else {
        self.waitingChangePreviousChapter = YES;
        self.waitingChangeNextChapter = NO;
    }
    ///直接切章强制从章首开始
    [self requestChapter:chapterInfo nextChapter:nextChapter forceSeekingStart:YES preload:NO aniamted:animated];
}

-(void)changeBookWithChapterInfo:(DWReaderChapterInfo *)chapterInfo defaultPage:(__kindof DWReaderPageViewController *)defaultPage nextChapter:(BOOL)nextChapter animated:(BOOL)animated {
    [self resetReader];
    if (defaultPage) {
        self.currentPageVC = defaultPage;
        [self setViewControllers:@[defaultPage] direction:(UIPageViewControllerNavigationDirectionForward) animated:NO completion:nil];
    }
    [self fetchChapter:chapterInfo nextChapter:nextChapter animated:animated];
}

-(void)registerClass:(Class)pageControllerClass forPageViewControllerReuseIdentifier:(nonnull NSString *)reuseIdentifier {
    if (!pageControllerClass || !reuseIdentifier.length) {
        return;
    }
    DWReaderReuseInternal * reusePool = [DWReaderReuseInternal registClass:pageControllerClass];
    self.reusePoolContainer[reuseIdentifier] = reusePool;
}

-(DWReaderPageViewController *)dequeueReusablePageViewControllerWithIdentifier:(NSString *)reuseIdentifier {
    if (!reuseIdentifier.length) {
        return nil;
    }
    DWReaderReuseInternal * reusePool = self.reusePoolContainer[reuseIdentifier];
    return reusePool.availablePage;
}

-(DWReaderPageViewController *)dequeueDefaultReusablePageViewController {
    return self.defaultReusePool.availablePage;
}

-(void)preloadNextChapter {
    
    ///获取下一章章节ID，如果获取不到则返回
    NSString * chapterId = [self queryChapterId:YES];
    if (!chapterId.length) {
        return;
    }
    
    ///如果本地有缓存好的章节，直接返回
    if ([self.chapterTbl objectForKey:chapterId]) {
        return;
    }
    
    ///组装章节信息
    DWReaderChapterInfo * chapterInfo = [[DWReaderChapterInfo alloc] init];
    chapterInfo.book_id = self.currentChapter.chapterInfo.book_id;
    chapterInfo.chapter_id = chapterId;
    [self requestChapter:chapterInfo nextChapter:YES forceSeekingStart:NO preload:YES aniamted:NO];
}

-(void)showNextPageWithAnimated:(BOOL)animated {
    ///防止连续翻页
    if (self.isTransitioning) {
        return;
    }
    ///首先取出下一页信息，在同一章中，页面信息存有链表关系，如果取到为nil说明这一章结束了，这时候要考虑下一章
    
    DWReaderPageViewController * currentVC = self.currentPageVC;
    DWReaderPageInfo * nextPage = currentVC.pageInfo.nextPageInfo;
    
    if (nextPage) {
        ///先取出可用于渲染下一页的页面控制器，在更新页面配置信息
        DWReaderPageViewController * nextPageVC = [self pageControllerFromInfo:nextPage];
        self.currentPageVC = nextPageVC;
        [self showPageVC:nextPageVC from:self.lastPageVC nextPage:YES initial:NO chapterChange:NO animated:YES];
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
    DWReaderChapter * nextChapter = [self.chapterTbl objectForKey:nextChapterID];
    if (nextChapter) {
        [self changeChapterConfigurationIfNeeded:nextChapter];
        ///如果存在，若当前正在解析，则状态已经记录下来，回调中会自动切章，不需额外切章，如果不是正在解析说明是解析过的章节且没有跳转功能，现在开始跳转（由于直接返回vc的都是可以取消的翻页，所以如果翻页取消了，要将章节和控制器恢复成切章之前的状态）
        if (!nextChapter.parsing) {
            ///切换章节并找到章节中第一页
            ///记录当前进行的是可取消的切章状态
            self.currentChapter = nextChapter;
            nextPage = nextChapter.firstPageInfo;
            
            DWReaderPageViewController * nextPageVC = [self pageControllerFromInfo:nextPage];
            ///记录原始页面控制器
            self.currentPageVC = nextPageVC;
            [self showPageVC:nextPageVC from:self.lastPageVC nextPage:YES initial:NO chapterChange:YES animated:YES];
        }
        return ;
    }
    
    ///如果不存在下一章直接请求下一章即可
    DWReaderChapterInfo * chapterInfo = [[DWReaderChapterInfo alloc] init];
    chapterInfo.book_id = self.currentChapter.chapterInfo.book_id;
    chapterInfo.chapter_id = nextChapterID;
    self.waitingChangeNextChapter = YES;
    self.waitingChangePreviousChapter = NO;
    ///异步提交请求任务，如果同步的话会造成当整个数据获取过程是同步时（即读取本地缓存数据），同步设置了pageViewController的vc，然后又立刻返回了nil。UIPageViewController如果短时间内改变两次vc（在一个动画未完成即开始另一个动画）避免黑屏。所以分成两次提交。
    dispatch_async(dispatch_get_main_queue(), ^{
        [self requestChapter:chapterInfo nextChapter:YES forceSeekingStart:NO preload:NO aniamted:animated];
    });
}

-(void)showPreviousPageWithAnimated:(BOOL)animated {
    if (self.isTransitioning) {
        return;
    }
    DWReaderPageViewController * currentVC = self.currentPageVC;
    DWReaderPageInfo * previousPage = currentVC.pageInfo.previousPageInfo;
    if (previousPage) {
        DWReaderPageViewController * previousPageVC = [self pageControllerFromInfo:previousPage];
        self.currentPageVC = previousPageVC;
        [self showPageVC:previousPageVC from:self.lastPageVC nextPage:NO initial:NO chapterChange:NO animated:YES];
        return ;
    }
    
    NSString * previousChapterID = [self queryChapterId:NO];
    if (!previousChapterID.length) {
        if (self.noMoreChapter) {
            self.noMoreChapter(YES);
        }
        return ;
    }
    
    DWReaderChapter * previousChapter = [self.chapterTbl objectForKey:previousChapterID];
    if (previousChapter) {
        [self changeChapterConfigurationIfNeeded:previousChapter];
        if (!previousChapter.parsing) {
            self.currentChapter = previousChapter;
            previousPage = previousChapter.lastPageInfo;
            
            DWReaderPageViewController * previousPageVC = [self pageControllerFromInfo:previousPage];
            self.currentPageVC = previousPageVC;
            [self showPageVC:previousPageVC from:self.lastPageVC nextPage:NO initial:NO chapterChange:YES animated:YES];
        }
        return ;
    }
    
    DWReaderChapterInfo * chapterInfo = [[DWReaderChapterInfo alloc] init];
    chapterInfo.book_id = self.currentChapter.chapterInfo.book_id;
    chapterInfo.chapter_id = previousChapterID;
    self.waitingChangePreviousChapter = YES;
    self.waitingChangeNextChapter = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self requestChapter:chapterInfo nextChapter:NO forceSeekingStart:NO preload:NO aniamted:animated];
    });
}

-(void)showPage:(NSInteger)page nextPage:(BOOL)nextPage animated:(BOOL)animated completion:(dispatch_block_t)completion {
    if (self.isTransitioning) {
        return;
    }
    DWReaderPageInfo * pageInfo = [self.currentChapter pageInfoOnPage:page];
    ///如果取不到则采用默认数据
    if (!pageInfo) {
        pageInfo = nextPage ? self.currentChapter.lastPageInfo : self.currentChapter.firstPageInfo;
    }
    
    DWReaderPageViewController * availablePage = [self pageControllerFromInfo:pageInfo];
    ///切换当前使用的控制器
    self.currentPageVC = availablePage;
    ///然后进行翻页即可(翻页操作必须在主线程)
    dispatch_async(dispatch_get_main_queue(), ^{
        ///切换页面控制器
        [self showPageVC:availablePage from:self.lastPageVC nextPage:nextPage initial:NO chapterChange:NO animated:animated];
        if (completion) {
            completion();
        }
    });
}

-(void)updateDisplayConfiguration:(DWReaderDisplayConfiguration *)conf {
    if ([conf isEqual:_internalDisplayConf]) {
        return;
    }
    self.displayConf = conf;
    [self.currentChapter configTextColor:conf.textColor];
    [self reload];
}

-(void)updateRenderConfiguration:(DWReaderRenderConfiguration *)conf {
    if ([conf isEqual:_internalRenderConf]) {
        return;
    }
    self.renderConf = conf;
    if (self.loadingAction) {
        self.loadingAction(YES);
    }
    NSInteger oriPage = self.currentPageVC.pageInfo.page;
    if (oriPage == DWReaderPageUndefined) {
        DWReaderPageInfo * tmpInfo = self.currentPageVC.pageInfo.previousPageInfo;
        while (tmpInfo.page == DWReaderPageUndefined) {
            tmpInfo = tmpInfo.previousPageInfo;
        }
        oriPage = tmpInfo.page;
    }
    CGFloat percent = oriPage * 1.0 / self.currentChapter.totalPage;
    ///重新分页后要重新二次处理
    [self.currentChapter seperatePageWithPageConfiguration:conf];
    [self reprocessChapterIfNeeded:self.currentChapter];
    NSUInteger page = floor(MIN(percent, 1) * self.currentChapter.totalPage);
    BOOL nextPage = page >= oriPage;
    [self showPage:page nextPage:nextPage animated:NO completion:^{
        if (self.loadingAction) {
            self.loadingAction(NO);
        }
    }];
}

-(void)reload {
    [self.currentPageVC reload];
}

-(void)clearCachedChapter {
    [self.chapterTbl removeAllObjects];
}

-(void)resetReader {
    [self clearCachedChapter];
    self.isTransitioning = NO;
    self.waitingChangeNextChapter = NO;
    self.waitingChangePreviousChapter = NO;
    self.cancelableChangingPage = NO;
    self.changingPageOnChangingChapter = NO;
    [self.requestingChapterIDs removeAllObjects];
}

#pragma mark --- life cycle ---
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addGestureRecognizer:self.tapGes];
    if (self.defaultPage) {
        [self setViewControllers:@[self.defaultPage] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
        self.defaultPage = nil;
    }
}

#pragma mark --- tool method ---
-(instancetype)initWithRenderConfiguration:(DWReaderRenderConfiguration *)renderConf displayConfiguration:(DWReaderDisplayConfiguration *)displayConf defaultPage:(__kindof DWReaderPageViewController *)defaultPage {
    if (self = [super initWithTransitionStyle:displayConf.transitionStyle navigationOrientation:(UIPageViewControllerNavigationOrientationHorizontal) options:nil]) {
        self.delegate = self;
        self.dataSource = self;
        self.renderConf = renderConf;
        self.displayConf = displayConf;
        self.currentPageVC = defaultPage?:self.defaultReusePool.availablePage;
        self.defaultPage = defaultPage;
    }
    return self;
}

-(void)changeChapterConfigurationIfNeeded:(DWReaderChapter *)chapter {
    [chapter seperatePageWithPageConfiguration:_internalRenderConf];
    [chapter configTextColor:_internalDisplayConf.textColor];
}

-(void)requestChapter:(DWReaderChapterInfo *)info nextChapter:(BOOL)next forceSeekingStart:(BOOL)forceSeekingStart preload:(BOOL)preload aniamted:(BOOL)animated {
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
    if (self.readerDelegate && [self.readerDelegate respondsToSelector:@selector(reader:requestBookDataWithChapterInfo:nextChapter:requestCompleteCallback:)]) {
        ///为请求做准备工作
        [self prepareForRequestData:info preload:preload];
        __weak typeof(self)weakSelf = self;
        [self.readerDelegate reader:self requestBookDataWithChapterInfo:info nextChapter:next requestCompleteCallback:^(BOOL success,NSString * _Nonnull title, NSString * _Nonnull content, NSString * _Nonnull bookID, NSString * _Nonnull chapterID, CGFloat percent, NSInteger chapterIndex, BOOL nextChapter, id  _Nullable userInfo) {
            if (success) {
                [weakSelf requestCompleteWithInfo:info preload:preload title:title content:content bookID:bookID chapterID:chapterID percent:percent chapterIndex:chapterIndex userInfo:userInfo nextChapter:nextChapter forceSeekingStart:forceSeekingStart animated:animated];
            } else {
                if (weakSelf.loadingAction) {
                    weakSelf.loadingAction(NO);
                }
            }
        }];
    } else if (self.requestBookDataCallback) {
        [self prepareForRequestData:info preload:preload];
        __weak typeof(self)weakSelf = self;
        self.requestBookDataCallback(self, info, next, ^(BOOL success,NSString * _Nonnull title, NSString * _Nonnull content, NSString * _Nonnull bookID, NSString * _Nonnull chapterID, CGFloat percent, NSInteger chapterIndex, BOOL nextChapter, id  _Nullable userInfo) {
            if (success) {
                [weakSelf requestCompleteWithInfo:info preload:preload title:title content:content bookID:bookID chapterID:chapterID percent:percent chapterIndex:chapterIndex userInfo:userInfo nextChapter:nextChapter forceSeekingStart:forceSeekingStart animated:animated];
            } else {
                if (self.loadingAction) {
                    self.loadingAction(NO);
                }
            }
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

-(void)requestCompleteWithInfo:(DWReaderChapterInfo *)info preload:(BOOL)preload title:(NSString *)title content:(NSString *)content bookID:(NSString *)bookID chapterID:(NSString *)chapterID percent:(CGFloat)percent chapterIndex:(NSInteger)chapterIndex
                      userInfo:(id)userInfo nextChapter:(BOOL)nextChapter forceSeekingStart:(BOOL)forceSeekingStart animated:(BOOL)animated {
    info.title = title;
    info.percent = percent;
    info.chapter_id = chapterID;
    info.chapter_index = chapterIndex;
    info.userInfo = userInfo;
    ///请求完成后先取消请求状态
    if (info.chapter_id) {
        [self.requestingChapterIDs removeObject:info.chapter_id];
    }
    
    ///配置章节信息
    DWReaderChapter * chapter = [DWReaderChapter chapterWithOriginString:content title:title info:info];
    
    ///如果是预加载，分页等工作要异步完成。由于异步自动跳转，同步不会，所以存入表中的时机要正确。按照下列的策略可以保证从表中获取的章节只有两种状态，一种是异步解析会自动跳转的状态，一种是同步解析不会自动跳转的状态
    if (preload) {
        ///如果是预加载是异步解析，且解析完成后会自动切章，所以在解析之前存储到章节表中
        if (info.chapter_id) {
            [self.chapterTbl setObject:chapter forKey:info.chapter_id];
        }
        ///如果是预加载，异步分页完成后应检测是否在等待切章
        __weak typeof(self)weakSelf = self;
        [chapter asyncParseChapterToPageWithConfiguration:_internalRenderConf reprocess:^{
            ///做完二次处理后要将颜色文字颜色改变为当前主题颜色
            [chapter configTextColor:weakSelf.internalDisplayConf.textColor];
            [self reprocessChapterIfNeeded:chapter];
        } completion:^{
            [self changeChapterIfNeeded:chapter nextChapter:nextChapter forceSeekingStart:forceSeekingStart animated:animated];
        }];
    } else {
        ///如果不是预加载，是同步解析，当解析完成后再加入到章节表中
        __weak typeof(self)weakSelf = self;
        [chapter parseChapterToPageWithConfiguration:_internalRenderConf reprocess:^{
            [chapter configTextColor:weakSelf.internalDisplayConf.textColor];
            [self reprocessChapterIfNeeded:chapter];
        }];
        if (info.chapter_id) {
            [self.chapterTbl setObject:chapter forKey:info.chapter_id];
        }
    }
    
    
    ///如果不是预加载应询问外部隐藏Loading
    if (!preload && self.loadingAction) {
        self.loadingAction(NO);
    }
    
    ///当不是预加载时，如果正在等待切章且与请求方向一致，应该切章
    if (!preload) {
        [self changeChapterIfNeeded:chapter nextChapter:nextChapter forceSeekingStart:forceSeekingStart animated:animated];
    }
}

-(void)changeChapterIfNeeded:(DWReaderChapter *)chapter nextChapter:(BOOL)nextChapter forceSeekingStart:(BOOL)forceSeekingStart animated:(BOOL)animated {
    if (self.isTransitioning) {
        return;
    }
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
    ///找到页面后配置页面信息(往后翻页则找到下一章的第一页，往前翻页则找到上一章的最后一页)
    DWReaderPageInfo * pageInfo = nil;
    ///如果有百分比且为初始化，调到对应页
    if (chapter.chapterInfo.percent > 0 && initializeReader) {
        NSUInteger page = floor(MIN(chapter.chapterInfo.percent, 1)  * chapter.totalPage);
        pageInfo = [chapter pageInfoOnPage:page];
        ///如果取不到则采用默认数据
        if (!pageInfo) {
            pageInfo = nextChapter ? chapter.firstPageInfo : chapter.lastPageInfo;
        }
    } else if (forceSeekingStart) {
        ///如果强制首页，则跳转至首页
        pageInfo = chapter.firstPageInfo;
    } else {
        ///否则直接跳至首页或者尾页
        pageInfo = nextChapter ? chapter.firstPageInfo : chapter.lastPageInfo;
    }
    
    ///找到当前未使用的页面控制器(当前采取复用模式，总共只有两个页面控制器)
    DWReaderPageViewController * availablePage = [self pageControllerFromInfo:pageInfo];
    
    ///然后进行翻页即可(翻页操作必须在主线程)
    dispatch_async(dispatch_get_main_queue(), ^{
        ///切换当前使用的控制器
        self.currentPageVC = availablePage;
        ///切换当前章节为指定章节
        self.currentChapter = chapter;
        ///切换页面控制器
        [self showPageVC:availablePage from:self.lastPageVC nextPage:nextChapter initial:initializeReader chapterChange:YES animated:animated];
    });
    
    self.waitingChangeNextChapter = NO;
    self.waitingChangePreviousChapter = NO;
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
    if (self.readerDelegate && [self.readerDelegate respondsToSelector:@selector(reader:queryChapterIdWithCurrentChapter:nextChapter:)]) {
        return [self.readerDelegate reader:self queryChapterIdWithCurrentChapter:self.currentChapter nextChapter:nextChapter];
    } else if (self.queryChapterIdCallback) {
        return self.queryChapterIdCallback(self,self.currentChapter,nextChapter);
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

-(void)showPageVC:(DWReaderPageViewController *)desVC from:(DWReaderPageViewController *)srcVC nextPage:(BOOL)nextPage initial:(BOOL)initial chapterChange:(BOOL)chapterChange animated:(BOOL)animated {
    ///关闭交互避免连续翻页
    self.isTransitioning = YES;
    self.view.userInteractionEnabled = NO;
    
    __weak typeof(self)weakSelf = self;
    [self willDisplayPage:desVC];
    [self setViewControllers:@[desVC] direction:nextPage?UIPageViewControllerNavigationDirectionForward:UIPageViewControllerNavigationDirectionReverse animated:animated completion:^(BOOL finished) {
        weakSelf.isTransitioning = NO;
        weakSelf.view.userInteractionEnabled = YES;
        if (!initial) {
            [weakSelf didEndDisplayingPage:srcVC];
        }
        if (chapterChange) {
            [weakSelf changeToChapter:desVC.pageInfo.chapter from:srcVC.pageInfo.chapter];
        }
        [desVC configCurrentVCInUsing];
    }];
}

-(void)changeToChapter:(DWReaderChapter *)desChapter from:(DWReaderChapter *)srcChapter {
    if (self.readerDelegate && [self.readerDelegate respondsToSelector:@selector(reader:changeToChapter:fromChapter:)]) {
        [self.readerDelegate reader:self changeToChapter:desChapter fromChapter:srcChapter];
    } else if (self.changeToChapterCallback) {
        self.changeToChapterCallback(self, desChapter, srcChapter);
    }
}

-(__kindof DWReaderPageViewController *)pageControllerFromInfo:(DWReaderPageInfo *)pageInfo {
    if (!pageInfo) {
        return nil;
    }
    if (self.readerDelegate && [self.readerDelegate respondsToSelector:@selector(reader:pageControllerForPageInfo:renderFrame:)]) {
        return [self.readerDelegate reader:self pageControllerForPageInfo:pageInfo renderFrame:_internalRenderConf.renderFrame];
    } else if (self.pageControllerForPageInfoCallback) {
        return self.pageControllerForPageInfoCallback(self,pageInfo,_internalRenderConf.renderFrame);
    } else {
        DWReaderPageViewController * page = self.defaultReusePool.availablePage;
        [page updateInfo:pageInfo];
        page.renderFrame = _internalRenderConf.renderFrame;
        return page;
    }
}

-(void)responseToTap:(UITapGestureRecognizer *)tap {
    if (self.readerDelegate && [self.readerDelegate respondsToSelector:@selector(reader:currentPage:tapGesture:)]) {
        [self.readerDelegate reader:self currentPage:self.currentPageVC tapGesture:tap];
    } else if (self.tapGestureOnReaderCallback) {
        self.tapGestureOnReaderCallback(self, self.currentPageVC, tap);
    }
}

#pragma mark --- UIPageViewController Delegate ---
-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(DWReaderPageViewController *)viewController {
    
    ///如果正在切章翻页过程中，则不进行手动翻页
    if (self.changingPageOnChangingChapter) {
        return nil;
    }
    ///首先取出下一页信息，在同一章中，页面信息存有链表关系，如果取到为nil说明这一章结束了，这时候要考虑下一章
    DWReaderPageInfo * nextPage = viewController.pageInfo.nextPageInfo;
    
    if (nextPage) {
        ///先取出可用于渲染下一页的页面控制器，在更新页面配置信息
        DWReaderPageViewController * nextPageVC = [self pageControllerFromInfo:nextPage];
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
    DWReaderChapter * nextChapter = [self.chapterTbl objectForKey:nextChapterID];
    if (nextChapter) {
        [self changeChapterConfigurationIfNeeded:nextChapter]; ///如果存在，若当前正在解析，则状态已经记录下来，回调中会自动切章，不需额外切章，如果不是正在解析说明是解析过的章节且没有跳转功能，现在开始跳转（由于直接返回vc的都是可以取消的翻页，所以如果翻页取消了，要将章节和控制器恢复成切章之前的状态）
        if (!nextChapter.parsing) {
            ///切换章节并找到章节中第一页
            ///记录当前进行的是可取消的切章状态
            self.cancelableChangingPage = YES;
            self.currentChapter = nextChapter;
            nextPage = nextChapter.firstPageInfo;
            DWReaderPageViewController * nextPageVC = [self pageControllerFromInfo:nextPage];
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
    self.waitingChangePreviousChapter = NO;
    ///异步提交请求任务，如果同步的话会造成当整个数据获取过程是同步时（即读取本地缓存数据），同步设置了pageViewController的vc，然后又立刻返回了nil。UIPageViewController如果短时间内改变两次vc（在一个动画未完成即开始另一个动画）避险黑屏。所以分成两次提交。
    dispatch_async(dispatch_get_main_queue(), ^{
        [self requestChapter:chapterInfo nextChapter:YES forceSeekingStart:NO preload:NO aniamted:YES];
    });
    return nil;
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(DWReaderPageViewController *)viewController {
    
    ///如果正在切章翻页过程中，则不进行手动翻页
    if (self.changingPageOnChangingChapter) {
        return nil;
    }
    
    DWReaderPageInfo * previousPage = viewController.pageInfo.previousPageInfo;
    if (previousPage) {
        DWReaderPageViewController * previousPageVC = [self pageControllerFromInfo:previousPage];
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
    
    DWReaderChapter * previousChapter = [self.chapterTbl objectForKey:previousChapterID];
    if (previousChapter) {
        [self changeChapterConfigurationIfNeeded:previousChapter];
        if (!previousChapter.parsing) {
            self.cancelableChangingPage = YES;
            self.currentChapter = previousChapter;
            previousPage = previousChapter.lastPageInfo;
            DWReaderPageViewController * previousPageVC = [self pageControllerFromInfo:previousPage];
            self.currentPageVC = previousPageVC;
            return previousPageVC;
        }
        return nil;
    }
    
    DWReaderChapterInfo * chapterInfo = [[DWReaderChapterInfo alloc] init];
    chapterInfo.book_id = self.currentChapter.chapterInfo.book_id;
    chapterInfo.chapter_id = previousChapterID;
    self.waitingChangePreviousChapter = YES;
    self.waitingChangeNextChapter = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self requestChapter:chapterInfo nextChapter:NO forceSeekingStart:NO preload:NO aniamted:YES];
    });
    return nil;
}

///避免连续翻页渲染失败（翻页开始时关闭交互防止二次翻页，翻页结束时再打开交互）
-(void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<DWReaderPageViewController *> *)pendingViewControllers {
    self.isTransitioning = YES;
    pageViewController.view.userInteractionEnabled = NO;
    [self willDisplayPage:pendingViewControllers.firstObject];
}

-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<DWReaderPageViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    pageViewController.view.userInteractionEnabled = YES;
    self.isTransitioning = NO;
    ///如果动画完成，则上一个控制器结束展示，否则刚刚出现的控制器结束展示
    if (completed) {
        [self didEndDisplayingPage:previousViewControllers.firstObject];
        [self.currentPageVC configCurrentVCInUsing];
        ///若以动画切章应在此处进行切章完成上报
        [self changeToChapter:self.currentChapter from:self.lastPageVC.pageInfo.chapter];
        
    } else {
        [self didEndDisplayingPage:self.currentPageVC];
    }
    
    ///如果进行的是可取消的切章且的确取消切章的话，要恢复原始章节及页面控制器
    if (!completed && self.cancelableChangingPage) {
        self.currentChapter = self.lastPageVC.pageInfo.chapter;
        self.currentPageVC = self.lastPageVC;
        self.lastPageVC = nil;
    }
    self.cancelableChangingPage = NO;
}

#pragma mark --- tap action ---
-(void)tapAction:(UITapGestureRecognizer *)tap {
    [self responseToTap:tap];
}

#pragma mark --- setter/getter ---

-(NSMutableSet *)requestingChapterIDs {
    if (!_requestingChapterIDs) {
        _requestingChapterIDs = [NSMutableSet set];
    }
    return _requestingChapterIDs;
}

-(NSCache *)chapterTbl {
    if (!_chapterTbl) {
        _chapterTbl = [[NSCache alloc] init];
    }
    return _chapterTbl;
}

-(BOOL)changingPageOnChangingChapter {
    return !self.view.userInteractionEnabled;
}

-(DWReaderReuseInternal *)defaultReusePool {
    if (!_defaultReusePool) {
        _defaultReusePool = [DWReaderReuseInternal registClass:[DWReaderPageViewController class]];
    }
    return _defaultReusePool;
}

-(NSMutableDictionary *)reusePoolContainer {
    if (!_reusePoolContainer) {
        _reusePoolContainer = [NSMutableDictionary dictionary];
    }
    return _reusePoolContainer;
}

-(void)setCurrentPageVC:(DWReaderPageViewController *)currentPageVC {
    _lastPageVC = _currentPageVC;
    _currentPageVC = currentPageVC;
}

-(void)setRenderConf:(DWReaderRenderConfiguration *)renderConf {
    if (![_internalRenderConf isEqual:renderConf]) {
        _renderConf = renderConf;
        _internalRenderConf = [renderConf copy];
    }
}

-(void)setDisplayConf:(DWReaderDisplayConfiguration *)displayConf {
    if (![_internalDisplayConf isEqual:displayConf]) {
        _displayConf = displayConf;
        _internalDisplayConf = [displayConf copy];
    }
}

-(UITapGestureRecognizer *)tapGes {
    if (!_tapGes) {
        _tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        _tapGes.delegate = self.tapGesProxy;
    }
    return _tapGes;
}

-(DWReaderGestureProxy *)tapGesProxy {
    if (!_tapGesProxy) {
        _tapGesProxy = [[DWReaderGestureProxy alloc] init];
    }
    return _tapGesProxy;
}

-(UITapGestureRecognizer *)tapGestureOnReader {
    return self.tapGes;
}

-(DWReaderPageViewController *)currentPage {
    return self.currentPageVC;
}

@end
