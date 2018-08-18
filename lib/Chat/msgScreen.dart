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
import 'groupMsgScreen.dart';
import 'package:flutter/services.dart';
import '../pageTransitions.dart';

typedef glimpseLoadedCB = void Function(File glimpseKey);

class ChatScreen extends StatefulWidget {
     final String convoId;
     final bool newConvo;
     ///critical info
     final String recipFullName;
     final String recipID;
     final String recipImgURL;

     final String senderFullName;
     final String senderImgURL;
     

  ChatScreen({this.recipID,this.convoId, this.newConvo, this.recipImgURL, this.recipFullName, this.senderFullName, this.senderImgURL});

     _chatScreenState createState() => new _chatScreenState();


}
class _chatScreenState extends State<ChatScreen> with RouteAware{
  //final List<Msg> _messages = <Msg>[];
  final TextEditingController _textController = new TextEditingController();
  bool _isWriting = false;
  bool newConvo;
  FocusNode txtInputFocusNode = new FocusNode();
  Query chatQuery;
  ScrollController listController = new ScrollController();

  /// critical info
  String recipFullName;
  String recipId;
  String recipImgURL;
  String senderId;
  String senderFullName;
  String senderImgURL;
  bool allInfoIsAvailable = false;
  bool sendingPicture = false;
  File pictureBeingSent;
  bool glimpseLoading = false;
  bool userHasSentAtLeastOneMsg = false;
  Map glimpseLoadLog = new Map();

  static const platform = const MethodChannel('thumbsOutChannel');





   void initState() {
    super.initState();
    newConvo = widget.newConvo;
    makeSureAllMsgScreenInfoIsAvailable();
    addDismissKeyboardListener();
    setupStreamQuery();
   }

    @override
  void didPop() {
    // TODO: implement didPop

    updateReadReceipts();

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

          (widget.convoId != globals.id && senderImgURL != null) ?  new FlatButton.icon(onPressed: (){
    Navigator.push(context, new MaterialPageRoute(builder: (context) => new AddUser(firstUser: widget.recipID,groupImg:senderImgURL,newConvo: true,))).then((convoInfo) {
      //  Map convoInfo = {'convoID': widget.convoId,'newConvo': true,'groupMembers': widget.members, 'groupName': controller.text,'groupImg':widget.groupImgURL};


      if(convoInfo == null){
        return;
      }

      Navigator.push(context, new MaterialPageRoute(builder: (context) =>
      new GroupChatScreen(convoID: convoInfo['convoID'],
        newConvo: true,
        groupMembers: convoInfo['groupMembers'],
        groupImg: convoInfo['groupImg'],
        groupName: convoInfo['groupName'],)));
    });
    }, icon: new Icon(Icons.group_add), label: new Text('')) : new Container()
        ],
        title: new Text((recipFullName != null) ? recipFullName : '', style: new TextStyle(color: Colors.black),),
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
        child: (allInfoIsAvailable) ? new Stack(
          children: <Widget>[
            msgStream(),

          ],
        ) : new Container(
          child: new Center(
            child: new CircularProgressIndicator(),
          ),
        ),


          ),
          new Divider(height: 1.0,),
          new Container(
            child: new Padding(padding: new EdgeInsets.only(bottom: 8.0),
            child: _buildComposer(),
    ),
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

          if(newConvo){
            newConvo = false;
          }

          if(msg['from'] == globals.id){
              userHasSentAtLeastOneMsg = true;

          }




          if(msg['type'] != null && msg['from'] != globals.id ){

                  return recipGlimpseCell(msg,widget.convoId,snapshot.key,recipFullName,recipImgURL);

          }
          if(msg['type'] != null && msg['from'] == globals.id ){
           // return GlimpseCell(msg, senderFullName, senderImgURL, widget.convoId,snapshot.key, false, widget.recipID,msg['duration'],false);

            return senderGlimpseCell(msg['viewed'],senderFullName, senderImgURL);
          }

//          if(msg['type'] != null && msg['from'] != senderId ){
//            return GlimpseCell(recipImgURL, recipFullName, msg['formattedTime'], msg['url']);
//          }

          if(msg['from'] == senderId){
            return Msg(msg['message'], senderImgURL,senderFullName, msg['formattedTime']);
          }else{
            return Msg(msg['message'], recipImgURL,recipFullName, msg['formattedTime']);
          }
        }
    );
  }




  Widget Msg(String txt, String imgURL, String name, String time) {

     
     return new Container(

      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            margin: const EdgeInsets.only(right: 5.0),
            child: new CircleAvatar(
              backgroundImage: new NetworkImage(imgURL),
              backgroundColor: Colors.transparent,            
            ),
          ),
          new Expanded(
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                    new Text(name,style: new TextStyle(fontWeight: FontWeight.bold),),
                       new Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                        //  new Icon(Icons.language, color: Colors.grey,size: 10.0,),
                          Text(getDateOfMsg(time), style: new TextStyle(color: Colors.grey, fontSize: 8.0),),
                        ],
                      ),
                new Container(
                  margin: const EdgeInsets.only(top: 3.0),
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
      (widget.convoId != globals.id) ? new Container(
                  height: 30.0,
                  width: 30.0,
                  decoration: new BoxDecoration(
                      color: Colors.yellowAccent,
                      shape: BoxShape.circle,
                      border: new Border.all(color: Colors.grey,width: 3.0)
                  ),
                  child: new InkWell(onTap: (){

                    Navigator.push(context,
                        new ShowRoute(widget: SnapPage(widget.convoId,widget.recipID,recipImgURL, recipFullName,newConvo,userHasSentAtLeastOneMsg)));




//                   platform.invokeMethod('showCamera').then((res){
//                     print(res);
//                   });


                     },
                  ),
                ) : new Container(),
              ],
            ),

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
    if(widget.convoId == globals.id){
     await sendFeedbackMsg();
    }else{
      if(newConvo){
       await sendNewConvoMsg();
      }else{
        await sendRegularMsg(globals.id);
      }
    }
    _textController.clear();
    setState(() {_isWriting = false;});
}








