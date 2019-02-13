//
//  DWReaderChapter.m
//  DWReader
//
//  Created by Wicky on 2019/2/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderChapter.h"
#import <CoreText/CoreText.h>

#define kIndentLength (2)
#define kIndentString @"\t\t"
#define kHeaderLineBreakLength (1)
#define kSeperateParagraphString @"\n\n\t\t"
#define kSeperateParagraphLength (4)
#define kFooterLineBreakLength (1)

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
@property (nonatomic ,strong) NSMutableString * parsedString;

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
        _title = nil;
        _paragraphs = nil;
        _parsedString = nil;
        _fontSize = MAXFLOAT;
        _lineSpacing = MAXFLOAT;
        _paragraphSpacing = MAXFLOAT;
    }
    return self;
}

-(void)parseChapter {
    NSMutableString * content = [NSMutableString stringWithString:_originString];
    
    ///去除文本原有制表符，后续将以制表符做段首缩进
    [[[NSRegularExpression alloc] initWithPattern:@"\\t+" options:0 error:nil] replaceMatchesInString:content options:0 range:NSMakeRange(0, content.length) withTemplate:@""];
    
    
    ///替换换行符为分段符（\n\n\t\t，这么做是因为两个换行符间可插入空白字符调整段落间距，两个制表符可作为段首缩进。后期可调整段首缩进的字符串及长度，修改宏即可）
    [[[NSRegularExpression alloc] initWithPattern:@"\\n+" options:0 error:nil] replaceMatchesInString:content options:0 range:NSMakeRange(0, content.length) withTemplate:kSeperateParagraphString];
    
    ///去除段首段尾的分段符
    if ([content hasPrefix:kSeperateParagraphString]) {
        [content replaceCharactersInRange:NSMakeRange(0, kSeperateParagraphLength) withString:@""];
    }
    if ([content hasSuffix:kSeperateParagraphString]) {
        [content replaceCharactersInRange:NSMakeRange(content.length - kSeperateParagraphLength, kSeperateParagraphLength) withString:@""];
    }
    
    ///获取段落以后处理段首缩进及段落间距，由于之前去除了段首的分段符，所以现在首先应该给段首添加缩进
    [content insertString:kIndentString atIndex:0];
    
    ///匹配段落
    NSArray <NSTextCheckingResult *>* results = [[[NSRegularExpression alloc] initWithPattern:kSeperateParagraphString options:0 error:nil] matchesInString:content options:0 range:NSMakeRange(0, content.length)];
    
    ///然后计算段落信息
    NSUInteger resultsCnt = results.count;
    NSMutableArray <DWReaderParagraph *>* paraTmp = [NSMutableArray arrayWithCapacity:resultsCnt + 1];
    __block NSUInteger lastLoc = 0;
    [results enumerateObjectsUsingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        lastLoc = [self seperateParagraphWithString:content paras:paraTmp lastLoc:lastLoc nextLoc:obj.range.location];
    }];
    
    ///补充最后一段
    [self seperateParagraphWithString:content paras:paraTmp lastLoc:lastLoc nextLoc:content.length];
    
    _paragraphs = [paraTmp copy];
    self.parsedString = content;
    
    NSLog(@"%@",paraTmp);
    NSLog(@"\n%@",self.parsedString);
    
    ///至此字符串已经完成分段，在正文内容不变的情况下，字符串可以保留，改变字号后重新计算分页即可
}

-(void)seperatePageWithFontSize:(CGFloat)fontSize lineSpacing:(CGFloat)lineSpacing paragraphSpacing:(CGFloat)paragraphSpacing {
    ///当任意一个影响分页的数据改变时才重新计算分页
    if (self.fontSize != fontSize || self.lineSpacing != lineSpacing || self.paragraphSpacing != paragraphSpacing) {
        
        ///赋值基础属性并清空之前的分页数据
        _fontSize = fontSize;
        _lineSpacing = lineSpacing;
        _paragraphSpacing = paragraphSpacing;
        _pages = nil;
        
        ///组装富文本
        [self configAttributeString];
        
        ///富文本组装完成后可以开始分页
    }
}

-(void)configTextColor:(UIColor *)textColor {
    if (![self.textColor isEqual:textColor]) {
        _textColor = textColor;
    }
}

