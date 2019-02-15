//
//  DWReaderChapter.m
//  DWReader
//
//  Created by Wicky on 2019/2/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderChapter.h"
#import <CoreText/CoreText.h>

#define kLineBreakSymbol @"\n"
#define kLineBreakLength (1)

///安全释放
#define CFSAFERELEASE(a)\
do {\
if(a) {\
CFRelease(a);\
a = NULL;\
}\
} while(0);

@interface DWReaderChapter ()

///分段后的正文内容
@property (nonatomic ,strong) NSString * parsedString;

///绘制文本
@property (nonatomic ,strong) NSMutableAttributedString * drawString;

@end

@implementation DWReaderChapter

#pragma mark --- interface method ---
+(instancetype)chapterWithOriginString:(NSString *)oriStr title:(NSString *)title renderSize:(CGSize)renderSize {
    return [[self alloc] initWithOriginString:oriStr title:title renderSize:renderSize];
}

-(instancetype)initWithOriginString:(NSString *)oriStr title:(NSString *)title renderSize:(CGSize)renderSize {
    if (self = [super init]) {
        _originString = oriStr;
        _title = title;
        _renderSize = renderSize;
        _content = nil;
        _parsedString = nil;
        _pageConf = nil;
    }
    return self;
}

-(void)parseChapter {
    NSString * content = _originString;
    
    ///替换连续\n为单个\n
    content = [[[NSRegularExpression alloc] initWithPattern:@"\\n+" options:0 error:nil] stringByReplacingMatchesInString:content options:0 range:NSMakeRange(0, content.length) withTemplate:kLineBreakSymbol];
    
    ///去除段首段尾的分段符
    if ([content hasPrefix:kLineBreakSymbol]) {
        content = [content substringFromIndex:kLineBreakLength];
    }
    if ([content hasSuffix:kLineBreakSymbol]) {
        content = [content substringToIndex:content.length - kLineBreakLength];
    }
    
    ///处理为可以直接排版的字符串
    self.parsedString = content;
    
}

-(void)seperatePageWithPageConfiguration:(DWReaderPageConfiguration *)conf {
    ///当任意一个影响分页的数据改变时才重新计算分页
    if (![self.pageConf isEqual:conf]) {
        
        ///赋值基础属性并清空之前的分页数据
        _pageConf = conf;
        _pages = nil;
        
        ///组装富文本
        [self configAttributeString];
        
        ///富文本组装完成后可以开始分页
        [self seperatePage];
    }
}

-(void)configTextColor:(UIColor *)textColor {
    if (![self.textColor isEqual:textColor]) {
        _textColor = textColor;
    }
}

#pragma mark --- tool method ---

-(void)configAttributeString {
    ///获取将要绘制的富文本，主要设置字号、行间距属性、添加空白字符
    self.drawString = nil;
    NSMutableAttributedString * draw = [[NSMutableAttributedString alloc] initWithString:self.parsedString];
    
    NSRange range = NSMakeRange(0, draw.length);
    ///设置字符串属性（字号、行间距）
    [draw addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:_pageConf.fontSize] range:range];
    NSMutableParagraphStyle * paraStyle = [[NSMutableParagraphStyle alloc] init];
    paraStyle.lineSpacing = _pageConf.lineSpacing;
    paraStyle.paragraphSpacing = _pageConf.paragraphSpacing;
    paraStyle.firstLineHeadIndent = _pageConf.paragraphHeaderSpacing;
    [draw addAttribute:NSParagraphStyleAttributeName value:paraStyle range:range];
    
    self.drawString = draw;
}

