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






   void initState() {
    super.initState();
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
        controller: listController,

        sort: (a, b) => (b.key.compareTo(a.key)),
        itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, ___) {

          Map msg = snapshot.value;


          //  GlimpseCell(this.msg, this.recipFullName, this.recipImgURL, this.convoId, this.glimpseKey);
          if(msg['type'] != null && msg['from'] != globals.id ){

              return GlimpseCell(msg, recipFullName, recipImgURL, widget.convoID,snapshot.key, true);

          }
          if(msg['type'] != null && msg['from'] == globals.id ){
            return GlimpseCell(msg, senderFullName, senderImgURL, widget.convoID,snapshot.key, false);
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
                    new Text(name,style: new TextStyle(fontWeight: FontWeight.bold),),
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
            new Divider(),

            new Container(
              height: 55.0,
              width: double.infinity,
              child:new Padding(padding: new EdgeInsets.only(bottom: 15.0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Padding(padding: new EdgeInsets.only(right: 15.0),

                    child: new IconButton(icon: new Icon(Icons.camera,color: Colors.grey), onPressed: (){}),
                  ),

                new Container(
                  height: 30.0,
                  width: 30.0,
                  decoration: new BoxDecoration(
                      color: Colors.yellowAccent,
                      shape: BoxShape.circle,
                      border: new Border.all(color: Colors.grey,width: 3.0)
                  ),
                  child: new InkWell(onTap: (){
                                      Navigator.push(context,
                      new MaterialPageRoute(
                          builder: (context) => new SnapPage(widget.convoID,widget.recipID)));



                  },),
                ),

                  new Padding(padding: new EdgeInsets.only(left: 15.0),

                  child: new IconButton(icon: new Icon(Icons.tag_faces,color: Colors.grey), onPressed: (){}),
                  )


                ],
              )

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


  String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();

  void _submitMsg(String txt)async{

   if(!allInfoIsAvailable){
     return;
   }
    if(widget.convoID == 'CAESIO1RccwK34OLN30OhSd6kcVqAGQ08Nbot4Qcw03dkV3m'){
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
  try{
    await ref.child('convoLists').child(globals.id).child(widget.recipID).update({'recentMsg':_textController.text, 'time':key,'formattedTime':now});// IDK
    await ref.child('convoLists').child(widget.recipID).child(globals.id).update({'recentMsg':_textController.text, 'time':key,'formattedTime':now,'new':true});
    await ref.child('feedback').push().set(message);// CREATE MESSAGE
    await ref.child('convos').child(widget.convoID).push().set(message); // SEND THE MESSAGE
  }catch(e){
    _errorMenu("Error", "There was an error sending your message.", '');
  }

}

  Future<void> sendFeedbackMsg()async{
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var now = formatter.format(new DateTime.now());

    if(globals.id != null || _textController.text != null || now == null){
      return;
    }

   // Map brettsChatlist = { 'imgURL':senderImgURL, 'formattedTime':now, 'new': true, 'recentMsg':_textController.text, 'recipFullName':senderFullName, 'recipId':globals.id, 'convoId':FirebaseDatabase.instance.reference().push().key}
    DatabaseReference ref = FirebaseDatabase.instance.reference();
   // ref.child('convoLists').child('CAESIO1RccwK34OLN30OhSd6kcVqAGQ08Nbot4Qcw03dkV3m').child(globals.id).set(value)
    Map message = {'to':'CAESIO1RccwK34OLN30OhSd6kcVqAGQ08Nbot4Qcw03dkV3m','from':globals.id,'message':_textController.text, 'formattedTime':now};
    try{
    ref.child('convos').child('').push().set(message);
    }catch(e){
      _errorMenu('Error', 'There was an error sending your message.', '');
    }
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
    ref.child('contacts').child(globals.id).child(widget.recipID).set({'name':getFirstName(recipFullName), 'imgURL':widget.recipImgURL});

    Map convoInfoForSender = {'recipID':widget.recipID,'convoID':widget.convoID, 'time':widget.convoID, 'imgURL':recipImgURL,
      'recipFullName': recipFullName, 'recentMsg':_textController.text,'formattedTime':now, 'new': false};
    ref.child('convoLists').child(globals.id).child(widget.recipID).set(convoInfoForSender);

    Map convoInfoForRecipient = {'recipID':globals.id,'convoID':widget.convoID, 'time':widget.convoID, 'imgURL':senderImgURL, 'recipFullName':senderFullName,'recentMsg':_textController.text,'formattedTime':now, 'new':true};
    ref.child('convoLists').child(widget.recipID).child(globals.id).set(convoInfoForRecipient);

    Map message = {'to':widget.recipID,'from':globals.id,'message':_textController.text,'formattedTime':now}; // CREATE MESSAG
    ref.child('convos').child(widget.convoID).push().set(message); // SEND THE MESSAGE
  }catch(e){
    _errorMenu('Error', 'There was an error sending your message.', '');
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
  chatQuery = ref.child('convos').child(widget.convoID);
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
    if(!newConvo && widget.convoID != globals.id){
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
}



class GlimpseCell extends StatefulWidget {

  GlimpseCell(this.msg, this.fullName, this.imgURL, this.convoId, this.glimpseKey,this.recipGlimpse);

  final Map msg;
  final String fullName;
  final String imgURL;
  final String convoId;
  final String glimpseKey;
  final bool recipGlimpse;




  @override
  _GlimpseCellState createState() => new _GlimpseCellState();

}

class _GlimpseCellState extends State<GlimpseCell> with TickerProviderStateMixin {


bool loading = false;
File img;
IconData icon = Icons.file_download;
bool loadedPic = false;
bool viewedPic = false;

String imgURL;
String fullName;
String time;
String glimpseURL;
String glimpseKey;
String convoId;


  @override
  void initState() {
    super.initState();
    initializeData();
  }

  void initializeData(){
    imgURL = widget.msg['imgURL'];
    viewedPic = widget.msg['viewed'];
    imgURL = widget.imgURL;
    fullName = widget.fullName;
    time = widget.msg['formattedTime'];
    glimpseURL = widget.msg['url'];
    glimpseKey = widget.glimpseKey;
    convoId = widget.convoId;
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
        child:(widget.recipGlimpse) ? recipGlimpseCell() : senderGlimpseCell(),

    );
  }


  Widget recipGlimpseCell(){
    return new Card(
      child:new InkWell(

        onTap: ()async{

          if(!loadedPic){
            await loadGlimpse();
          }else{
            if(loadedPic && !viewedPic){
              await viewGlimpse();
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
                            backgroundImage: new NetworkImage(imgURL),
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
                              child: new Text( (loadedPic && !viewedPic) ? 'New Glimpse, tap to view!':(!loadedPic && !viewedPic) ? 'New Glimpse, tap to download!' : 'Already Viewed Glimpse!', ),
                            )
                          ],
                        )
                      ],
                    )
                  ],
                  crossAxisAlignment: CrossAxisAlignment.start,
                )
            ),

            (!viewedPic) ? new Padding(padding: new EdgeInsets.all(15.0),
              child: new Container(
                  height: 30.0,
                  width: 30.0,
                  child: (loading) ? new CircularProgressIndicator(): (loadedPic && img != null) ? new Icon(Icons.image) : (!loadedPic && !viewedPic) ? new Icon(Icons.file_download) : new Icon(Icons.check)
              ),
            ) : new Container(),
          ],
        ),
      )
    );
  }





