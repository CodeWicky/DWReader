//
//  ViewController.m
//  DWReader
//
//  Created by Wicky on 2019/2/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "ViewController.h"
#import "DWReaderChapter.h"
#import "DWReaderPageViewController.h"
#import "DWReaderViewController.h"

@interface ViewController ()<UIPageViewControllerDelegate, UIPageViewControllerDataSource, DWReaderDataDelegate>

@property (nonatomic ,strong) DWReaderChapter * c;

@property (nonatomic ,strong) UIPageViewController * pageVC;

@property (nonatomic ,strong) NSMutableArray * dataArr;

@property (nonatomic ,strong) DWReaderViewController * reader;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
//    NSMutableAttributedString * titleAttr = [[NSMutableAttributedString alloc] initWithString:titleString];
//
//    [titleAttr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:28] range:NSMakeRange(0, titleAttr.length)];
//
//    NSMutableParagraphStyle * titleStyle = [[NSMutableParagraphStyle alloc] init];
//    titleStyle.paragraphSpacing = 100;
//    [titleAttr addAttribute:NSParagraphStyleAttributeName value:titleStyle range:NSMakeRange(0, titleAttr.length)];
//
//    NSMutableAttributedString * contentAttr = [[NSMutableAttributedString alloc] initWithString:testString];
//
//    [contentAttr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15] range:NSMakeRange(0, contentAttr.length)];
//
//    NSMutableParagraphStyle * contentStyle = [[NSMutableParagraphStyle alloc] init];
//    contentStyle.paragraphSpacing = 50;
//    [contentAttr addAttribute:NSParagraphStyleAttributeName value:contentStyle range:NSMakeRange(0, contentAttr.length)];
//
//    [titleAttr appendAttributedString:contentAttr];
//
//    UILabel * label = [[UILabel alloc] initWithFrame:self.view.bounds];
//    label.backgroundColor = [UIColor yellowColor];
//    label.numberOfLines = 0;
//    [self.view addSubview:label];
//
//    label.attributedText = titleAttr;
    
//    testString = @"\n\nabc\n\nde\nf\n";
    
    
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    NSString * tmp = @"豪华的别墅酒店。\n年轻俊美的男人刚刚从浴室里洗澡出来，健硕的腰身只围着一条浴巾，充满了力与美的身躯，仿佛西方阿波罗临世。\n“该死的。”一声低咒，男人低下头，一脸烦燥懊恼。\n他拿起手机，拔通了助手的电话，“给我找个干净的女人进来。”\n“少爷，怎么今晚有兴趣了？”\n\n“在酒会上喝错了东西，快点。”低沉的声线已经不奈烦了。\n“好的，马上。”\n一处景观灯的牌子面前，穿着清凉的女孩抬起头，看着那蛇线一样的线路图，感到相当的无语。\n明明就是来旅个游的，竟然迷路了。\n";
    NSString * testString = @"";
    for (int i = 0; i < 15; ++i) {
        testString = [testString stringByAppendingString:tmp];
    }
    
    NSLog(@"%lu",testString.length);

    NSString * titleString = @"霸道总裁爱上我\n";

    CGRect renderFrame = CGRectMake(15, self.view.safeAreaInsets.top, self.view.bounds.size.width - 30, self.view.bounds.size.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom);
    
    NSLog(@"start");
    
    DWReaderChapter * c = [DWReaderChapter chapterWithOriginString:testString title:titleString renderFrame:renderFrame info:[DWReaderChapterInfo new]];
    [c parseChapter];

    DWReaderTextConfiguration * conf = [[DWReaderTextConfiguration alloc] init];
    conf.titleFontSize = 28;
    conf.titleLineSpacing = 18;
    conf.titleSpacing = 28;
    conf.contentFontSize = 24;
    conf.contentLineSpacing = 18;
    conf.paragraphSpacing = 28;
    conf.paragraphHeaderSpacing = 30;

    [c seperatePageWithPageConfiguration:conf];
    [c configTextColor: [UIColor redColor]];

    
    NSLog(@"end");
    self.c = c;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
//    NSMutableArray <DWReaderPageViewController *>* pageVCs = [NSMutableArray arrayWithCapacity:self.c.pages.count];
//
//    __block DWReaderPageViewController * lastPageVC = nil;
//    [self.c.pages enumerateObjectsUsingBlock:^(DWReaderPageInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        DWReaderPageViewController * pageVC = [[DWReaderPageViewController alloc] initWithRenderFrame:self.c.renderFrame];
//        [pageVC updateInfo:obj];
//        pageVC.previousPage = lastPageVC;
//        lastPageVC.nextPage = pageVC;
//        [pageVCs addObject:pageVC];
//        lastPageVC = pageVC;
//    }];
//
//    pageVCs.firstObject.previousPage = lastPageVC;
//    lastPageVC.nextPage = pageVCs.firstObject;
//
//    self.dataArr = pageVCs;
//
    
