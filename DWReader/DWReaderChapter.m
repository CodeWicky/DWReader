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
#define kHeaderLineBreakLength (1)
#define kSeperateParagraphString @"\n\n\t\t"
#define kSeperateParagraphLength (4)
#define kFooterLineBreakLength (1)

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
    
    
    ///替换换行符为分段符（\n\n\t\t，这么做是因为两个换行符间可插入空白字符调整段落间距，两个制表符可作为段首缩进。后期可调整段首缩进的字符串及长度，修改宏即可）
    [[[NSRegularExpression alloc] initWithPattern:@"\\n+" options:0 error:nil] replaceMatchesInString:content options:0 range:NSMakeRange(0, content.length) withTemplate:kSeperateParagraphString];
    
    ///去除段首段尾的分段符
    if ([content hasPrefix:kSeperateParagraphString]) {
        [content replaceCharactersInRange:NSMakeRange(0, kSeperateParagraphLength) withString:@""];
    }
    if ([content hasSuffix:kSeperateParagraphString]) {
        [content replaceCharactersInRange:NSMakeRange(content.length - kSeperateParagraphLength, kSeperateParagraphLength) withString:@""];
    }
    
    ///匹配段落
    NSArray <NSTextCheckingResult *>* results = [[[NSRegularExpression alloc] initWithPattern:kSeperateParagraphString options:0 error:nil] matchesInString:content options:0 range:NSMakeRange(0, content.length)];
    
    ///获取段落以后处理段首缩进及段落间距，由于之前去除了段首的分段符，所以现在首先应该给段首添加缩进
    [content insertString:kIndentString atIndex:0];
    
    ///然后计算段落信息
    NSUInteger resultsCnt = results.count;
    NSMutableArray * paraTmp = [NSMutableArray arrayWithCapacity:resultsCnt + 1];
    __block NSUInteger lastLoc = 0;
    [results enumerateObjectsUsingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ///计算段落信息，其中LastLoc表示计算本段落的起始位置，除了首次采取默认值0以外，其他均为seperateParagraph方法返回的位置，该方法返回的位置是包括给段首添加
        lastLoc = [self seperateParagraphWithString:content paras:paraTmp lastLoc:lastLoc nextLoc:obj.range.location + kIndentLength];
    }];
    
    ///补充最后一段
    [self seperateParagraphWithString:content paras:paraTmp lastLoc:lastLoc nextLoc:content.length];
    
    _paragraphs = [paraTmp copy];
    self.parsedString = content;
    
    NSLog(@"%@",paraTmp);
    NSLog(@"\n%@",self.parsedString);
}

#pragma mark --- tool method ---
-(NSUInteger)seperateParagraphWithString:(NSMutableString *)str paras:(NSMutableArray *)paras lastLoc:(NSUInteger)lastLoc nextLoc:(NSUInteger)nextLoc {
    
    DWReaderParagraph * para = [DWReaderParagraph new];
    para.range = NSMakeRange(lastLoc,nextLoc - lastLoc);
    [paras addObject:para];
    
    return para.range.location + para.range.length + kFooterLineBreakLength;
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
