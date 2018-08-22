#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import <Flutter/Flutter.h>
#import "glimpseScreen.h"
#import "FbWebView.h"



static NSString *const CHANNEL_NAME = @"thumbsOutChannel";


//@interface AppDelegate()
//
//@property(nonatomic, retain) FlutterMethodChannel *channel;
//
//
//@end

@implementation AppDelegate

//+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
//    FlutterMethodChannel *channel =
//    [FlutterMethodChannel methodChannelWithName:CHANNEL_NAME
//                                binaryMessenger:[registrar messenger]];
//   AppDelegate *instance = [[AppDelegate alloc] init];
//        instance.channel = channel;
//    [registrar addMethodCallDelegate:self channel:channel];
//
//
//}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    // Override point for customization after application launch.
    

    
    FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;
    
    self.msgChannel = [FlutterBasicMessageChannel messageChannelWithName:@"notificationMsgChannel" binaryMessenger:controller];
    
    FlutterMethodChannel* settingsRedirect = [FlutterMethodChannel
                                              methodChannelWithName:@"thumbsOutChannel"
                                              binaryMessenger:controller];
    
    [settingsRedirect setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
        
        if ([@"goToSettings" isEqualToString:call.method]) {
            
            [self goToSettings];
        }
        
//        if ([@"snapchatLogin" isEqualToString:call.method]) {
//
//            [self loginToSnap:controller result:result];
//        }
//
//        if ([@"checkSnapchatLoginStatus" isEqualToString:call.method]) {
//
//            [self checkLoginStatus: result];
//        }
//        if ([@"getSnapId" isEqualToString:call.method]) {
//
//            [self getSnapId:result];
//        }
//        if ([@"logoutOfSnap" isEqualToString:call.method]) {
//
//            [self logoutOfSnap:result];
//        }
//        if ([@"snapGraph" isEqualToString:call.method]) {
//
//            [self snapGraph:controller result:result];
//        }
        if ([@"checkNotificationStatus" isEqualToString:call.method]) {
            
            [self checkNotificationStatus:result];
        }
        
        if ([@"showCamera" isEqualToString:call.method]) {
            glimpseScreen * vc = [[glimpseScreen alloc]initWithResult:result recipient:call.arguments[@"recip"] sender:call.arguments[@"sender"] convoId:call.arguments[@"convoId"] name:call.arguments[@"fullName"] imgURL:call.arguments[@"imgURL"]];
            
            [controller presentViewController:vc animated:NO completion:nil];
        }
        if ([@"showFb" isEqualToString:call.method]) {
            FbWebView * vc = [[FbWebView alloc]initWithURL:call.arguments[@"url"]];
            [controller presentViewController:vc animated:YES completion:nil];
        }
        
    }];
    
    
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

