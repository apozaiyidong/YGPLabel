# YGPLabel

使用 CoreText 框架 重写 UILabel，实现Label里面的文字能够点击。
当然是有做标识的文字。在Label中自动匹配文本中存在的手机号码、URL。
匹配成功会将其设为指定颜色。

YGPLabel *label = [[YGPLabel alloc]initWithFrame:CGRectZero];
label.YGPLabelDelegate = self;
