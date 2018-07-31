import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'msgStream.dart';
import '../globals.dart' as globals;
import '../homePage/feedStream.dart';
import 'package:intl/intl.dart';



class ChatScreen extends StatefulWidget {
     final String convoID;
     final bool newConvo;
     ///critical info
     final String recipFullName;
     final String recipID;
     final String recipImgURL;

     final String senderFullName;
     final String senderImgURL;
     

  ChatScreen({this.recipID,this.convoID, this.newConvo, this.recipImgURL, this.recipFullName, this.senderFullName, this.senderImgURL});

     _chatScreenState createState() => new _chatScreenState();


}
class _chatScreenState extends State<ChatScreen> with TickerProviderStateMixin{
  //final List<Msg> _messages = <Msg>[];
  final TextEditingController _textController = new TextEditingController();
  bool _isWriting = false;
  bool newConvo;
  FocusNode txtInputFocusNode = new FocusNode();
  Query chatQuery;
  /// critical info
  String recipFullName;
  String recipId;
  String recipImgURL;
  String senderId;
  String senderFullName;
  String senderImgURL;
  bool allInfoIsAvailable = false;




   void initState() {
    super.initState();

    makeSureAllMsgScreenInfoIsAvailable();


    DatabaseReference ref = FirebaseDatabase.instance.reference();

    chatQuery = ref.child('convos').child(widget.convoID);

    newConvo = widget.newConvo;

   }







  @override 
  Widget build(BuildContext context){
    return new Scaffold(

      appBar: new AppBar(
        backgroundColor: Colors.yellowAccent,
        title: new Text((recipFullName != null) ? recipFullName : '', style: new TextStyle(color: Colors.black),),
        leading: new IconButton(
          color: Colors.black,
          icon: new Icon(Icons.arrow_back),
          onPressed: (){
            updateReadReceipts();
            Navigator.pop(context);
          },
        ),
      ),
      body: new Column( children: <Widget>[
          new Expanded(
//            child: new chatStream(widget.convoID, new AnimationController(duration: new Duration(milliseconds: 800), vsync: this), (){
//              txtInputFocusNode.unfocus();
//            }),
        child: (allInfoIsAvailable) ? msgStream() : new Container(
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

        sort: (a, b) => (b.key.compareTo(a.key)),
        itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, ___) {

          Map msg = snapshot.value;
          //final animationController =  new AnimationController(duration: new Duration(milliseconds: 800), vsync: idk);
          // return new Msg(msg['message'], msg['imgURL'], msg['name'], animationController, msg['formattedTime']);

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
            margin: const EdgeInsets.only(right: 18.0),
            child: new CircleAvatar(
              backgroundImage: new NetworkImage(imgURL),
              backgroundColor: Colors.yellowAccent,
            ),
          ),
          new Expanded(
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                    new Text(name),
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
        child: new Row(
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
              child: Theme.of(context).platform == TargetPlatform.iOS ? 
              new CupertinoButton(
                child: new Text('submit'),
                onPressed: (_isWriting && _textController.text != null) ? () => _submitMsg(_textController.text): (){}
              ) : new IconButton(
                icon: new Icon(Icons.message,color: Colors.grey,),
                onPressed: (_isWriting && _textController.text != null) ? () => _submitMsg(_textController.text) : (){},
              )
            )
          ],
        ),
        decoration: Theme.of(context).platform == TargetPlatform.iOS ? 
        new BoxDecoration(
          border: new Border(top: new BorderSide(color: Colors.grey, width: 0.5))) : null
        ),
      );
    
  }


  void _submitMsg(String txt)async{

   if(!allInfoIsAvailable){
     return;
   }
    if(widget.convoID == globals.id){
      sendFeedbackMsg();
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
  var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
  var now = formatter.format(new DateTime.now());
  DatabaseReference ref = FirebaseDatabase.instance.reference();
  var key = ref.child('convos').child(widget.convoID).push().key;
  Map message = {'to':widget.recipID,'from':globals.id,'message':_textController.text, 'formattedTime':now};
  ref.child('feedback').push().set(message);// CREATE MESSAGE
  ref.child('convos').child(widget.convoID).push().set(message); // SEND THE MESSAGE
  ref.child('convoLists').child(globals.id).child(widget.recipID).update({'recentMsg':_textController.text, 'time':key,'formattedTime':now});// IDK
  ref.child('convoLists').child(widget.recipID).child(globals.id).update({'recentMsg':_textController.text, 'time':key,'formattedTime':now,'new':true});
return;

}

  void sendFeedbackMsg(){
  var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
  var now = formatter.format(new DateTime.now());
  DatabaseReference ref = FirebaseDatabase.instance.reference();
  Map message = {'to':'thumbsout','from':globals.id,'message':_textController.text, 'formattedTime':now}; // CREATE MESSAGE
  ref.child('convos').child(globals.id).push().set(message);
}




Future<void> sendNewConvoMsg()async{

if(!allInfoIsAvailable){
  return;
}

var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
  var now = formatter.format(new DateTime.now());
  DatabaseReference ref = FirebaseDatabase.instance.reference();
  newConvo = false;
  ref.child('contacts').child(globals.id).child(widget.recipID).set({'name':getFirstName(recipFullName), 'imgURL':widget.recipImgURL});


  Map convoInfoForSender = {'recipID':widget.recipID,'convoID':widget.convoID, 'time':widget.convoID, 'imgURL':recipImgURL,
    'recipFullName': recipFullName, 'recentMsg':_textController.text,'formattedTime':now, 'new': false};
  ref.child('convoLists').child(globals.id).child(widget.recipID).set(convoInfoForSender);

  Map convoInfoForRecipient = {'recipID':globals.id,'convoID':widget.convoID, 'time':widget.convoID, 'imgURL':senderImgURL, 'recipFullName':senderFullName,'recentMsg':_textController.text,'formattedTime':now, 'new':true};
  ref.child('convoLists').child(widget.recipID).child(globals.id).set(convoInfoForRecipient);

  Map message = {'to':widget.recipID,'from':globals.id,'message':_textController.text,'formattedTime':now}; // CREATE MESSAG
  ref.child('convos').child(widget.convoID).push().set(message); // SEND THE MESSAGE
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

    /// senderInfo
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


}




  Future<void> getSenderImgURL()async{
    if(widget.senderFullName != null){
      setState(() {
        senderImgURL = widget.senderImgURL;
      });
    }else {
      DatabaseReference ref = FirebaseDatabase.instance.reference();
      DataSnapshot snap = await ref.child(globals.cityCode).child('userInfo').child(globals.id).child('imgURL').once();
      setState(() {
        senderImgURL = snap.value;
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
      DataSnapshot snap = await ref.child(globals.cityCode).child('userInfo').child(globals.id).child('fullName').once();
      setState(() {
        senderFullName = snap.value;

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
      DataSnapshot snap = await ref.child(globals.cityCode).child('userInfo').child(widget.recipID).child('fullName').once();
      setState(() {
        recipFullName = snap.value;
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
      DataSnapshot snap = await ref.child(globals.cityCode).child('userInfo').child(widget.recipID).child('imgURL').once();
      setState(() {
        recipImgURL = snap.value;

      });
    }
  }


  void updateReadReceipts(){
    if(!newConvo && widget.convoID != globals.id){
      DatabaseReference ref = FirebaseDatabase.instance.reference();
      ref.child('convoLists').child(globals.id).child(widget.recipID).update({'new':false});// IDK
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
