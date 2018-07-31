import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../loginFlow/login_page.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import '../postSubmission/placepicker.dart';
import '../globals.dart' as globals;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../postSubmission/submitpost.dart';
import 'package:intl/intl.dart';
import '../Chat/msgScreen.dart';
import '../homePage/chatList.dart';
import '../homePage/feed.dart';
import 'feedStream.dart';
import '../postSubmission/postSubmitPopUp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../loginFlow/selectSchool.dart';
import '../Chat/msgStream.dart';
import 'profileSheet.dart';
import 'package:flutter/services.dart';
import '../notifications/notificationsPage.dart';
import '../Chat/msgScreen.dart';
import '../profilePages/commentsPage.dart';
import 'home.dart';

class Feed extends StatefulWidget {
 // MyHomePage({Key key, this.title}) : super(key: key);

  final UIcallback commentNotificationCallback;

  Feed({this.app, this.userID, this.commentNotificationCallback,this.keyboardNeedsDismissed, this.streamController});
    final FirebaseApp app;
    String userID;
    final bool keyboardNeedsDismissed;


  final StreamController streamController;// for communicating down the widget tree to dismiss the keyboard





  @override
  _FeedState createState() => new _FeedState();
}

class _FeedState extends State<Feed> {

    bool commenting = false;
    static bool askedToAllowNotifications = false;
    PersistentBottomSheetController _sheetController;
    ScaffoldFeatureController _bottomSheet;
    int _counter = 0;
    double menuHeight = 200.0;
    Map data = {};
    List<Post> postList = new List();
    bool menuShowing = false;
    String _btnTxt = "SUp";
    BottomSheet _sheet;
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    static const platform = const MethodChannel('thumbsOutChannel');


    FirebaseMessaging _firMes = new FirebaseMessaging();
    final _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree

    super.dispose();
  }



  void _toggleFavorite() {
    setState(() {
      // If the lake is currently favorited, unfavorite it.
      _btnTxt = "hello";
      menuHeight = 400.0;
    });
  }

    void initState() {
    super.initState();
    handleNotifications();
    updateGlobalInfo(globals.id);

  }




  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      resizeToAvoidBottomPadding: false,
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      body: new Center(
        child: new Container(
          child: (globals.cityCode != null) ? new feedStream(_scaffoldKey, (){
            setState(() {
              commenting = !commenting;
            });
          },widget.commentNotificationCallback,widget.streamController) : new CircularProgressIndicator(),
        ),
      ),
      floatingActionButton: (!commenting) ? new FloatingActionButton(
        backgroundColor: Colors.yellowAccent,
        onPressed: () {
          showDialog(context: context, builder: (BuildContext context) => new PostPopUp(widget.app));
        },
        child: new Icon(Icons.calendar_today),
      ) :  null,
    );
  }

void updateGlobalInfo(String id) async {
     FirebaseDatabase database = FirebaseDatabase.instance;
      final snap = await database.reference().child('usersCities').child(id).once();
      Map info = snap.value;
      if(info != null ){
        /// need city code, id, full name, home city
        setState(() {
          globals.id = id;
          globals.city = info['city'];
          globals.cityCode = info['cityCode'];
        });

      }
    }

    Future<void>getToken()async{
      final SharedPreferences prefs = await _prefs;

      if(prefs.getBool('requestedNotifications') == null){
        _firMes.getToken().then((token) {
          if(token != null){
            FirebaseDatabase database = FirebaseDatabase.instance;

            database.reference().child('tokens').child(globals.id).set(
                {'token': token});
            print(token);
          }
        });
      }
    }


    void handleNotifications() async {
      final SharedPreferences prefs = await _prefs;
      (!askedToAllowNotifications &&
          prefs.getBool('requestedNotifications') == null) ? new Future.delayed(
          const Duration(seconds: 5))
          .then((idk) {
        askedToAllowNotifications = true;
        prefs.setBool('requestedNotifications', true);
        createSnackBar();
      }
      ) : null;
    }


    void createSnackBar() {
      final snackBar = new SnackBar(content: new Row(
        children: <Widget>[
         new Expanded(child:  new Text('Allow Message Notifcations'),),
          new Padding(padding: new EdgeInsets.all(5.0),
            child: new MaterialButton(onPressed: () {
              Scaffold.of(context).hideCurrentSnackBar();
              _firMes.requestNotificationPermissions(const IosNotificationSettings(sound: true, badge: true, alert: true));


            },
              child: new Text(
                'TURN ON', style: new TextStyle(color: Colors.black),),
              color: Colors.yellowAccent,
            ),
          )

        ],
      ),
          backgroundColor: Colors.grey[800], duration: new Duration(seconds: 10));

      // Find the Scaffold in the Widget tree and use it to show a SnackBar!
      Scaffold.of(context).showSnackBar(snackBar);
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
                child: new Text('Ok', style: new TextStyle(color: Colors.black),),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
}


