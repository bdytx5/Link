import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../loginFlow/login_page.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import '../main.dart';
import '../postSubmission/placepicker.dart';
import 'package:flutter/cupertino.dart';
import 'chatList.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../globals.dart' as globals;
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'feed.dart';
import 'feedStream.dart';
import '../notifications/notificationsPage.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io' as io;
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import '../Chat/msgScreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'feedStream.dart';
import 'dart:io';
import '../main.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:intl/intl.dart';
import 'package:latlong/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:secure_string/secure_string.dart';
import 'package:image_cropper/image_cropper.dart';
import '../loginFlow/notificationsSplash.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Home extends StatefulWidget{
  

  static const String routeName = "home";

  _homeState createState() => new _homeState();


    FirebaseApp app;
    final String userID;
    final bool newLogin;
    Home(this.app,this.userID,this.newLogin );

}

class _homeState extends State<Home> with SingleTickerProviderStateMixin{
final originTextContoller = new TextEditingController();
static const platform = const MethodChannel('thumbsOutChannel');
static const MethodChannel _Channel = const MethodChannel('thumbsOutChannel');
static const BasicMessageChannel _chan = const BasicMessageChannel('notificationMsgChannel', StandardMessageCodec());

String logoURL = "https://is4-ssl.mzstatic.com/image/thumb/Purple125/v4/b2/a7/91/b2a7916a-35be-5a7e-4c91-45317fb40d9c/AppIcon-1x_U007emarketing-0-0-GLES2_U002c0-512MB-sRGB-0-0-0-85-220-0-0-0-3.png/246x0w.jpg";

final destinationTextContoller = new TextEditingController();
    Map data = {};
    TabController _tabController;
    final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
    bool commentNotificationReciepts = false;
    bool rideNotificationReciepts = false;
    bool messageNotification = false;
    io.File _image;
    bool bitmojiLoading = false;
    String transportMode;
    LatLng destination;
    SecureString secureString = new SecureString();

Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
final keyboardDismissalChangeNotifier = new StreamController.broadcast(); // for communicating down the widget tree to dismiss the keyboard

FirebaseMessaging _firMes = new FirebaseMessaging();
//FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  static bool askedToAllowNotifications = false;


  // notification logic is somwhat complicated...
  // basically we set a _pref bool to see once the user agrees/disagrees to notificaitons (true/false)
  // if it is, then we can set the bool to true
  // if its false, we can redirect the user to settings

   void initState() {
    super.initState();
  //  migrateData();
    globals.id = widget.userID;
    updateCityCode(widget.userID).then((idk){
      // need cityCode for these two functions
      fetchTransportModeAndRiderOrDriver();
      grabUsersImgAndFullName();
    });
    configureCloudMessaging();
    handleNotificationsRequest();
    updateLastUserPersistentStorage(widget.userID);
    _tabController = new TabController(vsync: this, initialIndex: 1, length: 2);
    _tabController.addListener(_tabIndexChanged);
    fetchNotificationCommentStatuses(); // attatch a listener to the comment notifications node
    fetchRideNotificationStatuses();// attatch a listener to the ride notifications node
    fetchNotificationMessageStatuses(); // attach a listener to the message notifications node
    getToken();
    if(Platform.isIOS){
       handleNotifications();
    }
   }

  void handleNotifications() async {
    final SharedPreferences prefs = await _prefs;
    var permissions = await platform.invokeMethod("checkNotificationStatus");
    (!askedToAllowNotifications && prefs.getBool('requestedNotifications') == null && permissions != 1) ? new Future.delayed(

        const Duration(milliseconds: 1000)).then((idk) {
      askedToAllowNotifications = true;
      Navigator.push(context, new MaterialPageRoute(builder: (context) => new NotificationsSplash())).then((res){
        if(res != null){
          if(res){
            platform.invokeMethod("goToSettings");
          }
        }
      });

    }
    ) : null;
  }