Future<void> sendRegularMsg(String id)async{
  await handleContactsList();
  var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
  var now = formatter.format(new DateTime.now());
  DatabaseReference ref = FirebaseDatabase.instance.reference();
  var key = ref.child('convos').child(widget.convoId).push().key;

  Map message = {'to':widget.recipID,'from':globals.id,'message':_textController.text, 'formattedTime':now};
  try{
    await ref.child('convoLists').child(globals.id).child(widget.recipID).update({'recentMsg':_textController.text, 'time':key,'formattedTime':now});// IDK
    await ref.child('convoLists').child(widget.recipID).child(globals.id).update({'recentMsg':_textController.text, 'time':key,'formattedTime':now,'new':true});
    await ref.child('convos').child(widget.convoId).push().set(message); // SEND THE MESSAGE
  }catch(e){
    _errorMenu("Error", "There was an error sending your message.", '');
  }

}

  Future<void> sendFeedbackMsg()async{
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var now = formatter.format(new DateTime.now());

    if(globals.id == null || _textController.text == null || now == null){
      return;
    }

   // Map brettsChatlist = { 'imgURL':senderImgURL, 'formattedTime':now, 'new': true, 'recentMsg':_textController.text, 'recipFullName':senderFullName, 'recipId':globals.id, 'convoId':FirebaseDatabase.instance.reference().push().key}
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    Map message = {'from':globals.id,'message':_textController.text, 'formattedTime':now};
    try{
      ref.child('feedback').child('admin').push().set(message); // for meee
      ref.child('feedback').child(globals.id).push().set(message);
      respondToFeedback();

    }catch(e){

      _errorMenu('Error', 'There was an error sending your message.', '');
    }

}


Future<void> respondToFeedback()async{
  var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
  var now = formatter.format(new DateTime.now());
  DatabaseReference ref = FirebaseDatabase.instance.reference();

  Map message = {'to':globals.id,'from':'link','message':"Thanks for the feedback! We will try to get back to you non-robotically.", 'formattedTime':now};
  await Future.delayed(new Duration(seconds: 1));
    ref.child('feedback').child(globals.id).push().set(message);

}



