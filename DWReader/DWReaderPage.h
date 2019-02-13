//
//  DWReaderPage.h
//  DWReader
//
//  Created by Wicky on 2019/2/13.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DWReaderPage : NSObject

@property (nonatomic ,assign) NSRange range;

@property (nonatomic ,assign) NSUInteger page;

@end

NS_ASSUME_NONNULL_END
