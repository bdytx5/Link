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
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../Chat/msgScreen.dart';
import '../globals.dart' as globals;
import '../Chat/msgStream.dart';
import 'chatListStream.dart';
import 'userSearch.dart';
import 'feedStream.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatList extends StatefulWidget{

  final Stream stream;

  _chatListState createState() => new _chatListState();

  ChatList({this.stream,this.updateChatListCallback});

     FirebaseApp app;

  final UIcallback updateChatListCallback;



}

class _chatListState extends State<ChatList> {

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final searchController = new TextEditingController();
  FirebaseMessaging _firMes = new FirebaseMessaging();
  static bool askedToAllowNotifications = false;

//GlobalKey<ScaffoldState>
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  final destinationTextContoller = new TextEditingController();
  String searchedName;
  Map data = {};
  Map returnedUsersData = {};
  bool loading = false;

  Map searchResults = {};

  List<User> chatContacts = new List<User>();
  List<User> returnedUsers = new List<User>();
  List<User> filteredUsers = new List<User>();
  bool userIsSearching = false;
  bool userIsViewingProfile = false;
  Icon actionBtnIconCncl = new Icon(Icons.cancel, color: Colors.black,);
  Icon actionBtnIconSearch = new Icon(Icons.search, color: Colors.black);
  Icon actionBtnIconChat = new Icon(Icons.chat, color: Colors.black);
  String logoURL = "https://is4-ssl.mzstatic.com/image/thumb/Purple125/v4/b2/a7/91/b2a7916a-35be-5a7e-4c91-45317fb40d9c/AppIcon-1x_U007emarketing-0-0-GLES2_U002c0-512MB-sRGB-0-0-0-85-220-0-0-0-3.png/246x0w.jpg";
  FocusNode searchNode = new FocusNode();
  StreamSubscription keyboardDissmissalStreamSubscription;








  // we will pass in this array to the usersearch class


  void updateSearchResults() {
    if (searchController.text.length == 0) {
      setState(() {
        filteredUsers.clear();
      });
      return;
    }

    filteredUsers.clear();

    returnedUsers.forEach((user) {
      // ignore caps
      if (user.fullName.toUpperCase().contains(searchController.text.toUpperCase())) {
        setState(() {
          filteredUsers.add(user);
          print('added');
        });
      }
    });
  }









  void initState() {
    super.initState();

    print(globals.id);
 //   handleNotifications();

    keyboardDissmissalStreamSubscription = widget.stream.listen((_) => dismissKeyboard());

    searchController.addListener(updateSearchResults);

  }


  void dismissKeyboard(){
    searchNode.unfocus();
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomPadding: false,
      // prevents widget movement when keyboard shows

      body: new Column(
        children: <Widget>[
          (userIsSearching) ? new Container(
            margin: new EdgeInsets.only(left: 3.0, top: 1.0, right: 3.0),
            child: new TextField(
              decoration: new InputDecoration(suffixIcon: new IconButton(
                  icon: new Icon(Icons.close, color: Colors.grey,),
                  onPressed: () {
                    setState(() {
                      userIsSearching = false;
                    });
                  })),
              controller: searchController,
              autofocus: true,
              focusNode:searchNode ,
            ),
            color: Colors.white,
          ) : new Container(),
          new Expanded(
              child: new Container(
                  color: Colors.white,
                  child: (userIsSearching) ? new userSearchStream(userList: filteredUsers,userCallback: (u){},groupChatUsage: false,) : new Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      new Padding(padding: new EdgeInsets.only(top: 8.0)),
                      new Expanded(child: new chatListStream(_scaffoldKey, () {
                        setState(() {
                          userIsViewingProfile = !userIsViewingProfile;
                        });
                      }, () {
                        widget.updateChatListCallback();
                      }),)

                    ],
                  )
              )
          )

        ],


      ),
      floatingActionButton: (userIsSearching) ? null : new FloatingActionButton(
        backgroundColor: Colors.yellowAccent,
        child: actionBtnIconSearch,
        onPressed: () {
          setState(() {
            if (userIsSearching) {
              userIsSearching = false;
              userIsViewingProfile = false;
            } else {
              userIsSearching = true;
              final FirebaseDatabase database = FirebaseDatabase.instance;
              database.reference().child(globals.cityCode).child('userInfo')
                  .orderByKey().once()
                  .then((snap) {
                returnedUsers.clear();
                returnedUsersData = snap.value;
                returnedUsersData.forEach((key, val) {
                  returnedUsersData = val;
                  print(returnedUsersData.toString());
                  User user = User(val['fullName'], key, val['imgURL']);
                  returnedUsers.add(user);
                });
              });
            }
          });
        },


      ),


    );
  }




}