Future<void> sendNewConvoMsg()async{

if(!allInfoIsAvailable){
  return;
}

var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
  var now = formatter.format(new DateTime.now());
  DatabaseReference ref = FirebaseDatabase.instance.reference();
  newConvo = false;


  try{
    await handleContactsList();
    Map convoInfoForSender = {'recipID':widget.recipID,'convoID':widget.convoId, 'time':widget.convoId, 'imgURL':recipImgURL,
      'recipFullName': recipFullName, 'recentMsg':_textController.text,'formattedTime':now, 'new': false};
    ref.child('convoLists').child(globals.id).child(widget.recipID).set(convoInfoForSender);

    Map convoInfoForRecipient = {'recipID':globals.id,'convoID':widget.convoId, 'time':widget.convoId, 'imgURL':senderImgURL, 'recipFullName':senderFullName,'recentMsg':_textController.text,'formattedTime':now, 'new':true};
    ref.child('convoLists').child(widget.recipID).child(globals.id).set(convoInfoForRecipient);

    Map message = {'to':widget.recipID,'from':globals.id,'message':_textController.text,'formattedTime':now}; // CREATE MESSAG
    ref.child('convos').child(widget.convoId).push().set(message); // SEND THE MESSAGE
  }catch(e){
    _errorMenu('Error', 'There was an error sending your message.', '');
  }
}



