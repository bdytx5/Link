import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../globals.dart' as globals;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'notificationsStream.dart';
import '../homePage/feedStream.dart';




class NotificationPage extends StatefulWidget {

  UIcallback commentAndRideNotificationCallback;
  NotificationPage(this.commentAndRideNotificationCallback);

  _NotificationPageState createState() => new _NotificationPageState();


}
class _NotificationPageState extends State<NotificationPage> {

  void initState() {
    super.initState();
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    ref.child('notificationReciepts').child(globals.id).update({'newAlert': 'false'});
    widget.commentAndRideNotificationCallback();
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        backgroundColor: Colors.yellowAccent,
        title: new Text('Notifications', style: new TextStyle(color: Colors.black),),
        iconTheme: new IconThemeData(color: Colors.black),
      ),
        body: buildNotificationsStream(context),
    );
  }

}