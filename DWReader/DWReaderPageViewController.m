//
//  DWReaderPage.m
//  DWReader
//
//  Created by Wicky on 2019/2/16.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderPageViewController.h"

@interface DWReaderPageInfo (Private_Page)

@property (nonatomic ,assign) BOOL needsReloadFlag;

@end

@interface DWReaderPageViewController ()

@property (nonatomic ,strong) UILabel * contentLb;

///隐藏私有属性，为extention中属性提供setter/getter
@property (nonatomic ,strong) id reuseInternal;

@end

@implementation DWReaderPageViewController

#pragma mark --- interface method ---
-(void)configNextPage:(DWReaderPageViewController *)nextPage {
    self.nextPage = nextPage;
    nextPage.previousPage = self;
}

-(void)updateInfo:(DWReaderPageInfo *)info {
    if (info.needsReloadFlag || ![_pageInfo isEqual:info]) {
        info.needsReloadFlag = NO;
        _pageInfo = info;
        [self reload];
    }
}

-(void)reload {
    self.contentLb.frame = self.renderFrame;
    [self draw];
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

-(void)setRenderFrame:(CGRect)renderFrame {
    if (!CGRectEqualToRect(renderFrame, _renderFrame)) {
        _renderFrame = renderFrame;
        self.contentLb.frame = _renderFrame;
        if (self.pageInfo) {
            [self draw];
        }
    }
}

@end
