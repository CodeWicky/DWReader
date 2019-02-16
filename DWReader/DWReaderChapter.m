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

///绘制文本
@property (nonatomic ,strong) NSMutableAttributedString * drawString;

@end

@implementation DWReaderChapter

#pragma mark --- interface method ---
+(instancetype)chapterWithOriginString:(NSString *)oriStr title:(NSString *)title renderFrame:(CGRect)renderFrame info:(DWReaderChapterInfo *)info {
    return [[self alloc] initWithOriginString:oriStr title:title renderFrame:renderFrame info:info];
}

-(instancetype)initWithOriginString:(NSString *)oriStr title:(NSString *)title renderFrame:(CGRect)renderFrame info:(DWReaderChapterInfo *)info {
    if (self = [super init]) {
        _originString = oriStr;
        _title = title;
        _renderFrame = renderFrame;
        _chapterInfo = info;
        _pageConf = nil;
        _textColor = nil;
        _content = nil;
        _pages = nil;
        _drawString = nil;
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
    _content = content;
}

-(void)seperatePageWithPageConfiguration:(DWReaderTextConfiguration *)conf {
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
        [self.drawString addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, self.drawString.length)];
        
        [self.pages enumerateObjectsUsingBlock:^(DWReaderPageInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.pageContent = [self.drawString attributedSubstringFromRange:obj.range];
        }];
    }
}

-(void)asyncParseChapterToPageWithConfiguration:(DWReaderTextConfiguration *)conf textColor:(UIColor *)textColor completion:(dispatch_block_t)completion {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self parseChapterToPageWithConfiguration:conf textColor:textColor];
        if (completion) {
            completion();
        }
    });
}

-(void)parseChapterToPageWithConfiguration:(DWReaderTextConfiguration *)conf textColor:(UIColor *)textColor {
    [self parseChapter];
    [self seperatePageWithPageConfiguration:conf];
    [self configTextColor:textColor];
}

#pragma mark --- tool method ---

-(void)configAttributeString {
    ///获取将要绘制的富文本，主要设置字号、行间距属性、添加空白字符
    self.drawString = nil;
    
    ///将标题插入正文头部(标题尾部加换行符)
    NSMutableAttributedString * titleAttr = [self createAttrWithString:[self.title stringByAppendingString:@"\n"] fontName:_pageConf.fontName fontSize:_pageConf.titleFontSize lineSpacing:_pageConf.titleLineSpacing paragraphSpacing:_pageConf.titleSpacing paragraphHeaderSpacing:0];
    NSMutableAttributedString * contentAttr = [self createAttrWithString:self.content fontName:_pageConf.fontName fontSize:_pageConf.contentFontSize lineSpacing:_pageConf.contentLineSpacing paragraphSpacing:_pageConf.paragraphSpacing paragraphHeaderSpacing:_pageConf.paragraphHeaderSpacing];
    [titleAttr appendAttributedString:contentAttr];

    self.drawString = titleAttr;
}

-(NSMutableAttributedString *)createAttrWithString:(NSString *)string fontName:(NSString *)fontName fontSize:(CGFloat)fontSize lineSpacing:(CGFloat)lineSpacing paragraphSpacing:(CGFloat)paragraphSpacing paragraphHeaderSpacing:(CGFloat)paragraphHeaderSpacing {
    
    NSMutableAttributedString * attr = [[NSMutableAttributedString alloc] initWithString:string];
    
    NSRange range = NSMakeRange(0, attr.length);
    ///设置字符串属性（字号、行间距）
    [attr addAttribute:NSFontAttributeName value:[UIFont fontWithName:fontName size:fontSize] range:range];
    NSMutableParagraphStyle * paraStyle = [[NSMutableParagraphStyle alloc] init];
    paraStyle.lineSpacing = lineSpacing;
    paraStyle.paragraphSpacing = paragraphSpacing;
    paraStyle.firstLineHeadIndent = paragraphHeaderSpacing;
    paraStyle.lineBreakMode = NSLineBreakByCharWrapping;
    [attr addAttribute:NSParagraphStyleAttributeName value:paraStyle range:range];
    
    return attr;
}

-(void)seperatePage {
    
    NSMutableArray * tmpPages = [NSMutableArray arrayWithCapacity:0];
    
    NSUInteger currentLoc = 0;
    ///当前手机以xs max做最大屏幕，14号字做最小字号，18像素为最小行间距，最大展示字数为564个字，取整估算为600字，为避免因数字较多在成的字形大小差距的影响，乘以1.2倍的安全余量，故当前安全阈值为720字
    NSUInteger totalLen = self.drawString.length;
    NSUInteger length = totalLen;
    CGSize renderSize = self.renderFrame.size;
    DWReaderPageInfo * lastPageInfo = nil;
    while (length > 0) {
        length = MIN(length, 720);
        
        ///截取一段字符串
        NSAttributedString * sub = [self.drawString attributedSubstringFromRange:NSMakeRange(currentLoc, length)];
        ///选定渲染区域
        NSRange range = [self calculateVisibleRangeWithString:sub renderSize:renderSize location:currentLoc];
        if (range.length == 0) {
            ///计算出错
            NSAssert(NO, @"DWReader can't calculate visible range,currentLoc = %lu,length = %lu,size = %@,sub = %@",currentLoc,length,NSStringFromCGSize(renderSize),sub.string);
            break;
        }
        
        ///配置分页信息
        DWReaderPageInfo * pageInfo = [[DWReaderPageInfo alloc] init];
        pageInfo.range = range;
        pageInfo.page = tmpPages.count;
        pageInfo.previousPageInfo = lastPageInfo;
        lastPageInfo.nextPageInfo = pageInfo;
        [tmpPages addObject:pageInfo];
        
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



