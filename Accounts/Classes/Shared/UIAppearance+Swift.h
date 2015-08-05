//
//  UIAppearance+Swift.h
//  Accounts
//
//  Created by Alex Bechmann on 06/08/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIView (UIAppearance_Swift)
/// @param containers An array of Class<UIAppearanceContainer>
+ (instancetype)appearanceWhenContainedWithin: (NSArray *)containers;
@end