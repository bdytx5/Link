import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'loginFlow/login_page.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:firebase_database/firebase_database.dart';
import 'globals.dart' as globals;

import 'homePage/home.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'loginFlow/selectSchool.dart';
import 'loginFlow/splash.dart';
import 'loginFlow/splashtwo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profilePages/profilePage.dart';
import 'loginFlow/imageResizer.dart';
import 'loginFlow/customizeProfile.dart';
import 'package:flutter/services.dart';
import 'profilePages/commentsPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: '',
      theme: new ThemeData(
      accentTextTheme: new TextTheme(
        body2: new TextStyle(
          color: Colors.blue,
        )
      ),
      textTheme: new TextTheme(
        subhead: new TextStyle(
          fontSize: 25.0,
        )
      ),
      primarySwatch: Colors.yellow,
      disabledColor: Colors.black,
      primaryTextTheme: new TextTheme(
        subhead: new TextStyle(
          fontSize: 50.0,
        ),
         display1: new TextStyle(
          fontSize: 50.0
        ),
      ),
    ),
    );
  }
}

// all globals (except for userInfo globals)

final RouteObserver<PageRoute> routeObserver = new RouteObserver<PageRoute>();
List<CameraDescription> cameras;


Future<void> main() async {

   const platform = const MethodChannel('thumbsOutChannel');
   Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
   bool goToSplashScreen = false;
   bool goToLoginScreen = false;
   bool goToHomeScreen= false;
   String id;
   final FirebaseApp app = await FirebaseApp.configure(
    
    name: 'mu-ridesharing',
    options: Platform.isIOS
        ? const FirebaseOptions(
            googleAppID: '1:297855924061:ios:c6de2b69b03a5be8',
            gcmSenderID: '509399610383',
            databaseURL: 'https://mu-ridesharing.firebaseio.com/',
          )
        : const FirebaseOptions(
            googleAppID: '1:509399610383:ios:ddde5590e35dc515',
            apiKey: 'AIzaSyAlJRV_uaKYXi4t9bdDlU55VI3jU9jtWUw',
            databaseURL: 'https://mu-ridesharing.firebaseio.com/',
          ),
  );

   final FirebaseAuth _auth = FirebaseAuth.instance;





   final SharedPreferences prefs = await _prefs;


// sign in ananymously with database !!
  // 1) first check the "opened" bool, if this is null, present the splash, otherwise
// 2) check login status, if its NOT logged in, present the login screen.
// 3) if the login status is true, make sure the 'loggedIn' pref bool is also set, then go to home
// 4) if 1 and 2 are both true, present the login screen also


// kind of complex... but necessary



  Future<bool> checkSnapLoginStatus()async{
    var userIsLoggedIn;
    try{
      userIsLoggedIn = await platform.invokeMethod("checkSnapchatLoginStatus");
    }catch(e){
      throw new Exception(e);
    }

    if(userIsLoggedIn == "true") {
      return true;
    }else{
      return false;
    }
  }

  bool checkIfUserHasOpened(){
    var firstOpen =  prefs.getBool("opened");
    if(firstOpen != null){
      return true;
    }else{
      return false;
    }
  }

  // the native function will throw an error if the user is not loggen in, thus returning false
  Future<bool> getSnapId()async{
    try{
      id = await platform.invokeMethod("getSnapId");
      return true;
    }catch(e){
      return false;
    }
  }






  Future<void> handleLogin()async{
    // 0) authenticate identitiy with database !
    await _auth.signInAnonymously();
    // 1) check opened bool, to see if the user has opened the app
    if(!checkIfUserHasOpened()){
      goToSplashScreen = true;
    }else{
      // 2) check if the user is NOT logged In!!
      var userIsLoggedIn = await checkSnapLoginStatus();
      if(!userIsLoggedIn){
        goToLoginScreen = true;
      }else{
        // 3) make sure that the "lastUser" is not null
        if(await getSnapId()){
        if(prefs.getString('lastUser') == id){
          goToHomeScreen = true;
        }else{
          // should never happen, but go to the login screen anyway...
          goToLoginScreen = true;
        }
        }

      }
    }
  }






await handleLogin();

  cameras = await availableCameras();

   runApp(new MaterialApp(
       // routes: routes,
     //   home: (prefs.getBool('signedUp') == null) ? new splashtwo(app: app,) : (isLoggedIn) ? new Home(app,currentAccessToken.userId) : new LoginPage(app: app),
     // home: (newUser)
     // new Home(app,currentAccessToken.userId) : new LoginPage(app: app),
  //  home: new splashtwo(app: app,),
  //  home: new cropImage(),
    // home: new HeroPage(),
    //home: new customizeProfile({}, {}),
    home: (goToHomeScreen) ? new Home(app, id,false) : (goToSplashScreen) ? new splashtwo(app: app) : new LoginPage(app: app),
   // home: customizeProfile({},{},app),
   //  home: ExpansionTileSample(),
    title: 'Flutter Database Example',
    navigatorObservers: [routeObserver],
    theme: new ThemeData(

      accentColor: Colors.yellowAccent,
      primaryTextTheme: new TextTheme(
        subhead: new TextStyle(
          fontSize: 50.0,

        ),
         display1: new TextStyle(
          fontSize: 50.0,
          color: Colors.red    
        ),
      ),
      primaryColorLight: Colors.yellowAccent,
      highlightColor: Colors.yellowAccent,
      accentTextTheme: new TextTheme(
        body2: new TextStyle(
          color: Colors.black
        ),
      )
    ),

  ));






















/// these functions handle the FB login status of the user (deprecated)

// final FacebookLogin userState = new FacebookLogin();
  //   bool newUser;
  //   bool loggedIn;
  //   bool oldDeviceNotSignedIn;

////////////////////////// FACEBOOK CODE ///////////////////////////////////////
//      bool isLoggedIn = await userState.isLoggedIn;
//     FacebookAccessToken currentAccessToken = await userState.currentAccessToken;
//    globals.fbLogin = globals.fbLogin = userState;
//      (isLoggedIn) ? globals.id = currentAccessToken.userId : null;
////////////////////////// FACEBOOK CODE ///////////////////////////////////////


//
//   Future<bool> checkSnapLoginStatus()async{
//     if(await platform.invokeMethod("checkSnapLoginStatus")) {
//       return true;
//     }else{
//       return false;
//     }
//   }
//
//
//   Future<bool> checkIfUserHasSignedUpOnDevice()async{
//   var firstOpen = await prefs.getBool("signedUp");
//   if(firstOpen != null){
//     return true;
//   }else{
//     return false;
//   }
//   }
//
//
//
//   Future<void> handleLoginStatus()async{
//     if(await checkSnapLoginStatus()){
//       loggedIn = true;
//       newUser = false;
//       oldDeviceNotSignedIn = false;
//     }else{
//       if(await checkIfUserHasSignedUpOnDevice()){
//         newUser = true;
//         loggedIn = false;
//         oldDeviceNotSignedIn = false;
//       }else{
//         newUser = false;
//         loggedIn = false;
//         oldDeviceNotSignedIn = false;
//       }
//
//     }
//   }

}




