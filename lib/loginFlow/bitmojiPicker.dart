import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import '../main.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../postSubmission/placepicker.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../globals.dart' as globals;
import '../homePage/home.dart';
import '../homePage/feed.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signupPopup.dart';
import 'customizeProfile.dart';
import '../homePage/home.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
// select school will accept push the placeInfo and the snap graph to the profile customization page....

class BitmojiPicker extends StatefulWidget {
  _BitmojiPickerState createState() => new _BitmojiPickerState();





}

class _BitmojiPickerState extends State<BitmojiPicker> with SingleTickerProviderStateMixin{
  TabController _tabController;

  List<String> bitmojiList = List<String>();
  AssetImage femaleImage = new AssetImage('assets/femaleIcon65.png');
  AssetImage maleIcon = new AssetImage('assets/maleIcon65.png');
  bool loading = false;

  void initState() {
    super.initState();
    _tabController = new TabController(vsync: this, initialIndex: 1, length: 2);
    grabBitmojis();
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        iconTheme: new IconThemeData(color: Colors.black),
        backgroundColor: Colors.yellowAccent,
        title: new Text('Choose your avatar!',style: new TextStyle(color: Colors.black),),
        bottom: new TabBar(
            controller: _tabController,
            tabs: <Widget>[
          new ImageIcon(femaleImage,color: Colors.black,),
          new ImageIcon(maleIcon,color: Colors.black,),
        ]),
      ),
        body: new Stack(
          children: <Widget>[
            new TabBarView(
                controller: _tabController,
                children: <Widget>[
                  new Container(
                    child: new GridView.builder(
                        itemCount: (bitmojiList != null) ? bitmojiList.length : 0,
                        gridDelegate:
                        new SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          return new InkWell(
                            child: Container(
                              height: 25.0,
                              width: 25.0,
                              child: new Image.network('https://image.ibb.co/hS9KeT/IMG_1264.jpg'),
                            ),
                            onTap: ()async{
                              if(loading){
                                return;
                              }
                              setState(() {loading = true;});
                              var file = await downloadImg('https://image.ibb.co/hS9KeT/IMG_1264.jpg');
                              var im = await cropImage(file);
                              var url = await uploadImg(im, FirebaseDatabase.instance.reference().push().key);
                              setState(() {loading = false;});
                              Navigator.pop(context, url);
                            },
                          );
                        }),
                  ),

                  new Container(
                    child: new GridView.builder(
                        itemCount: (bitmojiList != null) ? bitmojiList.length : 0,
                        gridDelegate:
                        new SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          return new InkWell(
                            child: Container(
                              height: 25.0,
                              width: 25.0,
                              child: new Image.network('https://image.ibb.co/hS9KeT/IMG_1264.jpg'),
                            ),
                            onTap: ()async{
                              setState(() {loading = true;});
                              var file = await downloadImg('https://image.ibb.co/hS9KeT/IMG_1264.jpg');
                              var im = await cropImage(file);
                              var url = await uploadImg(im,FirebaseDatabase.instance.reference().push().key);
                              setState(() {loading = false;});
                              Navigator.pop(context, url);
                            },
                          );
                        }),
                  )
                ]),
             new Center(
               child: (loading) ? new CircularProgressIndicator() : new Container(),
             )
          ],
        )
    );
  }


  Future<void> grabBitmojis()async{
    var snap = await FirebaseDatabase.instance.reference().child('bitmojis').once();
    setState(() {
      bitmojiList = List.from(snap.value);
      print(bitmojiList);
    });
  }


  Future<File> downloadImg(String url)async{
      try{
        var response = await http.get(url);
        final Directory systemTempDir = Directory.systemTemp;
        final file = await new File('${systemTempDir.path}/test.png').create();
        var result = await file.writeAsBytes(response.bodyBytes);
        return result;
      }catch(e){
        print(e);
        throw new Exception(e);
      }
    }


    Future<img.Image> cropImage(File imgFile)async{
    var imgr = await imgFile.readAsBytes();
    img.Image im =  img.decodeImage(imgr);
    var croppedImg = img.copyCrop(im, 60, 60, 280, 310);
    return croppedImg;
    }



  Future<String> uploadImg(img.Image image, String path2) async {
    try{
      var bytes = img.encodePng(image);
      final StorageReference ref = await FirebaseStorage.instance.ref().child("bitmojis").child(path2);
      final dataRes = await ref.putData(bytes);
      final dwldUrl = await dataRes.future;
      return dwldUrl.downloadUrl.toString();
    }catch(e){
      print(e);
      throw new Exception(e);
    }

  }



}




//return new Container(
//color: Colors.white30,
//child: new GridView.count(
//crossAxisCount: 4,
//childAspectRatio: 1.0,
//padding: const EdgeInsets.all(4.0),
//mainAxisSpacing: 4.0,
//crossAxisSpacing: 4.0,
//children: <String>[
//'http://www.for-example.org/img/main/forexamplelogo.png',
//'http://www.for-example.org/img/main/forexamplelogo.png',
//'http://www.for-example.org/img/main/forexamplelogo.png',
//'http://www.for-example.org/img/main/forexamplelogo.png',
//'http://www.for-example.org/img/main/forexamplelogo.png',
//'http://www.for-example.org/img/main/forexamplelogo.png',
//'http://www.for-example.org/img/main/forexamplelogo.png',
//'http://www.for-example.org/img/main/forexamplelogo.png',
//'http://www.for-example.org/img/main/forexamplelogo.png',
//'http://www.for-example.org/img/main/forexamplelogo.png',
//'http://www.for-example.org/img/main/forexamplelogo.png',
//].map((String url) {
//return new GridTile(
//child: new Image.network(url, fit: BoxFit.cover));
//}).toList()),
//);
