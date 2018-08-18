import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'msgStream.dart';
import '../globals.dart' as globals;
import '../homePage/feedStream.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import 'snap.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'viewPicScreen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'addUser.dart';
import 'groupMembersPopUp.dart';

class GroupChatScreen extends StatefulWidget {
  final String convoID;
  final bool newConvo;
  ///critical info
  final String recipFullName;
  final String recipID;
  final String recipImgURL;

  final String senderFullName;
  final String senderImgURL;
  final String groupName;
  final List<String> groupMembers;
  final String groupImg;


  GroupChatScreen({this.convoID, this.newConvo, this.groupMembers,this.groupName, this.groupImg});

  _GroupChatScreenState createState() => new _GroupChatScreenState();


}
class _GroupChatScreenState extends State<GroupChatScreen> with RouteAware{
  //final List<Msg> _messages = <Msg>[];
  final TextEditingController _textController = new TextEditingController();
  bool _isWriting = false;
  bool newConvo;
  FocusNode txtInputFocusNode = new FocusNode();
  Query chatQuery;
  ScrollController listController = new ScrollController();

  /// critical info

  String senderId;
  String senderFullName;
  String senderImgURL;
  bool allInfoIsAvailable = false;
  bool sendingPicture = false;
  File pictureBeingSent;
  Map nameInfo = new Map();
  Map imgInfo = new Map();
  bool imagesAndNamesReady = false;





  void initState() {
    super.initState();
    makeSureAllMsgScreenInfoIsAvailable();
    addDismissKeyboardListener();
    setupStreamQuery();
    getAllNamesAndProfilePics();
  }

  @override
  void didPop() {
    // TODO: implement didPop

   // updateReadReceipts();

    super.didPop();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }





  @override
  Widget build(BuildContext context){
    return new Scaffold(
      appBar: new AppBar(
        backgroundColor: Colors.yellowAccent,
        actions: <Widget>[

          (widget.convoID != globals.id && !widget.newConvo) ?  new GestureDetector(
            child: new Icon(Icons.format_list_bulleted,color: Colors.black,),
            onTap: (){

              showDialog(context: context, builder: (BuildContext context) => new ViewGroup(widget.convoID,widget.groupName));

            },
          ) : new Container(),


        new Padding(padding: new EdgeInsets.only(left: 10.0,right: 10.0),

        child:   (widget.convoID != globals.id && !widget.newConvo) ?  new GestureDetector(onTap: (){
          Navigator.push(context, new MaterialPageRoute(builder: (context) => new AddUser(firstUser: widget.recipID,newConvo: false,))).then((users){
            // users that have been selected now need to be added
            addUsersToGroup(users);
            List<String> usersAdded = List.from(users);


          });

        }, child: new Icon(Icons.group_add,color: Colors.black,), ) : new Container(),

        )
        ],
        title: new Text((widget.groupName != null) ? widget.groupName : '', style: new TextStyle(color: Colors.black),),
        leading: new IconButton(
          color: Colors.black,
          icon: new Icon(Icons.arrow_back),
          onPressed: (){
            Navigator.pop(context);
          },
        ),

      ),
      body: new Column( children: <Widget>[
        new Expanded(
//            child: new chatStream(widget.convoID, new AnimationController(duration: new Duration(milliseconds: 800), vsync: this), (){
//              txtInputFocusNode.unfocus();
//            }),
          child: (allInfoIsAvailable && imagesAndNamesReady) ? msgStream() : new Container(
            child: new Center(
              child: new CircularProgressIndicator(),
            ),
          ),


        ),
        new Divider(height: 1.0,),
        new Container(
          child: _buildComposer(),
          decoration: new BoxDecoration(color: Colors.white),
        ),
      ],
      ),


    );
  }

  Widget msgStream(){
    return new FirebaseAnimatedList(
        query: chatQuery,
        //  sort: (DataSnapshot a, DataSnapshot b) => a.key.compareTo(b.key),
        padding: new EdgeInsets.all(8.0),
        reverse: true,
        controller: listController,

        sort: (a, b) => (b.key.compareTo(a.key)),
        itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, ___) {

          Map msg = snapshot.value;





//          if(msg['type'] != null && msg['from'] != senderId ){
//            return GlimpseCell(recipImgURL, recipFullName, msg['formattedTime'], msg['url']);
//          }


            return Msg(msg['message'], msg['formattedTime'],msg['from']);

        }
    );
  }




  Widget Msg(String txt, String time, String id) {
    return new Container(

        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: const EdgeInsets.only(right: 18.0),
              child: (imgInfo[id] != null) ?  new CircleAvatar(
                backgroundImage: new NetworkImage(imgInfo[id]),
                backgroundColor: Colors.transparent,
              ) : new CircleAvatar(
                backgroundColor: Colors.white,
              ),
            ),
            new Expanded(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  (nameInfo[id] != null) ? new Text(nameInfo[id],style: new TextStyle(fontWeight: FontWeight.bold),) : new Text(''),
                  new Padding(padding: new EdgeInsets.all(0.5),
                    child: new Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        //  new Icon(Icons.language, color: Colors.grey,size: 10.0,),
                        Text(getDateOfMsg(time), style: new TextStyle(color: Colors.grey, fontSize: 8.0),),
                      ],
                    ),
                  ),
                  new Container(
                    margin: const EdgeInsets.only(top: 6.0),
                    child: new Text(txt),
                  )
                ],
              ),
            )
          ],
        ))
    ;

  }

