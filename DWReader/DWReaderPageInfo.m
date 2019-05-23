//
//  DWReaderPageInfo.m
//  DWReader
//
//  Created by Wicky on 2019/2/13.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderPageInfo.h"

@implementation DWReaderPageInfo

+(instancetype)pageInfoWithChapter:(DWReaderChapter *)chapter {
    return [[[self class] alloc] initWithChapter:chapter];
}

-(instancetype)initWithChapter:(DWReaderChapter *)chapter {
    if (self = [super init]) {
        _chapter = chapter;
    }
    return self;
}

#pragma mark --- override ---
-(instancetype)init {
    NSAssert(NO, @"DWReader can't initialize pageInfo with -init.Please use -pageInfoWithChapter: instead.");
    return nil;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"Page range is %@,index is %ld,pageContent is %@",NSStringFromRange(self.range),self.page,self.pageContent.string];
}
 
@end
