import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';

import '../globals.dart' as globals;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'feedStream.dart';
import 'profileSheet.dart';
import '../Chat/msgScreen.dart';
import 'chatList.dart';
import 'package:intl/intl.dart';
import '../profilePages/profilePage.dart';

class chatListStream extends StatelessWidget {


  GlobalKey<ScaffoldState> scaffoldKey;
  final UIcallback actionButtonCallback;
  final UIcallback updateChatListCallback;
   List<Map> feed = List<Map>();

  DatabaseReference ref = FirebaseDatabase.instance.reference();

  chatListStream(this.scaffoldKey, this.actionButtonCallback, this.updateChatListCallback, );

  @override
  Widget build(BuildContext context) {
    return new Container(
      child:buildFirebaseList(context),

    );
  }



    String getTime(DataSnapshot snap){
    Map info = snap.value;
    return info['time'];
    }




  FirebaseAnimatedList buildFirebaseList(BuildContext context)  {
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    print(globals.id);
   final falQuery = ref.child('convoLists').child(globals.id).orderByChild('time');

    return new FirebaseAnimatedList(
        query: falQuery,
         defaultChild: new Center(
           child: new CircularProgressIndicator(),
         ),
        // THIS IS WHY I LIKE CS
         sort: (DataSnapshot a, DataSnapshot b) => (a.value['convoID'] != globals.id && b.value['convoID'] == globals.id) ? 1 : (a.value['convoID'] == globals.id) ? -1 : getTime(b).compareTo(getTime(a)),
        reverse: false,
        itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, ___) {
          return ConvoCell(snapshot.value,context, snapshot.value['new']);

        });
  }


  String getDateOfMsg(Map convoInfo){

    String date = '';
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    DateTime recentMsgDate = formatter.parse(convoInfo['formattedTime']);
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





  Widget ConvoCell(Map convoInfo, BuildContext context,bool unread ){
    return new InkWell(
    child: new Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        new Row( // nested rows im feeling like collin jackson rn
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                new Padding(padding: new EdgeInsets.all(5.0),
                  child: new CircleAvatar(
                    radius: 5.0,
                    backgroundColor: (unread) ? Colors.yellowAccent : Colors.white,
                  ),
                ),
                new InkWell(
                  child: (convoInfo['imgURL'] != null) ? new CircleAvatar(
                    radius: 30.0,
                    backgroundColor: Colors.transparent,
                    backgroundImage: new NetworkImage(convoInfo['imgURL']),
                  ) : new Container(),
                  onTap: (){
                    User user = new User(convoInfo['recipFullName'], convoInfo['recipID'], convoInfo['imgURL']);
                    if(convoInfo['convoID'] != globals.id){
                      showProfilePage(user,context);
                    }
                  },
                )
              ],
            ),
            new Expanded(child: new Padding(padding: new EdgeInsets.only(left: 5.0),
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Text(convoInfo['recipFullName'],style: new TextStyle(fontWeight: FontWeight.bold),),
                    new Padding(padding: new EdgeInsets.only(top: 2.0),
                      child: new Text(convoInfo['recentMsg'],style: new TextStyle(color: Colors.grey),maxLines: 1,overflow: TextOverflow.ellipsis,),
                    )
                  ],
                )

            ),),
            new Padding(padding: new EdgeInsets.only(right: 5.0),
              child: new Text((convoInfo['formattedTime'] != null) ? getDateOfMsg(convoInfo) : 'Anytime!',style: new TextStyle(color: Colors.grey) )
            )
          ],
        ),
        new Divider()
      ],
    ),
      onTap: (){
        // show the message screen
        Navigator.push(context,
            new MaterialPageRoute(builder: (context) => new ChatScreen(convoID: convoInfo['convoID'],newConvo: false,recipFullName: convoInfo['recipFullName'],recipID: convoInfo['recipID'],recipImgURL: convoInfo['imgURL'])));
      },
    );
  }


  void showProfilePage(User user, BuildContext context)async{
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    // DataSnapshot postSnap = await ref.child(globals.cityCode).child(id).once();

    Navigator.push(context,
        new MaterialPageRoute(builder: (context) => new ProfilePage(id: user.id,profilePicURL: user.imgUrl,firstName: '',fullName: user.fullName)));
  }

  
}







// class ChatMessage extends StatelessWidget {
//   final DataSnapshot snapshot;
//   final Animation animation;
//   String imgURL;

//   ChatMessage({this.snapshot, this.animation, this.imgURL});



//   @override
//   Widget build(BuildContext context) {
//     return new SizeTransition(
//         sizeFactor:
//             new CurvedAnimation(parent: animation, curve: Curves.easeOut),
//         axisAlignment: 0.0,
//         child: new InkWell(
//          // margin: const EdgeInsets.symmetric(vertical: 10.0),
//           child: new Image.network(imgURL),
//           onTap: (){
//               print(snapshot.value.toString());
            
//           },
          
//         ));
//   }

  
// }

