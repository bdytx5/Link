import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';
import '../globals.dart' as globals;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'groupMsgScreen.dart';
//hey


class EditGroupChatPopUp extends StatefulWidget{


  _EditGroupChatPopUpState createState() => new _EditGroupChatPopUpState();


  final  bool newConvo;
  final String convoId;
 final List<String> members;
 final groupImgURL;



  EditGroupChatPopUp(this.convoId,this.members,this.groupImgURL);
}

class _EditGroupChatPopUpState extends State<EditGroupChatPopUp> {

  bool loading = false;
  TextEditingController controller = new TextEditingController();


  @override
  Widget build(BuildContext context) {
    return new SimpleDialog(
      children: <Widget>[
        new Padding(padding: new EdgeInsets.all(5.0),
            child:new Column(
              children: <Widget>[


                    new Container(
                      height: 50.0,
                      width: 200.0,
                      child: new TextField(
                        decoration: new InputDecoration(hintText: 'Group Name'),
                        controller: controller

                      ),
                    ),


                new Padding(padding: new EdgeInsets.all(5.0),
                    child: (!loading) ? new Center(
                      child: new MaterialButton(
                        height: 40.0,
                        minWidth: 90.0,
                        color: Colors.yellowAccent,
                        child: new Center(
                          child: new Text('Start Group',style: new TextStyle(fontWeight: FontWeight.bold),),
                        ),
                        onPressed: (){
                          // push group message screen
                          if(controller.text != null){
                            if(controller.text.length > 0){
                              Map convoInfo = {'convoID': widget.convoId,'newConvo': true,'groupMembers': widget.members, 'groupName': controller.text,'groupImg':widget.groupImgURL};
                              Navigator.pop(context,convoInfo);
                            }
                            }
                        },
                      ),
                    ) : new Center(
                      child: new CircularProgressIndicator(),
                    )
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



}


