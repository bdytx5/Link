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
import 'confirmGlimpse.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';



class SnapPage extends StatefulWidget {
  SnapPage(this.convoId,this.recipId, this.recipImgURL, this.recipFullName,this.newConvo, this.userHasSentAtLeastOneMessage);


  final bool userHasSentAtLeastOneMessage;
  final String recipId;
  final String convoId;
  final String recipImgURL;
  final String recipFullName;
  final bool newConvo;
  Offset postition = Offset(0.0, 0.0);
  @override
  _SnapPageState createState() => new _SnapPageState();
}

class _SnapPageState extends State<SnapPage> {
  AssetImage cameraSwitchIcon = new AssetImage('assets/switchCamera65.png');
  bool picTaken = false;
  File img;
  bool frontCamera = true;
  bool textAdded = false;
  File newImg;
  TextEditingController msgController = new TextEditingController();
  bool loading = false;
  bool fromCameraRoll = false;
  double slideValue = 25.0;


  String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();
  GlobalKey repaintKey = new GlobalKey();



  CameraController controller;
  Color caughtColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    controller = new CameraController(cameras[0], ResolutionPreset.high);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
  controller?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return new Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomPadding: false,
      body: (img == null) ? new Container(
        child: new Stack(
          children: <Widget>[
            cameraView(),
          ],
        ),
      ) : (!picTaken && img != null) ? picPreview() : new Container(),
    );
  }



  Widget picPreview(){
    return new Container(

      height: double.infinity,
      width: double.infinity,
      child: new Stack(
        children: <Widget>[

          new RepaintBoundary(
           key: repaintKey,
       child: new Stack(
          children: <Widget>[
            (!fromCameraRoll) ? new Container(
                decoration:  new BoxDecoration(
                  image:new DecorationImage(image: FileImage(img),
                    fit: BoxFit.cover,
                  ),
                ),
              ) : new Container(
              decoration: new BoxDecoration(border: new Border(bottom: new BorderSide(color: Colors.white,width: 50.0),top: new BorderSide(color: Colors.white,width: 50.0),),
                  image:new DecorationImage(image: FileImage(img))

              ),
            ),

            (textAdded) ? new DragBox(new Offset(0.0, 200.0), "square", Color.fromRGBO(0, 0, 0, 0.75),msgController) : new Container(),
          ],
        ),
    ),

     new Align(
            alignment: new Alignment(-0.9, -0.9),
            child: new IconButton(icon: Icon(Icons.close,color:  (!fromCameraRoll) ? Colors.white : Colors.yellowAccent), onPressed: (){
              setState(() {
                fromCameraRoll = false;
                textAdded = false;
                img = null;
                msgController.clear();
              });
            }),
          ),

          new Align(
            alignment: new Alignment(0.9, 0.6),
            child: new Container(
                height: 40.0,
                width: 40.0,
                decoration: new BoxDecoration(color: Colors.yellowAccent,shape: BoxShape.circle,),
                child: new Center(
                child: new InkWell(child: new Icon(Icons.mode_edit, color: Colors.black,), onTap: (){
                  setState(() {
                    if(textAdded){
                      textAdded = false;
                    }else{
                      textAdded = true;
                    }
                  });
                }),
              )
            )
          ),
          new Align(
            alignment: new Alignment(0.9, 0.8),
            child: (!loading) ? new Container(
              height: 40.0,
              width: 40.0,
              decoration: new BoxDecoration(color: Colors.yellowAccent,shape: BoxShape.circle,),
              child: new Center(
                child: new InkWell( child: new Icon(Icons.send, color: Colors.black,), onTap: ()async{
                  await _capturePng();
                  var sent = await  _showConfirmGlimpse();
                  //.then((sent){
                  if(sent == null){return;}
                  if(sent){
                    Navigator.pop(context);
                  }
                  //  });
                }),
              )
            ) : new Center(
              child: new CircularProgressIndicator(),
            )
          ),
        ],
      ),
    );
  }


  Future<File> _pickImage() async {

    var imageFile;
    try{
      imageFile = await  ImagePicker.pickImage(source: ImageSource.gallery);
    }catch(e){
      return;
    }
    setState(() {
      img = imageFile;
      fromCameraRoll = true;
    });
    return imageFile;
  }

  Future<bool> _showConfirmGlimpse()async{
    // need to render the img
    if(img == null){return false;}
    showDialog(context: context, builder: (BuildContext context) => new GlimpsePopUp(widget.recipId, widget.convoId, img, widget.recipImgURL, widget.recipFullName,fromCameraRoll,widget.newConvo, widget.userHasSentAtLeastOneMessage)).then((sent){
      return sent;
    });
  }

  Future<void>setup()async{
    final Directory systemTempDir = Directory.systemTemp;
    img = await new File('${systemTempDir.path}/${'ddssd'}.png').create();
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
     Directory extDir;
    try{
      extDir = await getTemporaryDirectory();
    }catch(e){
      _errorMenu('Error', 'There was an error capturing your photo. Please try again later.', '');
      return;
    }
    final String dirPath = '${extDir.path}/glimpses';
    await new Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';
    img = new File(filePath);

    try {
      await controller.takePicture(filePath);
      setState(() {});
    } on CameraException catch (e) {
      return;
    }

  }




  Future<void> _capturePng() async {
    setState(() {
      loading = true;
    });
    try{
      final Directory extDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${extDir.path}/Pictures/flutter_test';
      await new Directory(dirPath).create(recursive: true);
      String time = timestamp();
      RenderRepaintBoundary boundary = repaintKey.currentContext.findRenderObject();
      ui.Image image = await boundary.toImage();
      ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();
      img.writeAsBytesSync(pngBytes);
      setState(() {loading = false;});
    }catch(e){
      setState(() {loading = false;});
      _errorMenu('Error', "There was an error rendering your image.", "");
    }

  }



  Widget cameraView(){
    return new Transform.scale(
        scale: 1.0,

      child:     new Stack(
        children: <Widget>[
          new Center(
            child: new Container(
                child:  (!controller.value.isInitialized) ? new Container(
                    child: new Center(
                      child: new CircularProgressIndicator(),
                    )
                ) :

                new Container(
                  height: double.infinity,
                  width: double.infinity,
                  child:  new AspectRatio(
                    aspectRatio: (MediaQuery.of(context).size.width/(MediaQuery.of(context).size.height)),
                    //   aspectRatio: controller.value.aspectRatio,
                    child:  CameraPreview(controller),
                  ),
                )

            ),
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
            alignment: new Alignment(0.45, 0.9),
            child: new Container(
            child:  new GestureDetector(
                onTap: ()async{
                  // show image picker

                  try{
                    File im =  await _pickImage();
                  }catch(e){
                    _errorMenu('Error', "Please try closing the camera, and picking another image. We are aware of this bug.", '');
                  }
                  setState(() {});

                },
                child: new Icon(Icons.photo,color: Colors.white,),
              )
            ),
          ),

          new Align(
            alignment: new Alignment(0.9, 0.9),
            child: new IconButton(icon: new ImageIcon(cameraSwitchIcon,color: Colors.white,), onPressed: _toggleCameras),
          ),
          new Align(
            alignment: new Alignment(-0.9, 0.9),
            child: new IconButton(icon: new Icon(Icons.arrow_back,color: Colors.white), onPressed: (){
              print(controller.value.aspectRatio);
              Navigator.pop(context);
            }),
          )
        ],
      )
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
  FocusNode glimpseNode = new FocusNode();

  @override
  void initState() {
    super.initState();
    position = widget.initPos;
    controller = widget.controller;
    glimpseNode.addListener(_focusListener);
  }


  void _focusListener(){

    if(glimpseNode.hasFocus){
      setState(() {
        position = Offset(0.0, 200.0);
      });
    }
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
               child:new EditableText(
                //    decoration: new InputDecoration(border: InputBorder.none),
                    style: new TextStyle(color: Colors.white),
                    cursorColor: Colors.white,

                    autofocus: true,
                    controller: controller,
                    focusNode: glimpseNode,
                 textAlign: TextAlign.center,

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
            height: 75.0,
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