Future<void> handleContactsList()async{
  DatabaseReference ref = FirebaseDatabase.instance.reference();
  if(!userHasSentAtLeastOneMsg){
    DataSnapshot snap = await ref.child('contacts').child(globals.id).once();
    if(snap.value != null){
      List<String> contacts = List.from(snap.value);
      if(!contacts.contains(widget.recipID)){
        contacts.add(widget.recipID);
        await ref.child('contacts').child(globals.id).set(contacts);
      }
    }else{
      await ref.child('contacts').child(globals.id).set([widget.recipID]);
       }
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
      await getRecipFullName();
      await getRecipImgURL();

      if(senderFullName != null && senderImgURL != null && recipImgURL != null && senderFullName != null){
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
  if(widget.convoId == globals.id){
    chatQuery = ref.child('feedback').child(globals.id);
  }else{
    chatQuery = ref.child('convos').child(widget.convoId);
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


  Future<void> getRecipFullName()async{
    if(widget.recipFullName != null){
      setState(() {
        recipFullName = widget.recipFullName;
      });
    }else{
      DatabaseReference ref = FirebaseDatabase.instance.reference();
      DataSnapshot snap;

      try{
         snap = await ref.child(globals.cityCode).child('userInfo').child(widget.recipID).child('fullName').once();
      }catch(e){
       throw new Exception('Error');
      }
      setState(() {
        if(snap.value != null){
          recipFullName = snap.value;
        }else{
          throw new Exception("Error");
        }
      });
      }
    }

  Future<void> getRecipImgURL()async{
    if(widget.recipImgURL != null){
      setState(() {
        recipImgURL = widget.recipImgURL;
        return;
      });
    }else{
      DatabaseReference ref = FirebaseDatabase.instance.reference();
      DataSnapshot snap;
      try{
         snap = await ref.child(globals.cityCode).child('userInfo').child(widget.recipID).child('imgURL').once();
      }catch(e){
        throw new Exception('Error');
      }
      setState(() {
        if(snap.value != null){
          recipImgURL = snap.value;
        }else{
          throw new Exception('Error');
        }
      });
    }
  }


  Future<void> updateReadReceipts()async{
    if(!newConvo && widget.convoId != globals.id){
      DatabaseReference ref = FirebaseDatabase.instance.reference();
      try{
        await ref.child('convoLists').child(globals.id).child(widget.recipID).update({'new':false});// IDK
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




  // glimpse stuff


//  void initializeData(){
//    imgURL = widget.msg['imgURL'];
//    viewedPic = widget.msg['viewed'];
//    imgURL = widget.imgURL;
//    fullName = widget.fullName;
//    time = widget.msg['formattedTime'];
//    glimpseURL = widget.msg['url'];
//    glimpseKey = widget.glimpseKey;
//    convoId = widget.convoId;
//  }



  Widget recipGlimpseCell(Map msg, String convoId, String glimpseKey, String fullName, String imgURL){
    return new Card(
        child:new InkWell(

          onTap: ()async {
            if(!msg['viewed']){
              viewGlimpse(glimpseKey, msg);
            }else{
               Navigator.push(context,
                    new ShowRoute(widget: SnapPage(widget.convoId,widget.recipID,recipImgURL, recipFullName,newConvo,userHasSentAtLeastOneMsg)));
            }

          },
          child:  new Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              new Expanded(
                  child: new Column(
                    children: <Widget>[
                      new Row(
                        children: <Widget>[
                          new Padding(padding: new EdgeInsets.all(5.0),
                            child:  new CircleAvatar(
                              backgroundImage: new CachedNetworkImageProvider(imgURL),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                          new Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              new Padding(padding: new EdgeInsets.only(left: 10.0),
                                child: new Text(fullName,style: new TextStyle(fontWeight: FontWeight.bold),),

                              ),
                              //Text(getDateOfMsg(time), style: new TextStyle(color: Colors.grey, fontSize: 8.0),),

                              new Padding(padding: new EdgeInsets.only(left: 10.0),
                                child: new Text( (!msg['viewed']) ? 'New Glimpse, tap to view!': 'Tap to Reply!!' ),
                              )
                            ],
                          )
                        ],
                      )
                    ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                  )
              ),


            ],
          ),
        )
    );
  }



  Widget senderGlimpseCell(bool recipViewed, String senderName, String imgURL ){
    return new Container(

        child: InkWell(

            onTap: ()async{

              // nothing
            },

            child:  new Card(
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  new Expanded(
                      child: new Column(
                        children: <Widget>[
                          new Row(
                            children: <Widget>[
                              new Padding(padding: new EdgeInsets.all(5.0),
                                child:  new CircleAvatar(
                                  backgroundImage: new CachedNetworkImageProvider(imgURL),
                                  backgroundColor: Colors.transparent,
                                ),
                              ),

                              new Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  new Padding(padding: new EdgeInsets.only(left: 10.0),
                                    child: new Text(senderName,style: new TextStyle(fontWeight: FontWeight.bold),),

                                  ),
                                  //Text(getDateOfMsg(time), style: new TextStyle(color: Colors.grey, fontSize: 8.0),),

                                  new Padding(padding: new EdgeInsets.only(left: 10.0),
                                    child: new Text( (!recipViewed) ? 'Sent Glimpse!': 'Glimpse has been opened!',
                                    ),
                                  )
                                ],
                              )
                            ],
                          )
                        ],
                        crossAxisAlignment: CrossAxisAlignment.start,
                      )
                  ),

                ],
              ),
            )
        )
    );
  }



  Future<void> viewGlimpse(String glimpseKey, Map msg)async{

    if(msg.containsKey('fromCameraRoll')){
      Navigator.push(context, ShowRoute(widget: viewPic(msg['url'],msg['duration'], true,widget.convoId,glimpseKey)),);
    }else{
        Navigator.push(context, ShowRoute(widget: viewPic(msg['url'],msg['duration'], false,widget.convoId,glimpseKey)),
        );
    }
  }

//
//  Future<void> viewGlimpse(String glimpseURL, String glimpseKey, bool fromCameraRoll, bool, int duration)async{
//
//    if(fromCameraRoll){
//      Navigator.push(context, new MaterialPageRoute(builder: (context) => new viewPic(glimpseURL,duration, true,widget.convoId,glimpseKey))).then((D)async{
//      });
//    }else{
//      Navigator.push(context, new MaterialPageRoute(builder: (context) => new viewPic(glimpseURL,duration, false,widget.convoId,glimpseKey))).then((D)async{
//      });
//    }
//  }





//  Future<void> viewGlimpse(String convoId, String glimpseKey, int duration, String img,bool fromCameraRoll)async{
//
//    if(fromCameraRoll){
//      Navigator.push(context, new MaterialPageRoute(builder: (context) => new viewPic(img,duration, true)));
//    }else{
//      Navigator.push(context, new MaterialPageRoute(builder: (context) => new viewPicx(img,duration, false)));
//    }
//    try{
//      await FirebaseDatabase.instance.reference().child('convos').child(convoId).child(glimpseKey).update({'viewed':true});
//    }catch(e){
//      return;
//    };
//
//  }




}



class GlimpseCell extends StatefulWidget {

 // GlimpseCell(this.msg, this.fullName, this.imgURL, this.convoId, this.glimpseKey,this.recipGlimpse, this.id,this.duration, this.fromCameraRoll);
   GlimpseCell(this.msg, this.glimpseKey, this.convoId, this.fullName, this.imgURL,this.glimpseLog, this.loadedCB);
  // child:recipGlimpseCell(widget.imgURL, widget.msg['viewed'], fullName, time, glimpseURL, glimpseKey, convoId, widget.msg['from'], widget.fromCameraRoll, widget.msg['duration'], )


  final Map msg;
  final String convoId;
  final String glimpseKey;
  final String fullName;
  final String imgURL;
  final glimpseLoadedCB loadedCB;
  final Map glimpseLog;





  @override
  _GlimpseCellState createState() => new _GlimpseCellState();

}

class _GlimpseCellState extends State<GlimpseCell> with TickerProviderStateMixin {


bool loading = false;

IconData icon = Icons.file_download;


File glimpseFile;
bool glimpseLoaded = false;
bool viewed;
  @override
  void initState() {
    super.initState();
    viewed = widget.msg['viewed'];
    if(widget.glimpseLog.containsKey(widget.glimpseKey)){
      setState(() {
        glimpseFile = widget.glimpseLog[widget.glimpseKey];
        glimpseLoaded = true;
      });
    }
  }



  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();

  @override
  Widget build(BuildContext context) {
    return new Container(
      height: 60.0,
        width: double.infinity,

        margin: const EdgeInsets.symmetric(vertical: 2.0),
        child:recipGlimpseCell(widget.imgURL, viewed, widget.fullName, widget.msg['formattedTime'], widget.msg['url'], widget.glimpseKey, widget.convoId, widget.msg['from'], widget.msg['fromCameraRoll'], widget.msg['duration'])

    );
  }
//
//
//  Widget recipGlimpseCell(){
//    return new Card(
//      child:new InkWell(
//        onTap: (){
//          if(viewedPic){
//            // tap to reply
//          }else{
//            viewGlimpse(glimpseURL);
//          }
//        },
//        child:  new Row(
//          mainAxisAlignment: MainAxisAlignment.start,
//          children: <Widget>[
//            new Expanded(
//                child: new Column(
//                  children: <Widget>[
//                    new Row(
//                      children: <Widget>[
//                        new Container(
//                          child: new CircleAvatar(
//
//                            backgroundImage: new CachedNetworkImageProvider(imgURL),
//                            backgroundColor: Colors.transparent,
//                          ),
//                        ),
//                        new Column(
//                          crossAxisAlignment: CrossAxisAlignment.start,
//                          children: <Widget>[
//                            new Padding(padding: new EdgeInsets.only(left: 10.0),
//                              child: new Text(fullName,style: new TextStyle(fontWeight: FontWeight.bold),),
//
//                            ),
//                            //Text(getDateOfMsg(time), style: new TextStyle(color: Colors.grey, fontSize: 8.0),),
//
//                            new Padding(padding: new EdgeInsets.only(left: 10.0),
//                              child: new Text( (loadedPic && !viewedPic) ? 'New Glimpse, tap to view!': (!loadedPic && !viewedPic) ? 'New Glimpse, tap to download!' : (viewedPic) ? 'Tap to Reply!!' : new Text(''), ),
//                            )
//                          ],
//                        )
//                      ],
//                    )
//                  ],
//                  crossAxisAlignment: CrossAxisAlignment.start,
//                )
//            ),
//
////            (!viewedPic) ? new Padding(padding: new EdgeInsets.all(15.0),
////              child: new Container(
////                  height: 30.0,
////                  width: 30.0,
////                  child: (loading) ? new CircularProgressIndicator(): (loadedPic && img != null) ? new Icon(Icons.image) : (!loadedPic && !viewedPic) ? new Icon(Icons.file_download) : new Icon(Icons.check)
////              ),
////            ) : new Container(),
//          ],
//        ),
//      )
//    );
//  }
//





  Widget recipGlimpseCell(String imgURL, bool viewed, String fullName, String time, String glimpseURL, String glimpseKey, String convoId, String id, bool fromCameraRoll,int duration,){
    return new Card(
        child:new InkWell(

          onTap: ()async {

          //  viewGlimpse(glimpseURL, glimpseKey, fromCameraRoll, bool, duration);
            if(!loading && !glimpseLoaded){
              await loadGlimpse();
            }else{
              if(!viewed && glimpseLoaded && glimpseFile != null){
                setState(() {
                  viewed = true;
                });
            //    viewGlimpse('');
              }
            }

          },
          child:  new Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              new Expanded(
                  child: new Column(
                    children: <Widget>[
                      new Row(
                        children: <Widget>[
                          new Container(
                            child: new CircleAvatar(

                              backgroundImage: new CachedNetworkImageProvider(imgURL),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                         new Expanded(child:  new Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: <Widget>[
                         new Padding(padding: new EdgeInsets.only(left: 10.0),
                         child: new Text(fullName,style: new TextStyle(fontWeight: FontWeight.bold),),

                         ),
                         //Text(getDateOfMsg(time), style: new TextStyle(color: Colors.grey, fontSize: 8.0),),

                         new Padding(padding: new EdgeInsets.only(left: 10.0),
                         child: new Text( (!viewed && !glimpseLoaded) ? 'New Glimpse, tap to Load!': (!viewed && glimpseLoaded) ? 'Tap to view' : 'Tap to Reply!!' ),
    )
    ],
    ),),


    (!viewed) ? new Padding(padding: new EdgeInsets.all(15.0),
                child: new Container(
                    height: 30.0,
                    width: 30.0,
                    child: (loading) ? new CircularProgressIndicator() : new Container(),
    )):new Container()
                        ],
                      )
                    ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                  )
              ),


            ],
          ),
        )
    );
  }





  Widget senderGlimpseCell(){
  return new Container(

    child: InkWell(

        onTap: ()async{
        },

        child:  new Card(
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              new Expanded(
                  child: new Column(
                    children: <Widget>[
                      new Row(
                        children: <Widget>[
                     new Padding(padding: new EdgeInsets.all(5.0),
                     child:  new CircleAvatar(
                       backgroundImage: new CachedNetworkImageProvider(widget.imgURL),
                       backgroundColor: Colors.transparent,
                     ),
                     ),

                          new Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              new Padding(padding: new EdgeInsets.only(left: 10.0),
                                child: new Text(widget.fullName,style: new TextStyle(fontWeight: FontWeight.bold),),

                              ),
                              //Text(getDateOfMsg(time), style: new TextStyle(color: Colors.grey, fontSize: 8.0),),

                              new Padding(padding: new EdgeInsets.only(left: 10.0),
                                child: new Text( (!widget.msg['viewed']) ? 'Sent Glimpse!': 'Glimpse has been opened!',
                                ),
                              )
                            ],
                          )
                        ],
                      )
                    ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                  )
              ),

//        (!viewedPic) ? new Padding(padding: new EdgeInsets.all(15.0),
//          child: new Container(
//              height: 20.0,
//              width: 20.0,
//              child: (loading) ? new Center(child: CircularProgressIndicator(),) : (loadedPic && img != null ) ? new Container(height: 20.0,width: 20.0,child: new IconButton(icon: new Icon(Icons.image), onPressed: ()async{
//                await viewGlimpse();
//              }),) : new Icon(Icons.file_download)
//          ),
//        ) : new Container(),
            ],
          ),
        )
    )
  );
}