//

  Widget _buildComposer() {

    return new IconTheme(
      data: new IconThemeData(color: Colors.yellowAccent),
      child: new Container(

          margin: const EdgeInsets.symmetric(horizontal: 9.0),
          child: new Column(
            children: <Widget>[
              new Row(
                children: <Widget>[

                  new Flexible(
                    child: new TextField(
                      maxLines: null,
                      focusNode: txtInputFocusNode,
                      controller: _textController,
                      onChanged: (String txt){
                        setState(() {
                          _isWriting = true;

                        });

                      },
                      onSubmitted: _submitMsg,
                      decoration: new InputDecoration.collapsed(hintText: 'Enter a Message!'),
                    ),
                  ),
                  new Container(

                      margin: new EdgeInsets.symmetric(horizontal: 3.0),
                      child: new IconButton(
                        icon: new Icon(Icons.message,color: Colors.grey,),
                        onPressed: (_isWriting && _textController.text != null) ? () => _submitMsg(_textController.text) : (){},
                      )
                  ),
//                  new Container(
//                    height: 30.0,
//                    width: 30.0,
//                    decoration: new BoxDecoration(
//                        color: Colors.yellowAccent,
//                        shape: BoxShape.circle,
//                        border: new Border.all(color: Colors.grey,width: 3.0)
//                    ),
//                    child: new InkWell(onTap: (){
//                      Navigator.push(context,
//                          new MaterialPageRoute(
//                              builder: (context) => new SnapPage(widget.convoID,widget.recipID,recipImgURL, recipFullName)));
//
//                    },),
//                  ),
                ],
              ),
              //new Divider(),

              new Container(
                height: 10.0,
                width: double.infinity,
//              child:new Padding(padding: new EdgeInsets.only(bottom: 15.0),
//              child: new Row(
//                mainAxisAlignment: MainAxisAlignment.center,
//                children: <Widget>[
//                  new Padding(padding: new EdgeInsets.only(right: 15.0),
//
//                    child: new IconButton(icon: new Icon(Icons.camera,color: Colors.grey), onPressed: (){}),
//                  ),
//
//
//
//                  new Padding(padding: new EdgeInsets.only(left: 15.0),
//
//                  child: new IconButton(icon: new Icon(Icons.tag_faces,color: Colors.grey), onPressed: (){}),
//                  )
//
//
//                ],
//              )
//
//              )

              )

            ],
          ),
          decoration: Theme.of(context).platform == TargetPlatform.iOS ?
          new BoxDecoration(
              border: new Border(top: new BorderSide(color: Colors.grey, width: 0.5))) : null
      ),
    );

  }


  String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();

  void _submitMsg(String txt)async{


    if(!allInfoIsAvailable){
      return;
    }

      if(newConvo){
        await sendNewConvoMsg();
      }else{
        await sendRegularMsg(globals.id);
      }

    _textController.clear();
    setState(() {_isWriting = false;});
  }




  
  Future<void> addUsersToGroup(List<String> users)async{

    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child('groupChatLists').child(widget.convoID).once();
    List<String> currentUsers = List.from(snap.value);
    users.forEach((user)async{
      if(!currentUsers.contains(user)){
        currentUsers.add(user);
        await getNewlyAddedUsersInfo(user);
      }
    });
    await ref.child('groupChatLists').child(widget.convoID).set(currentUsers);
  }




  Future<void> getNewlyAddedUsersInfo(String id)async{
    DatabaseReference ref = FirebaseDatabase.instance.reference();

      DataSnapshot snap = await ref.child(globals.cityCode).child('userInfo').child(id).once();
      setState(() {
        imgInfo[id] = snap.value['imgURL'];
        nameInfo[id] = snap.value['fullName'];
    });

  }




  Future<void> sendRegularMsg(String id)async{

    // need to update the mother ship info (recent message, fromatted time)
    // need to send the regular message to the convoId node 


    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var now = formatter.format(new DateTime.now());
    DatabaseReference ref = FirebaseDatabase.instance.reference();

    try{
      

      Map message = {'from':globals.id,'message':_textController.text,'formattedTime':now,'fullName':senderFullName,'imgURL':senderImgURL}; // CREATE MESSAG
      await ref.child('groupConvos').child(widget.convoID).push().set(message);
      await ref.child('groupChatDetails').child(widget.convoID).update({'recentMsg':_textController.text, 'formattedTime':now});

    }catch(e){
      _errorMenu("Error", "There was an error sending your message.", '');
    }

  }






  Future<void> sendNewConvoMsg()async{
    //need to first send the group members list up
    // send the basic convoList info for each user which contains the groupChatNode id
    // send the message

    if(!allInfoIsAvailable){
      return;
    }

    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var now = formatter.format(new DateTime.now());
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    newConvo = false;


    try{
      // set group list (for notifications)
   await ref.child('groupChatLists').child(widget.convoID).set(widget.groupMembers);

      // basic convo info
      Map convoInfo = {'groupChatInfoId':  widget.convoID,'time':widget.convoID, 'formattedTime':now,'group':true, 'groupName':widget.groupName, 'groupImg':widget.groupImg,'new':true};

      // send the basic convo info for each user

      await setGroupList(convoInfo);


      // send the detailed convo info
      Map detailedConvoInfo = {'groupName':widget.groupName,'convoID':widget.convoID, 'time':widget.convoID, 'imgURL':senderImgURL, 'recentMsg':_textController.text,'formattedTime':now, };
     await ref.child('groupChatDetails').child(widget.convoID).set(detailedConvoInfo);

      Map message = {'from':globals.id,'message':_textController.text,'formattedTime':now}; // CREATE MESSAG
     await ref.child('groupConvos').child(widget.convoID).push().set(message); // SEND THE MESSAGE
    }catch(e){
      _errorMenu('Error', 'There was an error sending your message.', '');
    }
  }


  Future<void> setGroupList(Map convoInfo)async{
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    widget.groupMembers.forEach((id)async {
      await ref.child('convoLists').child(id).child(widget.convoID).set(convoInfo);
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





  Future<void> makeSureAllMsgScreenInfoIsAvailable()async{
    newConvo = widget.newConvo;
    /// senderInfo
    try{
      await getSenderFullName();
      await getSenderImgURL();
      senderId = globals.id;
      ///recipInfo


      if(senderFullName != null && senderImgURL != null){
        setState(() {
          allInfoIsAvailable = true;
        });
      }
    }catch(e){
      Future.delayed(new Duration(seconds: 2)).then((e){
        _errorMenu('Error', 'Database error, please contact Link Support.', '');
      });
    }

  }


  void setupStreamQuery(){
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    if(widget.convoID == globals.id){
      chatQuery = ref.child('feedback').child(globals.id);
    }else{
      chatQuery = ref.child('groupConvos').child(widget.convoID);
    }
  }


  void addDismissKeyboardListener(){
    listController.addListener((){
      txtInputFocusNode.unfocus();
    });
  }


  Future<void> getSenderImgURL()async{
    if(widget.senderImgURL != null){
      setState(() {
        senderImgURL = widget.senderImgURL;
      });
    }else {
      DatabaseReference ref = FirebaseDatabase.instance.reference();
      DataSnapshot snap;
      try{
        snap = await ref.child(globals.cityCode).child('userInfo').child(globals.id).child('imgURL').once();
      }catch(e){
        throw new Exception('Error');
      }
      setState(() {
        if(snap.value != null){
          senderImgURL = snap.value;
        }else{
          throw new Exception('Error');
        }
      });

    }
  }


  Future<void> getSenderFullName()async{
    if(widget.senderFullName != null){
      setState(() {
        senderFullName = widget.senderFullName;

      });
    }else{
      DatabaseReference ref = FirebaseDatabase.instance.reference();
      DataSnapshot snap;
      try{
        snap = await ref.child(globals.cityCode).child('userInfo').child(globals.id).child('fullName').once();
      }catch(e){
        throw new Exception('Error');
      }
      setState(() {
        if(snap.value != null){
          senderFullName = snap.value;
        }else{
          throw new Exception('Error');
        }

      });
    }

  }



  Future<void> getAllNamesAndProfilePics()async{
    DatabaseReference ref = FirebaseDatabase.instance.reference();

    if(!widget.newConvo){
      var snap = await ref.child('groupChatLists').child(widget.convoID).once();
      List<String> userList = List.from(snap.value);
      userList.forEach((id)async{
        var userSnap = await ref.child(globals.cityCode).child('userInfo').child(id).once();
        setState(() {
          nameInfo[id] = userSnap.value['fullName'];
          imgInfo[id] = userSnap.value['imgURL'];
        });
      });
      setState(() {imagesAndNamesReady = true;});
    }else{
      widget.groupMembers.forEach((id)async{
        var userSnap = await ref.child(globals.cityCode).child('userInfo').child(id).once();
        setState(() {
          nameInfo[id] = userSnap.value['fullName'];
          imgInfo[id] = userSnap.value['imgURL'];
        });
      });
      setState(() {imagesAndNamesReady = true;});
    }

  }




  Future<void> updateReadReceipts()async{
    if(!newConvo && widget.convoID != globals.id){
      DatabaseReference ref = FirebaseDatabase.instance.reference();
      try{
        await ref.child('convoLists').child(globals.id).child(widget.convoID).update({'new':false});// IDK
      }catch(e){
        throw new Exception('Error');
      }
      //   ref.child('convoLists').child(widget.recipID).child(globals.id).update({'new':'true','read':'true'});
    }
  }

  String getFirstName(String fullName) {
    int i;
    String firstName;
    String lastName;
    for (i = 0; i < fullName.length; i++) {
      if (fullName[i] == " ") {
        String firstName = fullName.substring(0, i);

        return firstName;
      }
    }
    return '';
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
              child: new Text('Okay', style: new TextStyle(color: Colors.black),),
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