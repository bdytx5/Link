import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';

import '../globals.dart' as globals;
import 'chatList.dart';
import '../Chat/msgScreen.dart';
import 'feedStream.dart';
import 'profileSheet.dart';
import '../profilePages/profilePage.dart';



class userSearchStream extends StatefulWidget {

  GlobalKey<ScaffoldState> scaffoldKey;

  final ActionButtonCallback actionButtonCallback;



  List<User> results;
  userSearchStream(this.userList, this.scaffoldKey, this.actionButtonCallback,);
  List<User> userList;

  _userSearchStreamState createState() => new _userSearchStreamState();




}


class _userSearchStreamState extends State<userSearchStream> {
  Map convoInfo = {};
  PersistentBottomSheetController controller;


  Widget returnUsers() {
    return new Container(

      // child: new ListView.builder(itemBuilder: new ItemBi),
      child: new ListView.builder(
          itemCount: widget.userList.length,
          itemBuilder: (BuildContext context, int index) {
            return userCell(widget.userList[index]);
          }
      ),

    );
  }

  Widget userCell(User user){
    return new InkWell(
      child: new Row(
        children: <Widget>[

          new Padding(padding: new EdgeInsets.all(10.0),
          child: new CircleAvatar(backgroundImage: new NetworkImage(user.imgUrl),),
          ),
          new Text(user.fullName),
        ],
      ),

      onTap: (){

        showProfilePage(user);

        },
    );




  }

  void showProfilePage(User user)async{
    DatabaseReference ref = FirebaseDatabase.instance.reference();
   // DataSnapshot postSnap = await ref.child(globals.cityCode).child(id).once();

    Navigator.push(context,
        new MaterialPageRoute(builder: (context) => new ProfilePage(id: user.id,profilePicURL: user.imgUrl,firstName: '',fullName: user.fullName)));
  }


  void chatWithUser(String recipID, String recipFullName, String recipImgURL)async{
    // need to do a bunch of stuff here....
    // first need to figure out if these two users have a convo going already
    // if they do, we need to get the convoID, and pass it to the msgscreen
    // if they do not, we need to create a new convo for both users

    if(recipID == globals.id){
      return;
    }

    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot convoListSnap = await ref.child('convoLists').child(globals.id).child(recipID).child('convoID').once();

    if(convoListSnap.value != null){
      // the user has a convo going with selected user

      final convoInfo = convoListSnap.value;
      Navigator.push(context, new MaterialPageRoute(builder: (context) => new ChatScreen(convoID: convoListSnap.value,newConvo: false,recipFullName: recipFullName,recipID: recipID,recipImgURL: recipImgURL)));
        }else{
      // the user  does not have a convo going with the selected user

      // we will create the convo node, then, get the info, and pass it to the chat screen


//
//      Map convoInfoForSender = {'recipID':recipID,'convoID':convoID, 'time':convoID, 'imgURL':recipImgURL,
//      'recipFullName': recipFullName};
//      ref.child('convoLists').child(globals.id).child(recipID).set(convoInfoForSender);
//
//      Map convoInfoForRecipient = {'recipID':globals.id,'convoID':convoID, 'time':convoID, 'imgURL':globals.imgURL, 'recipFullName':globals.id};
//      ref.child('convoLists').child(recipID).child(globals.id).set(convoInfoForRecipient);

      var key = ref.child('convoLists').child(globals.id).child(recipID).push().key;
      Navigator.push(context, new MaterialPageRoute(builder: (context) => new ChatScreen(convoID: key,newConvo: true,recipFullName: recipFullName,recipID: recipID,recipImgURL: recipImgURL)));



    }






  }



  void initState() {
    super.initState();

   // if() grabAllUsers();
  }


  void grabAllUsers() async{

      List<Map> sup;
      DataSnapshot snap = await FirebaseDatabase.instance.reference().child(globals.cityCode).child('userInfo').once();

        Map allUsers = snap.value;

        allUsers.forEach((id,info){

          User returnedUser = new User(info['fullName'], id, info['imgURL']);

            widget.userList.add(returnedUser);


          print(id);

        });



  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return new Container(
      child:(widget.userList != null) ? returnUsers() : new Container(),

    );
  }
  }
