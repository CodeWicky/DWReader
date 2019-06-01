//
//  DWReaderChapterInfo.h
//  DWReader
//
//  Created by Wicky on 2019/2/16.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DWReaderChapterInfo : NSObject

@property (nonatomic ,copy) NSString * chapter_id;

@property (nonatomic ,copy) NSString * book_id;

@property (nonatomic ,assign) CGFloat percent;

@property (nonatomic ,copy) NSString * title;

@property (nonatomic ,assign) NSInteger chapter_index;

@property (nonatomic ,strong) id userInfo;

@end

NS_ASSUME_NONNULL_END
