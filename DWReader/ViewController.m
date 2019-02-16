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

@interface ViewController ()

@property (nonatomic ,strong) DWReaderChapter * c;

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
    NSString * testString = @"豪华的别墅酒店。\n年轻俊美的男人刚刚从浴室里洗澡出来，健硕的腰身只围着一条浴巾，充满了力与美的身躯，仿佛西方阿波罗临世。\n“该死的。”一声低咒，男人低下头，一脸烦燥懊恼。\n他拿起手机，拔通了助手的电话，“给我找个干净的女人进来。”\n“少爷，怎么今晚有兴趣了？”\n\n“在酒会上喝错了东西，快点。”低沉的声线已经不奈烦了。\n“好的，马上。”\n一处景观灯的牌子面前，穿着清凉的女孩抬起头，看着那蛇线一样的线路图，感到相当的无语。\n明明就是来旅个游的，竟然迷路了。\n";
    
    NSString * titleString = @"霸道总裁爱上我\n";
    
    CGRect renderFrame = CGRectMake(15, self.view.safeAreaInsets.top, self.view.bounds.size.width - 30, self.view.bounds.size.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom);
    DWReaderChapter * c = [DWReaderChapter chapterWithOriginString:testString title:@"霸道总裁爱上我" renderFrame:renderFrame];
    [c parseChapter];
    
    DWReaderPageInfoConfiguration * conf = [[DWReaderPageInfoConfiguration alloc] init];
    conf.titleFontSize = 28;
    conf.titleLineSpacing = 18;
    conf.titleSpacing = 28;
    conf.contentFontSize = 24;
    conf.contentLineSpacing = 18;
    conf.paragraphSpacing = 28;
    conf.paragraphHeaderSpacing = 30;
    
    [c seperatePageWithPageConfiguration:conf];
    [c configTextColor: [UIColor redColor]];
    
    self.c = c;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSUInteger page = 0;
    
    DWReaderPageInfo * info = [self.c.pages objectAtIndex:page];
    DWReaderPageViewController * pageVC = [DWReaderPageViewController pageWithInfo:info renderFrame:self.c.renderFrame];
    
    [self.navigationController pushViewController:pageVC animated:YES];
    
}


@end
