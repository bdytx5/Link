import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import '../main.dart';
import '../postSubmission/placepicker.dart';
import 'package:flutter/cupertino.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../globals.dart' as globals;

import '../homePage/userSearch.dart';
import '../homePage/chatList.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'editGroupChatInfo.dart';


class AddUser extends StatefulWidget{

  final Stream stream;
  final String firstUser;
  final String groupImg;
  final bool newConvo;
  _AddUserState createState() => new _AddUserState();

  AddUser({this.firstUser,this.groupImg, this.newConvo});

  FirebaseApp app;


}

class _AddUserState extends State<AddUser> {

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
  List<User> addedUsers = new List<User>();









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

        });
      }
    });
  }









  void initState() {
    super.initState();


    grabAllUsers();
    searchController.addListener(updateSearchResults);

  }

  Future<void> grabAllUsers()async{
    final FirebaseDatabase database = FirebaseDatabase.instance;
    database.reference().child(globals.cityCode).child('userInfo').orderByKey().once().then((snap) {
      returnedUsers.clear();
      returnedUsersData = snap.value;
      returnedUsersData.forEach((key, val) {
        returnedUsersData = val;
        print(returnedUsersData.toString());
        User user = User(val['fullName'], key, val['imgURL']);
        returnedUsers.add(user);
          if(widget.firstUser != null){
            if(user.id == widget.firstUser){
              setState(() {
                addUserToList(user);
              });
            }
          }
      });


    });
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
      appBar: new AppBar(
        backgroundColor: Colors.yellowAccent,
      ),
      key: _scaffoldKey,

      // prevents widget movement when keyboard shows

      body: new Column(
        children: <Widget>[
         new Container(
            margin: new EdgeInsets.only(left: 3.0, top: 5.0, right: 3.0),
            child: new TextField(
//              decoration: new InputDecoration(suffixIcon: new IconButton(
//                  icon: new Icon(Icons.close, color: Colors.grey,),
//                  onPressed: () {
//                    setState(() {
//                      userIsSearching = false;
//                    });
//                  })),
              controller: searchController,
              autofocus: true,
              focusNode:searchNode ,
            ),

          ),
          new Divider(),
          new Expanded(
              child: new Container(
                  child: new userSearchStream(userList: filteredUsers,userCallback: (u){
                  addUserToList(u);
                  },
                      scaffoldKey: _scaffoldKey,
                      actionButtonCallback: (hidden){},
                      groupChatUsage: true
                  )
              ),
          ),
//            new Flexible(
//                child: new Container(
//              height: 30.0,
//              width: double.infinity,
//              color: Colors.grey,
//            ))

          new Divider(),
    new Row(
      children: <Widget>[
        new Container(
          height: 40.0,
          width: MediaQuery.of(context).size.width - 30,

          child: new ListView.builder(
              itemCount: addedUsers.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (BuildContext context, int index){
                return new Container(
                  height: 40.0,
                  width: 150.0,
                  child: new Card(
                      child: new Row(
                        children: <Widget>[
                          new CircleAvatar(
                            radius: 15.0,
                            backgroundImage: CachedNetworkImageProvider(addedUsers[index].imgUrl),
                          ),
                          new Expanded(child:  new Text(addedUsers[index].fullName),),
                          new GestureDetector(
                            child: new Icon(Icons.close,color: Colors.grey,size: 20.0,),
                            onTap: (){
                              setState(() {
                                addedUsers.removeAt(index);
                              });

                            },
                          )
                        ],
                      )
                  ),
                );
              }),
        ),
    (addedUsers.length != 0) ?  new GestureDetector(
          child: new Icon(Icons.arrow_forward),
          onTap: (){



            if(!widget.newConvo) {
                 if(addedUsers.length != 0) {
                     List<String> users = new List();
                     addedUsers.forEach((user) {
                       users.add(user.id);
                         });
                     Navigator.pop(context, users);
                    }

            }else{
              if(addedUsers.length != 0){
                // get neccessary info like name

                List<String> users = new List();
                addedUsers.forEach((user){
                  users.add(user.id);
                });
                users.add(globals.id);
                showDialog(context: context, builder: (BuildContext context) => new EditGroupChatPopUp(FirebaseDatabase.instance.reference().push().key,users,widget.groupImg)).then((convoInfo){
                  Navigator.pop(context,convoInfo);
                });


              }
            }


          },
        ) : new Container()

      ],
    )

        ],


      ),


    );
  }

  void addUserToList(User user){
    setState(() {
      if(user.id != globals.id){
        addedUsers.add(user);
      }
    });
  }




}