Widget senderGlimpseCell(){
  return new Container(

    child: InkWell(

        onTap: ()async{

          await loadGlimpse();
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
                       backgroundImage: new NetworkImage(imgURL),
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
                                child: new Text( (!viewedPic) ? 'Sent Glimpse!': 'Glimpse has been opened!',
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

  Future<void> viewGlimpse()async{
    Navigator.push(context, new MaterialPageRoute(builder: (context) => new viewPic(img))).then((D)async{
      setState(() {viewedPic = true;});

      try{
        await FirebaseDatabase.instance.reference().child('convos').child(widget.convoId).child(widget.glimpseKey).update({'viewed':true});
      }catch(e){
        print('error');
        return;
      }
    });

  }


  Future<void> loadGlimpse()async{
    setState(() {
      loading = true;
    });
    try{
      http.Response imgRes = await http.get(glimpseURL);
      var bytes = imgRes.bodyBytes;
      final Directory extDir = await getTemporaryDirectory();
      final String dirPath = '${extDir.path}/Pictures/flutter_test';
      await new Directory(dirPath).create(recursive: true);
      String time = timestamp();
      img = new File('$dirPath/${time}.png');
      img.writeAsBytes(bytes);

    }catch(e){
      setState(() {loading = false;});
    }

    setState(() {loading = false;
    loadedPic = true;
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
