//
//  DWReaderADViewController.m
//  DWReader
//
//  Created by Wicky on 2019/5/23.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderADViewController.h"


@implementation DWReaderADViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blueColor];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    DWReaderDisplayConfiguration * dis = [DWReaderDisplayConfiguration new];
    dis.textColor = [UIColor yellowColor];
    [self.reader updateDisplayConfiguration:dis];
    DWReaderRenderConfiguration * conf = self.reader.renderConf;
    conf.contentFontSize = 30;
    [self.reader updateRenderConfiguration:conf];
}

@end
