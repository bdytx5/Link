//
//  FbWebView.h
//  Runner
//
//  Created by Brett on 8/21/18.
//  Copyright © 2018 The Chromium Authors. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Flutter/Flutter.h>


@interface FbWebView : UIViewController 
@property (strong, nonatomic) NSString *url;
@property (strong, nonatomic) FlutterResult flutterRes;

- (instancetype)initWithURL:(NSString *)url Result:(FlutterResult )result;

@end
