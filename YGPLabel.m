//
//  YGPLabel.m
//  GoChat
//
//  Created by mux on 14-9-17.
//  Copyright (c) 2014年 mux. All rights reserved.
//

#import "YGPLabel.h"
#import <CoreText/CoreText.h>

#define YGP_C_FONT_NAME "ArialMT"

typedef  NS_ENUM(NSInteger ,YGPLabelLinkType)
{
    KYGPLabelLinkURL    = 0,
    KYGPLabelLinkNumber = 1,
    
};

@implementation YGPLabel
{
    CTFrameRef                  _frame;
    CTFramesetterRef            _framesetter;
    NSMutableAttributedString   *_attributedString;
    UITapGestureRecognizer      *_tap;
    UIColor                     *_attributedTextColor;
    
}
@synthesize links;
@synthesize YGPLabelDelegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.links    = [[NSMutableArray alloc]init];
        
        [self setBackgroundColor:[UIColor clearColor]];
        [self setUserInteractionEnabled:YES];
        [self setNumberOfLines:0];
        [self setLineBreakMode:NSLineBreakByWordWrapping];
        self.textAlignment=  NSTextAlignmentCenter;
        
        _tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
        [_tap setDelegate:self];
        [self addGestureRecognizer:_tap];
        
//        self.font = [UIFont fontWithName:@"Arial" size:YGPLabelFontSize()];
    }
    return self;
}

- (NSMutableAttributedString*)setLink:(NSString*)string
{
    
    NSMutableArray * rangeArray = [YGPLabel getUrlWithString:string];
    
    NSMutableAttributedString * attributed = [[NSMutableAttributedString alloc]initWithString:string];
    
    //这是文本的颜色--右边为白色
    [attributed addAttribute:NSForegroundColorAttributeName
                       value:[self getAttributedTextColor]
                       range:NSMakeRange(0, string.length)];
    
    
    
    //获取URL，设置颜色
    for (NSTextCheckingResult * result in rangeArray)
    {
        [attributed addAttribute:NSForegroundColorAttributeName
                           value:[UIColor grayColor]
                           range:result.range];
        
        [attributed addAttribute:NSUnderlineStyleAttributeName value:(id)[NSNumber numberWithInt:kCTUnderlineStyleSingle] range:result.range];
        
        [self addLinkToRange:result.range Url:[NSURL URLWithString:[string substringWithRange:result.range]]];
        
    }
    
    //获取电话号码，设置颜色
    [rangeArray removeAllObjects];
    rangeArray = [YGPLabel getMobileNumWithString:string];
    
    for (NSTextCheckingResult * result in rangeArray)
    {
        [attributed addAttribute:NSForegroundColorAttributeName
                           value:[self getAttributedTextColor]
                           range:result.range];
        
        [attributed addAttribute:NSUnderlineStyleAttributeName value:(id)[NSNumber numberWithInt:kCTUnderlineStyleSingle] range:result.range];
        
        [self addPhoneNumToRange:result.range Num:[string substringWithRange:result.range]];
        
    }
    
    CTFontRef font = CTFontCreateWithName(CFSTR(YGP_C_FONT_NAME), YGPLabelFontSize(), NULL);
    
    [attributed addAttribute:(id)kCTFontAttributeName value:(__bridge id)font range:NSMakeRange(0, attributed.length)];
    
    CFRelease(font);
    [rangeArray removeAllObjects];
    
    return attributed;
    
}

/**
 *  添加url
 *
 *  @param range URL的范围
 *  @param url   URL
 */
- (void)addLinkToRange:(NSRange)range Url:(NSURL*)url
{
    [self.links addObject:[NSTextCheckingResult linkCheckingResultWithRange:range URL:url]];
}

/**
 *  添加电话号码
 *
 */
- (void)addPhoneNumToRange:(NSRange)range Num:(NSString*)phoneNum
{
    [self.links addObject:[NSTextCheckingResult phoneNumberCheckingResultWithRange:range phoneNumber:phoneNum]];
}


/**
 *  获取点击的内容
 *
 *  @param idx 点击的字索引
 */
- (NSTextCheckingResult*)checkingLinkTypeWithCilckInLocation:(CFIndex)idx
{
    if (self.links.count > 0)
    {
        for (NSTextCheckingResult * result in self.links)
        {
            NSRange range = result.range;
            if ((CFIndex)range.location <= idx && (CFIndex)range.length+(CFIndex)range.location >= idx)
                return result;
            else
                return NULL;
        }
        
    }else
        return NULL;
    
    return nil;
}

- (void)drawTextInRect:(CGRect)rect
{
    if (self.text.length > 0) {
        
        //绘制 text
        CGContextRef context = UIGraphicsGetCurrentContext();
        //设置context的ctm，用于适应core text的坐标体系
        CGContextSaveGState(context);
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        CGContextTranslateCTM(context, 0, rect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        _attributedString = [[NSMutableAttributedString alloc]initWithString:self.text];//提取内容创建框架
        
        _attributedString = [self setLink:self.text];
        
        
        _framesetter =  CTFramesetterCreateWithAttributedString((CFAttributedStringRef)_attributedString);//self.attributedText  千万不能直接使用 要用上面的文本来进行转换
        
        //绘制文本
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, rect.size.width, rect.size.height));
        
        //创建CTFrame
        _frame = CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, _attributedString.length), path, NULL);
        
        
        CTFrameDraw(_frame, context);
        CFRelease(path);
    
    }
    
}


/**
 *  根据点击的坐标位置获取点击文字的类型
 *
 *  @param point 点击位置
 *
 *  @return 获取文本信息
 */
