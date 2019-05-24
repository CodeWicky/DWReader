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
    DWReaderDisplayConfiguration * conf = [DWReaderDisplayConfiguration new];
    conf.textColor = [UIColor yellowColor];
    [self.reader updateWithDisplayConfiguration:conf];
}

@end
