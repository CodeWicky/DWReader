//
//  DWReaderChapterInfo.m
//  DWReader
//
//  Created by Wicky on 2019/2/16.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderChapterInfo.h"

NSInteger const DWReaderChapterUndefined = -1;

@implementation DWReaderChapterInfo

-(instancetype)init {
    if (self = [super init]) {
        _chapter_index = DWReaderChapterUndefined;
    }
    return self;
}

@end
