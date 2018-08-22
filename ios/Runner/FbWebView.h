//
//  FbWebView.h
//  Runner
//
//  Created by Brett on 8/21/18.
//  Copyright © 2018 The Chromium Authors. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FbWebView : UIViewController 
@property (strong, nonatomic) NSString *url;

- (instancetype)initWithURL:(NSString *)url;

@end
