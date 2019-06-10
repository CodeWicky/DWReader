//
//  DWReaderChapter.m
//  DWReader
//
//  Created by Wicky on 2019/2/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderChapter.h"
#import "DWReaderLayouter.h"

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

@property (nonatomic ,strong) DWReaderRenderConfiguration * internalPageConf;

@property (nonatomic ,assign) BOOL needSetColor;

@end

@implementation DWReaderChapter

#pragma mark --- interface method ---
+(instancetype)chapterWithOriginString:(NSString *)oriStr title:(NSString *)title charactersToBeFiltered:(NSCharacterSet *)filtered info:(DWReaderChapterInfo *)info {
    return [[self alloc] initWithOriginString:oriStr title:title charactersToBeFiltered:filtered info:info];
}

-(instancetype)initWithOriginString:(NSString *)oriStr title:(NSString *)title charactersToBeFiltered:(NSCharacterSet *)filtered info:(DWReaderChapterInfo *)info {
    if (self = [super init]) {
        _originString = oriStr;
        _title = title;
        _charactersToBeFiltered = filtered;
        _chapterInfo = info;
        _pageConf = nil;
        _internalPageConf = nil;
        _textColor = nil;
        _content = nil;
        _firstPageInfo = nil;
        _lastPageInfo = nil;
        _drawString = nil;
    }
    return self;
}

-(void)parseChapter {
    NSString * content = _originString;
    
    ///替换字符集中所有不合法字符
    if (self.charactersToBeFiltered) {
        content = [[content componentsSeparatedByCharactersInSet:self.charactersToBeFiltered] componentsJoinedByString:@""];
    }
    ///替换\r为\n统一所有换行，然后替换连续\n为单个\n避免连续换行
    content = [content stringByReplacingOccurrencesOfString:@"\r" withString:kLineBreakSymbol];
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

-(BOOL)seperatePageWithPageConfiguration:(DWReaderRenderConfiguration *)conf {
    ///当任意一个影响分页的数据改变时才重新计算分页
    if (![_internalPageConf isEqual:conf]) {
        
        ///赋值基础属性并清空之前的分页数据
        self.pageConf = conf;
        _firstPageInfo = nil;
        _lastPageInfo = nil;
        
        ///组装富文本，此时并不能组装一个完整的富文本，因为分页是视情况而定要改变富文本
        [self configAttributeString];
        
        ///富文本组装完成后可以开始分页
        [self seperatePage];
        ///由于重新组装了富文本，所以要重新设置颜色
        if (self.textColor) {
            [self configTextColor:self.textColor];
        }
        return YES;
    }
    return NO;
}

-(BOOL)configTextColor:(UIColor *)textColor {
    if (![self.textColor isEqual:textColor] || _needSetColor) {
        _needSetColor = NO;
        _textColor = textColor;
        DWReaderPageInfo * page = _firstPageInfo;
        while (page) {
            [page.pageContent addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, page.pageContent.length)];
            [page setNeedsReload];
            page = page.nextPageInfo;
        }
        return YES;
    }
    return NO;
}

-(void)asyncParseChapterToPageWithConfiguration:(DWReaderRenderConfiguration *)conf reprocess:(dispatch_block_t)reprocess completion:(dispatch_block_t)completion {
    [self configAsyncParseStatus:YES];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self parseChapterToPageWithConfiguration:conf reprocess:reprocess];
        [self configAsyncParseStatus:NO];
        if (completion) {
            completion();
        }
    });
}

-(void)parseChapterToPageWithConfiguration:(DWReaderRenderConfiguration *)conf reprocess:( dispatch_block_t)reprocess {
    [self parseChapter];
    [self seperatePageWithPageConfiguration:conf];
    if (reprocess) {
        reprocess();
    }
}

-(void)reprocessChapterWithFirstPageInfo:(DWReaderPageInfo *)first lastPageInfo:(DWReaderPageInfo *)last totalPage:(NSInteger)totalPage {
    if (first) {
        _firstPageInfo = first;
    }
    if (last) {
        _lastPageInfo = last;
    }
    _totalPage = totalPage;
}

