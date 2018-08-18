import 'package:flutter/material.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/widgets.dart';
//import 'package:image/image.dart' as ui;
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

List<CameraDescription> cameras;



class viewPic extends StatefulWidget {
  viewPic(this.url,this.duration,this.fromCameraRoll,this.convoId,this.glimpseKey);
  final String url;
  final String title;
  Offset postition = Offset(0.0, 0.0);
  final int duration;
  final bool fromCameraRoll;
  String convoId;
  String glimpseKey;
  final File glimpseFile;


  @override
  _viewPicState createState() => new _viewPicState();
}

class _viewPicState extends State<viewPic> with TickerProviderStateMixin {

  AnimationController _controller;
  static const int kStartValue = 10;

  String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();
  GlobalKey globalKey = new GlobalKey();
  bool glimpseLoaded = false;
  File glimpse;




  CameraController controller;
  Color caughtColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      vsync: this,
      duration: new Duration(seconds: kStartValue),
    );

/// for when we only have the url
    downloadAndAssignGlimpse().then((d){
      _controller.forward(from: 0.0);

      if(widget.duration != 100){
        Future.delayed(new Duration(seconds: widget.duration)).then((E){
          Navigator.pop(context);
        });
      }
    });
/// for when there is a file passed to this screen.. Until the firebase team fixes the animated list, this will not be available
//    _controller.forward(from: 0.0);
//
//      if(widget.duration != 100){
//        Future.delayed(new Duration(seconds: widget.duration)).then((E){
//          Navigator.pop(context);
//        });
//      }



  }



  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    super.dispose();
  }





  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body:  (glimpse != null && glimpseLoaded) ? viewPicScreen() : loadingScreen()
    );
  }


  Widget loadingScreen(){
  return new Stack(
      children: <Widget>[
        new Container(
          height: double.infinity,
          width: double.infinity,
          color: Colors.black,
          child: new Center(
            child: new CircularProgressIndicator(),
          ),
        ),
        new Align(
          alignment: new Alignment(-0.9, -0.9),
          child: new IconButton(icon: new Icon(Icons.arrow_back,color: Colors.yellowAccent,), onPressed: (){
            Navigator.pop(context);
          }),
        )
      ],

    );
  }


  /// for when we only have the link

  Widget viewPicScreen(){

    setGlimpseViewed();


    return new InkWell(
      child: new Stack(
        children: <Widget>[
          (!widget.fromCameraRoll) ?  new Container(

            height: double.infinity,
            width: double.infinity,
            decoration: new BoxDecoration(
                image: new DecorationImage(image: FileImage(glimpse),fit: BoxFit.cover,),
                color: Colors.black
            ),
          ) : new Stack(
            children: <Widget>[
              new Container(
                height: double.infinity,
                width: double.infinity,
                decoration: new BoxDecoration(
                    border: new Border(top: new BorderSide(color: Colors.white,width: 50.0),bottom:new BorderSide(color: Colors.white,width: 50.0) ),
                    image: new DecorationImage(image: FileImage(glimpse),)
                ),
              ),
              new Align(
                alignment: new Alignment(0.0, .95),
                child: new Text('FROM CAMERA ROLL!',style: new TextStyle(fontWeight: FontWeight.bold,color: Colors.black),),
              )
            ],
          ) ,

          (widget.duration != 100) ?   new Align(
            alignment: new Alignment(0.9, 0.95),
            child:new Countdown(
              fromCameraRoll: widget.fromCameraRoll,
              animation: new StepTween(
                begin: kStartValue,
                end: 0,
              ).animate(_controller),
            ),
          ) : new Align(
              alignment: new Alignment(0.9, 0.95),
              child:new Text('infiniti',style: new TextStyle(fontWeight: FontWeight.bold,color: (!widget.fromCameraRoll) ? Colors.white : Colors.black),))
        ],
      ),
      onTap: (){
        Navigator.pop(context);
      },
    );
  }


  Future<void> downloadAndAssignGlimpse()async{
    try {
      var response = await http.get(widget.url);
      final Directory extDir = await getTemporaryDirectory();
      final String dirPath = '${extDir.path}/${timestamp()}';
      await new Directory(dirPath).create(recursive: true);
      final String filePath = '$dirPath/${timestamp()}.jpg';
      glimpse = await new File('${filePath}.png').create();
      await glimpse.writeAsBytes(response.bodyBytes);
      setState(() {
        glimpseLoaded = true;
      });
    }catch(e){
      return;
    }

  }











  Future<void> setGlimpseViewed()async{
    try{
      await FirebaseDatabase.instance.reference().child('convos').child(widget.convoId).child(widget.glimpseKey).update({'viewed':true});
    }catch(e){
      print('error');
      return;
    };
  }
}

