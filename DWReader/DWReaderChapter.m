//
//  DWReaderChapter.m
//  DWReader
//
//  Created by Wicky on 2019/2/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWReaderChapter.h"

#define kIndentLength (2)
#define kIndentString @"\t\t"
#define kLineBreakLength (1)
#define kLineBreakString @"\n"

@interface DWReaderChapter ()

@property (nonatomic ,strong) NSMutableString * parsedString;

@end

@implementation DWReaderChapter

#pragma mark --- interface method ---
+(instancetype)chapterWithOriginString:(NSString *)oriStr lineSpacing:(CGFloat)lineSpacing paragraphSpacing:(CGFloat)paragraphSpacing {
    return [[self alloc] initWithOriginString:oriStr lineSpacing:lineSpacing paragraphSpacing:paragraphSpacing];
}

-(instancetype)initWithOriginString:(NSString *)oriStr lineSpacing:(CGFloat)lineSpacing paragraphSpacing:(CGFloat)paragraphSpacing {
    if (self = [super init]) {
        _originString = oriStr;
        _lineSpacing = lineSpacing;
        _paragraphSpacing = paragraphSpacing;
        _content = nil;
        _title = nil;
        _paragraphs = nil;
        _parsedString = nil;
    }
    return self;
}

-(void)parseChapter {
    NSMutableString * content = [NSMutableString stringWithString:_originString];
    
    ///去除文本原有制表符，后续将以制表符做段首缩进
    [[[NSRegularExpression alloc] initWithPattern:@"\\t+" options:0 error:nil] replaceMatchesInString:content options:0 range:NSMakeRange(0, content.length) withTemplate:@""];
    
    ///开始分段，以'\n'作为分段信息，先替换多个连续'\n'为单个'\n'，防止原信息过多换行。在匹配当前换行符进行分段
    NSRegularExpression * reg = [[NSRegularExpression alloc] initWithPattern:@"\\n+" options:0 error:nil];
    
    ///替换单个换行符
    [reg replaceMatchesInString:content options:0 range:NSMakeRange(0, content.length) withTemplate:kLineBreakString];
    
    ///去除段首段尾的换行符
    if ([content hasPrefix:kLineBreakString]) {
        [content replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
    }
    if ([content hasSuffix:kLineBreakString]) {
        [content replaceCharactersInRange:NSMakeRange(content.length - 1, 1) withString:@""];
    }
    
    ///匹配段落
    NSArray <NSTextCheckingResult *>* results = [reg matchesInString:content options:0 range:NSMakeRange(0, content.length)];
    
    ///获取段落以后处理段首缩进及段落间距，现在文首添加一个缩进，之后在每个段落均添加缩进符，段尾不添加
    NSUInteger resultsCnt = results.count;
    NSMutableArray * paraTmp = [NSMutableArray arrayWithCapacity:resultsCnt + 1];
    __block NSUInteger loc = 0;
    __block NSUInteger lastLoc = 0;
    NSUInteger oriLen = content.length;
    [results enumerateObjectsUsingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ///插入缩进符，并创建段落信息（loc为上一个para的长度，len为匹配结果加一个缩进符的长度）
//        [content insertString:kIndentString atIndex:loc];
        [self seperateParagraphWithString:content loc:loc];
        DWReaderParagraph * para = [DWReaderParagraph new];
        para.range = NSMakeRange(loc, obj.range.location + kIndentLength + kLineBreakLength - lastLoc);
        [paraTmp addObject:para];
        lastLoc = obj.range.location + 1;
        loc = para.range.location + para.range.length;
    }];
    
    ///补充最后一段
//    [content insertString:kIndentString atIndex:loc];
    [self seperateParagraphWithString:content loc:loc];
    DWReaderParagraph * para = [DWReaderParagraph new];
    para.range = NSMakeRange(loc,oriLen + kIndentLength + kLineBreakLength - lastLoc);
    [paraTmp addObject:para];
    
    _paragraphs = [paraTmp copy];
    self.parsedString = content;
    
    NSLog(@"%@",paraTmp);
    NSLog(@"\n%@",self.parsedString);
}

#pragma mark --- tool method ---
-(void)seperateParagraphWithString:(NSMutableString *)str loc:(NSUInteger)loc {
    ///段首插入缩进符
    [str insertString:kIndentString atIndex:loc];
    ///如果不是首段，再插入一个换行符（这样段落之间既有两个连续的换行符，再在换行符中插入空白字符调整段落间距）
    if (loc != 0) {
        [str insertString:kLineBreakString atIndex:loc];
    }
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