class User{

  User(this.fullName, this.id, this.imgUrl);

  String fullName;
  String id;
  String imgUrl;
}




//
//void handleChatSelected(String selectedUser){
//
//
//  userIsSearching = false;
//
//     // we will check if there is a current convo with this user, and if there is, we will go to the send the convo id to the next screen
//
//
// final FirebaseDatabase database = new FirebaseDatabase(app: widget.app);
//
// Map convoList = {};
//
// database.reference().child('convoLists').child(globals.id).once().then((snap){
//
//    convoList = snap.value;
//
//    // make sure the user has a database node for a convoList
//    if(snap.value == null ){
//
//      DatabaseReference ref = database.reference().child('convoLists').child(globals.id).push();
//
//     String convoID = ref.key;
//
//        database.reference().child('userInfo').child(selectedUser).once().then((snap){
//
//          Map usersProfile = snap.value;
//
//          Map convoListForSender = {'convoID':ref.key,'imgURL': usersProfile['imgURL'], 'fullName':usersProfile['fullName'], 'userID':usersProfile['id'],'time':convoID,'read':'false' };
//
//        database.reference().child('convoLists').child(globals.id).child(selectedUser).set(convoListForSender);
//
//
//          Map convoListForRecipient = { 'convoID':ref.key,'imgURL': globals.imgURL,'fullName': globals.fullName,'userID':globals.id,'time':convoID,'read':'true' };
//
//        database.reference().child('convoLists').child(selectedUser).child(globals.id).set(convoListForRecipient);
//
//        Navigator.push(context,
//                new MaterialPageRoute(builder: (context) => new ChatScreen(selectedUser, ref.key))).then((val){
//                  loading = false;
//
//                  database.reference().child('convoLists').child(selectedUser).update({'read':'true'});
//
//
//                });
//
//
//        });
//
//              return;
//    }
//
//
//
//
//
//
//      convoList.forEach((key,val){
//        Map convoInfo = val;
//
//        if(convoInfo.containsValue(selectedUser)){
//          loading = false;
//
//        Navigator.push(context,
//                new MaterialPageRoute(builder: (context) => new ChatScreen(selectedUser, val['convoID']))).then((val){
//
//                  database.reference().child('convoLists').child(selectedUser).update({'read':'true'});
//
//                });
//
//
//                return;
//
//        }
//
//
//
//        });
//
//
//
//
// DatabaseReference ref = database.reference().child('convoLists').child(globals.id).push();
//
//     String convoID = ref.key;
//  database.reference().child('userInfo').child(selectedUser).once().then((snap){
//
//          Map value = snap.value;
//          Map usersProfile = value['selectedUser'];
//
//
//          Map  convoListForRecipient = {'convoID':ref.key,'imgURL': usersProfile['imgURL'], 'fullName':globals.fullName, 'userID':globals.id,'time':convoID, 'read':'false' };
//
//        database.reference().child('convoLists').child(selectedUser).child(globals.id).set(convoListForRecipient);
//
//
//          Map  convoListForSender = { 'convoID':ref.key,'imgURL': globals.imgURL,'fullName': usersProfile['fullName'],'userID':selectedUser,'time':convoID,'read':'true' };
//
//        database.reference().child('convoLists').child(globals.id).child(selectedUser).set(convoListForSender);
//
//         loading = false;
//
//        Navigator.push(context,
//                new MaterialPageRoute(builder: (context) => new ChatScreen(selectedUser, ref.key, false))).then((val){
//
//
//                    database.reference().child('convoLists').child(selectedUser).update({'read':'true'});
//
//                });
//
//
//  });
//
//
//
//
//
//
//      });
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//    // if(convoList.containsValue(selectedUser)){
//    //   // convo exists...
//
//    //   convoList.forEach((key, val){
//
//    //     if(val == selectedUser){
//
//    //         // value = convo ID    PUSH the Chat screen
//
//
//    //     database.reference().child('userInfo').child('heyyy').once().then((snap){
//    //       Map usersProfile = snap.value;
//
//
//    //     });
//
//
//    //     }
//
//
//    //   });
//
//
//    // }else{
//    //         // new convo list, so we will need to create push the user id to the database
//
//    //        DatabaseReference ref = database.reference().child('convoLists').child(globals.id).push();
//
//    //  Map convoListForSender = {ref.key:selectedUser};
//
//
//    //     database.reference().child('convoLists').child(globals.id).set(convoListForSender);
//
//    //        Map convoListForRecipient = {ref.key:globals.id};
//
//
//
//    //     database.reference().child('convoLists').child(selectedUser).set(convoListForRecipient);
//
//
//    //     database.reference().child('userInfo').child(selectedUser).once().then((snap){
//    //       Map usersProfile = snap.value;
//    // // we are gonna send the convolist info over to chat screen.. If the data is out of date, we will update it in the init state meathod of chat screen
//    //     Navigator.push(context,
//    //             new MaterialPageRoute(builder: (context) => new ChatScreen(widget.app, selectedUser, usersProfile['fullName'], usersProfile['imgURL'], ref.key))).then((val){
//
//    //               loading = false;
//
//    //             });
//    //     });
//
//
//    // }
//
//
//
//
//
//
//
//    }
//


