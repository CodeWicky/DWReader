//
//  DWReaderPageInfo.m
//  DWReader
//
//  Created by Wicky on 2019/2/13.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderPageInfo.h"

@implementation DWReaderPageInfo

-(NSString *)description {
    return [NSString stringWithFormat:@"Page range is %@,index is %lu,pageContent is %@",NSStringFromRange(self.range),self.page,self.pageContent.string];
}
 
@end
