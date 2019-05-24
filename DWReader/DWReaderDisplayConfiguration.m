//
//  DWReaderDisplayConfiguration.m
//  DWReader
//
//  Created by Wicky on 2019/2/17.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderDisplayConfiguration.h"

@implementation DWReaderDisplayConfiguration

-(instancetype)init {
    if (self = [super init]) {
        _transitionStyle = UIPageViewControllerTransitionStylePageCurl;
        _textColor = [UIColor blackColor];
    }
    return self;
}

-(BOOL)isEqual:(__kindof DWReaderDisplayConfiguration *)object {
    if (self.transitionStyle == object.transitionStyle &&
        [self.textColor isEqual:object.textColor]) {
        return YES;
    }
    return NO;
}

-(id)copyWithZone:(NSZone *)zone {
    typeof(self) newInstance = [[[self class] alloc] init];
    newInstance.transitionStyle = self.transitionStyle;
    newInstance.textColor = self.textColor;
    return newInstance;
}

@end
