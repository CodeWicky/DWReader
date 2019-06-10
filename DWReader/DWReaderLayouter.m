//
//  DWReaderLayouter.m
//  DWReader
//
//  Created by Wicky on 2019/6/7.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderLayouter.h"

///安全释放
#define CFSAFERELEASE(a)\
do {\
if(a) {\
CFRelease(a);\
a = NULL;\
}\
} while(0);

///安全赋值
#define CFSAFESETVALUEA2B(a,b)\
do {\
CFSAFERELEASE(b)\
if (a) {\
CFRetain(a);\
b = a;\
}\
} while(0);

@implementation DWReaderCTLineWraper

#pragma mark --- tool method ---
+(instancetype)createWrapperForCTLine:(CTLineRef)ctLine {
    DWReaderCTLineWraper * wrapper = [[DWReaderCTLineWraper alloc] initWithCTLine:ctLine];
    return wrapper;
}

-(instancetype)initWithCTLine:(CTLineRef)ctLine {
    if (self = [super init]) {
        CFSAFESETVALUEA2B(ctLine, _ctLine)
        CFRange range = CTLineGetStringRange(ctLine);
        _startIndex = range.location;
        _endIndex = range.location + range.length;
    }
    return self;
}

-(void)configWithOrigin:(CGPoint)origin row:(NSUInteger)row ctFrame:(CTFrameRef)ctFrame convertHeight:(CGFloat)height {
    _lineOrigin = origin;
    _row = row;
    CGFloat lineAscent;
    CGFloat lineDescent;
    CGFloat lineWidth = CTLineGetTypographicBounds(_ctLine, &lineAscent, &lineDescent, nil);
    CGRect boundsLine = CGRectMake(0, - lineDescent, lineWidth, lineAscent + lineDescent);
    boundsLine = CGRectOffset(boundsLine, origin.x, origin.y);
    _lineRect = getRectWithCTFramePathOffset(boundsLine, ctFrame);
    _frame = convertRect(_lineRect, height);
}

-(void)configPreviousLine:(DWReaderCTLineWraper *)preLine {
    _previousLine = preLine;
    [preLine configNextLine:self];
}

-(void)configNextLine:(DWReaderCTLineWraper *)nextLine {
    _nextLine = nextLine;
}

///获取CTFrame校正后的尺寸
NS_INLINE CGRect getRectWithCTFramePathOffset(CGRect rect,CTFrameRef frame) {
    CGPathRef path = CTFrameGetPath(frame);
    CGRect colRect = CGPathGetBoundingBox(path);
    return CGRectOffset(rect, colRect.origin.x, colRect.origin.y);
}

///获取镜像frame
NS_INLINE CGRect convertRect(CGRect rect,CGFloat height) {
    if (CGRectEqualToRect(rect, CGRectNull)) {
        return CGRectNull;
    }
    return CGRectMake(rect.origin.x, height - rect.origin.y - rect.size.height, rect.size.width, rect.size.height);
}

@end

@implementation DWReaderLayouter

#pragma mark --- interface method ---
+(instancetype)layoutWithCTFrame:(CTFrameRef)ctFrame containerHeight:(CGFloat)height {
    DWReaderLayouter * layout = [[DWReaderLayouter alloc] initWithCTFrame:ctFrame containerHeight:height];
    return layout;
}

#pragma mark --- tool method ---
-(instancetype)initWithCTFrame:(CTFrameRef)ctFrame containerHeight:(CGFloat)height {
    if (self = [super init]) {
        CFArrayRef arrLines = CTFrameGetLines(ctFrame);
        NSUInteger count = CFArrayGetCount(arrLines);
        CGPoint points[count];
        CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), points);
        DWReaderCTLineWraper * previousLine = nil;
        NSMutableArray * tmpLineArr = @[].mutableCopy;
        for (int i = 0; i < count; i++) {
            CTLineRef line = CFArrayGetValueAtIndex(arrLines, i);
            DWReaderCTLineWraper * lineWrap = [DWReaderCTLineWraper createWrapperForCTLine:line];
            [lineWrap configWithOrigin:points[i] row:i ctFrame:ctFrame convertHeight:height];
            
            if (CGRectGetMaxY(lineWrap.frame) > height) {
                break;
            }
            [lineWrap configPreviousLine:previousLine];
            previousLine = lineWrap;
            [tmpLineArr addObject:lineWrap];
        }
        _lines = tmpLineArr.copy;
    }
    return self;
}

@end