-(DWReaderPageInfo *)pageInfoOnPage:(NSUInteger)pageIndex {
    
    BOOL front = YES;
    if (pageIndex > self.totalPage * 0.5) {
        front = NO;
    }
    DWReaderPageInfo * ret = nil;
    if (front) {
        DWReaderPageInfo * tmp = _firstPageInfo;
        while (tmp) {
            if (tmp.page == pageIndex) {
                ret = tmp;
                break;
            } else {
                tmp = tmp.nextPageInfo;
            }
        }
    } else {
        DWReaderPageInfo * tmp = _lastPageInfo;
        while (tmp) {
            if (tmp.page == pageIndex) {
                ret = tmp;
                break;
            } else {
                tmp = tmp.previousPageInfo;
            }
        }
    }
    return ret;
}

#pragma mark --- tool method ---

-(void)configAttributeString {
    ///获取将要绘制的富文本，主要设置字号、行间距属性、添加空白字符
    self.drawString = nil;
    
    ///将标题插入正文头部(标题尾部加换行符)
    NSMutableAttributedString * titleAttr = [self createAttrWithString:[self.title stringByAppendingString:@"\n"] font:_pageConf.titleFont             lineSpacing:_pageConf.titleLineSpacing paragraphSpacing:_pageConf.titleSpacing paragraphHeaderSpacing:0];
    NSMutableAttributedString * contentAttr = [self createAttrWithString:self.content font:_pageConf.contentFont lineSpacing:_pageConf.contentLineSpacing paragraphSpacing:_pageConf.paragraphSpacing paragraphHeaderSpacing:_pageConf.paragraphHeaderSpacing];
    [titleAttr appendAttributedString:contentAttr];
    self.drawString = titleAttr;
    _needSetColor = YES;
}

-(NSMutableAttributedString *)createAttrWithString:(NSString *)string font:(UIFont *)font lineSpacing:(CGFloat)lineSpacing paragraphSpacing:(CGFloat)paragraphSpacing paragraphHeaderSpacing:(CGFloat)paragraphHeaderSpacing {
    
    NSMutableAttributedString * attr = [[NSMutableAttributedString alloc] initWithString:string];
    
    NSRange range = NSMakeRange(0, attr.length);
    ///设置字符串属性（字号、行间距）
    [attr addAttribute:NSFontAttributeName value:font range:range];
    NSMutableParagraphStyle * paraStyle = [[NSMutableParagraphStyle alloc] init];
    paraStyle.lineSpacing = lineSpacing;
    paraStyle.paragraphSpacing = paragraphSpacing;
    paraStyle.firstLineHeadIndent = paragraphHeaderSpacing;
    paraStyle.lineBreakMode = NSLineBreakByCharWrapping;
    [attr addAttribute:NSParagraphStyleAttributeName value:paraStyle range:range];
    
    return attr;
}

