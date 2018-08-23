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



class viewPicPage extends StatefulWidget{


  static const String routeName = "home";

  _viewPicPageState createState() => new _viewPicPageState();

  final bool cover;
  final String profilePicURL;

  // id and profile pic url will ALWAYS be available, full name will be sometimes, and coverphoto never will be available
  viewPicPage(this.cover, this.profilePicURL);
}

class _viewPicPageState extends State<viewPicPage> {
  // profilePage({Key key, this.layoutGroup, this.onLayoutToggle,}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        body: new GestureDetector(
          child: new Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.grey[800],
            child: new Center(
              child: (!widget.cover && widget.profilePicURL != null) ? new Container(
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
                      image: new CachedNetworkImageProvider(widget.profilePicURL),
                      fit: BoxFit.contain),),
              ) : (widget.profilePicURL != null) ?  new Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                decoration: new BoxDecoration(image: new DecorationImage(
                    image: new CachedNetworkImageProvider(widget.profilePicURL),
                    fit: BoxFit.cover),),
              ) : new Container()
            ),
          ),
          onTap: () {
            Navigator.pop(context);
          },
        )
    );
  }

}