-(void)seperatePage {
    ///第一页存在标题，所以首页处理不同。首页应先绘制标题，绘制标题过后计算首页正文绘制区域，来进行首页的分页。其余页的分页均以渲染区域进行分页，每个新页中要考虑新页的起始位置是否是分段的换行符或空白字符，如果是，要排除掉此区域在计算分页
    UIFont * titleFont = [UIFont systemFontOfSize:_pageConf.fontSize * 1.5];
    UILabel * tmpLb = [[UILabel alloc] initWithFrame:(CGRect){CGPointZero,self.renderSize}];
    tmpLb.font = titleFont;
    tmpLb.numberOfLines = 0;
    tmpLb.text = self.title;
    [tmpLb sizeToFit];
    
    ///计算首页渲染区域
    CGFloat title_h = tmpLb.bounds.size.height;
    CGFloat offset_y = title_h + _pageConf.titleSpacing;
    CGSize firstParagraphRenderSize = CGSizeMake(self.renderSize.width, self.renderSize.height - offset_y);
    
    NSMutableArray * tmpPages = [NSMutableArray arrayWithCapacity:0];
    
    ///如果剩余绘制区域高度小于零说明第一页只能绘制标题，故数组中添加标题页
    if (firstParagraphRenderSize.height <= 0) {
        DWReaderPage * titlePage = [[DWReaderPage alloc] init];
        titlePage.needRenderTitle = YES;
        [tmpPages addObject:titlePage];
    }
    
    NSUInteger currentLoc = 0;
    ///当前手机以xs max做最大屏幕，14号字做最小字号，18像素为最小行间距，最大展示字数为564个字，取整估算为600字，为避免因数字较多在成的字形大小差距的影响，乘以1.2倍的安全余量，故当前安全阈值为720字
    NSUInteger totalLen = self.drawString.length;
    NSUInteger length = totalLen;
    while (length > 0) {
        length = MIN(length, 720);
        
        ///截取一段字符串
        NSAttributedString * sub = [self.drawString attributedSubstringFromRange:NSMakeRange(currentLoc, length)];
        ///选定渲染区域
        CGSize size = tmpPages.count == 0 ? firstParagraphRenderSize : self.renderSize;
        NSRange range = [self calculateVisibleRangeWithString:sub renderSize:size location:currentLoc];
        if (range.length == 0) {
            ///计算出错
            NSAssert(NO, @"DWReader can't calculate visible range,currentLoc = %lu,length = %lu,size = %@,sub = %@",currentLoc,length,NSStringFromCGSize(size),sub.string);
            break;
        }
        
        ///配置分页信息
        DWReaderPage * page = [[DWReaderPage alloc] init];
        page.range = range;
        page.page = tmpPages.count;
        page.pageContent = [self.drawString attributedSubstringFromRange:page.range];
        if (page.page == 0) {
            page.offsetY = offset_y;
            page.needRenderTitle = YES;
        }
        [tmpPages addObject:page];
        
        ///更改currentLoc
        currentLoc = NSMaxRange(range);
        ///无需考虑当前位置恰好为一个换行符的情况，因为换行符横向不占空间，一定会计算到之前的段尾中，所以不存在currentLoc位置恰好为换行符的情况。直接计算剩余参与分页长度
        length = totalLen - currentLoc;
    }
    
    ///至此分页完成
    _pages = [tmpPages copy];
    NSLog(@"%@",_pages);
}

-(NSRange)calculateVisibleRangeWithString:(NSAttributedString *)string renderSize:(CGSize)size location:(NSUInteger)loc {
    ///利用CoreText计算当前显示区域内可显示的范围
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef) string);
    UIBezierPath * bezierPath = [UIBezierPath bezierPathWithRect:(CGRect){CGPointZero,size}];
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), bezierPath.CGPath, NULL);
    CFRange range = CTFrameGetVisibleStringRange(frame);
    NSRange fixRange = {loc, range.length};
    CFSAFERELEASE(frame);
    CFSAFERELEASE(framesetter);
    return fixRange;
}

#pragma mark --- override ---
-(BOOL)isEqual:(id)object {
    ///比较类
    if (![NSStringFromClass(object) isEqualToString:NSStringFromClass([self class])]) {
        return NO;
    }
    ///比较原始字符串
    if (![((DWReaderChapter *)object).originString isEqualToString:self.originString]) {
        return NO;
    }
    ///比较页面配置
    if (((DWReaderChapter *)object).pageConf != self.pageConf) {
        return NO;
    }
    return YES;
}

@end


@implementation DWReaderPageConfiguration

-(BOOL)isEqual:(__kindof DWReaderPageConfiguration *)object {
    if (self.fontSize == object.fontSize &&
        self.titleSpacing == object.titleSpacing &&
        self.lineSpacing == object.lineSpacing &&
        self.paragraphSpacing == object.paragraphSpacing &&
        self.paragraphHeaderSpacing == object.paragraphHeaderSpacing) {
        return YES;
    }
    return NO;
}

@end
