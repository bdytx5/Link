import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../globals.dart' as globals;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'feed.dart';
import 'chatList.dart';
import '../Chat/msgScreen.dart';
import 'feedStream.dart';
import '../textFieldFix.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import '../profilePages/commentsPage.dart';

import '../profilePages/addFeedback.dart';

















class UserProfile extends StatefulWidget {



Map postInfo = {};
String id;
UserProfile({this.postInfo, this.id});
  _UserProfileState createState() => new _UserProfileState();


}
class _UserProfileState extends State<UserProfile> {
  bool userIsViewFb = false;
  bool webViewHidden = true;
  bool userIsViewingThemseves = false;
  bool textfieldVisible = true;
  List<String> urls = [];
   String url = '';
  String fullName = '';

   String recipientToComment;

  final flutterWebviewPlugin = new FlutterWebviewPlugin();

  FocusNode commentNode = new FocusNode();

  TextEditingController commentController = new TextEditingController();

  StreamSubscription<WebViewStateChanged> _onStateChanged;
  void initState() {
    super.initState();

//
//  if(widget.postInfo.containsKey('fbLink')){
//
//    url = widget.postInfo['fbLink'];
//  }

if(globals.id == widget.id){
    userIsViewingThemseves = true;
    textfieldVisible = false;
}

getUsersFullName();


  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree
    flutterWebviewPlugin.close();

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          iconTheme: new IconThemeData(color: Colors.black),
          title: new Text(fullName, style: new TextStyle(color: Colors.black),),
          backgroundColor: Colors.yellowAccent,
        ),
        body: (!userIsViewFb) ? sheet(widget.postInfo, context) : new Container(
          height: double.infinity,
          width: double.infinity,
          color: Colors.yellowAccent,
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              new Row(
                children: <Widget>[
                  new MaterialButton(onPressed: (){
                    setState(() {
                      userIsViewFb = false;
                    });
                    flutterWebviewPlugin.close();
                   },
                    child: new Text('close'),
                  ),
                ],
              )
            ],
          ),
        ));
  }


  Widget profileTitle(Map post) {
    String date = formatDateForCellTitle(post['leaveDate']);
    bool updated = checkIfPostIsUpdated(post);
    if (post['riderOrDriver'] == 'Riding') {
      return new RichText(
        maxLines: 1,
        textAlign: TextAlign.left,
        overflow: TextOverflow.clip,
        text: new TextSpan(
            style: new TextStyle(fontSize: 14.0, color: Colors.black),
            children: <TextSpan>[
              updated ? new TextSpan(text: 'Needs a ') : new TextSpan(
                  text: 'Usually Needs a '),
              new TextSpan(text: 'Ride',
                  style: new TextStyle(fontWeight: FontWeight.bold)),
              new TextSpan(text: ' to '),
              new TextSpan(text: '${post['destination']}, ${post['state']}',
                  style: new TextStyle(fontWeight: FontWeight.bold)),
              updated ? new TextSpan(text: ' on ') : new TextSpan(text: ''),
              updated
                  ? new TextSpan(
                  text: date, style: new TextStyle(fontWeight: FontWeight.bold))
                  : new TextSpan(text: '')
            ]
        ),
      );
    } else {
      return new RichText(
        textAlign: TextAlign.left,
        overflow: TextOverflow.clip,
        maxLines: 1,
        text: new TextSpan(
            style: new TextStyle(fontSize: 14.0, color: Colors.black),
            children: <TextSpan>[
              updated ? new TextSpan(text: '') : new TextSpan(
                  text: 'Usually '),
              updated
                  ? new TextSpan(text: ' Driving ',
                  style: new TextStyle(fontWeight: FontWeight.bold))
                  : new TextSpan(text: ' drives ',
                  style: new TextStyle(fontWeight: FontWeight.bold)),
              new TextSpan(text: 'to '),
              new TextSpan(text: '${post['destination']}, ${post['state']}',
                  style: new TextStyle(fontWeight: FontWeight.bold)),
              updated ? new TextSpan(text: ' on ') : new TextSpan(text: ''),
              updated
                  ? new TextSpan(
                  text: date, style: new TextStyle(fontWeight: FontWeight.bold))
                  : new TextSpan(text: '')
            ]

        ),
      );
    }
  }