  Future<void> handleNotificationsForSideMenu()async{

    final prefs = await _prefs;
    var notificationResult = prefs.getBool('notifications');
    if(notificationResult == null){
      // show menu to ask for access
      var res = await _warningMenu("Allow Notifications?", "Would you like to allow notifications?", '');
      if(res) {
        // request access to notifications
        _firMes.requestNotificationPermissions(const IosNotificationSettings(sound: true, badge: true, alert: true));
      }
    }else{
      var permissions = await platform.invokeMethod("checkNotificationStatus");
      if(permissions  == 1){
        // tell the user that notifications are enabled
        _warningMenu("Notifications are Enabled", "They can be turned off in settings", '');
      }else{
        // tell the user that notifications are not enabled, and that they need to go to settings
        var res = await  _warningMenu("Notifications are Disabled", "Click okay to be redirected to notification settings", '');
        if(res){
          platform.invokeMethod("goToSettings");
        }
      }
    }
  }

//  void createSnackBar() async{
//    final SharedPreferences prefs = await _prefs;
//
//    final snackBar = new SnackBar(content: new Row(
//      children: <Widget>[
//        new Expanded(child:  new Text('Allow Message Notifcations'),),
//        new Padding(padding: new EdgeInsets.all(5.0),
//          child: new MaterialButton(
//            onPressed: () {
//              prefs.setBool('requestedNotifications', true);
//              _scaffoldKey.currentState.removeCurrentSnackBar();
//              _firMes.requestNotificationPermissions(const IosNotificationSettings(sound: true, badge: true, alert: true));
//            },
//            child: new Text(
//              'TURN ON', style: new TextStyle(color: Colors.black),),
//            color: Colors.yellowAccent,
//          ),
//        )
//
//      ],
//    ),
//        backgroundColor: Colors.grey[800], duration: new Duration(seconds: 10));
//    // Find the Scaffold in the Widget tree and use it to show a SnackBar
//    if(context != null){
//      Scaffold.of(context).showSnackBar(snackBar);
//    }
//  }

   void configureCloudMessaging(){
     _firMes.configure(

       onMessage: (Map<String, dynamic> message) {
         print(message);
         //  _showNotification();
       },
       onLaunch: (Map<String, dynamic> message) {
         print(message);
       },
       onResume: (Map<String, dynamic> message) {
         print(message);
//        var aps = message['aps'];
//        var alert = aps['alert'];
//        var body = alert['body'];

       },

     );
   }


   void getToken()async{
     if(widget.newLogin){
     _firMes.getToken().then((token){
       print(token);
       var ref = FirebaseDatabase.instance.reference();
      ref.child('tokens').child(globals.id).set({'token':token});

    }).catchError((err){

      print(err);
     });

     }
   }




   void handleNotificationsRequest() async {
     _chan.setMessageHandler((msg)async{
       if(msg == 1){
         final prefs = await _prefs;
         prefs.setBool('notifications', true);
       }else{
         final prefs = await _prefs;
         prefs.setBool('notifications', false);
         var res = await _warningMenu('Error', "In order to allow notifications, we can redirect you to settings", '');
         if(res){
           // go to settings
           platform.invokeMethod("goToSettings");
         }
       }
     });
   }
   
  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree


