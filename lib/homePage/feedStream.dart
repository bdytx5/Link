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
import 'profileSheet.dart';
import 'feed.dart';
import 'chatList.dart';
import '../profilePages/profilePage.dart';
import '../textFieldFix.dart';

import '../postSubmission/postSubmitPopUp.dart';
import '../modifiedExpansionTile.dart';


typedef UIcallback = void Function();

typedef ActionButtonCallback = void Function(bool hidden);


class feedStream extends StatelessWidget {
  StreamSubscription streamSubscription;


  void someMethod(){
    print('hey');
  }


  GlobalKey<ScaffoldState> scaffoldKey;
  final UIcallback actionButtonCallback;
  final UIcallback commentNotificationCallback;
  final StreamController streamController;

    feedStream(this.scaffoldKey, this.actionButtonCallback, this.commentNotificationCallback,this.streamController);
  @override
  Widget build(BuildContext context) {

    return new Container(
      child: buildFeedStream(),

    );
  }





  FirebaseAnimatedList buildFeedStream()  {
//    print(globals.city);
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    final falQuery = ref.child(globals.cityCode).child('posts').orderByChild('key');

    return new FirebaseAnimatedList(
        query: falQuery,

        defaultChild: new CircularProgressIndicator(),
        padding: new EdgeInsets.all(8.0),
        reverse: false,
        sort: (DataSnapshot a, DataSnapshot b) => (a.key != globals.id) ? getTime(b).compareTo(getTime(a)) : -1,
        itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, ___) {
          // here we can just look up every user from the snapshot, and then pass it into the chat message
          Map post = snapshot.value;
                          // current post and ghost mode
          return   ((checkIfPostIsGhosted(snapshot.value)) && (snapshot.key == globals.id)) ? new FeedCell(snapshot: snapshot,animation: animation, imgURL:post['imgURL'], scaffoldKey: this.scaffoldKey, uIcallback: this.actionButtonCallback, commentNotificationCallback: this.commentNotificationCallback, currentUsersPost: true,ghostMode: true,stream: this.streamController.stream,)
              : (!(checkIfPostIsGhosted(snapshot.value)) && (snapshot.key == globals.id)) ? new FeedCell(snapshot: snapshot,animation: animation, imgURL:post['imgURL'], scaffoldKey: this.scaffoldKey, uIcallback: this.actionButtonCallback, commentNotificationCallback: this.commentNotificationCallback, currentUsersPost: true,ghostMode: false,stream: this.streamController.stream,) :
          (!checkIfPostIsGhosted(snapshot.value)) ? new FeedCell(snapshot: snapshot,animation: animation, imgURL:post['imgURL'], scaffoldKey: this.scaffoldKey, uIcallback: this.actionButtonCallback, commentNotificationCallback: this.commentNotificationCallback, currentUsersPost: false,ghostMode: false,stream: this.streamController.stream,) :
          new Container();

        });
    }

}

bool checkIfPostIsGhosted(Map post){
  if(post.containsKey('ghost')){
    var ghostTime = post['ghost'];
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var ghostEndDate = formatter.parse(ghostTime);
    var now = new DateTime.now();
    if(now.isAfter(ghostEndDate)){
      return false;
    }else{
      return true; // user is in ghost mode
    }
  }else{
    return false;
  }
}

String getTime(DataSnapshot snap){
  Map info = snap.value;
  return info['key'];
}


class FeedCell extends StatefulWidget{
  GlobalKey<ScaffoldState> scaffoldKey;

  final DataSnapshot snapshot;
  final Animation animation;
  String imgURL;
  Color read = Colors.black;
  UIcallback uIcallback;
  UIcallback commentNotificationCallback;
  final bool currentUsersPost;
  final bool ghostMode;
  final Stream stream;





  FeedCell({this.snapshot, this.animation, this.imgURL, this.scaffoldKey, this.uIcallback, this.commentNotificationCallback, this.currentUsersPost, this.ghostMode,this.stream});

  _FeedCellState createState() => new _FeedCellState();

  FirebaseApp app;

}

class _FeedCellState extends State<FeedCell> with TickerProviderStateMixin{
  PersistentBottomSheetController controller;
  StreamSubscription streamSubscription;

  AssetImage commentIcon = new AssetImage('assets/comment50.png');

  bool comments = true;
  FocusNode commentNode = new FocusNode();
  String fullName;
  String imgURL;
  

  TextEditingController commentController = new TextEditingController();
  double commentHeight = 40.0;