#pragma mark --- tool method ---
-(NSUInteger)seperateParagraphWithString:(NSMutableString *)str paras:(NSMutableArray <DWReaderParagraph *>*)paras lastLoc:(NSUInteger)lastLoc nextLoc:(NSUInteger)nextLoc {
    
    ///计算段落信息，其中LastLoc表示计算本段落的起始位置，nextLoc表示结束位置。起始位置除手段从默认值0开始计算以外，其他均为上一段落结束位置后加一个结尾换行符的长度的位置。结束位置及每次匹配到的分段符的Location。（语言表述能力有限，实在想不明白建议画个图）
    DWReaderParagraph * para = [DWReaderParagraph new];
    para.range = NSMakeRange(lastLoc,nextLoc - lastLoc);
    
    ///如果这是第一段，改变标志位，标志首段，如果不是，将数组中最后一段的下一段置位本段
    if (paras.count != 0) {
        para.prevParagraph = paras.lastObject;
        paras.lastObject.nextParagraph = para;
    }
    
    para.index = paras.count;
    ///第0段和第1段不用修，因为第0段不插入空白符，第1段为第一个插入的空白符，故两段不用修range
    if (para.index < 2) {
        para.fixRange = para.range;
    } else {
        para.fixRange = NSMakeRange(para.range.location + para.index - 1, para.range.length);
    }
    
    [paras addObject:para];
    
    ///之所以要加一个结尾换行符长度是因为在结尾换行符后我们后续会添加空白字符来调整段落间距，事实上我们分段就是为了找这个位置及段首缩进。所以找到这个位置很重要
    return para.range.location + para.range.length + kFooterLineBreakLength;
}

-(void)configAttributeString {
    ///获取将要绘制的富文本，主要设置字号、行间距属性、添加空白字符
    self.drawString = nil;
    NSMutableAttributedString * draw = [[NSMutableAttributedString alloc] initWithString:self.parsedString];
    
    ///插入空白字符，调整段落间距
    DWReaderParagraph * para = self.paragraphs.firstObject.nextParagraph;
    while (para) {
        [self insertPlaceholderForDrawString:draw withParagraph:para];
        para = para.nextParagraph;
    }
    
    NSRange range = NSMakeRange(0, draw.length);
    ///设置字符串属性（字号、行间距）
    [draw addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:self.fontSize] range:range];
    NSMutableParagraphStyle * paraStyle = [[NSMutableParagraphStyle alloc] init];
    paraStyle.lineSpacing = self.lineSpacing;
    [draw addAttribute:NSParagraphStyleAttributeName value:paraStyle range:range];
    
    self.drawString = draw;
}

-(void)insertPlaceholderForDrawString:(NSMutableAttributedString *)draw withParagraph:(DWReaderParagraph *)para {
    if (para.fixRange.location > draw.length) {
        return;
    }
    
    NSDictionary * dic = @{@"size":[NSValue valueWithCGSize:CGSizeMake(self.renderSize.width, self.paragraphSpacing - 2 * self.lineSpacing)]};
    CTRunDelegateCallbacks callBacks;
    memset(&callBacks, 0, sizeof(CTRunDelegateCallbacks));
    callBacks.version = kCTRunDelegateVersion1;
    callBacks.getAscent = ascentCallBacks;
    callBacks.getDescent = descentCallBacks;
    callBacks.getWidth = widthCallBacks;
    CTRunDelegateRef delegate = CTRunDelegateCreate(& callBacks, (__bridge void *)dic);
    unichar placeHolder = 0xFFFC;
    NSString * placeHolderStr = [NSString stringWithCharacters:&placeHolder length:1];
    NSMutableAttributedString * placeHolderAttrStr = [[NSMutableAttributedString alloc] initWithString:placeHolderStr];
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)placeHolderAttrStr, CFRangeMake(0, 1), kCTRunDelegateAttributeName, delegate);
    CFSAFERELEASE(delegate);
    [draw insertAttributedString:placeHolderAttrStr atIndex:para.fixRange.location];
}

-(NSRange)calculateVisibleRangeWithString:(NSAttributedString *)string renderSize:(CGSize)size {
    return NSMakeRange(0, 0);
}

#pragma mark --- CoreText callback ---
static CGFloat ascentCallBacks(void * ref) {
    NSDictionary * dic = (__bridge NSDictionary *)ref;
    CGSize size = [dic[@"size"] CGSizeValue];
    return size.height;
}

static CGFloat descentCallBacks(void * ref) {
    return 0;
}

static CGFloat widthCallBacks(void * ref) {
    NSDictionary * dic = (__bridge NSDictionary *)ref;
    CGSize size = [dic[@"size"] CGSizeValue];
    return size.width;
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
    ///比较行间距
    if (((DWReaderChapter *)object).lineSpacing != self.lineSpacing) {
        return NO;
    }
    ///比较段落间距
    if (((DWReaderChapter *)object).paragraphSpacing != self.paragraphSpacing) {
        return NO;
    }
    return YES;
}

@end
