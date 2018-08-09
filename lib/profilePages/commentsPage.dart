import 'package:flutter/material.dart';
import '../homePage/chatList.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../globals.dart' as globals;
import '../profilePages/profilePage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class commentsPage extends StatefulWidget {


final String id;
final String commentKey;


commentsPage({this.id,this.commentKey});
  _commentsPageState createState() => new _commentsPageState();


}
class _commentsPageState extends State<commentsPage> {
  String logoURL = "https://is4-ssl.mzstatic.com/image/thumb/Purple125/v4/b2/a7/91/b2a7916a-35be-5a7e-4c91-45317fb40d9c/AppIcon-1x_U007emarketing-0-0-GLES2_U002c0-512MB-sRGB-0-0-0-85-220-0-0-0-3.png/246x0w.jpg";
  FocusNode commentNode = new FocusNode();
  TextEditingController commentController = new TextEditingController();
  bool userHasComments = true;
  DataSnapshot postSnap;
  bool commentKeyIsUpdated = true;



  void initState() {
    super.initState();
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    grabPost(widget.id);
  }




  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          backgroundColor: Colors.yellowAccent,
          iconTheme: new IconThemeData(color: Colors.black),
          title: new Text('Comments', style: new TextStyle(color: Colors.black),),
        ),
        body: new ListView(
          children: <Widget>[
            new Container(
                child: (postSnap != null) ? PostCell(postSnap) : new Container()
            ),
           commentInputBox(),
           (postSnap != null)  ? new Container(
             height: (!checkIfCommentKeyIsUpdated(postSnap.value)) ? 200.0 : MediaQuery.of(context).size.height,
             width: double.infinity,
             child: (checkIfCommentKeyIsUpdated(postSnap.value)) ? commentStream(widget.commentKey) : checkIfPostIsUpdated(postSnap.value) ? commentStream(postSnap.value['key']) : commentStream("${postSnap.value['key']}expired"),
           ) : new Container(),

            (postSnap != null) ?   (!checkIfCommentKeyIsUpdated(postSnap.value)) ? new Column(
          children: <Widget>[
            expiredBar(),
            new Container(
              height: 500.0,
              width: double.infinity,
              child: commentStream(widget.commentKey),
            )
          ],
        ) : new Container() : new Container(),


          ],
        )
    );
  }







  Future<void>grabPost(String id)async{
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child(globals.cityCode).child('posts').child(id).once();
    setState(() {
      postSnap = snap;
    });
  }



  bool checkIfCommentKeyIsUpdated(Map post){
    if(post['key'] == widget.commentKey && checkIfPostIsUpdated(post)){
      return true;
    }
    if("${post['key']}expired" == widget.commentKey && !checkIfPostIsUpdated(post)){
      return true;
    }

    return false;
  }


  bool checkIfPostIsUpdated(Map post) {
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    return checkDate(post['leaveDate']);
    
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

  void sendComment(String key,String comment, String postId,bool expired)async {
    await grabUserInfo();
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    String now = formatter.format(new DateTime.now());
    Map msg = {
      'time':now,
      'comment': comment,
      'sender': globals.id,
      'imgURL': globals.imgURL,
      'fullName': globals.fullName,
      'postId':postId
    };
    await ref.child('comments').child(key).push().set(msg);
    await incrementCommentCount(postId, expired);
    
  }


  Future<void> incrementCommentCount(String postId,bool expired)async {

    if(!expired){
      DatabaseReference ref = FirebaseDatabase.instance.reference();
      DataSnapshot snap = await ref.child(globals.cityCode).child('posts').child(postId).child('commentCount').once();
      if(snap.value != null){
        int incremented = snap.value + 1;
        ref.child(globals.cityCode).child('posts').child(postId).child('commentCount').set(incremented);
      }else{
        ref.child(globals.cityCode).child('posts').child(postId).child('commentCount').set(1);
      }
    }else{
      DatabaseReference ref = FirebaseDatabase.instance.reference();
      DataSnapshot snap = await ref.child(globals.cityCode).child('posts').child(postId).child('expiredCommentCount').once();
      if(snap.value != null){
        int incremented = snap.value + 1;
        ref.child(globals.cityCode).child('posts').child(postId).child('expiredCommentCount').set(incremented);
      }else{
        ref.child(globals.cityCode).child('posts').child(postId).child('expiredCommentCount').set(1);
      }
    }
  }
  
  

  Future<void> grabUserInfo() async {
    if(globals.imgURL != null && globals.fullName != null){
      return;
    }
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child(globals.cityCode).child('userInfo').child(globals.id).once();
    setState(() {
      globals.fullName = snap.value['fullName'];
      globals.imgURL = snap.value['imgURL'];
    });
  }




 

  String getDateOfMsg(String time){

    String date = '';
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    DateTime recentMsgDate = formatter.parse(time);
    var dayFormatter = new DateFormat('EEEE');
    var shortDatFormatter = new DateFormat('M/d/yy');
    var timeFormatter = new DateFormat('h:mm a');
    var now = new DateTime.now();
    Duration difference = now.difference(recentMsgDate);
    var differenceInSeconds = difference.inSeconds;
    // msg is less than a week old
    if(differenceInSeconds < 86400){
      date = timeFormatter.format(recentMsgDate);
    }else{
      date = shortDatFormatter.format(recentMsgDate);
    }
    return date;
  }






  String formatDateForCellTitle(String date) {
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var postDate = formatter.parse(date);

    var shortDateFormatter = new DateFormat('M/d');
    var newDate = shortDateFormatter.format(postDate);

    return newDate;
  }

  Widget expiredBar(){
    return  new Container(
      height: 30.0,
      width: double.infinity,
      color: Colors.red,
      child: new Center(
        child: Text('Comments are Expired',style: new TextStyle(color: Colors.white),),
      ),
    );
  }


  Widget FeedCellTitle(Map post) {
    String date = formatDateForCellTitle(post['leaveDate']);
    bool updated = checkIfPostIsUpdated(post);
    var fromHomeCity = true;

    // first check if the user is leaving from their home city, and the post is still up to date!!!
    if(post.containsKey('fromHome')){
      if(!(post['fromHome']) && checkIfPostIsUpdated(post)){

        fromHomeCity = false;
      }
    }


    if (post['riderOrDriver'] == 'Riding') {
      return new RichText(
        maxLines: 1,
        textAlign: TextAlign.left,
        overflow: TextOverflow.clip,
        text: new TextSpan(
            style: new TextStyle(fontSize: 14.0, color: Colors.black),
            children: <TextSpan>[

              new TextSpan(text: post['name'],
                  style: new TextStyle(fontWeight: FontWeight.bold)),
              updated ? new TextSpan(text: ' needs a ') : new TextSpan(
                  text: ' usually needs a '),
              new TextSpan(text: 'ride',
                  style: new TextStyle(fontWeight: FontWeight.bold)),


              (fromHomeCity) ? new TextSpan(text: ' to ') : new TextSpan(text: ' back from '),
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

              new TextSpan(text: post['name'],
                  style: new TextStyle(fontWeight: FontWeight.bold)),
              updated ? new TextSpan(text: ' is ') : new TextSpan(
                  text: ' usually '),
              updated
                  ? new TextSpan(text: 'driving',
                  style: new TextStyle(fontWeight: FontWeight.bold))
                  : new TextSpan(text: 'drives',
                  style: new TextStyle(fontWeight: FontWeight.bold)),
              (fromHomeCity) ? new TextSpan(text: ' to ') : new TextSpan(text: ' back from '),
              new TextSpan(text: '${post['destination']}, ${post['state']}',style: new TextStyle(fontWeight: FontWeight.bold) ),
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


  Widget commentInputBox(){
    return new Container(
      margin: const EdgeInsets.symmetric(horizontal: 9.0),
      width:double.infinity,
      child: new TextField(
        controller: commentController,
        focusNode: commentNode,
        decoration: new InputDecoration(hintText: 'Enter a Comment!',suffixIcon: new IconButton(icon: new Icon(Icons.send), onPressed: (){
          if(commentController.text != null){
            if(commentController.text != "" && widget.id != null){
              if(checkIfPostIsUpdated(postSnap.value)){
                sendComment(postSnap.value['key'], commentController.text,postSnap.key ,false);
              }else{
                sendComment("${postSnap.value['key']}expired",commentController.text,postSnap.key, true);
              }
              commentController.clear();
              commentNode.unfocus();

            }
          }

        })),
      ),

    );
  }



  Widget PostCell(DataSnapshot snapshot){
    return  new Padding(padding: new EdgeInsets.all(10.0),

        child: new Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new InkWell(
                child: Padding(
                  padding: new EdgeInsets.all(5.0),
                  child: new CircleAvatar(backgroundImage: new CachedNetworkImageProvider(snapshot.value['imgURL']),radius: 30.0,backgroundColor: Colors.transparent,),
                ),
                onTap: (){
                  Navigator.push(context, new MaterialPageRoute(builder: (context) => new ProfilePage(id: snapshot.key,profilePicURL: snapshot.value['imgURL'])));
                },
              ),
              new Expanded(
                  child: new Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      new FittedBox(
                        child: new Container(
                            child: new Padding(padding: new EdgeInsets.only(top: 5.0),

                              child: FeedCellTitle(snapshot.value),
                            )
                        ),
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                      ),
                      new Row(
                        children: <Widget>[
                          (snapshot.value['time'] != null) ? new Icon(Icons.language, size: 12.0,color: Colors.grey[600],) : new Container(),
                          new Text((snapshot.value['time'] != null) ? "Updated ${getDateOfMsg(snapshot.value['time'])}" : '', style: new TextStyle(fontSize: 11.0,color: Colors.grey[600]),),
                        ],
                      ),
                      new Padding(
                        padding: new EdgeInsets.only(
                            left: 7.0, top: 7.0, right: 7.0, bottom: 2.0),
                        child: checkIfPostIsUpdated(snapshot.value) ? new Text(snapshot.value['post'], style: new TextStyle(fontSize: 20.0,color: Colors.grey[800])) : new Text(''),
                      ),
                      new Row(
                        children: <Widget>[


                        ],
                      )
                    ],
                  )
              ),
            ],
          ),
        )
    );
  }



  Widget commentStream(String key){
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    Query falQuery = ref.child('comments').child(key).orderByKey();

    return new Container(
      child: FirebaseAnimatedList(
          query: falQuery,
          defaultChild: new Center(
            child: new CircularProgressIndicator(),
          ),
          padding: new EdgeInsets.all(8.0),
          reverse: false,
          sort: (a, b) => (a.key.compareTo(b.key)),
          itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, ___) {
            // here we can just look up every user from the snapshot, and then pass it into the chat message
            Map post = snapshot.value;

            return new Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Padding(
                    padding: new EdgeInsets.only(left: 5.0, top: 2.0, right: 3.0),
                    child:new InkWell(
                      child:  new CircleAvatar(backgroundColor: Colors.transparent,radius: 20.0,
                        backgroundImage: new CachedNetworkImageProvider(snapshot.value['imgURL']),
                      ),
                      onTap: (){
                        Navigator.push(context, new MaterialPageRoute(builder: (context) => new ProfilePage(id: snapshot.value['sender'],profilePicURL: snapshot.value['imgURL'])));
                      },
                    )



                ),
                new Expanded(
                    child: new Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        new FittedBox(
                          child: new Container(
                              child: new Text(snapshot.value['fullName'],style: new TextStyle(fontWeight: FontWeight.bold),)
                          ),
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                        ),
                        new Text(getDateOfMsg(snapshot.value['time']),style: new TextStyle(fontSize: 11.0, color: Colors.grey[600]),),
                        new Padding(
                            padding: new EdgeInsets.only(
                                left: 3.0, top: 3.0, right: 7.0, bottom: 8.0),
                            child: new Text(snapshot.value['comment'])
                        ),
                      ],
                    )
                ),
              ],
            );

          })
    );
  }




} 

