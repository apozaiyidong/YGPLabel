//
//  YGPLabel.h
//  GoChat
//
//  Created by mux on 14-9-17.
//  Copyright (c) 2014年 mux. All rights reserved.
//

#import <UIKit/UIKit.h>

static inline CGFloat YGPLabelFontSize (){
    
    return 15.f;
}

@protocol YGPLabelDelegate;

@interface YGPLabel : UILabel<UIGestureRecognizerDelegate>

/**
 *  装载 NSTextCheckingResult 数组
 */
@property (strong, nonatomic) NSMutableArray  *links;

- (void)setAttributedTextColor:(UIColor*)color;
+ (CGSize)getTextSize:(NSString *)text maxSize:(CGSize)size;


///-----------------------------
/// @name Accessing the Delegate
///-----------------------------

/**
 *  label 点击代理 点击 label 内存在link 就会调用此代码 此代理有几个方法
 *  (1) URL
 *  (2) PhoneNumber
 */
@property (assign, nonatomic) id<YGPLabelDelegate>YGPLabelDelegate;

- (void)reload;

@end

///-----------------------------
/// @name YGPLabelDelegate  可自行修改此处，合并Delegate回调。或用Block 2016/03
///-----------------------------

@protocol YGPLabelDelegate <NSObject>

///-----------------------------
/// @name YGPLabelDelegate
///-----------------------------

/**
 *  YGPLabelDelegate 当点击的文本出现URL链接时触发此方法
 *
 *  @param label YGPLabel
 *  @param url   获取点击的url
 */
-(void)YGPLabel:(YGPLabel*)label selectLinkWithURL:(NSURL*)url;

-(void)YGPLabel:(YGPLabel*)label selectPhoneNumberWithNumber:(NSString*)PhoneNumber;

@end