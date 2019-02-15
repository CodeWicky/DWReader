//
//  DWReaderPage.m
//  DWReader
//
//  Created by Wicky on 2019/2/13.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderPage.h"

@implementation DWReaderPage

-(NSString *)description {
    return [NSString stringWithFormat:@"Page range is %@,index is %lu,pageContent is %@,offsetY is %f,needRenderTitle is %@",NSStringFromRange(self.range),self.page,self.pageContent.string,self.offsetY,self.needRenderTitle ? @"true" : @"false"];
}

@end
