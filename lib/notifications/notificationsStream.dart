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
import '../homePage/profileSheet.dart';
import 'notificationsPage.dart';
import '../profilePages/commentsPage.dart';
import '../profilePages/profilePage.dart';


FirebaseAnimatedList buildNotificationsStream(BuildContext context)  {
  DatabaseReference ref = FirebaseDatabase.instance.reference();
  final falQuery = ref.child('notifications').child(globals.id).orderByKey();

  return new FirebaseAnimatedList(
      query: falQuery,

      defaultChild: new Center(
        child: new CircularProgressIndicator(),
      ),
      padding: new EdgeInsets.all(8.0),
      sort: (a, b) => (b.key.compareTo(a.key)),
      reverse: false,
      itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, ___) {
        // here we can just look up every user from the snapshot, and then pass it into the chat message
        Map notificaiton = snapshot.value;
        return (notificaiton['type'] == 'ride') ? rideNotificationCell(notificaiton, context) : commentNotificationCell(notificaiton, context);


      });
}


Widget rideNotificationCell(Map notification, BuildContext context){
  return new Container(



      child: new Card(
          child: new InkWell(
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                new InkWell(
                  child:new Padding(padding:new EdgeInsets.all(5.0),
          child:  new CircleAvatar(
            backgroundImage: new NetworkImage(notification['imgURL']),
          ),
          ),
                  onTap: (){
                    Navigator.push(context, new MaterialPageRoute(builder: (context) => new ProfilePage(id: notification['id'],profilePicURL: notification['imgURL'],)));
                  },
                ),
                new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[

                    new Padding(padding: new EdgeInsets.all(5.0),
                      child: new RichText(text: new TextSpan(
                        style: new TextStyle(fontSize: 14.0, color: Colors.black),
                        children: <TextSpan>[
                          new TextSpan(text: notification['fullName'], style: new TextStyle(fontWeight: FontWeight.bold)),
                          new TextSpan(text: notification['message']),
                        ],
                      ),)

                    ),
                    new Padding(padding: new EdgeInsets.only(left: 5.0),
                      child: new Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          new Icon(Icons.language, color: Colors.grey,size: 10.0,),
                          Text(getDateOfMsg(notification), style: new TextStyle(color: Colors.grey, fontSize: 10.0),),
                        ],
                      ),
                    ),
                    new Divider()
                  ],
                )
              ],
            ),
            onTap: (){
              showProfilePage(notification['id'], context);
            },
          )
      )


  );
}


Widget commentNotificationCell(Map notification, BuildContext context){
  return new Container(



    child: new Card(
      child: new InkWell(
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new InkWell(
              child: new Padding(padding:new EdgeInsets.all(5.0),
                child:  new CircleAvatar(
                  backgroundImage: new NetworkImage(notification['imgURL']),
                  radius: 30.0,
                  backgroundColor: Colors.transparent,
                ),
              ),
              onTap: (){
                Navigator.push(context, new MaterialPageRoute(builder: (context) => new ProfilePage(id: notification['id'],profilePicURL: notification['imgURL'],)));
              },
            ),
            new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[

                new Padding(padding: new EdgeInsets.all(5.0),
                  child: new RichText(text: new TextSpan(
                    style: new TextStyle(fontSize: 14.0, color: Colors.black),
                     children: <TextSpan>[
                       new TextSpan(text: notification['name'], style: new TextStyle(fontWeight: FontWeight.bold)),
                       new TextSpan(text: ' left a comment!'),


                     ],
                  ),)

                  //new Text('${notification['name']} left a comment!'),
                ),
                new Padding(padding: new EdgeInsets.only(left: 5.0),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      new Icon(Icons.language, color: Colors.grey,size: 10.0,),
                      Text(getDateOfMsg(notification), style: new TextStyle(color: Colors.grey, fontSize: 10.0),),
                    ],
                  ),
                ),
                new Divider()
              ],
            )
          ],
        ),
        onTap: (){
          showProfilePage(notification['id'], context);
        },
      )
    )


  );
}

String getDateOfMsg(Map notification){

  String date = '';
  var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
  DateTime recentMsgDate = formatter.parse(notification['time']);
  var dayFormatter = new DateFormat('EEEE');
  var shortDatFormatter = new DateFormat('M/d/yy');
  var timeFormatter = new DateFormat('h:mm a');
  var now = new DateTime.now();
  Duration difference = now.difference(recentMsgDate);
  var differenceInSeconds = difference.inSeconds;
  if(differenceInSeconds < 604800){
    // msg is less than a week old
    final lastMidnight = new DateTime(now.year, now.month, now.day);
    if(differenceInSeconds < 86400 && recentMsgDate.isAfter(lastMidnight)){
      date = timeFormatter.format(recentMsgDate);
    }else{
      date = dayFormatter.format(recentMsgDate);
    }
  }else{
    date = shortDatFormatter.format(recentMsgDate);
  }
  return date;
}


void showProfilePage(String id, BuildContext context)async{


  Navigator.push(context,
      new MaterialPageRoute(builder: (context) => new commentsPage(id: id)));
}


//Widget rideNotificationCell(Map notification,BuildContext context){
//  return new Container(
//      child: new InkWell(
//        child: new Card(
//          child: new Row(
//            children: <Widget>[
//              new Padding(
//                padding: new EdgeInsets.all(10.0),
//                child:     new CircleAvatar(
//                  backgroundImage: new NetworkImage(notification['imgURL']),
//                ),
//              ),
//
//              new Column(
//                children: <Widget>[
//                  new Text(notification['message'])
//                ],
//              )
//            ],
//          ),
//        ),
//        onTap: (){
//          // push the users profile
//          showProfilePage(notification['id'], context);
//        },
//      )
//
//
//
//  );
//}