//
//  Widget _buildComposer() {
//
//    return new IconTheme(
//      data: new IconThemeData(color: Colors.yellowAccent),
//      child: new Container(
//
//          margin: const EdgeInsets.symmetric(horizontal: 9.0),
//          child: new Row(
//            children: <Widget>[
//
//              new Flexible(
//                child: new TextField(
//                  maxLines: null,
//                  focusNode: txtInputFocusNode,
//                  controller: _textController,
//                  onChanged: (String txt){
//                    setState(() {
//                      _isWriting = true;
//
//                    });
//                  },
//                  onSubmitted: _submitMsg,
//                  decoration: new InputDecoration.collapsed(hintText: 'Enter a Message!'),
//                ),
//              ),
//              new Container(
//                  margin: new EdgeInsets.symmetric(horizontal: 3.0),
//                  child: Theme.of(context).platform == TargetPlatform.iOS ?
//                  new CupertinoButton(
//                      child: new Text('submit'),
//                      onPressed: (_isWriting && _textController.text != null) ? () => _submitMsg(_textController.text): (){}
//                  ) : new IconButton(
//                    icon: new Icon(Icons.message),
//                    onPressed: (_isWriting && _textController.text != null) ? () => _submitMsg(_textController.text) : (){},
//                  )
//              )
//            ],
//          ),
//          decoration: Theme.of(context).platform == TargetPlatform.iOS ?
//          new BoxDecoration(
//              border: new Border(top: new BorderSide(color: Colors.grey, width: 0.5))) : null
//      ),
//    );
//
//  }
//
//}
//
//
//

