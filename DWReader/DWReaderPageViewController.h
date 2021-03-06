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

@property (nonatomic ,strong) UILabel * contentLabel;

@property (nonatomic ,weak) DWReaderPageViewController * nextPage;

@property (nonatomic ,weak) DWReaderPageViewController * previousPage;

@property (nonatomic ,strong ,readonly) DWReaderPageInfo * pageInfo;

@property (nonatomic ,assign) CGRect renderFrame;

-(void)configNextPage:(DWReaderPageViewController *)nextPage;

-(void)updateInfo:(DWReaderPageInfo *)info;

-(void)reload;

@end

NS_ASSUME_NONNULL_END
