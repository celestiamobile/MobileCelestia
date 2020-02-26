//
//  UIViewController+Presentation.h
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/26.
//  Copyright © 2020 李林峰. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol UIViewControllerDismissDelegate <NSObject>

@optional
- (void)viewControllerWillDismiss:(UIViewController *)viewController;
- (void)viewControllerDidDismiss:(UIViewController *)viewController;

@end

@interface UIViewController (Presentation)

@property (nonatomic) id<UIViewControllerDismissDelegate> dismissDelegate;

@end

NS_ASSUME_NONNULL_END
