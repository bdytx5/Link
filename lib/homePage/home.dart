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

Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
final changeNotifier = new StreamController.broadcast(); // for communicating down the widget tree to dismiss the keyboard

FirebaseMessaging _firMes = new FirebaseMessaging();
//FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;


  // notification logic is somwhat complicated...
  // basically we set a _pref bool to see once the user agrees/disagrees to notificaitons (true/false)
  // if it is, then we can set the bool to true
  // if its false, we can redirect the user to settings

   void initState() {
    super.initState();
    globals.id = widget.userID;

    configureCloudMessaging();

    handleNotificationsRequest();
    updateLastUserPersistentStorage(widget.userID);

    _tabController = new TabController(vsync: this, initialIndex: 1, length: 2);
    _tabController.addListener(_tabIndexChanged);

    fetchNotificationCommentStatuses(); // attatch a listener to the comment notifications node
    fetchRideNotificationStatuses();// attatch a listener to the ride notifications node
    fetchNotificationMessageStatuses(); // attach a listener to the message notifications node

    getToken();

    updateCityCode(widget.userID).then((idk){
      fetchTransportModeAndRiderOrDriver();
    });

   }


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
                    grabUsersImgAndFullName();
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
          new ChatList(stream: changeNotifier.stream),
      (transportMode != null && destination != null ) ?  new Feed(app: widget.app,userID: widget.userID, commentNotificationCallback:_commentNotificationCallback,streamController: changeNotifier, destination: destination,transportMode: transportMode) : new Container(
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
                                  child: (bitmojiLoading) ? new CircularProgressIndicator() : new Container(),
                                )
                            ) : new CircularProgressIndicator(),
                            onTap: ()async{
                              var res = await   _warningMenu('Update Bitmoji?', 'Are You Sure You want to update your Bitmoji?', "This CANNOT be undone.");
                              if(res){
                                updateBitmoji();
                              }
                            },
                          )

                        ),
                        new Positioned(child:  new IconButton(icon: new Icon(Icons.edit,color: Colors.white,), onPressed: ()async{
                          // change bitmoji
                       var res = await   _warningMenu('Update Bitmoji?', 'Are You Sure You want to update your Bitmoji?', "This CANNOT be undone.");
                       if(res){
                         updateBitmoji();
                       }
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
                        url: 'https://docs.google.com/document/d/1eci-jMZvGyrLwJWctB4TMsjR2Mk0WHXMvzalD_UZhvQ/edit?usp=sharing',
                        appBar: new AppBar(
                            backgroundColor: Colors.yellow,
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

                    handleNotifications();

                  },
                ),
              ) : new Container(),
              new Card(
                child:  new ListTile(
                  leading: new Icon(Icons.launch),
                  title: new Text('logout'),

                  onTap: ()async{
                    bool res = await _warningMenu('Logout?', 'Are you sure you want to logout of Thumbs-Out?', '');

                    if(res){
                      try{

                        platform.invokeMethod('logoutOfSnap').then((res)async{
                          var ref = FirebaseDatabase.instance.reference();
                          await ref.child('tokens').child(globals.id).remove();
                          globals.id = null;
                          globals.cityCode = null;
                          globals.name = null;
                          globals.fullName = null;
                          Navigator.pushReplacement(context , new MaterialPageRoute(builder: (context) => new LoginPage(app: widget.app)));
                        });
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


  Future<void> handleNotifications()async{
     
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

  Future<void> updateBitmoji()async{

     setState(() {bitmojiLoading = true;});
    try{
      var userInfo = await  platform.invokeMethod('snapGraph');
      if(userInfo['url'] == null){
        _errorMenu('Error', "You must add a Bitmoji in the Bitmoji app.", '');
        setState(() {
          bitmojiLoading = false;
        });
        return;
      }
      var url = await uploadImg(userInfo['url'],"bitmoji",globals.id ,FirebaseDatabase.instance.reference().push().key);  // dont want to overwrite previous pictures
      FirebaseDatabase database = FirebaseDatabase.instance;
      database.reference().child(globals.cityCode).child('userInfo').child(globals.id).update({'imgURL':url});
      database.reference().child(globals.cityCode).child('posts').child(globals.id).update({'imgURL':url});
      setState(() {
        bitmojiLoading = false;
        globals.imgURL = url;
      });

    }catch(e){
      setState(() {
        bitmojiLoading = false;
      });
      _errorMenu('Error', 'Unable to update Bitmoji.', 'Please chat with Thumbs-Out Feedback!');
    }
  }

  Future<String> uploadImg(String url, String path1,String path2, String path3) async {
    try{
      var response = await http.get(url);
      final Directory systemTempDir = Directory.systemTemp;
// im a dart n00b and this is my code, and it runs s/o to dart async
      final file = await new File('${systemTempDir.path}/test.png').create();
      var result = await file.writeAsBytes(response.bodyBytes);
      final StorageReference ref = await FirebaseStorage.instance.ref().child("profilePics").child(path1).child(path2).child(path3);
      final dataRes = await ref.putData(response.bodyBytes);
      final dwldUrl = await dataRes.future;
      return dwldUrl.downloadUrl.toString();
    }catch(e){
      setState(() {
      });
      print(e);
      throw new Exception(e);
    }

  }






void grabUsersImgAndFullName()async{

  FirebaseDatabase database = FirebaseDatabase.instance;
     if(globals.fullName != null && globals.imgURL != null){
       return;
     }
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
  });
}



  void fetchNotificationMessageStatuses()async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    database.reference().child('messageNotificationReciepts').child(globals.id).child('newAlert').onValue.listen((data) async {

      if(data.snapshot.value == null){
        return;
      }
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
    try{
      DataSnapshot snap = await ref.child('tokens').child(lastUser).child('token').once();
      if(snap.value == await getMyCloudToken()){
        ref.child('tokens').child(lastUser).child('token').remove();
      }
    }catch(e){

    }
  }
  prefs.setString('lastUser', id);
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

  changeNotifier.sink.add(null);

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


}

