//
//  DWReaderPage.h
//  DWReader
//
//  Created by Wicky on 2019/2/16.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DWReaderPageInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWReaderPage : NSObject

@property (nonatomic ,strong ,readonly) DWReaderPageInfo * pageInfo;

+(instancetype)pageWithInfo:(DWReaderPageInfo *)info;
-(instancetype)initWithInfo:(DWReaderPageInfo *)info;

@end

NS_ASSUME_NONNULL_END