//  Future<void> getProlileFullName(){
//    DatabaseReference ref = FirebaseDatabase.instance.reference();
//    DataSnapshot snap = await ref.child('userInfo').child(widget.id).once();
//  }

  Future<void> getUsersFullName()async{
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child('userInfo').child(widget.id).child('fullName').once();
    setState(() {
      fullName = snap.value;
    });
  }

  String formatDateForCellTitle(String date) {
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var postDate = formatter.parse(date);

    var shortDateFormatter = new DateFormat('M/d');
    var newDate = shortDateFormatter.format(postDate);

    return newDate;
  }



  bool checkIfPostIsUpdated(Map post) {
    // first check if the post is deleted using the new system for deletion

    if (post.containsKey('deleted')) {
      if (post['deleted'] == 'true') {
        return false;
      } else {
        return (checkDate(post['leaveDate'])) ? true : false;
      }
    }
    // now check if post is deleted using old meathod
    if (post['post'] == 'deletedPost') {
      return false;
    } else {
      return (checkDate(post['leaveDate'])) ? true : false;
    }
  }

  bool checkDate(String date) {
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var postDate = formatter.parse(date);

    if (postDate.isAfter(new DateTime.now())) {
      return true;
    } else {
      return false;
    }
  }

  Widget sheet(Map post,BuildContext context){
   return Container(
     child: new ListView(
       children: <Widget>[
         new Container(
           child: new Column(
             mainAxisAlignment: MainAxisAlignment.start,
             children: <Widget>[
               new Padding(
                 padding: new EdgeInsets.only(top: 10.0),
                 child:  new Container(
                   padding: new EdgeInsets.only(top: 30.0),
                   height: 100.0,
                   width: 100.0,
                   decoration: new BoxDecoration(
                     shape: BoxShape.circle,
                     color: Colors.yellow,
                     image: new DecorationImage(image: new NetworkImage(post['imgURL'])),
                   ),
                 ),
               ),
               new Padding(
                 padding: new EdgeInsets.only(top: 10.0,bottom: 10.0),
                 child: new Text(fullName, style: new TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),
               ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                  new Padding(padding: new EdgeInsets.all(5.0),
                  child: new Icon(Icons.location_on),
                  ),
                profileTitle(post),

              ],
            ),

               new Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: <Widget>[
                    new Padding(padding: new EdgeInsets.all(10.0),
                      child: new Container(
                        decoration: new BoxDecoration(
                            color: Colors.yellowAccent,
                            borderRadius: new BorderRadius.all(new Radius.circular(10.0)),
                            border: new Border.all(color: Colors.black)
                        ),
                        height: 40.0,
                        width: 150.0,
                        child: new MaterialButton(onPressed: (){
                          goToSendMessage();
                        },
                          child: new Text('Send Message', style: new TextStyle(fontWeight: FontWeight.bold),),
                        ),
                      ),
                    )
                 ],
               ),
               infoListView(fullName),
               new Padding(padding: new EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: new Container(
                      child: (textfieldVisible) ?
                      EnsureVisibleWhenFocused(
                          child: new TextField(
                            autofocus: (userIsViewingThemseves) ? true : false,
                            controller: commentController,
                              decoration: new InputDecoration(
                                hintText: ((userIsViewingThemseves)) ? 'Respond to Questions!' : 'Ask a Question!!',
                                  suffixIcon: new IconButton(icon: Icon(Icons.send, color: Colors.yellow,), onPressed: ()async{

                                    await sendComment(commentController.text, widget.id);
                                    commentController.clear();
                                    commentNode.unfocus();

                                    if(userIsViewingThemseves){
                                      setState(() {
                                        textfieldVisible = false;
                                      });
                                    }
                                  })
                              ),
                              focusNode: commentNode),
                          focusNode: commentNode) : new Container(),
                    ),

                    ),

             new Container(
               height: 300.0,
               width: double.infinity,
               child: buildFirebaseList(context, widget.id),
             )
             ],
           ),
         )
       ]//
     )
    );
  }

  Widget infoListView(String name){
    AssetImage fbIcon = new AssetImage('assets/fb.png');
    List<String> titles = ["View ${name}'s Facebook", 'See Detailed Feedback','Do you know ${name}? Give Feedback!'];
    List<dynamic> icons = [new ImageIcon(fbIcon), new Icon(Icons.feedback),new Icon(Icons.thumbs_up_down)];
    final flutterWebviewPlugin = new FlutterWebviewPlugin();
    return new Container(
      width: double.infinity,
      height: 140.0,
      child: new ListView.builder(
          itemCount: 3,
          itemBuilder: (context,index) {
            return new Container(
              height: 45.0,
              width: double.infinity,
              child: new InkWell(
                child: new Column(
                  children: <Widget>[
                    new Expanded(child: new Row(
                      children: <Widget>[
                        new Padding(padding: new EdgeInsets.all(5.0), child: icons[index],),
                        new Expanded(child: new  Text(titles[index]),),
                        new Icon(Icons.chevron_right)
                      ],
                     ),
                    ),
                    new Divider()
                  ],
                ),
                  onTap: (){
                  switch(index) {
                    case 0:
                  if(url != ''){
                    Navigator.push(context, new MaterialPageRoute(builder: (context) => new WebviewScaffold(
                        url: url,
                        appBar: new AppBar(
                            backgroundColor: Colors.yellow,
                            title: new Text("Facebook", style: new TextStyle(color: Colors.black),)))));
                  }

                      break;
                    case 1:

                      if(widget.id == globals.id){
                        return;
                      }
                   //   Navigator.push(context, new MaterialPageRoute(builder: (context) => new SeeFeedback(userInfo: widget.postInfo)));
                      break;
                    case 2:
                      if(widget.id == globals.id){
                        return;
                      }
                      showDialog(context: context, builder: (BuildContext context) => new AddFeedback(userInfo: widget.postInfo));
                      break;
                  }
                },
              ),
            );
          }
      ),
    );
  }

  void goToSendMessage()async{

    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child('convoLists').child(globals.id).child(widget.id).child('convoID').once();

    if(snap.value != null){

    //  Navigator.push(context,
      //    new MaterialPageRoute(builder: (context) => new ChatScreen(convoID: snap.value,newConvo: false,recipFullName: fullName,recipID: widget.id,recipImgURL: widget.p)));
    }else{
      if(widget.id == globals.id){
        return;
      }
     // Navigator.push(context,
      //    new MaterialPageRoute(builder: (context) => new ChatScreen(widget.id, 'noConvo', true, widget.postInfo['imgURL'],fullName,)));
    }


  }