//Widget feedBackCell() {
//  return new Container(
//    height: 55.0,
//    width: double.infinity,
//    child: new InkWell(
//      onTap: () {
//        goToFeedbackScreen();
//      },
//      child: new Row(
//        children: <Widget>[
//
//          new Padding(
//            padding: new EdgeInsets.all(2.0),
//            child: new Container(
//              height: 50.0,
//              width: 50.0,
//              decoration: new BoxDecoration(
//                color: Colors.yellow,
//                shape: BoxShape.circle,
//              ),
//
//            ),
//          ),
//
//          new Column(
//            children: <Widget>[
//              new Expanded(
//                child: new Padding(
//                  padding: new EdgeInsets.all(6.0),
//                  child: new Text('Give Thumbs-Out Feedback',
//                      style: new TextStyle(
//                          fontSize: 15.0, fontWeight: FontWeight.bold)),
//                ),
//              ),
//
//            ],
//          )
//        ],
//      ),
//    ),
//
//
//  );
//}
//




//
//void goToFeedbackScreen() {
//  Navigator.push(context, new MaterialPageRoute(builder: (context) =>
//  new ChatScreen(convoID: convoInfo['convoID'],newConvo: false,recipFullName: convoInfo['recipFullName'],recipID: convoInfo['recipID'],recipImgURL: convoInfo['imgURL'])))
//      .then((val) {
//    // new ChatScreen(recipID, convoID, newConvo, recipImgURL, name)
//    loading = false;
//  });
//}



//
//
//Widget feedback(){
//  return new InkWell(
//    child: new Column(
//      crossAxisAlignment: CrossAxisAlignment.center,
//      children: <Widget>[
//        new Row( // nested rows im feeling like collin jackson rn
//          crossAxisAlignment: CrossAxisAlignment.start,
//
//          children: <Widget>[
//            new Row(
//              mainAxisAlignment: MainAxisAlignment.start,
//              children: <Widget>[
//                new Padding(padding: new EdgeInsets.all(5.0),
//                  child: new CircleAvatar(
//                    radius: 5.0,
//                    backgroundColor: Colors.white,
//                  ),
//                ),
//                new Padding(padding: new EdgeInsets.only(top: 8.0),
//                  child: new CircleAvatar(
//                    radius: 25.0,
//                    backgroundColor: Colors.transparent,
//                    backgroundImage: new NetworkImage(logoURL),
//                  ),
//                )
//              ],
//            ),
//            new Expanded(child: new Padding(padding: new EdgeInsets.only(left: 5.0),
//              child: new Padding(padding: new EdgeInsets.only(top: 8.0),
//                child: new Column(
//                  crossAxisAlignment: CrossAxisAlignment.start,
//                  children: <Widget>[
//                    new Text('Thumbs-Out',style: new TextStyle(fontWeight: FontWeight.bold),),
//                    new Padding(padding: new EdgeInsets.only(top: 2.0),
//                      child: new Text("Tell us what you don't like!",style: new TextStyle(color: Colors.grey),maxLines: 1,overflow: TextOverflow.ellipsis,),
//                    )
//                  ],
//                ),
//              ),
//
//            ),),
//            new Padding(padding: new EdgeInsets.only(right: 8.0,top: 8.0),
//              child: new Text('Anytime',style: new TextStyle(color: Colors.grey)),
//
//            )
//
//
//
//
//          ],
//        ),
//
//        new Divider()
//
//      ],
//    ),
//    onTap: (){
//      // show the feedback screen
//      goToFeedbackScreen();
//    },
//
//  );
//
//}