class Countdown extends AnimatedWidget {
  final bool fromCameraRoll;
  Countdown({ Key key, this.animation,this.fromCameraRoll }) : super(key: key, listenable: animation);
  Animation<int> animation;

  @override
  build(BuildContext context){
    return new Text(
      animation.value.toString(),
      style: new TextStyle(fontSize: 15.0,color: (fromCameraRoll) ? Colors.black : Colors.white),
    );
  }


/// for when we only have the link
//
//  Widget viewPicScreen(){
//
//    setGlimpseViewed();
//
//
//    return new InkWell(
//      child: new Stack(
//        children: <Widget>[
//          (!widget.fromCameraRoll) ?  new Container(
//
//            height: double.infinity,
//            width: double.infinity,
//            decoration: new BoxDecoration(
//                image: new DecorationImage(image: FileImage(glimpse),fit: BoxFit.cover,),
//                color: Colors.black
//            ),
//          ) : new Stack(
//            children: <Widget>[
//              new Container(
//                height: double.infinity,
//                width: double.infinity,
//                decoration: new BoxDecoration(
//                    border: new Border(top: new BorderSide(color: Colors.white,width: 50.0),bottom:new BorderSide(color: Colors.white,width: 50.0) ),
//                    image: new DecorationImage(image: FileImage(glimpse),)
//                ),
//              ),
//              new Align(
//                alignment: new Alignment(0.0, .95),
//                child: new Text('FROM CAMERA ROLL!',style: new TextStyle(fontWeight: FontWeight.bold,color: Colors.black),),
//              )
//            ],
//          ) ,
//
//          (widget.duration != 100) ?   new Align(
//            alignment: new Alignment(0.9, 0.95),
//            child:new Countdown(
//              fromCameraRoll: widget.fromCameraRoll,
//              animation: new StepTween(
//                begin: kStartValue,
//                end: 0,
//              ).animate(_controller),
//            ),
//          ) : new Align(
//              alignment: new Alignment(0.9, 0.95),
//              child:new Text('infiniti',style: new TextStyle(fontWeight: FontWeight.bold,color: (!widget.fromCameraRoll) ? Colors.white : Colors.black),))
//        ],
//      ),
//      onTap: (){
//        Navigator.pop(context);
//      },
//    );
//  }
//

//  Future<void> downloadAndAssignGlimpse()async{
//    try {
//      var response = await http.get(widget.url);
//      final Directory extDir = await getTemporaryDirectory();
//      final String dirPath = '${extDir.path}/${timestamp()}';
//      await new Directory(dirPath).create(recursive: true);
//      final String filePath = '$dirPath/${timestamp()}.jpg';
//      glimpse = await new File('${filePath}.png').create();
//      await glimpse.writeAsBytes(response.bodyBytes);
//      setState(() {
//        glimpseLoaded = true;
//      });
//    }catch(e){
//      return;
//    }
//
//  }



/// when we have the file
///

//  Widget viewPicScreen(){
//
//    setGlimpseViewed();
//
//
//    return new InkWell(
//      child: new Stack(
//        children: <Widget>[
//          (!widget.fromCameraRoll) ?  new Container(
//
//            height: double.infinity,
//            width: double.infinity,
//            decoration: new BoxDecoration(
//                image: new DecorationImage(image: FileImage(widget.glimpseFile),fit: BoxFit.cover,),
//                color: Colors.black
//            ),
//          ) : new Stack(
//            children: <Widget>[
//              new Container(
//                height: double.infinity,
//                width: double.infinity,
//                decoration: new BoxDecoration(
//                    border: new Border(top: new BorderSide(color: Colors.white,width: 50.0),bottom:new BorderSide(color: Colors.white,width: 50.0) ),
//                    image: new DecorationImage(image: FileImage(widget.glimpseFile),)
//                ),
//              ),
//              new Align(
//                alignment: new Alignment(0.0, .95),
//                child: new Text('FROM CAMERA ROLL!',style: new TextStyle(fontWeight: FontWeight.bold,color: Colors.black),),
//              )
//            ],
//          ) ,
//
//          (widget.duration != 100) ?   new Align(
//            alignment: new Alignment(0.9, 0.95),
//            child:new Countdown(
//              fromCameraRoll: widget.fromCameraRoll,
//              animation: new StepTween(
//                begin: kStartValue,
//                end: 0,
//              ).animate(_controller),
//            ),
//          ) : new Align(
//              alignment: new Alignment(0.9, 0.95),
//              child:new Text('infiniti',style: new TextStyle(fontWeight: FontWeight.bold,color: (!widget.fromCameraRoll) ? Colors.white : Colors.black),))
//        ],
//      ),
//      onTap: (){
//        Navigator.pop(context);
//      },
//    );
//  }
}