-(void) goToSettings{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

-(void) showGlimpseCamera{
    
//    glimpseScreen * vc = [[glimpseScreen alloc]init];
//    [self.window.rootViewController]

}

//-(void) loginToSnap:(FlutterViewController * )vc result:(FlutterResult)res {
//
//
//
//
//    [SCSDKLoginClient loginFromViewController:vc
//                                   completion:^(BOOL success, NSError * _Nullable error) {
//                                       // do something
//
//                                       if(!error){
//
//                                           [self snapGraph:vc result:res];
//
//                                       }else{
//                                           res([FlutterError errorWithCode:@"code 4" message:@"log in error" details:error.description]);
//                                       }
//                                   }];
//
//
//}
//
//
//-(void) snapGraph:(FlutterViewController * )vc result:(FlutterResult)res {
//
//    NSDictionary *variables = @{@"page": @"bitmoji"};
//    NSString *graphQLQuery = @"{me{displayName, bitmoji{avatar}, externalId}}";
//
//    [SCSDKLoginClient fetchUserDataWithQuery:graphQLQuery
//                                   variables:variables success:^(NSDictionary *resources) {
//                                       NSDictionary *data = resources[@"data"];
//                                       NSDictionary *me = data[@"me"];
//                                       NSString *displayName = me[@"displayName"];
//                                       NSString *externalId = me[@"externalId"];
//                                       NSDictionary *bitmoji = me[@"bitmoji"];
//                                       NSString *bitmojiAvatarUrl = bitmoji[@"avatar"];
//
//                                       if(me != nil){
//                                           if(bitmojiAvatarUrl != nil){
//                                               NSDictionary * info = @{@"url":bitmojiAvatarUrl, @"name":displayName, @"id":externalId};
//                                               res(info);
//                                           }else{
//                                               NSDictionary * info = @{ @"name":displayName, @"id":externalId};
//                                               res(info);
//
//                                           }
//
//                                       }else{ // sometimes it will be nil.. snapchat CS's arent that good imo
//                                           res([FlutterError errorWithCode:@"code 0"message:@"unknownError" details:@"no details"]);
//                                       }
//                                   } failure:^(NSError * error, BOOL isUserLoggedOut) {
//                                       // handle error as appropriate
//                                       if(isUserLoggedOut){
//                                           res([FlutterError errorWithCode:@"code 7" message: error.description details:@"graph Failed bc logged out"]);
//
//                                       }else{
//                                           res([FlutterError errorWithCode:@"code 3" message: error.description details:@"graph Failed"]);
//
//                                       }
//                                   }];
//
//}

//- (BOOL)application:(UIApplication *)application
//            openURL:(NSURL *)url
//            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
//{
//    BOOL handled = [SCSDKLoginClient application:application
//                                         openURL:url
//                                         options:options];
//    return true;
//}

//
//- (void) getSnapId:(FlutterResult)res{
//    NSDictionary *variables = @{@"page": @"bitmoji"};
//    NSString *graphQLQuery = @"{me{displayName, bitmoji{avatar}, externalId}}";
//
//    if([SCSDKLoginClient isUserLoggedIn]){
//        [SCSDKLoginClient fetchUserDataWithQuery:graphQLQuery
//                                       variables:variables success:^(NSDictionary *resources) {
//                                           NSDictionary *data = resources[@"data"];
//                                           NSDictionary *me = data[@"me"];
//                                           NSString *externalId = me[@"externalId"];
//
//                                           if(me != nil){
//                                               res(externalId);
//                                           }else{ // sometimes it will be nil.. snapchat CS's arent that good imo
//                                               //  res(@"error");
//                                               res([FlutterError errorWithCode:@"code 0"message:@"unknownError" details:@"no details"]);
//                                           }
//                                       } failure:^(NSError * error, BOOL isUserLoggedOut) {
//                                           // handle error as appropriate
//                                           res([FlutterError errorWithCode:@"code 1" message:@"graphIdFailed" details:error.description]);
//                                       }];
//
//    }else{
//        res([FlutterError errorWithCode:@"code 2" message:@"userIsNotLoggedIn" details:@"user needs to log in"]);
//
//    }
//
//
//}
//

//- (void) checkLoginStatus:(FlutterResult)res{
//    BOOL LoggedIn = [SCSDKLoginClient isUserLoggedIn];
//    if(LoggedIn){
//        res(@"true");
//    }else{
//        res(@"false");
//    }
//}


//-(void) logoutOfSnap:(FlutterResult)res{
//
//    [SCSDKLoginClient unlinkAllSessionsWithCompletion:^(BOOL success){
//        if(success){
//            res(@true);
//        }else{
//            res([FlutterError errorWithCode:@"code 6" message:@"unable to logout" details:@""]);
//        }
//    }];
//
//}


-(void) checkNotificationStatus:(FlutterResult)res{
    UIUserNotificationSettings *notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    
    if(notificationSettings.types != nil){
        res(@true);
    }else{
        res(@false);
    }
    
}




// GOOOGLE is using deprecated methods ....
- (void)application:(UIApplication *)application
didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings{
    
    if(notificationSettings.types != nil){
        // succesful
        [self.msgChannel sendMessage:@true];
    }else{
        [self.msgChannel sendMessage:@false];
    }
}



@end