//void createSnackBar() {
//  final snackBar = new SnackBar(content: new Row(
//    children: <Widget>[
//      new Text('Turn on Message Notifcations'),
//      new Padding(padding: new EdgeInsets.all(5.0),
//        child: new MaterialButton(onPressed: () {
//          Scaffold.of(context).hideCurrentSnackBar();
//
//          _firMes.requestNotificationPermissions(
//              const IosNotificationSettings(
//                  sound: true, badge: true, alert: true));
//
//          _firMes.onIosSettingsRegistered.listen((
//              IosNotificationSettings settings) async {
//            final SharedPreferences prefs = await _prefs;
//            print("settings registered $settings");
//            _firMes.getToken().then((token) {
//              if(token != null){
//                prefs.setBool('requestedNotifications', true);
//                final FirebaseDatabase database = new FirebaseDatabase(
//                    app: widget.app);
//                database.reference().child('tokens').child(globals.id).set(
//                    {'token': token});
//              }else{
//                // user declined notifications haha so that means we need to redirect them back to settings
//
//
//              }
//
//            });
//          });
//        },
//          child: new Text(
//            'TURN ON', style: new TextStyle(color: Colors.black),),
//          color: Colors.yellowAccent,
//        ),
//      )
//
//    ],
//  ),
//      backgroundColor: Colors.grey[800], duration: new Duration(seconds: 10));
//
//  // Find the Scaffold in the Widget tree and use it to show a SnackBar!
//  Scaffold.of(context).showSnackBar(snackBar);
//}



//
//Widget ConvoCell(Map convoInfo, BuildContext context) {
//  return new Container(
//      padding: new EdgeInsets.all(5.0),
//
//      child: new Column(
//        children: <Widget>[
//          new InkWell(
//            // margin: const EdgeInsets.symmetric(vertical: 10.0),
//            child: new Container(
//              child: new Row(
//                children: <Widget>[
//                  new Padding(
//                    padding: new EdgeInsets.only(
//                        left: 10.0, top: 10.0, bottom: 10.0),
//
//                    child: new Container(
//                      height: 50.0,
//                      width: 50.0,
//                      child: new CircleAvatar(
//                        backgroundImage: new NetworkImage(
//                            convoInfo['imgURL']),
//                      ),
//                    ),
//                  ),
//                  new Column(
//                    crossAxisAlignment: CrossAxisAlignment.start,
//
//                    children: <Widget>[
//                      new Padding(
//                        padding: new EdgeInsets.only(left: 8.0),
//                        child: new Text(convoInfo['recipFullName'],
//                          style: new TextStyle(fontWeight: FontWeight.bold),),
//                      ),
//                      new Padding(
//                        padding: new EdgeInsets.only(left: 8.0),
//                        child: new Text(convoInfo['recentMsg'],
//                            style: new TextStyle(color: Colors.grey),
//                            textAlign: TextAlign.left),
//                      ),
//                    ],
//                  )
//                ],
//              ),
//            ),
//            onTap: () {
//              // show the message screen
//              Navigator.push(context,
//                  new MaterialPageRoute(builder: (context) => new ChatScreen(convoID: convoInfo['convoID'],newConvo: false,recipFullName: convoInfo['recipFullName'],recipID: convoInfo['recipID'],recipImgURL: convoInfo['imgURL'])));
//
//
////                convoInfo['recipID'], convoInfo['convoID'], false,
////                convoInfo['imgURL'], convoInfo['recipFullName']
//            },
//
//          ),
//          new Divider()
//        ],
//      )
//
//  );
//}
//void handleNotifications() async {
//  final SharedPreferences prefs = await _prefs;
//  (!askedToAllowNotifications &&
//      prefs.getBool('requestedNotifications') == null) ? new Future.delayed(
//      const Duration(seconds: 1))
//      .then((idk) {
//    askedToAllowNotifications = true;
//    createSnackBar();
//  }
//  ) : null;
//}