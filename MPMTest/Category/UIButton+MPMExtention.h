//
//  UIButton+MPMExtention.h
//  MPMAtendence
//
//  Created by gangneng shen on 2018/4/15.
//  Copyright © 2018年 gangneng shen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImage+MPMExtention.h"

@interface UIButton (MPMExtention)

/**
 *  根据给定的颜色，设置按钮的颜色
 *  @param btnSize  这里要求手动设置下生成图片的大小，防止coder使用第三方layout,没有设置大小
 *  @param clrs     渐变颜色的数组
 *  @param percent  渐变颜色的占比数组
 *  @param type     渐变色的类型
 */
- (UIButton *)gradientButtonWithSize:(CGSize)btnSize colorArray:(NSArray *)clrs percentageArray:(NSArray *)percent gradientType:(GradientType)type;

@end