Future<void> sendComment(String comment, String userID)async{

//
//  var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
//  DatabaseReference ref = FirebaseDatabase.instance.reference();
//
//  if(userIsViewingThemseves){
//    DatabaseReference ref = FirebaseDatabase.instance.reference();
//    Map notification = {'message':"${globals.name} responded to your comment!!", 'id':globals.id, 'name':globals.name};
//    ref.child('notifications').child(recipientToComment).push().set(notification);
//  }else{
//    DatabaseReference ref = FirebaseDatabase.instance.reference();
//    Map notification = {'message':"${globals.name} left a comment!!", 'id':globals.id, 'name':globals.name};
//    ref.child('notifications').child(userID).push().set(notification);
//  }


if(globals.fullName == null){
  DatabaseReference ref = FirebaseDatabase.instance.reference();
 DataSnapshot snap = await ref.child('userInfo').child(globals.id).once();
  globals.fullName = snap.value['fullName'];

}

if(globals.imgURL == null){
  DatabaseReference ref = FirebaseDatabase.instance.reference();
  DataSnapshot snap = await ref.child('profileImages').child(globals.id).once();
  globals.imgURL = snap.value['imgURL'];

}

if(commentController.text.length != 0){
  var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
  DatabaseReference ref = FirebaseDatabase.instance.reference();
    if(userIsViewingThemseves){
      ref.child('comments').child(globals.id).push().set(
          {'fromId':globals.id, 'fromName':globals.fullName, 'imgURL':globals.imgURL, 'comment':comment, 'date':formatter.format(new DateTime.now()), 'to':recipientToComment}
      );
    }else{
      ref.child('comments').child(userID).push().set(
          {'fromId':globals.id, 'fromName':globals.fullName, 'imgURL':globals.imgURL, 'comment':comment, 'date':formatter.format(new DateTime.now()), 'to':userID}
      );
    }

}

}



  FirebaseAnimatedList buildFirebaseList(BuildContext context, String userID)  {
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    final falQuery = ref.child('comments').child(userID).orderByKey();
    return new FirebaseAnimatedList(
        query: falQuery,
        defaultChild: new Center(
          child: CircularProgressIndicator(),
        ),
        sort: (DataSnapshot a, DataSnapshot b) => b.key.compareTo(a.key),
        reverse: false,
        itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, ___) {
          return new Container(
               child: new Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Padding(padding: new EdgeInsets.all(5.0),
                      child: new InkWell(
                        child: new CircleAvatar(
                          backgroundImage: new NetworkImage(snapshot.value['imgURL']),
                        ),
                        onTap: (){
                          showProfileSheet(snapshot.value['fromId']);
                        },
                      )
                    ),
                    new Flexible(child: new Column(
                      children: <Widget>[
                        new Padding(padding: new EdgeInsets.only(top: 5.0, left: 1.0),
                          child: new Text(snapshot.value['fromName'], style: new TextStyle(fontWeight: FontWeight.bold),),
                        ),
                        new Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            new Icon(Icons.language, color: Colors.grey,size: 10.0,),
                            Text(getDateOfMsg(snapshot.value), style: new TextStyle(color: Colors.grey, fontSize: 10.0),),
                          ],
                        ),

                        new Padding(padding: new EdgeInsets.all(1.0),
                          child:  new Text(snapshot.value['comment'],softWrap: true,),
                        ),


                      ],
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
                    ),
          ((snapshot.value['fromId'] != globals.id) && userIsViewingThemseves ) ? new IconButton(icon: new Icon(Icons.reply,color: Colors.grey,), onPressed: (){
            setState(() {
              textfieldVisible = true;
              commentController.text = '@${snapshot.value['fromName']} ';
              recipientToComment = snapshot.value['fromId'];
            });


                    }) : new Container(),
                  ],
                ),
             );
        });
    }

  String getDateOfMsg(Map comment){

    String date = '';
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    DateTime recentMsgDate = formatter.parse(comment['date']);
    var dayFormatter = new DateFormat('EEEE');
    var shortDatFormatter = new DateFormat('M/d/yy');
    var timeFormatter = new DateFormat('h:mm a');
    var now = new DateTime.now();
    Duration difference = now.difference(recentMsgDate);
    var differenceInSeconds = difference.inSeconds;
    if(differenceInSeconds < 604800){
      // msg is less than a week old
      if(differenceInSeconds < 86400){
        date = timeFormatter.format(recentMsgDate);
      }else{
        date = dayFormatter.format(recentMsgDate);
      }
    }else{
      date = shortDatFormatter.format(recentMsgDate);
    }
    return date;
  }



  void showProfileSheet(String id)async {
    if(widget.id == id){
      return;
    }
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child('posts').child(id).once();
    Map post = snap.value;
    Navigator.push(context,
        new MaterialPageRoute(builder: (context) => new UserProfile(postInfo: post)));

  }

  }




