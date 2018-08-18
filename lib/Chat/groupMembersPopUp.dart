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
import '../homePage/chatList.dart';
import '../profilePages/profilePage.dart';

class ViewGroup extends StatefulWidget{


  _ViewGroupState createState() => new _ViewGroupState();


  final String convoId;
  final String groupName;




  ViewGroup(this.convoId, this.groupName);
}

class _ViewGroupState extends State<ViewGroup> {

  bool loading = false;
  TextEditingController controller = new TextEditingController();

  List<User> userList = new List();


  @override
  Widget build(BuildContext context) {
    return new SimpleDialog(
      children: <Widget>[
        new Center(
          child: new Padding(padding: new EdgeInsets.only(bottom: 20.0,left: 5.0,right: 5.0),
            child: new FittedBox(
              child: Text(widget.groupName,style: new TextStyle(fontSize: 20.0,fontStyle: FontStyle.italic),),
              fit: BoxFit.scaleDown,
            )
          ),
        ),
        (userList.length != 0) ? new Container(

            width: 200.0,
            height: 300.0,
            child: new ListView.builder(
                itemCount: userList.length,
                itemBuilder: (BuildContext context, int index){
                  return new Card(
                    child: new ListTile(
                      leading: new CircleAvatar(
                        backgroundImage: new CachedNetworkImageProvider(userList[index].imgUrl),
                      ),
                      title:
                          new FittedBox(
                            child: new Text(userList[index].fullName,style: new TextStyle(fontWeight: FontWeight.bold,fontSize: 16.0,),textAlign: TextAlign.left,),
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft
                          ),
                      onTap: (){


                        Navigator.push(context,
                            new MaterialPageRoute(builder: (context) => new ProfilePage(id: userList[index].id,profilePicURL: userList[index].imgUrl,firstName: '',fullName: userList[index].fullName)));
                      },
                    ),
                  );
                }
            )
        ) : new CircularProgressIndicator()
      ],
    );
  }



  void initState() {
    super.initState();
    grabAllGroupMembers();
  }



Future<void> grabAllGroupMembers()async{
    var ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child('groupChatLists').child(widget.convoId).once();
    List<String> idList = List.from(snap.value);

    for(var id in idList){
      DataSnapshot userInfo = await ref.child(globals.cityCode).child('userInfo').child(id).once();
      User user = new User(userInfo.value['fullName'], id, userInfo.value['imgURL']);
      setState(() {
        userList.add(user);
      });

    }

}


}