//  Future<void> viewGlimpse(String glimpseURL)async{
//
//    if(widget.msg.containsKey('fromCameraRoll')){
//      Navigator.push(context, new MaterialPageRoute(builder: (context) => new viewPic(glimpseFile,widget.msg['duration'], true,widget.convoId,widget.glimpseKey))).then((D)async{
//        setState(() {viewed = true;});
//      });
//          }else{
//      Navigator.push(context, new MaterialPageRoute(builder: (context) => new viewPic(glimpseFile,widget.msg['duration'], false,widget.convoId,widget.glimpseKey))).then((D)async{
//       setState(() {viewed = true;});
//      });
//    }
//
//
//  }


  Future<void> loadGlimpse()async{
    setState(() {
      loading = true;
    });
    try{
      http.Response imgRes = await http.get(widget.msg['url']);
      var bytes = imgRes.bodyBytes;
      final Directory extDir = await getTemporaryDirectory();
      final String dirPath = '${extDir.path}/Pictures/flutter_test';
      await new Directory(dirPath).create(recursive: true);
      String time = timestamp();
      glimpseFile = new File('$dirPath/${time}.png');
      glimpseFile.writeAsBytes(bytes);

    }catch(e){
      setState(() {
        loading = false;
      }
        );
      return;
    }

    setState(() {
      widget.loadedCB(glimpseFile);
      loading = false;
    glimpseLoaded = true;
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

}

//Widget Msg(String url, String Name){
//    return new Container(
//      child: new Row(
//        children: <Widget>[
//          new CircleAvatar(
//            backgroundImage: new NetworkImage(url),
//          ),
//          new Column(
//            children: <Widget>[
//            //  new Text(name, style: new TextStyle(fontWeight: FontWeight.bold, ),)
//            ],
//          )
//        ],
//      )
//    );
//  }





//  Widget recipGlimpseCell(String imgURL, bool viewedPic, String fullName, String time, String glimpseURL, String glimpseKey, String convoId, String id){
//    return new Card(
//        child:new InkWell(
//
//          onTap: ()async{
//
//
//
//          },
//
//          child:  new Row(
//            mainAxisAlignment: MainAxisAlignment.start,
//            children: <Widget>[
//              new Expanded(
//                  child: new Column(
//                    children: <Widget>[
//                      new Row(
//                        children: <Widget>[
//                          new Container(
//                            child: new CircleAvatar(
//
//                              backgroundImage: new CachedNetworkImageProvider(imgURL),
//                              backgroundColor: Colors.transparent,
//                            ),
//                          ),
//                          new Column(
//                            crossAxisAlignment: CrossAxisAlignment.start,
//                            children: <Widget>[
//                              new Padding(padding: new EdgeInsets.only(left: 10.0),
//                                child: new Text(fullName,style: new TextStyle(fontWeight: FontWeight.bold),),
//
//                              ),
//                              //Text(getDateOfMsg(time), style: new TextStyle(color: Colors.grey, fontSize: 8.0),),
//
//                              new Padding(padding: new EdgeInsets.only(left: 10.0),
//                                child: new Text( (loadedPic && !viewedPic) ? 'New Glimpse, tap to view!': (!loadedPic && !viewedPic) ? 'New Glimpse, tap to download!' : (viewedPic) ? 'Tap to Reply!!' : new Text(''), ),
//                              )
//                            ],
//                          )
//                        ],
//                      )
//                    ],
//                    crossAxisAlignment: CrossAxisAlignment.start,
//                  )
//              ),
//
//              (!viewedPic) ? new Padding(padding: new EdgeInsets.all(15.0),
//                child: new Container(
//                    height: 30.0,
//                    width: 30.0,
//                    child: (loading) ? new CircularProgressIndicator(): (loadedPic && img != null) ? new Icon(Icons.image) : (!loadedPic && !viewedPic) ? new Icon(Icons.file_download) : new Icon(Icons.check)
//                ),
//              ) : new Container(),
//            ],
//          ),
//        )
//    );
//  }


