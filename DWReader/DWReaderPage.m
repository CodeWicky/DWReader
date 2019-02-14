//
//  DWReaderPage.m
//  DWReader
//
//  Created by Wicky on 2019/2/13.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderPage.h"

@implementation DWReaderPage

#pragma mark --- override ---
-(NSString *)description {
    return [NSString stringWithFormat:@"Page range is Loc:%lu - Len:%lu,Page index is %lu,Page content:%@",self.range.location,self.range.length,self.page,self.pageContent.string];
}

@end
