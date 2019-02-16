//
//  DWReaderPage.m
//  DWReader
//
//  Created by Wicky on 2019/2/16.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderPage.h"

@implementation DWReaderPage

+(instancetype)pageWithInfo:(DWReaderPageInfo *)info {
    return [[[self class] alloc] initWithInfo:info];
}

-(instancetype)initWithInfo:(DWReaderPageInfo *)info {
    if (self = [super init]) {
        _pageInfo = info;
    }
    return self;
}

@end