-(void)seperatePage {
    
    NSUInteger currentLoc = 0;
    ///当前手机以xs max做最大屏幕，14号字做最小字号，18像素为最小行间距，最大展示字数为564个字，取整估算为600字，为避免因数字较多在成的字形大小差距的影响，乘以1.2倍的安全余量，故当前安全阈值为720字
    NSUInteger totalLen = self.drawString.length;
    NSUInteger length = totalLen;
    CGSize renderSize = self.pageConf.renderFrame.size;
    DWReaderPageInfo * lastPageInfo = nil;
    DWReaderPageInfo * firstPageInfo = nil;
    NSMutableAttributedString * drawString = self.drawString;
    NSUInteger pageCount = 0;
    while (length > 0) {
        length = MIN(length, 720);
        
        ///截取一段字符串
        NSAttributedString * sub = [drawString attributedSubstringFromRange:NSMakeRange(currentLoc, length)];
        ///选定渲染区域
        NSRange range = [self calculateVisibleRangeWithString:sub renderSize:renderSize location:currentLoc];
        if (range.length == 0) {
            ///计算出错
            NSAssert(NO, @"DWReader can't calculate visible range,currentLoc = %lu,length = %lu,size = %@,sub = %@",currentLoc,length,NSStringFromCGSize(renderSize),sub.string);
            break;
        }
        
        ///配置分页信息
        DWReaderPageInfo * pageInfo = [DWReaderPageInfo pageInfoWithChapter:self];
        pageInfo.range = range;
        pageInfo.page = pageCount + 1;
        ///这里不直接用subStringFromRange是因为，实测偶尔会返回一个不可变字符串，具体原因未知。后续有人想知道问题或者想复现问题，请使用以下字符串生成一个可变字符串：
        
        ///@"暗夜亡灵\n付　强\n付强，北京大学物理系博士，从事科研工作多年，目前主攻绿色低碳管理。科幻迷、推理迷、动漫迷；自称死逻辑派、死理性派，却能被一首歌、一段剧情感动得稀里哗啦。发誓要将推理科幻进行到底。已出版科幻长篇《时间深渊》、中篇系列作品《孤独者游戏》。"
        pageInfo.pageContent = [[NSMutableAttributedString alloc] initWithAttributedString:[drawString attributedSubstringFromRange:range]];
        pageInfo.previousPageInfo = lastPageInfo;
        lastPageInfo.nextPageInfo = pageInfo;
        pageCount += 1;
        if (!firstPageInfo) {
            firstPageInfo = pageInfo;
        }
        lastPageInfo = pageInfo;
        
        ///更改currentLoc
        currentLoc = NSMaxRange(range);
        ///无需考虑当前位置恰好为一个换行符的情况，因为换行符横向不占空间，一定会计算到之前的段尾中，所以不存在currentLoc位置恰好为换行符的情况。直接计算剩余参与分页长度
        ///此处需要考虑另一件事，由于第二页是subString下来。所以第二页的开头几个字到另一个换行符之前会被误认为是一段。这里应该排除这种错误，可采用方案是第二页subString之前，检验之前一个符号是否是换行符，如果是换行符则说明subString的确是新的一段。如果不是换行符则不是新段，应将第一个字的段落属性中的段首间距至为0再计算第二页分页
    
        ///检查上一个字符是不是换行符，条件是这里不是第一页也不是最后一页
        if (currentLoc > 0 && currentLoc < totalLen) {
            ///如果上一页最后一个字符不是换行符则排除错误(不是第一页就不可能是标题，参数使用文章正文参数)
            if (![pageInfo.pageContent.string hasSuffix:@"\n"]) {
                NSMutableParagraphStyle * paraStyle = [[NSMutableParagraphStyle alloc] init];
                paraStyle.lineSpacing = _pageConf.contentLineSpacing;
                paraStyle.paragraphSpacing = _pageConf.paragraphSpacing;
                paraStyle.lineBreakMode = NSLineBreakByCharWrapping;
                [drawString addAttribute:NSParagraphStyleAttributeName value:paraStyle range:NSMakeRange(currentLoc, 1)];
            }
        }
        
        length = totalLen - currentLoc;
    }
    
    ///至此分页完成，事实上关于影响布局的富文本至此才配置完成，文字颜色要在配置画笔颜色时再改变
    [self reprocessChapterWithFirstPageInfo:firstPageInfo lastPageInfo:lastPageInfo totalPage:pageCount];
}

-(NSRange)calculateVisibleRangeWithString:(NSAttributedString *)string renderSize:(CGSize)size location:(NSUInteger)loc {
///由于直接利用CTFrameGetVisibleStringRange计算出的位置有时不是很准确，导致空白很大，故采取分析每行尺寸后自行判断可见范围，这种方式的好处在于，如果以后每页维护一个layouter的话，做选择或者批注的时候将有很强的扩展性。毕竟这部分内容在DWCoreTextLabel中我已经做过实现。
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef) string);
    UIBezierPath * bezierPath = [UIBezierPath bezierPathWithRect:(CGRect){CGPointZero,size}];
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), bezierPath.CGPath, NULL);
    DWReaderLayouter * layouter = [DWReaderLayouter layoutWithCTFrame:frame containerHeight:size.height];
    return NSMakeRange(loc, layouter.lines.lastObject.endIndex);
}

-(void)configAsyncParseStatus:(BOOL)parsing {
    _parsing = parsing;
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

#pragma mark --- setter/getter ---
-(void)setPageConf:(DWReaderRenderConfiguration * _Nonnull)pageConf {
    if (![_internalPageConf isEqual:pageConf]) {
        _pageConf = pageConf;
        _internalPageConf = [pageConf copy];
    }
}

@end