//
//
//void grabPosts(String city) {
//  final FirebaseDatabase database = new FirebaseDatabase(app: widget.app);
//  database.reference().child('posts').orderByKey().once().then((snap) {
//    data = snap.value;
//    data.forEach((key, value) {
//      Map post = value;
//      if (post.length == 20 && city == post['usersCity']) {
//        addPost(post);
//      }
//    });
//  });
//}
//
//
//
//
//void addPost(Map value) {
//  setState(() {
//    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
//    var postDate = formatter.parse(value['date']);
//
//
//    if ((postDate.isBefore(new DateTime.now())) ||
//        (value['post'] == 'deletedPost')) {
//      Post post = Post(
//          value['post'],
//          value['name'],
//          value['imgURL'],
//          value['fullName'],
//          value['id'],
//          value['phone'],
//          value['origin'],
//          value['destination'],
//          value['state'],
//          value['riderOrDriver'],
//          value['riderOrDriver']);
//
//
//      postList.add(post);
//    } else {
//      Post post = Post(
//          'deletedPost',
//          value['name'],
//          value['imgURL'],
//          value['fullName'],
//          value['id'],
//          value['phone'],
//          value['origin'],
//          value['destination'],
//          value['state'],
//          value['riderOrDriver'],
//          value['riderOrDriver']);
//
//
//      postList.add(post);
//    }
//  });
//}
//
//
//
//
//void updateUIStatus(){
//  setState(() {
//    userIsViewingProfile = !userIsViewingProfile;
//  });
//
//}




//class Post{
//  String post;
//  String _name;
//  String _imgUrl;
//  String fullName;
//  String id;
//  String phoneNumber;
//  String riderOrDriver;
//  String origin;
//  String destination;
//  String state;
//  String longDestination;
//  String longOrigin;
//  String date;
//  String leaveDate;
//
//
//
//
//
//  Post(this.post, this._name, this._imgUrl, this.fullName, this.id, this.phoneNumber, this.origin,this.destination,this.state,this.riderOrDriver, this.date);
//
//
//
//}
//
//void changeUi() {
//  _scaffoldKey.currentState.setState(() {
//    _btnTxt = "hey";
//  }
//
//  );
//}

//
//Future<Null> _askedToLead() async {
//  bool selected = false;
//  switch (await showDialog<bool>(
//      context: context,
//      builder: (BuildContext context) {
//        return new SimpleDialog(
//          title: (!selected)
//              ? new Text('When would you like to leave?')
//              : new Text(''),
//          children: <Widget>[
//            new MonthPicker(selectedDate: new DateTime.now(),
//                onChanged: (d) {
//                  again();
//                },
//                firstDate: DateTime.parse("-2020-12-24"),
//                lastDate: DateTime.parse("-2010-12-24"))
//          ],
//        );
//      }
//  )) {
//    case true:
//    // Let's go.
//    // ...
//      break;
//    case false:
//    // ...
//      break;
//  }
//}
//
//
//void again() {
//  _askedToLead();
//}