/// other snap code that was "deprecated"

//
//Future<void> handleLoginStatus()async{
//
//  if(prefs.getBool('signedUp') == null){
//    var opened =  checkIfUserHasOpened();
//    if(opened){
//      newUser = false;
//      loggedIn = false;
//      oldDeviceNotSignedIn = false;
//    }else{
//      newUser = true;
//      loggedIn = false;
//      oldDeviceNotSignedIn = false;
//    }
//
//  }else{
//    var res = await checkSnapLoginStatus();
//    if(res){
//      loggedIn = true;
//      newUser = false;
//      oldDeviceNotSignedIn = false;
//    }else{
//      loggedIn = false;
//      newUser = false;
//      oldDeviceNotSignedIn = true;
//    }
//  }
//
//}
//
//
//await handleLoginStatus();
////  globals.id = 'CAESIO1RccwK34OLN30OhSd6kcVqAGQ08Nbot4Qcw03dkV3m';
////  id = 'CAESIO1RccwK34OLN30OhSd6kcVqAGQ08Nbot4Qcw03dkV3m';
////  oldDeviceNotSignedIn = false;
////  newUser = false;
////  loggedIn = true;
//if(loggedIn){
//try{
//id = await getSnapId();
//globals.id = id;
//}catch(e){
//oldDeviceNotSignedIn = true;
//newUser = false;
//loggedIn = false;
//}
//}
//


///deprecated webview code
///
///
///
//
//var routes = <String, WidgetBuilder>{
//
//  LoginPage.routeName : (BuildContext context) => new LoginPage(app: app),
//  // Home.routeName : (BuildContext context) => new Home(app, ),
//
//  "/webview": (_) => new WebviewScaffold(
//    url: "https://www.facebook.com/brett.young.395",
//    appBar: new AppBar(
//      backgroundColor: Colors.yellowAccent,
//      title: new Text("Facebook", style: new TextStyle(color: Colors.black),),
//    ),
//  )
//};

