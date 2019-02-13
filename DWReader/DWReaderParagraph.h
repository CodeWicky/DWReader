//
//  DWReaderParagraph.h
//  DWReader
//
//  Created by Wicky on 2019/2/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DWReaderParagraph : NSObject

///段落范围
@property (nonatomic ,assign) NSRange range;

///插入分段符后修正的range(fixRange的loc即为要插入空白符的loc)
@property (nonatomic ,assign) NSRange fixRange;

///第几段
@property (nonatomic ,assign) NSUInteger index;

///上一段
@property (nonatomic ,weak) DWReaderParagraph * prevParagraph;

///下一段
@property (nonatomic ,weak) DWReaderParagraph * nextParagraph;

@end

NS_ASSUME_NONNULL_END
