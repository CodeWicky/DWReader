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

@interface DWReaderPageViewController : UIViewController

@property (nonatomic ,strong ,readonly) DWReaderPageInfo * pageInfo;

@property (nonatomic ,assign ,readonly) CGRect renderFrame;

+(instancetype)pageWithInfo:(DWReaderPageInfo *)info renderFrame:(CGRect)renderFrame;
-(instancetype)initWithInfo:(DWReaderPageInfo *)info renderFrame:(CGRect)renderFrame;

@end

NS_ASSUME_NONNULL_END
