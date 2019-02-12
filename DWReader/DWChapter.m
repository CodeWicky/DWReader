//
//  DWChapter.m
//  DWReader
//
//  Created by Wicky on 2019/2/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWChapter.h"

@implementation DWChapter

#pragma mark --- interface method ---
+(instancetype)chapterWithOriginString:(NSString *)oriStr lineSpacing:(CGFloat)lineSpacing paragraphSpacing:(CGFloat)paragraphSpacing {
    return [[self alloc] initWithOriginString:oriStr lineSpacing:lineSpacing paragraphSpacing:paragraphSpacing];
}

-(instancetype)initWithOriginString:(NSString *)oriStr lineSpacing:(CGFloat)lineSpacing paragraphSpacing:(CGFloat)paragraphSpacing {
    if (self = [super init]) {
        _originString = oriStr;
        _lineSpacing = lineSpacing;
        _paragraphSpacing = paragraphSpacing;
    }
    return self;
}

#pragma mark --- tool method ---
-(void)parseChapter {
    
}

@end
