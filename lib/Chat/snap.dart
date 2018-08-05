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
import '../main.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../globals.dart' as globals;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';



class SnapPage extends StatefulWidget {
  SnapPage(this.convoId,this.recipId);



  final String recipId;
  final String convoId;
  Offset postition = Offset(0.0, 0.0);
  @override
  _SnapPageState createState() => new _SnapPageState();
}

class _SnapPageState extends State<SnapPage> {

  bool picTaken = false;
  File img;
  bool frontCamera = true;
  bool textAdded = false;
  File newImg;
  TextEditingController msgController = new TextEditingController();

  String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();
  GlobalKey repaintKey = new GlobalKey();



  CameraController controller;
  Color caughtColor = Colors.grey;

  @override
  void initState() {
    super.initState();

    //setupFilePath();
    // setup();
    controller = new CameraController(cameras[0], ResolutionPreset.high);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }




  @override
  Widget build(BuildContext context) {

    return new Scaffold(
      resizeToAvoidBottomPadding: false,
      body: (img == null) ? new Container(
        child: new Stack(
          children: <Widget>[
            cameraView(),
          ],
        ),
      ) : (!picTaken && img != null) ? picPreview() : new Container(
        ///   child: picTestView(),
      ),


    );
  }



  Widget picPreview(){
    return new Container(

      height: double.infinity,
      width: double.infinity,
      child: new Stack(
        children: <Widget>[
//          new RepaintBoundary(
//            key: globalKey,
//            child:
//          ),
      new RepaintBoundary(
      key: repaintKey,
       child: new Stack(
          children: <Widget>[

           new Container(
                decoration:  new BoxDecoration(
                  image:new DecorationImage(image: FileImage(img),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            (textAdded) ? new DragBox(new Offset(0.0, 200.0), "square", Color.fromRGBO(0, 0, 0, 0.75),msgController) : new Container(),
          ],
        ),
    ),


          new Align(
            alignment: new Alignment(-0.9, -0.9),
            child: new IconButton(icon: Icon(Icons.close,color: Colors.yellowAccent,), onPressed: (){
              setState(() {
                textAdded = false;
                img = null;
                msgController.clear();
              });
            }),
          ),
          new Align(
            alignment: new Alignment(0.9, 0.7),
            child: new IconButton(icon: new Icon(Icons.mode_edit, color: Colors.white,), onPressed: (){
              setState(() {
                if(textAdded){
                  textAdded = false;
                }else{
                  textAdded = true;
                }
              });
            }),
          ),
          new Align(
            alignment: new Alignment(0.9, 0.8),
            child: new IconButton(icon: new Icon(Icons.send, color: Colors.white,), onPressed: _sendImage),
          ),
        ],
      ),
    );
  }

  Future<void>setup()async{
    final Directory systemTempDir = Directory.systemTemp;
    img = await new File('${systemTempDir.path}/${'ddssd'}.png').create();
  }


  Widget picTestView(){
    return new Container(
        height: double.infinity,
        width: double.infinity,
        child: new Container(
          decoration: new BoxDecoration(
              image: new DecorationImage(image:new FileImage(newImg), fit: BoxFit.cover )

          ),
        )

    );
  }

  Future<void> takePicture() async {

    print(msgController.text);
    if (!controller.value.isInitialized) {

      return null;
    }

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }
    final Directory extDir = await getTemporaryDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await new Directory(dirPath).create(recursive: true);
    String time = timestamp();
    File newImg = new File('$dirPath/idk.png');
    img = new File('$dirPath/${time}.png');

    try {
      await controller.takePicture('$dirPath/${time}.png');
      setState(() {



      });
    } on CameraException catch (e) {
      // _showCameraException(e);
      return null;
    }

  }

//  Future<void> _capturePng() async {
//    RenderRepaintBoundary boundary = globalKey.currentContext.findRenderObject();
//    ui.Image image = await boundary.toImage();
//    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png); // fail
//    Uint8List pngBytes = byteData.buffer.asUint8List();
//    final Directory extDir = await getTemporaryDirectory();
//    final String dirPath = '${extDir.path}/Pictures/flutter_test';
//    await new Directory(dirPath).create(recursive: true);
//    String time = timestamp();
//    img = new File('$dirPath/${time}.png');
//    await img.writeAsBytes(pngBytes);
//    setState(() {
//     // picTaken = true;
//    });
//  }
//


  Future<void> _sendImage()async{
    if(img == null){
      return;
    }
    try{
      await _capturePng();
    }catch(e){
      return;
    }
    var url = await uploadCoverPhoto(img,globals.id);
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    var now = formatter.format(new DateTime.now());
    Map msg = {
      'url':url,
      'formmatedTime':now,
      'type':'glimpse',
      'from':globals.id,
      'to':widget.recipId,
      'viewed' : false,
    };
    try{
      await FirebaseDatabase.instance.reference().child('convos').child(widget.convoId).push().set(msg);
      Navigator.pop(context);
    }catch(e){
      return;
    }

  }


  Future<void> _capturePng() async {
    final Directory extDir = await getTemporaryDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await new Directory(dirPath).create(recursive: true);
    String time = timestamp();
    img = new File('$dirPath/${time}.png');

    RenderRepaintBoundary boundary = repaintKey.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage();
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    await img.writeAsBytesSync(pngBytes);
    setState(() {

    });
  }


  Future<String> uploadCoverPhoto(File img, String id) async {

    try{
      final StorageReference ref = await FirebaseStorage.instance.ref().child("glimpes").child(id).child(timestamp());
      final dataRes = await ref.putData(img.readAsBytesSync());
      final dwldUrl = await dataRes.future;
      return dwldUrl.downloadUrl.toString();

    }catch(e){
      print(e);
      throw new Exception(e);
    }

  }


  Widget cameraView(){
    return new
    Stack(
      children: <Widget>[
        new Container(
            height: double.infinity,
            width: double.infinity,
            child:  (!controller.value.isInitialized) ? new Container() :
            new AspectRatio(
              aspectRatio:
              controller.value.aspectRatio,

              child: CameraPreview(controller),
            )
        ),
        new Align(
          alignment: new Alignment(0.0, 0.9),
          child: new Container(
            height: 50.0,
            width: 50.0,
            decoration: new BoxDecoration(
                color: Colors.transparent,
                border: new Border.all(color: Colors.white,width: 2.0,),
                shape: BoxShape.circle
            ),
            child: new InkWell(
                onTap: () {
                         takePicture();
                  //  _capturePng();

//                  Navigator.push(context,
//                      new MaterialPageRoute(
//                          builder: (context) => new viewPic()));
                } ),
          ),
        ),

        new Align(
          alignment: new Alignment(0.9, 0.7),
          child: new IconButton(icon: new Icon(Icons.switch_video,color: Colors.white), onPressed: _toggleCameras),
        ),
        new Align(
          alignment: new Alignment(-0.9, -0.9),
          child: new IconButton(icon: new Icon(Icons.arrow_back,color: Colors.white), onPressed: (){
            Navigator.pop(context);
          }),
        )
      ],
    );
  }



  void _toggleCameras(){
    if(cameras.length > 1 && frontCamera){
      controller = new CameraController(cameras[1], ResolutionPreset.high);
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          frontCamera = false;
        });
      });
    }else{
      if(cameras.length > 1 && !frontCamera){
        controller = new CameraController(cameras[0], ResolutionPreset.high);
        controller.initialize().then((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            frontCamera = true;
          });
        });
      }
    }
  }



}






