  void initState() {
    super.initState();
    commentNode.addListener(_onFocusChange);
    
    streamSubscription = widget.stream.listen((_) => someMethod());


  }


  void someMethod(){
    commentNode.unfocus(); // well, it's not pretty but neither is flutter state management...
  }
  void _onFocusChange(){
    widget.uIcallback();
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree

    super.dispose();
  }

  @override
  void didPopNext() {
    // Covering route was popped off the navigator.
  }

  @override
  Widget build(BuildContext context) {
    CurvedAnimation _easeInAnimation;
    Animation<double> _iconTurns;
    const Duration _kExpand = const Duration(milliseconds: 200);

    AnimationController _controller = new AnimationController(duration: _kExpand, vsync: this);

    _easeInAnimation = new CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _iconTurns = new Tween<double>(begin: 0.0, end: 0.25).animate(_easeInAnimation);





    return new SizeTransition(
      sizeFactor: new CurvedAnimation(
          parent: widget.animation, curve: Curves.easeOut),
      // new CurvedAnimation(parent: widget.animation, curve: Curves.easeOut),
      // axisAlignment: 0.0,
      child: new Card(
        color: Colors.white,
        child: new ModifiedExpansionTile(
          children: <Widget>[
            (comments) ? new Container(
              height: checkCommentCountForCommentsContainer(widget.snapshot.value),
              width: double.infinity,
              child: new Column(
                children: <Widget>[
                  new Divider(),
                  // comment input textfield (height does not change!)
                  new Container(
                    height: 34.0,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 9.0),
                    child: new EnsureVisibleWhenFocused(child: new TextField(
                      controller: commentController,
                      focusNode: commentNode,
                      decoration: new InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Add a comment!',
                          suffixIcon: new IconButton(
                              icon: new Icon(Icons.send, color: Colors.grey,size: 18.0,),
                              onPressed: () async{
                                if(commentController.text != null){
                                  if(commentController.text != '' ){
                                    await handleCommentNotificaitonList(widget.snapshot.key);
                                    if(checkDateOfPost(widget.snapshot.value)){
                                      sendComment(widget.snapshot.key, commentController.text);
                                      incrementCommentCount(widget.snapshot.key);
                                    }else{
                                      sendExpiredComment(widget.snapshot.key, commentController.text);
                                      incrementExpiredCommentCount(widget.snapshot.key);
                                    }

                                    commentController.clear();
                                    commentNode.unfocus();
                                  }
                                }
                              })),
                    ), focusNode: commentNode)

                        //focusNode: commentNode)
                  ),
                  // container for comment stream, height changes up to 3 comments, then stays the same!

                  new Container(
                    height: checkCommentCountForCommentsOnly(widget.snapshot.value),
                    width: double.infinity,
                    child: (checkCommentCountForCommentsOnly(widget.snapshot.value) != 1.0) ? (checkDateOfPost(widget.snapshot.value) ? commentStream(widget.snapshot.key) : expiredCommentStream(widget.snapshot.key)) : new Container()
                  )

                ],
              ),
            ) : new Container()

          ],
          initiallyExpanded: false,
          onExpansionChanged: (expanded){
             // fetch comments
            if(expanded){
              _controller.forward();
              setState(() {});
              if(widget.snapshot.key == globals.id){
                widget.commentNotificationCallback();
              }

            }else{
              _controller.reverse();
              if(widget.snapshot.key == globals.id){
                widget.commentNotificationCallback();
              }
            }
          },

          trailing: new Container(  // hack
            height: 0.1,
            width: 0.1,
          ),

       //   leading:

          body: new Container(
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[

              new Column(
                children: <Widget>[
                  new Padding(padding: new EdgeInsets.all(8.0),
                    child:  new InkWell(
                      child: new CircleAvatar(backgroundColor: Colors.transparent,radius: 25.0,
                          backgroundImage: new NetworkImage(widget.imgURL)
                      ),
                      onTap: (){
                        Navigator.push(context, new MaterialPageRoute(builder: (context) => new ProfilePage(id: widget.snapshot.key,profilePicURL: widget.snapshot.value['imgURL'])));
                      },
                    ),
                  ),
                  
                  new Padding(padding: new EdgeInsets.only(top: 5.0),
                  child:  (widget.currentUsersPost) ? new GestureDetector(
                      onTap: ()async{
                        var res = await _editPostWarning('Edit or Ghost Mode?', 'Ghost Mode allows you to hide your post from the Feed.', "Ghost Mode last's two weeks unless renewed");
                        if(res == null){
                          return;
                        }
                        if(res){
                          // show edit post page
                          showDialog(context: context, builder: (BuildContext context) => new PostPopUp(widget.app));
                        }else{
                          // go into ghost mode
                          enterGhostMode();
                        }
                      },
                      child: new Padding(padding: new EdgeInsets.only(right: 10.0),
                        child: new Icon(Icons.mode_edit, size: 17.0,color: Colors.grey[600],),
                      )
                  ) : new Container(),)

                ],
              ),
              new Expanded(
                  child: new Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      new Padding(padding: new EdgeInsets.only(top: 8.0),
                      child: new FittedBox(
                        child: new Container(
                          padding: new EdgeInsets.only(right: 3.0),

                          child: new GestureDetector(
                            child: FeedCellTitle(widget.snapshot.value),
                            onTap: (){
                              showProfileSheet();
                            },
                          ),
                        ),
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                      ),
                      ),
                     new Row(
                       children: <Widget>[
                         (widget.snapshot.value['time'] != null) ? new Icon(Icons.language, size: 12.0,color: Colors.grey[600],) : new Container(),
                         new Text((widget.snapshot.value['time'] != null) ? "Updated ${getDateOfMsg(widget.snapshot.value['time'])}" : '', style: new TextStyle(fontSize: 11.0,color: Colors.grey[600]),),
                       ],
                     ),
                      new Padding(
                        padding: new EdgeInsets.only(
                            left: 7.0, top: 7.0, right: 7.0, bottom: 2.0),
                        child: checkIfPostIsUpdated(widget.snapshot.value) ? new Text(widget.snapshot.value['post'], style: new TextStyle(fontSize: 20.0,color: Colors.grey[800])) : new Text(''),
                      ),
                      new Row(
                        children: <Widget>[
                          (widget.ghostMode) ? new Padding(padding: new EdgeInsets.only(right: 10.0),
                          child: new GestureDetector(
                            child: Icon(Icons.remove_red_eye),
                            onTap: ()async{
                              var res = await _exitGhostModeWarning('Exit Ghost Mode?', 'This will make your post visible to other users!', '');
                              if(res){
                                exitGhostMode();
                              }
                            },
                          ),
                          ):new Container(),

                         new Padding(padding: new EdgeInsets.only(bottom:3.0),
                         child:  new RotationTransition(
                           turns: _iconTurns,
                           child: new Padding(padding: new EdgeInsets.all(2.0),
                             child: new ImageIcon(commentIcon,size: 20.0,color: Colors.grey[600]),),
                         ),),

          (widget.snapshot.value['commentCount'] != null && checkDateOfPost(widget.snapshot.value)) ?
          new Padding(padding: new EdgeInsets.only(bottom: 5.0,top: 5.0),
          child:  new Text(widget.snapshot.value['commentCount'].toString(),style: new TextStyle(color: Colors.grey[800],fontSize: 11.0),)

      ) : (!checkDateOfPost(widget.snapshot.value) && widget.snapshot.value['expiredCommentCount'] != null) ? new Padding(padding: new EdgeInsets.only(bottom: 5.0,top: 5.0),
            child:  new Text(widget.snapshot.value['expiredCommentCount'].toString(),style: new TextStyle(color: Colors.grey[800],fontSize: 11.0),)) : new Container(),

                        ],
                      )
                    ],
                  )
              ),
            ],
          ),


        ),)

      ),

    );
  }


  void sendExpiredComment(String id,String comment)async {
    await grabUserInfo();
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    String now = formatter.format(new DateTime.now());
    Map msg = {
      'time':now,
      'comment': comment,
      'sender': globals.id,
      'imgURL': globals.imgURL,
      'fullName': globals.fullName
    };
    ref.child('expiredComments').child(id).push().set(msg);
  }
  
  
  void sendComment(String id,String comment)async {
    await grabUserInfo();
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    String now = formatter.format(new DateTime.now());
    Map msg = {
      'time':now,
      'comment': comment,
      'sender': globals.id,
      'imgURL': globals.imgURL,
      'fullName': globals.fullName
    };
    ref.child('comments').child(id).push().set(msg);
  }

  Future<void>handleCommentNotificaitonList(String posterId)async{
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child('commentLists').child(posterId).once();
    if(snap.value != null){
      List<String> commentList = List.from(snap.value);
      if(!commentList.contains(globals.id)){
        commentList.add(globals.id);
          ref.child('commentLists').child(posterId).set([globals.id]);
      }else{
        return; // the user is already involved in the convo....
      }
    }else{
    ref.child('commentLists').child(posterId).set([globals.id, posterId]);
  }

  }

  
  
  


  Widget FeedCellTitle(Map post) {
    String date = formatDateForCellTitle(post['leaveDate']);
//    bool updated = checkIfPostIsUpdated(post);
    bool updated = checkDateOfPost(post);
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
          (post['destination'] != 'KCMO') ? new TextSpan(text: '${post['destination']}, ${post['state']}',style: new TextStyle(fontWeight: FontWeight.bold) ) :
          new TextSpan(text: '${post['destination']}',style: new TextStyle(fontWeight: FontWeight.bold) ), // not the best solution I know but yeah....
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


  bool checkDate(String date) {
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var postDate = formatter.parse(date);

    if (postDate.isAfter(new DateTime.now())) {
      return true;
    } else {
      return false;
    }
  }


  Future<void> grabUserInfo() async {

    print(globals.id);

    if(globals.imgURL != null && globals.fullName != null){
     return;
    }
    print(globals.id);
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child(globals.cityCode).child('userInfo').child(globals.id).once();
    setState(() {
      globals.fullName = snap.value['fullName'];
      globals.imgURL = snap.value['imgURL'];
    });
  }


  Widget commentStream(String id){
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    Query falQuery = ref.child('comments').child(id).orderByKey();

    return new FirebaseAnimatedList(
        query: falQuery,

        defaultChild: new Center(
          child: new CircularProgressIndicator(),
        ),
        padding: new EdgeInsets.all(8.0),
        reverse: false,
        sort: (a, b) => (b.key.compareTo(a.key)),
        itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, ___) {
          // here we can just look up every user from the snapshot, and then pass it into the chat message
          Map post = snapshot.value;

        if(id == globals.id){
          widget.commentNotificationCallback(); // kind of sly.... this will update every time there is an update to the comments, and set the notification flag accordingly to false... only thing is that it's a little complex
        }
       return commentCell(snapshot);

        });
  }
  Widget expiredCommentStream(String id){
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    Query falQuery = ref.child('expiredComments').child(id).orderByKey();

    return new FirebaseAnimatedList(
        query: falQuery,
        defaultChild: new Center(
          child: new CircularProgressIndicator(),
        ),
        padding: new EdgeInsets.all(8.0),
        reverse: false,
        sort: (a, b) => (b.key.compareTo(a.key)),
        itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, ___) {
          // here we can just look up every user from the snapshot, and then pass it into the chat message
          Map post = snapshot.value;
          if(id == globals.id){
            widget.commentNotificationCallback(); // kind of sly.... this will update every time there is an update to the comments, and set the notification flag accordingly to false... only thing is that it's a little complex
          }
          return commentCell(snapshot);

        });
  }

  Widget commentCell(DataSnapshot snapshot){
    return new Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        new Padding(
          padding: new EdgeInsets.only(left: 5.0, top: 2.0, right: 3.0),
          child: new CircleAvatar(backgroundColor: Colors.transparent,radius: 20.0,
            backgroundImage: new NetworkImage(snapshot.value['imgURL']),
          ),
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
  }

  double checkCommentCountForCommentsContainer(Map snapshot){
    var count;
    if(snapshot['expiredCommentCount'] == null){
      if(checkDateOfPost(snapshot)){
        count = snapshot['commentCount'];
      }
    }else{
      count = snapshot['expiredCommentCount'];
    }
    if(count != null){
      switch (count){
        case 1:
          return 140.0;
          break;
        case 2:
          return 220.0;
          break;
        case 3:
          return 250.0;
          break;
        default:
          return 280.0;
      }
    }else{
      return 51.0;
    }
  }

  double checkCommentCountForCommentsOnly(Map snapshot){

    var count;
    if(snapshot['expiredCommentCount'] == null){
      if(checkDateOfPost(snapshot)){
        count = snapshot['commentCount'];
      }
    }else{
      count = snapshot['expiredCommentCount'];
    }
    if(count != null){
      switch (count){
        case 1:
          return 90.0;
          break;
        case 2:
          return 170.0;
          break;
        case 3:
          return 200.0;
          break;
        default:
          return 230.0;
      }
    }else{
      return 1.0;
    }
  }


  void enterGhostMode(){
    FirebaseDatabase database = FirebaseDatabase.instance;
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var now = new DateTime.now();
    var ghostEndDate = now.add(new Duration(days: 14));
    database.reference().child(globals.cityCode).child('posts').child(globals.id).update({'ghost':formatter.format(ghostEndDate)});
  }

  void exitGhostMode(){
    FirebaseDatabase database = FirebaseDatabase.instance;
   
    database.reference().child(globals.cityCode).child('posts').child(globals.id).child('ghost').remove();
  }

  void incrementCommentCount(String id)async {

    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child(globals.cityCode).child('posts').child(id).child('commentCount').once();

    if(snap.value != null){
      int incremented = snap.value + 1;
      ref.child(globals.cityCode).child('posts').child(id).child('commentCount').set(incremented);
    }else{
      ref.child(globals.cityCode).child('posts').child(id).child('commentCount').set(1);
    }
  }

  void incrementExpiredCommentCount(String id)async {

    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child(globals.cityCode).child('posts').child(id).child('expiredCommentCount').once();
    if(snap.value != null){
      int incremented = snap.value + 1;
      ref.child(globals.cityCode).child('posts').child(id).child('expiredCommentCount').set(incremented);
    }else{
      ref.child(globals.cityCode).child('posts').child(id).child('expiredCommentCount').set(1);
    }
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
    final lastMidnight = new DateTime(now.year, now.month, now.day );
    if(differenceInSeconds < 604800) {
      if (differenceInSeconds < 86400 && recentMsgDate.isAfter(lastMidnight)) {
        date = timeFormatter.format(recentMsgDate);
      } else {
        date = dayFormatter.format(recentMsgDate);
      }
    }
    else{
      date = shortDatFormatter.format(recentMsgDate);
    }
    return date;
  }




  bool checkDateOfPost(Map post){
    // post will check if the post is on time
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var expireDate = post['leaveDate'];
    if(formatter.parse(expireDate).isAfter(new DateTime.now())){
      return true;
    }else{
      return false;
    }
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

  String formatDateForCellTitle(String date) {
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var postDate = formatter.parse(date);

    var shortDateFormatter = new DateFormat('M/d');
    var newDate = shortDateFormatter.format(postDate);

    return newDate;
  }

  void showProfileSheet(){
    Map post = widget.snapshot.value;
  //  Navigator.push(context,
        ///new MaterialPageRoute(builder: (context) => new UserProfile(postInfo: post, id: widget.snapshot.key,))).then((idk){
//          widget.uIcallback();
//    });

    Navigator.push(context, new MaterialPageRoute(builder: (context) => new ProfilePage(id: widget.snapshot.key,profilePicURL: post['imgURL'],)));

  }


  Future<bool> _editPostWarning(String title, String primaryMsg, String secondaryMsg) async {
    var decision = await showDialog(
      context: context,
      barrierDismissible: true, // user must tap button!
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
              child: new Text('Edit Post', style: new TextStyle(color: Colors.black),),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            new FlatButton(
              child: new Text('Ghost Mode', style: new TextStyle(color: Colors.black),),
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

  Future<bool> _exitGhostModeWarning(String title, String primaryMsg, String secondaryMsg) async {
    var decision = await showDialog(
      context: context,
      barrierDismissible: true, // user must tap button!
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
              child: new Text('Exit Ghost Mode', style: new TextStyle(color: Colors.black),),
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

//
//child:  Stack(
//alignment: Alignment.topCenter,
//overflow: Overflow.visible,
//
//children: <Widget>[
//Positioned(
//top: -25.0,
//left: 25.0,
//right: 25.0,
//
//
//child: new Container(
//
//height: 50.0,
//width: 50.0,
//child: new Image.network(postInfo['imgURL']),
//
//)
//)
//
//],
//),


//
//class test extends StatefulWidget{
//  GlobalKey<ScaffoldState> scaffoldKey;
//
//  final DataSnapshot snapshot;
//  final Animation animation;
//  String imgURL;
//  Color read = Colors.black;
//
//  FeedCell({this.snapshot, this.animation, this.imgURL, this.scaffoldKey});
//
//  tests createState() => new tests();
//
//
//
//
//
//}
//
//class tests extends State<test> {
//
//
//  void initState() {
//    super.initState();
//
//
//  }
//
//  @override
//  void dispose() {
//    // Clean up the controller when the Widget is removed from the Widget tree
//
//    super.dispose();
//  }
//
//
//  @override
//  Widget build(BuildContext context) {
//    return new Container(
//      child: new Text(hey),
//      height: 100.0,
//    )
//  }
//
//
//}