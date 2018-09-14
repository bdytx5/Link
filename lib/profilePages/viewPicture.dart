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
import 'editProfilePopup.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:secure_string/secure_string.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:photo_view/photo_view.dart';
import '../photoView/photo_view.dart';



class viewPicPage extends StatefulWidget{


  static const String routeName = "home";

  _viewPicPageState createState() => new _viewPicPageState();

  final bool cover;
  final bool regularPhoto;
  final String imgURL;
  final bool userIsViewingTheirOwnPhoto;
  final List<dynamic> allPhotos;
  final String photoId;

  // id and profile pic url will ALWAYS be available, full name will be sometimes, and coverphoto never will be available
  viewPicPage({this.cover, this.imgURL,this.regularPhoto,this.userIsViewingTheirOwnPhoto,this.allPhotos, this.photoId});
}

class _viewPicPageState extends State<viewPicPage> {
  // profilePage({Key key, this.layoutGroup, this.onLayoutToggle,}) : super(key: key);

  Map tagCoodinates;
  double xTag;
  double yTag;

  void initState() {
    super.initState();
    if(widget.photoId != null){
      getTagCoordinates(widget.photoId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        body: new Stack(
          children: <Widget>[
            new GestureDetector(
              child: new Container(
                height: double.infinity,
                width: double.infinity,
                color: Colors.grey[800],
                child: new Center(
                    child:new Stack(
                      children: <Widget>[
                        (!widget.cover && widget.imgURL != null && !widget.regularPhoto) ? new Container(
                          height: MediaQuery
                              .of(context)
                              .size
                              .width - 100,
                          width: MediaQuery
                              .of(context)
                              .size
                              .width - 100,
                          decoration: new BoxDecoration(shape: BoxShape.circle,
                            image: new DecorationImage(
                                image: new CachedNetworkImageProvider(widget.imgURL),
                                fit: BoxFit.contain),),
                        ) : (widget.imgURL != null && !widget.regularPhoto) ?  new Container(
                          height: MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                          decoration: new BoxDecoration(image: new DecorationImage(
                              image: new CachedNetworkImageProvider(widget.imgURL),
                              fit: BoxFit.cover),),
                        ) : (widget.regularPhoto) ? new Container(
                          child: new PhotoView(imageProvider: new NetworkImage(widget.imgURL),minScale: PhotoViewScaleBoundary.contained,loadingChild: new Container(),backgroundColor: Colors.grey[800],xTag: xTag,yTag: yTag,),
                        ) : new Container(),
//                        new Positioned(child: new Container(
//                          height: 30.0,
//                          width: 30.0,
//                          color: Colors.green,
//                        ),
//                        top: 44.0,
//                          left: 66.0,
//                        )
                      ],
                    )
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            (widget.userIsViewingTheirOwnPhoto) ? new Align(
              alignment: new Alignment(0.95, 0.95),
              child: new IconButton(icon: new Icon(Icons.delete,color: Colors.white, ), onPressed: ()async{
                // delete photo
                var res = await _photoDeleteWarningMenu("Delete Photo?", 'Are you sure you want to delete this photo?', "");
                if(res){
                  deletePhoto();
                }
              }),
            ) : new Container(),



              (tagCoodinates != null) ? new Align(
              alignment: new Alignment(0.7, 0.95),
              child: new IconButton(icon: new Icon(Icons.tag_faces,color: Colors.white, ), onPressed: ()async{
                // delete photo
                setState(() {
                  xTag = tagCoodinates['x'];
                  yTag = tagCoodinates['y'];
                });

                Future.delayed(new Duration(seconds: 2)).then((s){
                 if(mounted){
                   setState(() {
                     xTag = null;
                     yTag = null;
                   });
                 }
                });
              }),
            ) : new Container()
          ],
        )
    );
  }
  
  Future<void> deletePhoto()async{
    // need to delete the url from the array, then update this list on firebase...
    // will also need to pass back the url when popping, to remove it from the list 
    var ref = FirebaseDatabase.instance.reference();
    var newList = new List<dynamic>.from(widget.allPhotos);
      newList.remove(widget.imgURL);
        await ref.child('fbPhotos').child(globals.id).set(newList);
        Navigator.pop(context,widget.imgURL);

  }


  Future<void> getTagCoordinates(String photoId)async{
    var ref = FirebaseDatabase.instance.reference();
    var snap = await ref.child('tagCoordinates').child(globals.id).child(photoId).once();
    Map coordinates = snap.value;
    setState(() {
      tagCoodinates = snap.value;
    });

  }


  Future<bool> _photoDeleteWarningMenu(String title, String primaryMsg, String secondaryMsg) async {
    var decision = await showDialog(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text(title),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text(primaryMsg,maxLines: null,),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Delete', style: new TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            new FlatButton(
              child: new Text('Cancel', style: new TextStyle(color: Colors.black),),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );

    return decision;
  }

}
