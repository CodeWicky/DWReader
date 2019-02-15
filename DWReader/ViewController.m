//
//  ViewController.m
//  DWReader
//
//  Created by Wicky on 2019/2/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "ViewController.h"
#import "DWReaderChapter.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString * testString = @"豪华的别墅酒店。\n年轻俊美的男人刚刚从浴室里洗澡出来，健硕的腰身只围着一条浴巾，充满了力与美的身躯，仿佛西方阿波罗临世。\n“该死的。”一声低咒，男人低下头，一脸烦燥懊恼。\n他拿起手机，拔通了助手的电话，“给我找个干净的女人进来。”\n“少爷，怎么今晚有兴趣了？”\n\n“在酒会上喝错了东西，快点。”低沉的声线已经不奈烦了。\n“好的，马上。”\n一处景观灯的牌子面前，穿着清凉的女孩抬起头，看着那蛇线一样的线路图，感到相当的无语。\n明明就是来旅个游的，竟然迷路了。\n";
//    testString = @"\n\nabc\n\nde\nf\n";
    
    NSMutableParagraphStyle * p = [[NSMutableParagraphStyle alloc] init];
    p.firstLineHeadIndent = 100;
    p.paragraphSpacing = 100;
    NSMutableAttributedString * attr = [[NSMutableAttributedString alloc] initWithString:testString];
    [attr addAttribute:NSParagraphStyleAttributeName value:p range:NSMakeRange(0, testString.length)];
    
    /**
     0-5,
     6-4,
     11-3,
     */
    
    UILabel * lab = [[UILabel alloc] initWithFrame:self.view.bounds];
    lab.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:lab];
    
    lab.attributedText = attr;
    lab.numberOfLines = 0;
    
    
    
//    DWReaderChapter * c = [DWReaderChapter chapterWithOriginString:testString title:@"aaa" renderSize:CGSizeMake(200, 40)];
//    [c parseChapter];
//
//    [c seperatePageWithFontSize:24 titleSpacing:28 lineSpacing:18 paragraphSpacing:28];
}


@end
