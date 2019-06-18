//
//  DWReaderRenderConfiguration.m
//  DWReader
//
//  Created by Wicky on 2019/2/16.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderRenderConfiguration.h"

@implementation DWReaderRenderConfiguration

-(BOOL)isEqual:(__kindof DWReaderRenderConfiguration *)object {
    if (CGRectEqualToRect(self.renderFrame, object.renderFrame) &&
        [self.titleFont isEqual:object.titleFont] &&
        self.titleLineSpacing == object.titleLineSpacing &&
        self.titleSpacing == object.titleSpacing &&
        [self.contentFont isEqual:object.contentFont] &&
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
    newInstance.titleFont = self.titleFont;
    newInstance.titleLineSpacing = self.titleLineSpacing;
    newInstance.titleSpacing = self.titleSpacing;
    newInstance.contentFont = self.contentFont;
    newInstance.contentLineSpacing = self.contentLineSpacing;
    newInstance.paragraphSpacing = self.paragraphSpacing;
    newInstance.paragraphHeaderSpacing = self.paragraphHeaderSpacing;
    return newInstance;
}

@end