//    NSMutableArray <DWReaderPageViewController *>* pageVCs = [NSMutableArray arrayWithCapacity:2];
//
//    DWReaderPageViewController * vc1 = [DWReaderPageViewController new];
//    vc1.view.backgroundColor = [UIColor redColor];
//
//    DWReaderPageViewController * vc2 = [DWReaderPageViewController new];
//    vc2.view.backgroundColor = [UIColor yellowColor];
//
//    vc1.nextPage = vc2;
//    vc1.previousPage = vc2;
//    vc2.previousPage = vc1;
//    vc2.nextPage = vc1;
//
//    [pageVCs addObject:vc1];
//    [pageVCs addObject:vc2];
//
//    self.dataArr = pageVCs;
//
//
//    [self.pageVC setViewControllers:@[pageVCs.firstObject] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
//    [self.navigationController pushViewController:self.pageVC animated:YES];
    
    DWReaderTextConfiguration * conf = [[DWReaderTextConfiguration alloc] init];
    conf.titleFontSize = 28;
    conf.titleLineSpacing = 18;
    conf.titleSpacing = 28;
    conf.contentFontSize = 24;
    conf.contentLineSpacing = 18;
    conf.paragraphSpacing = 28;
    conf.paragraphHeaderSpacing = 30;

    CGRect renderFrame = CGRectMake(15, self.view.safeAreaInsets.top, self.view.bounds.size.width - 30, self.view.bounds.size.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom);

    DWReaderDisplayConfiguration * disCon = [[DWReaderDisplayConfiguration alloc] init];
    disCon.renderFrame = renderFrame;
    disCon.textColor = [UIColor redColor];
    disCon.transitionStyle = UIPageViewControllerTransitionStylePageCurl;


    DWReaderChapterInfo * info = [[DWReaderChapterInfo alloc] init];
    info.book_id = @"1000";
    info.chapter_id = @"10002";

    self.reader = [DWReaderViewController readerWithTextConfiguration:conf displayConfiguration:disCon];
    self.reader.readerDelegate = self;
    [self.reader fetchChapter:info];

    [self presentViewController:self.reader animated:YES completion:nil];
}

-(void)reader:(DWReaderViewController *)reader requestBookDataForBook:(NSString *)bookID chapterID:(NSString *)chapterID nextChapter:(BOOL)next requestCompleteCallback:(DWReaderRequestDataCompleteCallback)callback {
    if (callback) {
        
        NSString * tmp = @"豪华的别墅酒店。\n年轻俊美的男人刚刚从浴室里洗澡出来，健硕的腰身只围着一条浴巾，充满了力与美的身躯，仿佛西方阿波罗临世。\n“该死的。”一声低咒，男人低下头，一脸烦燥懊恼。\n他拿起手机，拔通了助手的电话，“给我找个干净的女人进来。”\n“少爷，怎么今晚有兴趣了？”\n\n“在酒会上喝错了东西，快点。”低沉的声线已经不奈烦了。\n“好的，马上。”\n一处景观灯的牌子面前，穿着清凉的女孩抬起头，看着那蛇线一样的线路图，感到相当的无语。\n明明就是来旅个游的，竟然迷路了。\n";
        NSString * testString = @"";
        for (int i = 0; i < 3; ++i) {
            testString = [testString stringByAppendingString:tmp];
        }
        
        callback(@"霸道总裁爱上我",testString,bookID,chapterID,0.5,3,next,nil);
    }
}

-(NSString *)reader:(DWReaderViewController *)reader queryChapterIdForBook:(NSString *)bookID currentChapterID:(NSString *)chapterID nextChapter:(BOOL)nextChapter {
    
    NSInteger step = nextChapter ? 1 : -1;
    
    return [@(chapterID.integerValue + step) stringValue];
}

-(void)reader:(DWReaderViewController *)reader reprocessChapter:(DWReaderChapter *)chapter configChapterCallback:(DWReaderReprocessorCallback)callback {
    DWReaderPageInfo * page = [[DWReaderPageInfo alloc] init];
    NSMutableAttributedString * attr = [[NSMutableAttributedString alloc] initWithString:@"测试首页"];
    [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:28] range:NSMakeRange(0, attr.length)];
    [attr addAttribute:NSForegroundColorAttributeName value:[UIColor yellowColor] range:NSMakeRange(0, attr.length)];
    page.pageContent = attr;
    
    ///修改新首页
    chapter.firstPageInfo.previousPageInfo = page;
    page.nextPageInfo = chapter.firstPageInfo;
    
    DWReaderPageInfo * tmpPage = chapter.firstPageInfo;
    while (tmpPage) {
        
        if (tmpPage.page % 4 != 3) {
            tmpPage = tmpPage.nextPageInfo;
            continue;
        }
        
        NSMutableAttributedString * attr = [[NSMutableAttributedString alloc] initWithString:@"测试广告"];
        [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:56] range:NSMakeRange(0, attr.length)];
        DWReaderPageInfo * adPage = [[DWReaderPageInfo alloc] init];
        adPage.pageContent = attr;

        DWReaderPageInfo * nextPage = tmpPage.nextPageInfo;

        if (!nextPage) {
            break;
        }

        tmpPage.nextPageInfo = adPage;
        adPage.previousPageInfo = tmpPage;
        nextPage.previousPageInfo = adPage;
        adPage.nextPageInfo = nextPage;

        tmpPage = nextPage;
    }
    
    callback(page,nil,chapter.totalPage + 1);
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(DWReaderPageViewController *)viewController {
    return viewController.nextPage;
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(DWReaderPageViewController *)viewController {
    return viewController.previousPage;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    
}

-(UIPageViewController *)pageVC {
    if (!_pageVC) {
        _pageVC = [[UIPageViewController alloc] initWithTransitionStyle:(UIPageViewControllerTransitionStylePageCurl) navigationOrientation:(UIPageViewControllerNavigationOrientationHorizontal) options:nil];
        _pageVC.delegate = self;
        _pageVC.dataSource = self;
    }
    return _pageVC;
}


@end
