import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import '../main.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';

import '../postSubmission/placepicker.dart';
import 'selectSchool.dart';

class UsersNumber extends StatefulWidget{

  _UsersNumberState createState() => new _UsersNumberState();

      String fbLink;

     FirebaseApp app;
     String fullName;
     String imgURL;
     String name;
     String id;
     String phone; 
     bool loading = false;
     double loadingRad = 0.0;
     




     UsersNumber({this.app, this.name,this.fullName,this.imgURL,this.id, this.fbLink});

}

class _UsersNumberState extends State<UsersNumber>{


     FirebaseApp app;
     String fullName;
     String imgURL;
     String name;
     String id;
     String phone; 

     bool userClicked = false;


   void initState() {
    super.initState();


    

   }
     

    _UsersNumberState();

  final textContoller = new TextEditingController();
@override 
      Widget build(BuildContext context) {

        return new Scaffold(
          
          body: new Container(


            child: new Center(

              child: new Column(
                children: <Widget>[
                  new Expanded(
                    flex: 1,
                    child: new SizedBox(height: 100.0),
                     ),
                     new Padding(
                       padding: new EdgeInsets.only(top: 30.0),
                       child:  new Text("What's your number?",
                  style: new TextStyle(fontSize: 25.0,fontWeight: FontWeight.bold)),
                     ),
                  new SizedBox(height: 70.0),
             new Container(
              decoration: new BoxDecoration(
                border: new Border(bottom: new BorderSide(color: Colors.black))
              ),

               height: 50.0,
               width: 300.0,
                 child: new TextField(
                    controller: textContoller,
                    textAlign: TextAlign.center,
                    style: new TextStyle(fontSize: 25.0,color: Colors.black),
                    decoration: new InputDecoration(
                      hintStyle: new TextStyle(fontSize: 15.0),
                      hintText: 'Phone Number',
                      border: InputBorder.none
              
                    ),
                  ),

             ),
           new SizedBox(height: 50.0),
                  new Container(
                    width: double.infinity,
                    height: 60.0,
                    child: new RaisedButton(
                      child: new Text("Continue to Update Status",
                      style: new TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold)),
                      color: Colors.yellow,
                      onPressed: (){
                        continueToSelectSchool();

                      },
                    ),
                  ),
                   (widget.loading) ? new CupertinoActivityIndicator(
                  animating: widget.loading,
                  radius: widget.loadingRad,
                ): new Container(),

                new Expanded(
                  flex: 2,
                 child: new SizedBox(height:18.0),

                )
                ],
              )
            ),
          ),
        );
      }




Future<String> uploadImg(String url) async {

var response = await http.get(url);
//final Directory systemTempDir = Directory.systemTemp;
// im a dart n00b and this is my code, and it runs
//final file =  await new File('${systemTempDir.path}/test.png').create();
// var result = await file.writeAsBytes(response.bodyBytes);
final StorageReference ref =  FirebaseStorage.instance.ref().child("profilePics");
 final dataRes = await ref.putData(response.bodyBytes);
final dwldUrl = await dataRes.future;
  return dwldUrl.downloadUrl.toString();
}





void continueToSelectSchool(){


  if (!userClicked){
                        userClicked = true;
                        if(textContoller.text.length == 10){
                          setState(() {
                            widget.loading = true;
                            widget.loadingRad = 10.0;
                               });
                          uploadImg(widget.imgURL).then((url){
                            final signupInfo = UserInfo(name: widget.name,fullName: widget.fullName,id: widget.id, phoneNumber: textContoller.text, imgURL: url,fbLink: widget.fbLink);
                          setState(() {
                            widget.loading = false;
                            widget.loadingRad = 10.0;
                               });
                // need to pushpush the screen that allows the user to signup!
//              SelectSchool selectSchool = new SelectSchool(app: widget.app,userInfo: signupInfo.toJson());
//              Navigator.pushReplacement(context, new MaterialPageRoute(builder: (context) => selectSchool));
                            });
                        }else{
                          // tell the user that they have not entered enough characters!!
                            userClicked = false;
                          _errorMenu('Phone Number Error', 'Check your number', '');
                        }
                        }
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


class UserInfo{
       UserInfo({this.name,this.fullName,this.imgURL,this.id,this.phoneNumber, this.fbLink});


  String fullName;
  String id;
  String name;
  String imgURL;
  String phoneNumber;
  String fbLink;


   toJson() {
    return {
      
      "fullName": fullName,
      "id": id,
      "name": name,
       "imgURL": imgURL,
      "phone": phoneNumber,
      'fbLink':fbLink,

    
      
    };
  }

}

