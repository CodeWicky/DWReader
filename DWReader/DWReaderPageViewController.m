//
//  DWReaderPage.m
//  DWReader
//
//  Created by Wicky on 2019/2/16.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderPageViewController.h"

@interface DWReaderPageViewController ()

@property (nonatomic ,strong) UILabel * contentLb;

@end

@implementation DWReaderPageViewController

#pragma mark --- interface method ---
+(instancetype)pageWithRenderFrame:(CGRect)renderFrame {
    return [[[self class] alloc] initWithRenderFrame:renderFrame];
}

-(instancetype)initWithRenderFrame:(CGRect)renderFrame {
    if (self = [super init]) {
        _renderFrame = renderFrame;
    }
    return self;
}

-(void)configNextPage:(DWReaderPageViewController *)nextPage {
    self.nextPage = nextPage;
    nextPage.previousPage = self;
}

-(void)updateInfo:(DWReaderPageInfo *)info {
    if (![_pageInfo isEqual:info]) {
        _pageInfo = info;
        self.contentLb.frame = self.renderFrame;
        [self draw];
    }
}

#pragma mark --- life cycle ---
-(void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark --- tool method ---
-(void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.contentLb];
}

-(void)draw {
    self.contentLb.attributedText = self.pageInfo.pageContent;
    [self.contentLb sizeToFit];
}

#pragma mark --- setter/getter ---
-(UILabel *)contentLb {
    if (!_contentLb) {
        _contentLb = [[UILabel alloc] initWithFrame:self.renderFrame];
        _contentLb.numberOfLines = 0;
    }
    return _contentLb;
}

@end