//
//class ExpansionTileSample extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      home: Scaffold(
//        appBar: AppBar(
//          title: const Text('ExpansionTile'),
//        ),
//        body: ListView.builder(
//          itemBuilder: (BuildContext context, int index) =>
//              EntryItem(data[index]),
//          itemCount: data.length,
//        ),
//      ),
//    );
//  }
//}
//
//// One entry in the multilevel list displayed by this app.
//class Entry {
//  Entry(this.title, [this.children = const <Entry>[]]);
//
//  final String title;
//  final List<Entry> children;
//}
//
//// The entire multilevel list displayed by this app.
//final List<Entry> data = <Entry>[
//  Entry(
//    'Chapter A',
//    <Entry>[
//      Entry(
//        'Section A0',
//        <Entry>[
//          Entry('Item A0.1'),
//          Entry('Item A0.2'),
//          Entry('Item A0.3'),
//        ],
//      ),
//      Entry('Section A1'),
//      Entry('Section A2'),
//    ],
//  ),
//  Entry(
//    'Chapter B',
//    <Entry>[
//      Entry('Section B0'),
//      Entry('Section B1'),
//    ],
//  ),
//  Entry(
//    'Chapter C',
//    <Entry>[
//      Entry('Section C0'),
//      Entry('Section C1'),
//      Entry(
//        'Section C2',
//        <Entry>[
//          Entry('Item C2.0'),
//          Entry('Item C2.1'),
//          Entry('Item C2.2'),
//          Entry('Item C2.3'),
//        ],
//      ),
//    ],
//  ),
//];
//
//// Displays one Entry. If the entry has children then it's displayed
//// with an ExpansionTile.
//class EntryItem extends StatelessWidget {
//  const EntryItem(this.entry);
//
//  final Entry entry;
//
//  Widget _buildTiles(Entry root) {
//    if (root.children.isEmpty) return ListTile(title: Text(root.title));
//    return ExpansionTile(
//      key: PageStorageKey<Entry>(root),
//      title: Text(root.title),
//      children: root.children.map(_buildTiles).toList(),
//    );
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return _buildTiles(entry);
//  }
//}