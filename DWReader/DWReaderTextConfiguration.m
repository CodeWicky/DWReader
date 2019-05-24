//
//  DWReaderTextConfiguration.m
//  DWReader
//
//  Created by Wicky on 2019/2/16.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderTextConfiguration.h"

@implementation DWReaderTextConfiguration

#pragma mark --- override ---
-(instancetype)init {
    if (self = [super init]) {
        ///默认黑体简体中文
        _fontName = @"Heiti SC";
    }
    return self;
}

-(BOOL)isEqual:(__kindof DWReaderTextConfiguration *)object {
    if (CGRectEqualToRect(self.renderFrame, object.renderFrame) &&
        [self.fontName isEqualToString:object.fontName] &&
        self.titleFontSize == object.titleFontSize &&
        self.titleLineSpacing == object.titleLineSpacing &&
        self.titleSpacing == object.titleSpacing &&
        self.contentFontSize == object.contentFontSize &&
        self.contentLineSpacing == object.contentLineSpacing &&
        self.paragraphSpacing == object.paragraphSpacing &&
        self.paragraphHeaderSpacing == object.paragraphHeaderSpacing) {
        return YES;
    }
    return NO;
}

@end