- (NSTextCheckingResult*)getLinkWithPoint:(CGPoint)point
{
    CFArrayRef lines = CTFrameGetLines(_frame);
    CGPoint origins[CFArrayGetCount(lines)];
    
    
    //获取每行的原点坐标
    CTFrameGetLineOrigins(_frame, CFRangeMake(0, 0), origins);
    
    CTLineRef line = NULL;
    CGPoint lineOrigin = CGPointZero;
    for (int i= 0; i < CFArrayGetCount(lines); i++)
    {
        CGPoint origin = origins[i];
        CGPathRef path = CTFrameGetPath(_frame);
        //获取整个CTFrame的大小
        CGRect rect = CGPathGetBoundingBox(path);
        //坐标转换，把每行的原点坐标转换为uiview的坐标体系
        CGFloat y = rect.origin.y + rect.size.height - origin.y;
        //判断点击的位置处于那一行范围内
        if ((point.y <= y) && (point.x >= origin.x))
        {
            line = CFArrayGetValueAtIndex(lines, i);
            
            lineOrigin = origin;
            break;
        }
    }
    
    point.x -= lineOrigin.x;
    //获取点击位置所处的字符位置，就是相当于点击了第几个字符
    CFIndex index = CTLineGetStringIndexForPosition(line, point);
    
    return [self checkingLinkTypeWithCilckInLocation:index];
    
}

#pragma mark - UIGestureRecognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return [self getLinkWithPoint:[touch locationInView:self]] != nil;
}

- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    
    //获取触摸点击当前view的坐标位置
    NSTextCheckingResult * result =  [self getLinkWithPoint:[gestureRecognizer locationInView:self]];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        
        if (!result)
            return;
        
        switch (result.resultType)
        {
            case NSTextCheckingTypeLink:
                
                if ([self.YGPLabelDelegate respondsToSelector:@selector(YGPLabel:selectLinkWithURL:)])
                    [self.YGPLabelDelegate YGPLabel:self selectLinkWithURL:result.URL];
                
                break;
            case NSTextCheckingTypePhoneNumber:
                if ([YGPLabelDelegate respondsToSelector:@selector(YGPLabel:selectPhoneNumberWithNumber:)])
                    [YGPLabelDelegate YGPLabel:self selectPhoneNumberWithNumber:result.phoneNumber];
                break;
            default:
                break;
        }
    }
}

#pragma mark custome method

+ (CGSize )getTextSize:(NSString *)text maxSize:(CGSize)size{
    
    CTFontRef font = CTFontCreateWithName(CFSTR(YGP_C_FONT_NAME), YGPLabelFontSize(), NULL);
    
    NSMutableAttributedString * attributed = [[NSMutableAttributedString alloc]initWithString:text];
    [attributed addAttribute:(id)kCTFontAttributeName value:(__bridge id)font range:NSMakeRange(0, attributed.length)];
    
    CFRelease(font);
    
    CTFramesetterRef framesetter;
    framesetter =  CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributed);
    //self.attributedText  千万不能直接使用 要用上面的文本来进行转换
    //    CGSizeMake(SCREEN_WIDTH_YGPLABLE()-(SCREEN_WIDTH_YGPLABLE()/3), MAXFLOAT)
    
    CGSize totaiSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(size.width, size.height), NULL);
    
      
    return totaiSize;

    if (text.length > 0) {
        
        CTFontRef font = CTFontCreateWithName(CFSTR(YGP_C_FONT_NAME), YGPLabelFontSize(), NULL);
        
        NSMutableAttributedString * attributed = [[NSMutableAttributedString alloc]initWithString:text];
        [attributed addAttribute:(id)kCTFontAttributeName value:(__bridge id)font range:NSMakeRange(0, attributed.length)];
        
        CFRelease(font);
        
        CTFramesetterRef framesetter;
        framesetter =  CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributed);
        
        CGSize totaiSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(size.width, size.height), NULL);
        
        
        return totaiSize;
    }
    
    return CGSizeMake(0, 0);


}

- (void)reload{
    
    [self layoutIfNeeded];
}

- (void)setAttributedTextColor:(UIColor*)color{
    
    _attributedTextColor = color;
    
}

- (UIColor *)getAttributedTextColor{
    
    if (!_attributedTextColor) {
        return [UIColor blackColor];
    }
    
    return _attributedTextColor;
}

#pragma mark Regular
+ (NSMutableArray *)getUrlWithString:(NSString *)string
{
    NSMutableArray * newTotalArr = [[NSMutableArray alloc] init];
    NSError * error = nil;
    
    NSString *regulaStr = @"((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    NSArray *arrayOfAllMatches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    
    
    for (NSTextCheckingResult * match in arrayOfAllMatches) {
        [newTotalArr addObject:match];
    }
    
    return newTotalArr;
}

+ (NSMutableArray *)getMobileNumWithString:(NSString *)string
{
    NSMutableArray * newTotalArr = [[NSMutableArray alloc] init];
    
    NSArray * arrayOfAllMatches = nil;
    NSRegularExpression * regex = nil;
    NSError *error = nil;
    
    NSString *regulaStr4 = @"(((13[0-9])|(15([0-9]))|(18[0-9]))\\d{8})";
    regex = [NSRegularExpression regularExpressionWithPattern:regulaStr4 options:NSRegularExpressionCaseInsensitive error:&error];
    arrayOfAllMatches = [regex matchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length])];
    
    for (NSTextCheckingResult *match in arrayOfAllMatches) {
        [newTotalArr addObject:match];
    }
    
    return newTotalArr;
}


@end
