//
//  DWReaderRenderConfiguration.m
//  DWReader
//
//  Created by Wicky on 2019/2/16.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderRenderConfiguration.h"

@implementation DWReaderRenderConfiguration

#pragma mark --- override ---
-(instancetype)init {
    if (self = [super init]) {
        ///默认黑体简体中文
        _fontName = @"Heiti SC";
    }
    return self;
}

-(BOOL)isEqual:(__kindof DWReaderRenderConfiguration *)object {
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

-(id)copyWithZone:(NSZone *)zone {
    typeof(self) newInstance = [[[self class] alloc] init];
    newInstance.renderFrame = self.renderFrame;
    newInstance.fontName = self.fontName;
    newInstance.titleFontSize = self.titleFontSize;
    newInstance.titleLineSpacing = self.titleLineSpacing;
    newInstance.titleSpacing = self.titleSpacing;
    newInstance.contentFontSize = self.contentFontSize;
    newInstance.contentLineSpacing = self.contentLineSpacing;
    newInstance.paragraphSpacing = self.paragraphSpacing;
    newInstance.paragraphHeaderSpacing = self.paragraphHeaderSpacing;
    return newInstance;
}

@end
