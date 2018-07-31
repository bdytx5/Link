import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../globals.dart' as globals;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import '../homePage/feedStream.dart';



//class Msg extends StatelessWidget{
//  Msg(this.txt,this.imgURL,this.name,this.animationController, this.time );
//final String txt;
//final String imgURL;
// final String name;
// final String time;
//
//final AnimationController animationController;
//
//
//
//@override
//Widget build(BuildContext context){
//  return
////    new SizeTransition(
////     sizeFactor: new CurvedAnimation(parent: animationController, curve: Curves.bounceOut,),
////     axisAlignment: 0.0,
////      child:
//
// new Container(
//
//      margin: const EdgeInsets.symmetric(vertical: 8.0),
//      child: new Row(
//        crossAxisAlignment: CrossAxisAlignment.start,
//        children: <Widget>[
//          new Container(
//            margin: const EdgeInsets.only(right: 18.0),
//            child: new CircleAvatar(
//              backgroundImage: new NetworkImage(imgURL),
//
//            ),
//          ),
//          new Expanded(
//            child: new Column(
//              crossAxisAlignment: CrossAxisAlignment.start,
//              children: <Widget>[
//                    new Text(name),
//                    new Padding(padding: new EdgeInsets.all(0.5),
//                      child: new Row(
//                        crossAxisAlignment: CrossAxisAlignment.center,
//                        children: <Widget>[
//                        //  new Icon(Icons.language, color: Colors.grey,size: 10.0,),
//                          Text(getDateOfMsg(time), style: new TextStyle(color: Colors.grey, fontSize: 8.0),),
//                        ],
//                      ),
//                    ),
//
//                new Container(
//                  margin: const EdgeInsets.only(top: 6.0),
//                  child: new Text(txt),
//                )
//              ],
//            ),
//          )
//        ],
//      ),
//  );
//}

//String getDateOfMsg(String time){
//
//  String date = '';
//  var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
//  DateTime recentMsgDate = formatter.parse(time);
//  var dayFormatter = new DateFormat('EEEE');
//  var shortDatFormatter = new DateFormat('M/d/yy');
//  var timeFormatter = new DateFormat('h:mm a');
//  var now = new DateTime.now();
//  Duration difference = now.difference(recentMsgDate);
//  var differenceInSeconds = difference.inSeconds;
//  // msg is less than a week old
//  if(differenceInSeconds < 86400){
//    date = timeFormatter.format(recentMsgDate);
//  }else{
//    date = shortDatFormatter.format(recentMsgDate);
//  }
//  return date;
//}
//}





Widget Msg(String url){
  return new Container(
    child: new Image(image: new NetworkImage(url)),
  );
}



class chatStream extends StatelessWidget {
  String convoID;
  UIcallback dismissKeyboardCallback;
  AnimationController animationController;
  ScrollController listController = new ScrollController();
  final GlobalKey<AnimatedListState> _listKey = new GlobalKey<AnimatedListState>();
  chatStream(this.convoID, this.animationController, this.dismissKeyboardCallback);


  @override
  Widget build(BuildContext context) {


    listController.addListener((){
      dismissKeyboardCallback();
    });
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    Query chatQuery = ref.child('convos').child(convoID).orderByKey();

    //return  buildFirebaseList();

    return new GestureDetector(

      child: new FirebaseAnimatedList(

          controller: listController,
          query: chatQuery,

          //  sort: (DataSnapshot a, DataSnapshot b) => a.key.compareTo(b.key),
          padding: new EdgeInsets.all(8.0),
          reverse: true,

          sort: (a, b) => (b.key.compareTo(a.key)),
          itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, ___) {

            Map msg = snapshot.value;
            //final animationController =  new AnimationController(duration: new Duration(milliseconds: 800), vsync: idk);
            // return new Msg(msg['message'], msg['imgURL'], msg['name'], animationController, msg['formattedTime']);

            return Msg(msg['imgURL']);
          }

      ),
    );
  }





  GestureDetector buildFirebaseList()  {
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    Query chatQuery = ref.child('convos').child(convoID).orderByChild('time');

//    if(convoID=='thumbsOutFeedback'){
//      chatQuery = ref.child('feedback').child(globals.id).orderByChild('time');
//`
//    }else{
//      if(convoID != ''){
//        chatQuery = ref.child('convos').child(convoID).orderByChild('time');
//
//      }



    //}


    return new GestureDetector(

      child: new FirebaseAnimatedList(

          controller: listController,
          query: chatQuery,

          //  sort: (DataSnapshot a, DataSnapshot b) => a.key.compareTo(b.key),
          padding: new EdgeInsets.all(8.0),
          reverse: true,

          sort: (a, b) => (b.key.compareTo(a.key)),
          itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, ___) {

            Map msg = snapshot.value;
            //final animationController =  new AnimationController(duration: new Duration(milliseconds: 800), vsync: idk);
           // return new Msg(msg['message'], msg['imgURL'], msg['name'], animationController, msg['formattedTime']);

            return Msg(msg['imgURL']);
          }

      ),
    );



  }
}


























//
//class chatStream extends StatefulWidget  {
//
//  String convoID;
//  AnimationController anim;
//
//  _chatStreamState createState() => new _chatStreamState();
//  chatStream(this.convoID, this.anim);
//
//}
//
//
//class _chatStreamState extends State<chatStream> {
//
//  void initState() {
//    super.initState();
//  }
//
//
//  @override
//  Widget build(BuildContext context) {
//    return  buildFirebaseList();
//  }
//
//
//  FirebaseAnimatedList buildFirebaseList()  {
//    DatabaseReference ref = FirebaseDatabase.instance.reference();
//    final falQuery = ref.child('convos').child(widget.convoID).orderByChild('time');
//
//    return new FirebaseAnimatedList(
//        query: falQuery,
//        //  sort: (DataSnapshot a, DataSnapshot b) => a.key.compareTo(b.key),
//        padding: new EdgeInsets.all(8.0),
//
//        reverse: false,
//        itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, ___) {
//
//          Map msg = snapshot.value;
//
//          return new Msg(msg['message'], msg['imgURL'], msg['name'], widget.anim);
//        }
//
//    );
//
//
//
//
//
//
//
//  }
//
//}





