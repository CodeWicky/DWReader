//
//  DWReaderParagraph.m
//  DWReader
//
//  Created by Wicky on 2019/2/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderParagraph.h"

@implementation DWReaderParagraph

#pragma mark --- override ---
-(NSString *)description {
    return [NSString stringWithFormat:@"Paragraph range is Loc:%lu - Len:%lu",self.range.location,self.range.length];
}

@end