//
//class ConvoCell extends StatefulWidget{
//
//
//  Map convoInfo;
//
//  String imgURL;
//  Color read = Colors.black;
// GlobalKey<ScaffoldState> scaffoldKey;
// final UIcallback actionButtonCallback;
// final UIcallback updateChatListCallback;
//
//
//
//
//
//
// ConvoCell({this.convoInfo, this.scaffoldKey, this.actionButtonCallback, this.updateChatListCallback});
//
//  _ConvoCellState createState() => new _ConvoCellState();
//
//
//
//}
//
//
//class _ConvoCellState extends State<ConvoCell> {
//  Map convoInfo = {};
//  PersistentBottomSheetController controller;
//
//   void initState() {
//    super.initState();
//
//    convoInfo = widget.convoInfo;
//   }
//
//
//
//
//  @override
//  void dispose() {
//    // Clean up the controller when the Widget is removed from the Widget tree
//
//   super.dispose();
//  }
//
//
//    @override
//  Widget build(BuildContext context) {
//
//        return new InkWell(
//         // margin: const EdgeInsets.symmetric(vertical: 10.0),
//          child: new Container(
//            child: new Row(
//              children: <Widget>[
//            new Container(
//            decoration: new BoxDecoration(
//              color: Colors.yellow,
//              shape: BoxShape.circle,
//            ),
//              height: 10.0,
//              width: 10.0,
//            ),
//                new Padding(
//                    padding: new EdgeInsets.all(10.0),
//                  child:   new CircleAvatar(
//                    backgroundImage: new NetworkImage(convoInfo['imgURL']),
//                  ),
//
//                ),
//
//                new Column(
//                  children: <Widget>[
//                    new Text(convoInfo['recipFullName'], style: new TextStyle(fontWeight: FontWeight.bold),),
//                    new Text(convoInfo['recentMsg'],style: new TextStyle(color: Colors.grey), )
//                  ],
//                )
//
//
//
//
//
//              ],
//            ),
//          ),
//          onTap: (){
//             // show the message screen
//
//
//
//
//
//
//
//            Navigator.push(context,
//                new MaterialPageRoute(builder: (context) => new ChatScreen(convoInfo['recipID'], convoInfo['convoID'], false, convoInfo['recipImgURL'],convoInfo['recipFullName'])));
//
//
//
//          },
//
//        );
//
//
//  }
//
//
//
//  void getRecipInfo(String recip) async {
//
//  //   DataSnapshot snap = await FirebaseDatabase.instance.reference().child('userInfo').
//  }
//
//
//  void showProfileSheet(){
//     widget.actionButtonCallback();
//
//     User user = new User(widget.convoInfo['recipFullName'], widget.convoInfo['id'], widget.convoInfo['imgURL']);
//
//    controller = widget.scaffoldKey.currentState.showBottomSheet((context) {
//      return ProfileSheet(user, controller, context, widget.scaffoldKey, widget.updateChatListCallback);
//    });
//
//    controller.closed.then((val){
//      widget.actionButtonCallback();
//
//    });
//
//
//
//  }
//
//}


//            new Padding(
//              padding: new EdgeInsets.only(left: 10.0),
//              child: new Container(
//                height: 50.0,
//                width: 50.0,
//                child:new CircleAvatar(
//                  backgroundImage: new NetworkImage(convoInfo['imgURL']),
//                  backgroundColor: Colors.transparent,
//                ),
//              ),
//            ),
//  new Expanded(
//                child: new Row(
//                  crossAxisAlignment: CrossAxisAlignment.start,
//            children: <Widget>[
//              new Expanded(child: Column(
//                mainAxisSize: MainAxisSize.max,
//                crossAxisAlignment: CrossAxisAlignment.start,
//                mainAxisAlignment: MainAxisAlignment.start,
//                children: <Widget>[
//                  Container(
//                    padding: new EdgeInsets.only(left: 8.0),
//                    child: new Text(convoInfo['recipFullName'], style: new TextStyle(fontWeight: FontWeight.bold),),
//                  ),
//                  Container(
//                      padding: new EdgeInsets.only(left: 8.0),
//                      child: new Text(convoInfo['recentMsg'],style: new TextStyle(color: Colors.grey),textAlign: TextAlign.left, )
//                  ),
//                ],
//              ),
//
//              ),
//    new Text(getDateOfMsg(convoInfo), style: new TextStyle(color: Colors.grey)),
//    ],
//    )
//
//
//
//
//
//            ),

//Widget buildList(){
//  DatabaseReference ref = FirebaseDatabase.instance.reference();
//  final listStream = ref.child('convoLists').child(globals.id).orderByChild('time').onValue;
//
//  return new StreamBuilder(
//    stream: listStream,
//
//    builder: (BuildContext context, AsyncSnapshot<Event> snapshot) {
//
//
//      if(snapshot.hasData){
//        feed.clear();
//        Map val = snapshot.data.snapshot.value;
//        val.forEach((key,val){
//          feed.add(val);
//        });
//        List<Map> reversedFeed = [];
//        int i = 0;
//
//        // the 'reversed' function returns an 'iterable', and i cant find an easy way to do this...
////        for(i=feed.length - 1;i>=0;i-=1){
////          reversedFeed.add(feed[i]);
////        }
//        return new ListView.builder(
//            itemCount:feed.length,
//            itemBuilder: (context, index){
//
//              //  reversedFeed.insert(0, reversedFeed[index]);
//              return ConvoCell(feed[index], context,true );
//            });
//      }else{
//        return new Container(
//          // return loading screen here
//          height: 50.0,
//          width: 50.0,
//          color: Colors.yellow,
//        );
//      }
//    },
//  );
//}