class DragBox extends StatefulWidget {
  final Offset initPos;
  final String label;
  final Color itemColor;
  final TextEditingController controller;


  DragBox(this.initPos, this.label, this.itemColor, this.controller);

  @override
  DragBoxState createState() => DragBoxState();
}

class DragBoxState extends State<DragBox> {
  Offset position = Offset(0.0, 0.0);
  FocusNode textNode = new FocusNode();
  TextEditingController controller;

  @override
  void initState() {
    super.initState();
    position = widget.initPos;
    controller = widget.controller;
  }


  @override
  Widget build(BuildContext context) {
    return Positioned(
        left: 0.0,
        top: position.dy,
        child: Draggable(
          data: widget.itemColor,
          child: Container(
            width: MediaQuery
                .of(context)
                .size
                .width,
            height: 50.0,
            color: widget.itemColor,
            child: Center(
               child:new TextField(
                    decoration: new InputDecoration(border: InputBorder.none),
                    style: new TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                    autofocus: true,
                    controller: controller

                ),
          ),
          ),
          onDraggableCanceled: (velocity, offset) {
            setState(() {
              position = offset;
            });
          },
          feedback: Container(
            width: MediaQuery
                .of(context)
                .size
                .width,
            height: 120.0,
            color: widget.itemColor.withOpacity(0.5),
            child: Center(
              child: Text(
                controller.text,
                style: TextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.none,
                  fontSize: 18.0,
                ),
              ),
            ),
          ),
        ));
  }
}