//
//  glimpseScreen.h
//  Runner
//
//  Created by Brett on 8/13/18.
//  Copyright © 2018 The Chromium Authors. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Flutter/Flutter.h>

@interface glimpseScreen : UIViewController
@property (strong, nonatomic) FlutterResult flutterRes;


- (instancetype)initWithResult:(FlutterResult )result;
@end
