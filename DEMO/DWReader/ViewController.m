//
//  ViewController.m
//  DWReader
//
//  Created by Wicky on 2019/2/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "ViewController.h"
#import "DWReaderViewController.h"
#import "DWReaderADInfo.h"
#import "DWReaderADViewController.h"

@interface ViewController ()<DWReaderDataDelegate>

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
    
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    ///由于内部没有tabBar，所以要减去tabBar的高度。
    CGRect renderFrame = CGRectMake(30, safeAreaInsets.top + 66.5, self.view.bounds.size.width - 60, self.view.bounds.size.height - safeAreaInsets.top - 66.5 -  safeAreaInsets.bottom - 70.5);
    CGFloat fontSize = 15;
    DWReaderRenderConfiguration * renderConf = [[DWReaderRenderConfiguration alloc] init];
    renderConf.renderFrame = renderFrame;
    renderConf.contentFont = [UIFont fontWithName:@"PingFang SC" size:fontSize];
    renderConf.titleFont = [UIFont fontWithName:@"PingFang SC" size:fontSize * 1.5];
    renderConf.titleLineSpacing = fontSize * 0.3;
    renderConf.titleSpacing = fontSize * 1.5;
    renderConf.contentLineSpacing = fontSize * 0.2;
    renderConf.paragraphSpacing = fontSize * 1.3;
    renderConf.paragraphHeaderSpacing = fontSize * 2;

    DWReaderDisplayConfiguration * disCon = [[DWReaderDisplayConfiguration alloc] init];
    disCon.textColor = [UIColor redColor];
    disCon.transitionStyle = UIPageViewControllerTransitionStylePageCurl;

    DWReaderChapterInfo * info = [[DWReaderChapterInfo alloc] init];
    info.book_id = @"1000";
    info.chapter_id = @"10002";

    DWReaderPageViewController * vc = [DWReaderPageViewController new];
    vc.view.backgroundColor = [UIColor redColor];

    self.reader = [DWReaderViewController readerWithRenderConfiguration:renderConf displayConfiguration:disCon defaultPage:vc];

    self.reader.readerDelegate = self;
    [self.reader fetchChapter:info nextChapter:YES animated:NO];
    [self.reader registerClass:[DWReaderADViewController class] forPageViewControllerReuseIdentifier:@"ad"];
    [self presentViewController:self.reader animated:YES completion:nil];
}

-(void)reader:(DWReaderViewController *)reader requestBookDataWithChapterInfo:(DWReaderChapterInfo *)chapterInfo nextChapter:(BOOL)next preload:(BOOL)preload requestCompleteCallback:(DWReaderRequestDataCompleteCallback)callback {
    if (callback) {
        NSString * tmp = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"a" ofType:@"txt"] encoding:(NSUTF8StringEncoding) error:nil];
        
        callback(YES,@"霸道总裁爱上我",tmp,chapterInfo.book_id,chapterInfo.chapter_id,0.5,3,next,nil);
    }
}

-(NSString *)reader:(DWReaderViewController *)reader queryChapterIdWithCurrentChapter:(DWReaderChapter *)currentChapter nextChapter:(BOOL)nextChapter {
    NSInteger step = nextChapter ? 1 : -1;
    
    return [@(currentChapter.chapterInfo.chapter_id.integerValue + step) stringValue];
}

//-(void)reader:(DWReaderViewController *)reader reprocessChapter:(DWReaderChapter *)chapter configChapterCallback:(DWReaderReprocessorCallback)callback {
//    DWReaderPageInfo * page = [DWReaderPageInfo pageInfoWithChapter:chapter];
//    NSMutableAttributedString * attr = [[NSMutableAttributedString alloc] initWithString:@"测试首页"];
//    [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:28] range:NSMakeRange(0, attr.length)];
//    [attr addAttribute:NSForegroundColorAttributeName value:[UIColor yellowColor] range:NSMakeRange(0, attr.length)];
//    page.pageContent = attr;
//    ///修改新首页
//    chapter.firstPageInfo.previousPageInfo = page;
//    page.nextPageInfo = chapter.firstPageInfo;
//    
//    DWReaderPageInfo * tmpPage = chapter.firstPageInfo;
//    ///最后一页之后不加广告
//    while (tmpPage && tmpPage.nextPageInfo) {
//        
//        if (tmpPage.page % 4 != 3) {
//            tmpPage = tmpPage.nextPageInfo;
//            continue;
//        }
//        
//        NSMutableAttributedString * attr = [[NSMutableAttributedString alloc] initWithString:@"测试广告"];
//        [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:56] range:NSMakeRange(0, attr.length)];
//        DWReaderADInfo * adPage = [DWReaderADInfo pageInfoWithChapter:chapter];
//        adPage.pageContent = attr;
//        DWReaderPageInfo * nextPage = tmpPage.nextPageInfo;
//
//        if (!nextPage) {
//            break;
//        }
//
//        tmpPage.nextPageInfo = adPage;
//        adPage.previousPageInfo = tmpPage;
//        nextPage.previousPageInfo = adPage;
//        adPage.nextPageInfo = nextPage;
//
//        tmpPage = nextPage;
//    }
//    
//    callback(page,nil,chapter.totalPage + 1);
//}


-(DWReaderPageViewController *)reader:(DWReaderViewController *)reader pageControllerForPageInfo:(DWReaderPageInfo *)pageInfo renderFrame:(CGRect)renderFrame {
    if ([pageInfo isKindOfClass:[DWReaderADInfo class]]) {
        DWReaderADViewController * ad = [reader dequeueReusablePageViewControllerWithIdentifier:@"ad"];
        [ad updateInfo:pageInfo];
        ad.reader = reader;
        ad.renderFrame = renderFrame;
        return ad;
    }
    DWReaderPageViewController * r = [reader dequeueDefaultReusablePageViewController];
    [r updateInfo:pageInfo];
    r.renderFrame = renderFrame;
    return r;
}

-(void)reader:(DWReaderViewController *)reader willDisplayPage:(DWReaderPageViewController *)page {
    NSLog(@"Will Display %@,%@",page.pageInfo.pageContent.string,page);
}

-(void)reader:(DWReaderViewController *)reader didEndDisplayingPage:(DWReaderPageViewController *)page {
    NSLog(@"Did End Displaying %@,%@",page.pageInfo.pageContent.string,page);
}

-(void)reader:(DWReaderViewController *)reader currentPage:(DWReaderPageViewController *)currentPage tapGesture:(UITapGestureRecognizer *)tapGes {
    NSLog(@"Has tap page");
    
}

@end
