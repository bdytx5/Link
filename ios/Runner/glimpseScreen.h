//
//  glimpseScreen.h
//  Runner
//
//  Created by Brett on 8/13/18.
//  Copyright © 2018 The Chromium Authors. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Flutter/Flutter.h>

@interface glimpseScreen : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>
@property (strong, nonatomic) FlutterResult flutterRes;
@property (strong, nonatomic) NSString *recip;
@property (strong, nonatomic) NSString *sender;
@property (strong, nonatomic) NSString *convoId;
@property (strong, nonatomic) NSString *imgURL;
@property (strong, nonatomic) NSString *fullName;

- (instancetype)initWithResult:(FlutterResult )result recipient:(NSString *)recip sender:(NSString *)sender convoId:(NSString *)convoId name:(NSString *)fullName imgURL:(NSString *)imgURL;


@end
