import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';
import '../globals.dart' as globals;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

//hey


class GlimpsePopUp extends StatefulWidget{


  _GlimpsePopUpState createState() => new _GlimpsePopUpState();


  final  String recipId;
  final String convoId;
  final File img;
  final String recipImgURL;
  final String recipFullName;
  final bool fromCameraRoll;
  final bool newConvo;
  final bool userHasSentAtLeastOneMsg;


  GlimpsePopUp(this.recipId, this.convoId, this.img, this.recipImgURL, this.recipFullName,this.fromCameraRoll,this.newConvo, this.userHasSentAtLeastOneMsg);
}

class _GlimpsePopUpState extends State<GlimpsePopUp> {

  bool loading = false;
  double slideValue = 55.0;


  @override
  Widget build(BuildContext context) {
    return new SimpleDialog(
      children: <Widget>[
       new Padding(padding: new EdgeInsets.all(5.0),
        child:new Column(
          children: <Widget>[
           new Row(
             children: <Widget>[
               new CircleAvatar(
                 backgroundImage: new CachedNetworkImageProvider(widget.recipImgURL),
                 backgroundColor: Colors.transparent,
               ),
               new Expanded(child:

                   new FittedBox(
                     child: new Text(widget.recipFullName, style: new TextStyle(fontWeight: FontWeight.bold),),
                     fit: BoxFit.scaleDown,
                     alignment: Alignment.centerLeft,
                   )

               ),
               new Padding(padding: new EdgeInsets.only(right: 15.0),
               child: (!loading) ? new MaterialButton(
                 height: 40.0,
                 minWidth: 90.0,
                 color: Colors.yellowAccent,
                 child: new Center(
                   child: new Text('Send',style: new TextStyle(fontWeight: FontWeight.bold),),
                 ),
                 onPressed: ()async{
                   try{
                     if(widget.newConvo){
                       await sendNewConvoGlimpse();
                     }else{
                      await _sendImage();
                     }

                     Navigator.pop(context,true);
                   }catch(e) {
                     Navigator.pop(context, false);
                   }
                 },
               ) : new Center(
                 child: new CircularProgressIndicator(),
               )
               )
             ],
           ),
          new Row(
            children: <Widget>[
              new Container(
                height: 30.0,
                width: 200.0,
                color: Colors.transparent,
                child: new Slider(value: slideValue,
                  max: 55.0,
                  min: 0.0,
                  onChanged: (val){
                    setState(() {
                      slideValue = val;
                    });
                  },
                  activeColor: Colors.black,
                  inactiveColor: Colors.yellowAccent,

                ),
              ),
              new Text((slideValue != 55.0) ? (slideValue/5.0).toInt().toString() : 'infiniti')
            ],
          )
          ],
        )
       ),
      ],
    );
  }



  void initState() {
    super.initState();
  }



  String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();


  Future<void> _sendImage()async{
    if(widget.img == null){
      return;
    }
    setState(() {loading = true;});

    if(!widget.userHasSentAtLeastOneMsg){
      await handleContactsList();
    }


    var url = await uploadGlimpse(widget.img,globals.id);
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var now = formatter.format(new DateTime.now());
    Map msg = {
      'url':url,
      'formattedTime':now,
      'type':'glimpse',
      'from':globals.id,
      'to':widget.recipId,
      'viewed' : false,
      'duration':(slideValue == 55.0) ? 100 : (slideValue/5.0).toInt(),
    };

    if(widget.fromCameraRoll){
      msg['fromCameraRoll'] = widget.fromCameraRoll;
    }
    try{
      await FirebaseDatabase.instance.reference().child('convos').child(widget.convoId).push().set(msg);
      await FirebaseDatabase.instance.reference().child('convoLists').child(widget.recipId).child(globals.id).update({'new':true,'recentMsg':'Recieved Glimpse','formattedTime':now, 'time':FirebaseDatabase.instance.reference().push().key});
      await FirebaseDatabase.instance.reference().child('convoLists').child(globals.id).child(widget.recipId).update({'recentMsg':'Sent Glimpse','formattedTime':now, 'time':FirebaseDatabase.instance.reference().push().key});
      Navigator.pop(context);
    }catch(e){
      setState(() {loading = false;});
      throw new Exception('error');
    }
  }

  Future<String> uploadGlimpse(File img, String id) async {
    try{
      final StorageReference ref = await FirebaseStorage.instance.ref().child("glimpses").child(id).child(timestamp());
      final dataRes = await ref.putData(img.readAsBytesSync());
      final dwldUrl = await dataRes.future;
      return dwldUrl.downloadUrl.toString();
    }catch(e){
      print(e);
      throw new Exception(e);
    }
  }




  Future<void> sendNewConvoGlimpse()async{


    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var now = formatter.format(new DateTime.now());
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    var senderName;
    var senderImgURL;

    try{
      await handleContactsList();
      senderName = await getSenderFullName();
      senderImgURL = await getSenderImgURL();
      Map convoInfoForSender = {'recipID':widget.recipId,'convoID':widget.convoId, 'time':widget.convoId, 'imgURL':widget.recipImgURL,
        'recipFullName': widget.recipFullName, 'recentMsg':'New Glimpse','formattedTime':now, 'new': false};
      await ref.child('convoLists').child(globals.id).child(widget.recipId).set(convoInfoForSender);

      Map convoInfoForRecipient = {'recipID':globals.id,'convoID':widget.convoId, 'time':widget.convoId, 'imgURL':senderImgURL, 'recipFullName':senderName,'recentMsg':'New Glimpse','formattedTime':now, 'new':true};
      await ref.child('convoLists').child(widget.recipId).child(globals.id).set(convoInfoForRecipient);

      // send glimpse here

     await _sendImage();



    }catch(e){
    //  _errorMenu('Error', 'There was an error sending your message.', '');
    }
  }

Future<void> handleContactsList()async{
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child('contacts').child(globals.id).once();
    if(snap.value != null){
      List<String> contacts = List.from(snap.value);
      if(!contacts.contains(widget.recipId)){
        contacts.add(widget.recipId);
        await ref.child('contacts').child(globals.id).set(contacts);
      }
    }
}

  Future<String> getSenderImgURL()async{
    if(globals.imgURL != null){
      return globals.imgURL;
    }

    DatabaseReference ref = FirebaseDatabase.instance.reference();

    DataSnapshot snap = await ref.child(globals.cityCode).child('userInfo').child(globals.id).child('imgURL').once();
    if(snap.value != null){
      return snap.value;
    }else{
      throw new Exception();
    }
  }



  Future<String> getSenderFullName()async{

    if(globals.fullName != null){
      return globals.fullName;
    }

    DatabaseReference ref = FirebaseDatabase.instance.reference();

    DataSnapshot snap = await ref.child(globals.cityCode).child('userInfo').child(globals.id).child('fullName').once();
    if(snap.value != null){
      return snap.value;
    }else{
      throw new Exception();
    }
  }






}



