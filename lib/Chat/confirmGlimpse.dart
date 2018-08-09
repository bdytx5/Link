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

  GlimpsePopUp(this.recipId, this.convoId, this.img, this.recipImgURL, this.recipFullName,this.fromCameraRoll);
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
               new Expanded(child: new Text(widget.recipFullName, style: new TextStyle(fontWeight: FontWeight.bold),)),
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
                     await _sendImage();
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
    var url = await uploadGlimpse(widget.img,globals.id);
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var now = formatter.format(new DateTime.now());
    Map msg = {
      'url':url,
      'formmatedTime':now,
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
}