//
//void chatWithUser(String recipID, String recipFullName, String recipImgURL, BuildContext context)async{
//  // need to do a bunch of stuff here....
//  // first need to figure out if these two users have a convo going already
//  // if they do, we need to get the convoID, and pass it to the msgscreen
//  // if they do not, we need to create a new convo for both users
//
//  if(recipID == globals.id){
//    return;
//  }
//
//  DatabaseReference ref = FirebaseDatabase.instance.reference();
//  DataSnapshot convoListSnap = await ref.child('convoLists').child(globals.id).child(recipID).once();
//
//  if(convoListSnap.value != null){
//    // the user has a convo going with selected user
//
//    final convoInfo = convoListSnap.value;
//
//
//
//    Navigator.push(context, new MaterialPageRoute(builder: (context) => new ChatScreen(convoInfo['recipID'], convoInfo['convoID'], false, recipImgURL, recipFullName)));
//  }else{
//    // the user  does not have a convo going with the selected user
//
//    // we will create the convo node, then, get the info, and pass it to the chat screen
//
//    var convoID = ref.child('convoLists').child(globals.id).child(recipID).push().key;
////
////    Map convoInfoForSender = {'recipID':recipID,'convoID':convoID, 'time':convoID, 'imgURL':recipImgURL,
////      'recipFullName': recipFullName};
////    ref.child('convoLists').child(globals.id).child(recipID).set(convoInfoForSender);
////
////    Map convoInfoForRecipient = {'recipID':globals.id,'convoID':convoID, 'time':convoID, 'imgURL':globals.imgURL, 'recipFullName':globals.id};
////    ref.child('convoLists').child(recipID).child(globals.id).set(convoInfoForRecipient);
//
//
//    Navigator.push(context, new MaterialPageRoute(builder: (context) => new ChatScreen(recipID, convoID, true, recipImgURL, recipFullName)));
//
//
//  }
//
//}
//
//






