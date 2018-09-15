import 'package:flutter/material.dart';
import '../homePage/chatList.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import '../globals.dart' as globals;
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../Chat/msgScreen.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';





class EditProfilePopup extends StatefulWidget {


  Map userInfo;
  String id;
  EditProfilePopup();
  _EditProfilePopupState createState() => new _EditProfilePopupState();

}


class _EditProfilePopupState extends State<EditProfilePopup> {

  DatabaseReference ref;
  TextEditingController controller;
  void initState() {
    super.initState();
    controller = new TextEditingController();
    ref = FirebaseDatabase.instance.reference();
    getBio();
  }


  @override
  Widget build(BuildContext context) {
    return new SimpleDialog(
      children: <Widget>[
        new Column(
          children: <Widget>[
            new Padding(padding: new EdgeInsets.all(5.0),
            child: new Text("Edit Bio",style: new TextStyle(fontWeight: FontWeight.bold),),
            ),
            new Container(
              height: 100.0,
              width: 200.0,
              child: new TextField(
                autofocus: true,
                maxLines: null,
                controller:controller,
                maxLength: 30,
                decoration: new InputDecoration(border: InputBorder.none),
              )
            ),
            new Padding(padding: new EdgeInsets.all(10.0),
            child: new MaterialButton(onPressed: ()async{
              await changeBio();
              Navigator.pop(context, true);
            },
            height: 40.0,
              minWidth: 90.0,
              color: Colors.yellowAccent,
              child: new Text('Confirm Change',style: new TextStyle(fontWeight: FontWeight.bold),),
            ),
            )
          ],
        )
      ],
    );
  }


  Future<void> getBio()async{
    try{
      DataSnapshot snap = await ref.child('bios').child(globals.id).child('bio').once();
      setState(() {
        controller.text = snap.value;
          });
    }catch(E){
      return;
    }
  }

  Future<void> changeBio()async{
    if(controller.text != null){
      await ref.child('bios').child(globals.id).update({'bio':controller.text});
    }
  }







}