   super.dispose();
   
  }
 

    @override
  Widget build(BuildContext context) {
    return new Scaffold(

      drawer: menuDrawer(),
      key: _scaffoldKey,
      appBar: new AppBar(
        backgroundColor: Colors.yellowAccent,
        leading:new Container(
          child:  new Stack(
            children: <Widget>[
              new Center(
                child: new IconButton(icon: new Icon(Icons.menu, color: Colors.black), onPressed: () async{
                  await grabUsersImgAndFullName();
                 _scaffoldKey.currentState.openDrawer();

                }),
              ),
      (commentNotificationReciepts || rideNotificationReciepts) ?  new Align(
                alignment: new Alignment(0.35, -0.30),
                child:new Container(
                  height: 8.0,
                  width: 8.0,
                  decoration: new BoxDecoration(shape: BoxShape.circle, color: Colors.red,),
                ),
              ):new Container(),


            ],
          ),
        ),
        iconTheme: new IconThemeData(
          color: Colors.black
        ),
   
        title: new Text('Columbia, MO', style: new TextStyle(color: Colors.black),),
        elevation: 0.7,
          bottom: new TabBar(
        controller: _tabController,
        indicatorColor: Colors.black,
        tabs: <Widget>[
          new Tab(child: new Stack(
            children: <Widget>[
              new Center(
                child:   new Icon(Icons.chat, color: Colors.black,),
              ),
              (messageNotification) ?  new Align(
                alignment: new Alignment(0.1, -0.4),
                child:new Container(
                  height: 8.0,
                  width: 8.0,
                  decoration: new BoxDecoration(shape: BoxShape.circle, color: Colors.red,),
                ),
              ):new Container(),


            ],
          ),),
          new Tab(icon: new Icon(Icons.home,color: Colors.black,),),
        ],
      ),
      ),
      body: new TabBarView(
        controller: _tabController,
        children: <Widget>[
          new ChatList(stream: keyboardDismissalChangeNotifier.stream,updateChatListCallback: (){
            setState(() {

            });
          },),
      (transportMode != null && destination != null ) ?  new Feed(app: widget.app,userID: widget.userID, commentNotificationCallback:_commentNotificationCallback,keyboardDismissalStreamController: keyboardDismissalChangeNotifier, destination: destination,transportMode: transportMode) : new Container(
        child: new Center(
          child: new CircularProgressIndicator()
        )
      ),

        ],
      ),
    );


  }


  Widget menuDrawer(){
     return new Drawer(
         child: new Container(
           color: Color.fromRGBO(55, 60, 66, 1.0),
           child: ListView(
             children: <Widget>[
              new Center(
                child:Padding(padding: new EdgeInsets.only(top: 50.0, bottom: 20.0),
                child: new Column(
                  children: <Widget>[
                    new Stack(
                      children: <Widget>[
                        new Container(
                          color: Colors.transparent,
                          height: 90.0,
                          width: 90.0,
                          child: new InkWell(
                            child: (globals.imgURL != null ) ? new CircleAvatar(radius: 25.0,backgroundColor: Colors.transparent,backgroundImage: new NetworkImage((globals.imgURL != null) ? globals.imgURL : logoURL),
                                child: new Center(
                                  child: (bitmojiLoading) ? new Container(
                                    height: 25.0,
                                    width: 25.0,
                                    child: CircularProgressIndicator(),
                                  ) : new Container(),
                                )
                            ) : new Center(
                              child:CircularProgressIndicator() ,
                            ),
                            onTap: ()async{
                                changeProfilePic();
                            },
                          )

                        ),
                        new Positioned(child:  new IconButton(icon: new Icon(Icons.edit,color: Colors.white,), onPressed: ()async{
                          // change bitmoji




                        },iconSize: 10.0,),
                            top:60.0,
                            left: 60.0
                        )

                      ],

                    ),

                    new Padding(padding: new EdgeInsets.all(10.0),

                    child: new Text((globals.fullName != null) ? globals.fullName : '',style: new TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                    )
                  ],
                ),
                )
              ),
               new Card(
                 child:  new ListTile(
                   leading: new Icon(Icons.notifications),
                   title: new Row(
                        children: <Widget>[

                      new Text('Notifications'),
                   (rideNotificationReciepts || commentNotificationReciepts) ? new Padding(padding: new EdgeInsets.all(3.0),
                              child: new Container(
                              height: 8.0,
                               width: 8.0,
                              decoration: new BoxDecoration(shape: BoxShape.circle, color: Colors.red,),
                          ),
                        ) : new Container(),
                        ],
                   ),

    onTap: (){
    Navigator.push(context, new MaterialPageRoute(builder: (context) => new NotificationPage(_generalNotificationCallback)));
    },

                 ),
               ),


              new Card(
                child: new ListTile(
                  title: new Text('Terms of Service'),
                  leading: new Icon(Icons.assignment),
                  onTap: (){
                    // showNotificationsSettingsMenu();
                    Navigator.push(context, new MaterialPageRoute(builder: (context) => new WebviewScaffold(
                        url: 'https://bdytx5.github.io/termsOfService/',
                        appBar: new AppBar(
                          iconTheme: new IconThemeData(color: Colors.black),

                          backgroundColor: Colors.yellowAccent,
                            title: new Text("Terms of Service", style: new TextStyle(color: Colors.black),
                            
                            ),
                          actions: <Widget>[
                            new Icon(Icons.clear)
                          ],
                        ))));                  },
                ),
              ),

              (Theme.of(context).platform == TargetPlatform.iOS ) ?  new Card(
                child: new ListTile(
                  title: new Text('Notification Settings'),
                  leading: new Icon(Icons.settings),
                  onTap: ()async{
                    handleNotificationsForSideMenu();
                  },
                ),
              ) : new Container(),
              new Card(
                child:  new ListTile(
                  leading: new Icon(Icons.launch),
                  title: new Text('logout'),

                  onTap: ()async{
                    bool res = await _warningMenu('Logout?', 'Are you sure you want to logout of Link?', '');

                    if(res){
                      try{
                        final FacebookLogin facebookSignIn = new FacebookLogin();

                          await facebookSignIn.logOut();
                          var ref = FirebaseDatabase.instance.reference();
                          await ref.child('tokens').child(globals.id).remove();
                          globals.id = null;
                          globals.cityCode = null;
                          globals.name = null;
                          globals.fullName = null;
                          Navigator.pushReplacement(context , new MaterialPageRoute(builder: (context) => new LoginPage(app: widget.app)));

                      }catch(e){

                        _errorMenu('Unable to Logout', 'Please try again later', '');

                      }
                    }

                  },
                ),
              ),




             ],
           ),
         )
     );
  }


//  Future<void> handleNotifications()async{
//
//    final prefs = await _prefs;
//    var notificationResult = prefs.getBool('notifications');
//    if(notificationResult == null){
//      // show menu to ask for access
//      var res = await _warningMenu("Allow Notifications?", "Would you like to allow notifications?", '');
//      if(res) {
//        // request access to notifications
//        _firMes.requestNotificationPermissions(const IosNotificationSettings(sound: true, badge: true, alert: true));
//      }
//    }else{
//      var permissions = await platform.invokeMethod("checkNotificationStatus");
//      if(permissions  == 1){
//        // tell the user that notifications are enabled
//        _warningMenu("Notifications are Enabled", "They can be turned off in settings", '');
//      }else{
//        // tell the user that notifications are not enabled, and that they need to go to settings
//      var res = await  _warningMenu("Notifications are Disabled", "Click okay to be redirected to notification settings", '');
//      if(res){
//        platform.invokeMethod("goToSettings");
//      }
//      }
//    }
//  }
//


  Future<void> changeProfilePic()async{

     try{
       File newPic = await _pickImage();
       var croppedImg;
       if(newPic != null){
         croppedImg = await _cropImage(newPic);
       }else{
         return;
       }

       if(newPic != null){
         // File resizeImg = await FlutterNativeImage.compressImage(newPic.path, quality: 100,targetHeight: 200,targetWidth: 200);
         String profilePicURL = await uploadPhoto(croppedImg, globals.id);
         DatabaseReference ref = FirebaseDatabase.instance.reference();
         await ref.child(globals.cityCode).child('posts').child(globals.id).update({'imgURL':profilePicURL});
         await ref.child(globals.cityCode).child('userInfo').child(globals.id).update({'imgURL':profilePicURL});
         await ref.child('usersCities').child(globals.id).update({'imgURL':profilePicURL});
       }
     }catch(e){
       return;
     }

  }

  Future<File> _pickImage() async {

    var imageFile = await  ImagePicker.pickImage(source: ImageSource.gallery);
    return imageFile;
  }




  Future<String> uploadPhoto(File img, String id) async {

    try{
      final StorageReference ref = await FirebaseStorage.instance.ref().child("profilePics").child(id).child(secureString.generate(length: 10,charList: ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s']));
      final dataRes = await ref.putData(img.readAsBytesSync());
      final dwldUrl = await dataRes.future;
      setState(() {
        globals.imgURL = dwldUrl.downloadUrl.toString();
      });
      return dwldUrl.downloadUrl.toString();

    }catch(e){
      print(e);
      throw new Exception(e);
    }

  }





void grabUsersImgAndFullName()async{

  FirebaseDatabase database = FirebaseDatabase.instance;
     if(globals.fullName != null && globals.imgURL != null){
       return;
     }
     print(globals.cityCode);
     print(globals.id);
  DataSnapshot snapshot = await database.reference().child(globals.cityCode).child('userInfo').child(globals.id).once();

  setState(() {
    globals.imgURL = snapshot.value['imgURL'];
    globals.fullName = snapshot.value['fullName'];
  });
}




  void fetchTransportModeAndRiderOrDriver()async {
    FirebaseDatabase database = FirebaseDatabase.instance;
     database.reference().child(globals.cityCode).child('posts').child(globals.id).onValue.listen((data)async{
      setState(() {
        if(data.snapshot.value != null ){
          setState(() {
            Map coordinates = data.snapshot.value['coordinates'];
            destination = new LatLng(double.parse(coordinates['lat']), double.parse(coordinates['lon']));
            transportMode = data.snapshot.value['riderOrDriver'];
          });
        }
      });
    });

  }


void fetchNotificationCommentStatuses()async {
  FirebaseDatabase database = FirebaseDatabase.instance;
  database.reference().child('commentNotificationReciepts').child(globals.id).onValue.listen((data)async{

    DataSnapshot rideNotificationSnap = await database.reference().child('rideNotificationReciepts').child(globals.id).child('newAlert').once(); // if the user has either a ride notification or a comment notification
    if(rideNotificationSnap.value == null || data.snapshot.value == null){
      return;
    }

      setState(() {
        if(data.snapshot.value == null ){
          if(rideNotificationSnap.value){
            rideNotificationReciepts = true;
          }
          return;
        }


        if(data.snapshot.value['newAlert']) {
          commentNotificationReciepts = true; // set the flag!
        }else{
          commentNotificationReciepts = false; // now need to make sure there are no ride notifications!!
          if(rideNotificationSnap.value != null){
            if(rideNotificationSnap.value){
                rideNotificationReciepts = true;
            }
          }
        }
      });
  });
}

void fetchRideNotificationStatuses()async {
  FirebaseDatabase database = FirebaseDatabase.instance;
  database.reference().child('rideNotificationReciepts').child(globals.id).onValue.listen((data)async{

    DataSnapshot commentNotificationSnap = await database.reference().child('commentNotificationReciepts').child(globals.id).child('newAlert').once(); // if the user has either a ride notification or a comment notification
    if(commentNotificationSnap.value == null || data.snapshot.value == null){
      return;
    }
   if(mounted){
     setState(() {
       if(data.snapshot.value == null){
         if(commentNotificationSnap.value){
           commentNotificationReciepts = true;
         }
         return;
       }


       if(data.snapshot.value['newAlert']) {
         rideNotificationReciepts = true; // set the flag!
       }else{
         rideNotificationReciepts = false; // now need to make sure there are no ride notifications!!
         if(commentNotificationSnap.value != null){
           if(commentNotificationSnap.value){
             commentNotificationReciepts = true;
           }
         }
       }
     });
   }else{
     if(data.snapshot.value == null){
       if(commentNotificationSnap.value){
         commentNotificationReciepts = true;
       }
       return;
     }


     if(data.snapshot.value['newAlert']) {
       rideNotificationReciepts = true; // set the flag!
     }else{
       rideNotificationReciepts = false; // now need to make sure there are no ride notifications!!
       if(commentNotificationSnap.value != null){
         if(commentNotificationSnap.value){
           commentNotificationReciepts = true;
         }
       }
     }


   }
  });
}



  void fetchNotificationMessageStatuses()async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    database.reference().child('messageNotificationReciepts').child(globals.id).child('newAlert').onValue.listen((data) async {

      if(data.snapshot.value == null){
        return;
      }
      if(mounted){
        setState(() {
          if (data.snapshot.value) {
            if(_tabController.index == 0){
              database.reference().child('messageNotificationReciepts').child(globals.id).update({'newAlert':false});
            }else{
              messageNotification = true;
            }
          }else{
            messageNotification = false;
          }
        });
      }else{
        if (data.snapshot.value) {
          if(_tabController.index == 0){
            database.reference().child('messageNotificationReciepts').child(globals.id).update({'newAlert':false});
          }else{
            messageNotification = true;
          }
        }else{
          messageNotification = false;
        }
      }
    });
  }



Future<void> updateCityCode(String id) async {

  FirebaseDatabase database = FirebaseDatabase.instance;
  database.setPersistenceEnabled(true);
  final snap = await database.reference().child('usersCities').child(id).child('cityCode').once();
/// need city code, id, full name, home city
    setState(() {
      globals.cityCode = snap.value;
    });


}

void updateLastUserPersistentStorage(String id)async{
  var prefs = await _prefs;
  var lastUser = prefs.getString('lastUser');
  if(lastUser != globals.id){
    var ref = FirebaseDatabase.instance.reference();
    // need to make sure that the old user does not have the same cloud token as the last user !t
    prefs.setString('lastUser', id);
    try{
      DataSnapshot snap = await ref.child('tokens').child(lastUser).child('token').once();
      if(snap.value == await getMyCloudToken()){
        ref.child('tokens').child(lastUser).child('token').remove();
      }
    }catch(e){

    }
  }
}

Future<String> getMyCloudToken()async{
     var token = await _firMes.getToken();
     return token;
}



void _commentNotificationCallback(){
     if(commentNotificationReciepts){
       FirebaseDatabase database = FirebaseDatabase.instance;
       database.reference().child('commentNotificationReciepts').child(globals.id).update({'newAlert':false});
     }
}


void _generalNotificationCallback(){
     // sets the both the comments and the ride notifications to false!
  FirebaseDatabase database = FirebaseDatabase.instance;
  if(rideNotificationReciepts){
    database.reference().child('rideNotificationReciepts').child(globals.id).update({'newAlert':false});
  }
  if(commentNotificationReciepts){
    database.reference().child('commentNotificationReciepts').child(globals.id).update({'newAlert':false});

  }
}

void _messageNotificationCallback(){
  FirebaseDatabase database = FirebaseDatabase.instance;
  if(messageNotification){
    database.reference().child('messageNotificationReciepts').child(globals.id).update({'newAlert':false});
  }
}

void _tabIndexChanged(){

  keyboardDismissalChangeNotifier.sink.add(null);

     if(_tabController.index == 0){
       _messageNotificationCallback();
     }
}



Widget showNotificationsSettingsMenu(){

    return new SimpleDialog(
      children: <Widget>[

        new MaterialButton(
            onPressed: (){

          platform.invokeMethod('snapchatLogin').then((info){

          });
        },
          color: Colors.yellowAccent,

        )

      ],
    );

}



Future<Null> _errorMenu(String title, String primaryMsg, String secondaryMsg) async {
  return showDialog<Null>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return new AlertDialog(
        title: new Text(title),
        content: new SingleChildScrollView(
          child: new ListBody(
            children: <Widget>[
              new Text(primaryMsg),
              new Text(secondaryMsg),
            ],
          ),
        ),
        actions: <Widget>[
          new FlatButton(
            child: new Text('Okay', style: new TextStyle(color: Colors.black),),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


  Future<bool> _warningMenu(String title, String primaryMsg, String secondaryMsg) async {
    var decision = await showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text(title),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text(primaryMsg),
                new Text(secondaryMsg),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Okay', style: new TextStyle(color: Colors.black),),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            new FlatButton(
              child: new Text('Cancel', style: new TextStyle(color: Colors.black),),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );

    return decision;
  }








  Future<File> _cropImage(File imageFile) async {
    File croppedFile = await ImageCropper.cropImage(
      sourcePath: imageFile.path,
      ratioX: 1.0,
      ratioY: 1.0,
      maxWidth: 200,
      maxHeight: 200,
    );

    return croppedFile;
  }










  // for data migration purposes ....



  Future<void>migrateData()async{
     // post

    var ref = FirebaseDatabase.instance.reference();




    String id = "834834113343750";
     Map coordinates = {"lat":"40.0410509","lon":"-94.8214312"};
     String Destination = "Rosendale";
     bool fromHome = true;
     String imgURL = "https://s8.postimg.cc/7jr3stzn9/Screen_Shot_2018-08-10_at_8.42.17_PM.png";
     String key = '-LJ_EnyQaQa3MA7RcEAx';
     String leaveDate = '2018-08-8 02:10:26 PM';
     String name = 'Brody';
     String riderOrDriver = 'Driving';
     String state = 'MO';
     String time = '2018-08-10 01:00:26 PM';
     String fullName = "Brody Bauman";
     String bio = '';
     String fbLink = 'https://www.facebook.com/brody.bauman.1';

    Map coverPhoto = {'imgURL':'https://s8.postimg.cc/8m1abaxv9/Screen_Shot_2018-08-10_at_8.41.20_PM.png'};

    Map gradYear = {'gradYear':"2020"};


    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var now = formatter.format(new DateTime.now());
    Map message = {'to':globals.id,'from':'Link','message':"Thanks for joinng Link! We would love to hear your thoughts on how we can improve the app!", 'formattedTime':now};
    ref.child('feedback').child(id).push().set(message);



     // citycode/id/posts -> set post
     Map post = {
       'coordinates':coordinates,
       'fromHome':fromHome,
       'imgURL':imgURL,
       'key':key,
       'leaveDate':leaveDate,
       'name':name,
       'riderOrDriver':riderOrDriver,
       'state':state,
       'time':time,
       'destination':Destination
     };

   await ref.child('Columbia-MO').child('posts').child(id).set(post);



     // citycode/userInfo /id-> set post
     Map userInfo = {
      'fullName':fullName,
      'imgURL':imgURL
    };
    await ref.child('Columbia-MO').child('userInfo').child(id).set(userInfo);




    // bios /id -> set
    Map bioMap = {
      'bio':bio
    };

    await ref.child('bios').child(id).set(bioMap);




    // set comment notification false
     Map alertTrue = {'newAlert': true};
     Map alertFalse = {'newAlert': false};

    await ref.child('commentNotificationReciepts').child(id).set(alertFalse);




     Map feedbackConvoInfo = {
       'convoID':id,
       'formattedTime':'2018-08-10 02:10:26 PM',
       'imgURL':'https://s8.postimg.cc/g46nesl3p/Icon-_App-60x60_2x-1.png',
       'new':false,
       'recentMsg':'Tell us how we can improve!!',
       'recipFullName':'Link',
       'recipID':'Link',
       'time':time
     };

    await ref.child('convoLists').child(id).child(id).set(feedbackConvoInfo);


     // need to set coordinates

    await ref.child('coordinates').child('Columbia-MO').child(riderOrDriver).child(id).set({'coordinates':coordinates});

    await ref.child('coverPhotos').child(id).set(coverPhoto);
    await ref.child('gradYears').child(id).set(gradYear);

    await ref.child('messageNotificationReciepts').child(id).set(alertTrue);
    await ref.child('commentReciepts').child(id).set(alertTrue);


    // set messageNotificationReciepts true
    //set notificationReciepts to true

    Map signupNotification = {
      'imgURL':"https://is4-ssl.mzstatic.com/image/thumb/Purple125/v4/b2/a7/91/b2a7916a-35be-5a7e-4c91-45317fb40d9c/AppIcon-1x_U007emarketing-0-0-GLES2_U002c0-512MB-sRGB-0-0-0-85-220-0-0-0-3.png/246x0w.jpg",
      'message':"Welcome to Link!! This is where you will recieve ride alerts, when someone is going to a city near your destination.",
      'type':"signup"
    };

    await ref.child('notifications').child(id).push().set(signupNotification);

    await ref.child('rideNotificationReciepts').child(id).set(alertTrue);

    await ref.child('fbLinks').child(id).set({'link':fbLink});





    // set rideNotificationReciepts = false




    Map usersCitiesInfo = {
      'city':'Columbia, MO',
      'cityCode':'Columbia-MO',
      'fullName':fullName,
      'imgURL':imgURL,
      'school':'Mizzou'
    };



    await ref.child('usersCities').child(id).set(usersCitiesInfo);


  }


}


//  Future<void> updateBitmoji()async{
//
//     setState(() {bitmojiLoading = true;});
//    try{
//      var userInfo = await  platform.invokeMethod('snapGraph');
//      if(userInfo['url'] == null){
//        _errorMenu('Error', "You must add a Bitmoji in the Bitmoji app.", '');
//        setState(() {
//          bitmojiLoading = false;
//        });
//        return;
//      }
//      var url = await uploadImg(userInfo['url'],"bitmoji",globals.id ,FirebaseDatabase.instance.reference().push().key);  // dont want to overwrite previous pictures
//      FirebaseDatabase database = FirebaseDatabase.instance;
//      database.reference().child(globals.cityCode).child('userInfo').child(globals.id).update({'imgURL':url});
//      database.reference().child(globals.cityCode).child('posts').child(globals.id).update({'imgURL':url});
//      setState(() {
//        bitmojiLoading = false;
//        globals.imgURL = url;
//      });
//
//    }catch(e){
//      setState(() {
//        bitmojiLoading = false;
//      });
//      _errorMenu('Error', 'Unable to update Bitmoji.', 'Please chat with Link Feedback!');
//    }
//  }