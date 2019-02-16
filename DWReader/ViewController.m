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

    DWReaderConfiguration * conf = [[DWReaderConfiguration alloc] init];
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
    
    
    
    
    
//    [self.pageVC setViewControllers:@[pageVCs.firstObject] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
//    [self.navigationController pushViewController:self.pageVC animated:YES];
    
    DWReaderConfiguration * conf = [[DWReaderConfiguration alloc] init];
    conf.titleFontSize = 28;
    conf.titleLineSpacing = 18;
    conf.titleSpacing = 28;
    conf.contentFontSize = 24;
    conf.contentLineSpacing = 18;
    conf.paragraphSpacing = 28;
    conf.paragraphHeaderSpacing = 30;
    
    CGRect renderFrame = CGRectMake(15, self.view.safeAreaInsets.top, self.view.bounds.size.width - 30, self.view.bounds.size.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom);
    
    DWReaderChapterInfo * info = [[DWReaderChapterInfo alloc] init];
    info.book_id = @"1000";
    info.chapter_id = @"10002";
    info.chapter_index = 2;
    
    self.reader = [DWReaderViewController readerWithConfiguration:conf textColor:[UIColor redColor] renderFrame:renderFrame chapterInfo:info readerDelegate:self transitionStyle:(UIPageViewControllerTransitionStylePageCurl)];
    [self presentViewController:self.reader animated:YES completion:nil];
}

-(void)reader:(DWReaderViewController *)reader requestBookDataForBook:(NSString *)bookID chapterID:(NSString *)chapterID nextChapter:(BOOL)next requestCompleteCallback:(DWReaderRequestDataCompleteCallback)callback {
    if (callback) {
        
        NSString * tmp = @"豪华的别墅酒店。\n年轻俊美的男人刚刚从浴室里洗澡出来，健硕的腰身只围着一条浴巾，充满了力与美的身躯，仿佛西方阿波罗临世。\n“该死的。”一声低咒，男人低下头，一脸烦燥懊恼。\n他拿起手机，拔通了助手的电话，“给我找个干净的女人进来。”\n“少爷，怎么今晚有兴趣了？”\n\n“在酒会上喝错了东西，快点。”低沉的声线已经不奈烦了。\n“好的，马上。”\n一处景观灯的牌子面前，穿着清凉的女孩抬起头，看着那蛇线一样的线路图，感到相当的无语。\n明明就是来旅个游的，竟然迷路了。\n";
        NSString * testString = @"";
        for (int i = 0; i < 15; ++i) {
            testString = [testString stringByAppendingString:tmp];
        }
        
        callback(@"霸道总裁爱上我",testString,bookID,chapterID,0,3,next,nil);
    }
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(DWReaderPageViewController *)viewController {
    return viewController.nextPage;
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(DWReaderPageViewController *)viewController {
    return viewController.previousPage;
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
