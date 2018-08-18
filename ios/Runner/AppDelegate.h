#import <UIKit/UIKit.h>
#import <Flutter/Flutter.h>

@interface AppDelegate : FlutterAppDelegate


@property(nonatomic, retain) FlutterBasicMessageChannel *msgChannel;

@property (nonatomic, strong) UINavigationController *navigationController;

@end

