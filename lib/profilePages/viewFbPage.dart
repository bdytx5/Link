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
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';



class viewFbPage extends StatefulWidget{


  static const String routeName = "home";

  _viewFbPageState createState() => new _viewFbPageState();


  final String fbLink;

  // id and profile pic url will ALWAYS be available, full name will be sometimes, and coverphoto never will be available
  viewFbPage(this.fbLink);
}

class _viewFbPageState extends State<viewFbPage> {
  // profilePage({Key key, this.layoutGroup, this.onLayoutToggle,}) : super(key: key);

  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  var loading = true;
  int i = 0;


  void initState() {
    super.initState();
    Future.delayed(new Duration(seconds: 1)).then((d){
      launchFb();
    });

    flutterWebviewPlugin.onStateChanged.listen((WebViewStateChanged d){
      if(d.type == WebViewState.finishLoad){
        setState(() {
          loading = false;
        });
      }
    });
  }



  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree

    flutterWebviewPlugin.close();

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
        resizeToAvoidBottomPadding: false,
        body: new Stack(
          children: <Widget>[
            Align(
              alignment: new Alignment(0.0, 1.0),
              child: new Container(
                height: 50.0,
                width: double.infinity,
                color: Colors.black,
                child: new Center(
                    child: new Stack(
                      children: <Widget>[

                        (!loading) ? new Center(child: new IconButton(icon: new Icon(Icons.close,color: Colors.yellowAccent,size: 30.0), onPressed:_goBack),) : new Container(),

                        (loading) ? new Center(child: new CircularProgressIndicator()) : new Container(),

                      ],
                    )

                ),
              ),
            ),

            Align(
              alignment: new Alignment(0.0, -1.0),
              child: new Container(
                height: 50.0,
                width: double.infinity,
                color: Colors.white,

              ),
            )
          ],
        )
        );
  }


  void launchFb(){
    flutterWebviewPlugin.launch(
        widget.fbLink,
        rect: new Rect.fromLTWH(
            0.0,
            50.0,
            MediaQuery.of(context).size.width,
            (MediaQuery.of(context).size.height - 100.0)));
       }

  void _goBack(){
      Navigator.pop(context);
  }



    }