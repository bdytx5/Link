import 'package:flutter/material.dart';

import '../globals.dart' as globals;
import 'package:flutter/rendering.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

class NotificationsSplash extends StatefulWidget{




  _NotificationsSplashState createState() => new _NotificationsSplashState();


  }

class _NotificationsSplashState extends State<NotificationsSplash> {
  // profilePage({Key key, this.layoutGroup, this.onLayoutToggle,}) : super(key: key);

  AssetImage androidPhone = new AssetImage('assets/androidPhone100.png');
  AssetImage iphonePhone = new AssetImage('assets/iphone100.png');
  AssetImage signalIcon = new AssetImage('assets/logoSignal.png');
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  FirebaseMessaging _firMes = new FirebaseMessaging();
  static const platform = const MethodChannel('thumbsOutChannel');
  static const BasicMessageChannel _chan = const BasicMessageChannel('notificationMsgChannel', StandardMessageCodec());
  bool declined = false;

  void initState() {
    super.initState();
    handleNotificationsRequest();
  }


  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
        onWillPop: () async {
      return false;
    },

     child: new Scaffold(
        resizeToAvoidBottomPadding: false,
        body: new Stack(
          children: <Widget>[
            new Container(
                child:new Padding(padding: new EdgeInsets.only(bottom: 200.0),
                  child:  new Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Padding(padding: new EdgeInsets.only(top: 100.0,bottom: 50.0),
                        child:   new RichText(
                            maxLines: 1,
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.clip,
                            text: new TextSpan(
                                style: new TextStyle(fontSize: 25.0, color: Colors.black),
                                children: <TextSpan>[
                                  new TextSpan(text: 'Stay in the ',
                                      style: new TextStyle()),
                                  new TextSpan(text: 'Link',style: new TextStyle(fontWeight: FontWeight.bold))]
                            )),
                      ),

                new RichText(
                  maxLines: 1,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.clip,
                  text: new TextSpan(
                    style: new TextStyle(fontSize: 14.0, color: Colors.black),
                    children: <TextSpan>[

                      new TextSpan(text: 'Never Miss Out',
                          style: new TextStyle(fontWeight: FontWeight.bold)),
                       new TextSpan(text: '',style: new TextStyle(fontWeight: FontWeight.bold))]
                )),



                      new Padding(padding: new EdgeInsets.only(bottom: 25.0,),
                        child:  new Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new ImageIcon(androidPhone,size: 45.0,),
                            new ImageIcon(signalIcon,size: 60.0,),
                            new ImageIcon(iphonePhone,size: 45.0,),

                          ],
                        ),

                      ),

                     new Padding(padding: new EdgeInsets.only(left: 10.0,right: 10.0),
                     child:  new Text("Turn on message alerts and never miss out on an opportunity to share a ride. This helps Link provide the best service to all it's users, including you!", textAlign: TextAlign.center,style: new TextStyle(color: Colors.grey[800],fontSize: 16.0),),
                     )


                    ],
                  ),
                )
            ),

            new Align(
              alignment: new Alignment(0.0, 0.85),
              child: new Container(
                  width: MediaQuery.of(context).size.width - 50.0,
                  height: 75.0,
                  child: new RaisedButton(onPressed: ()async{
                    _firMes.requestNotificationPermissions(const IosNotificationSettings(sound: true, badge: true, alert: true));
                  },
                    color: Colors.yellowAccent,
                    child:  new Center(
                      child: new Text('Turn On Message Alerts',style: new TextStyle(fontSize: 15.0),),
                    ),
                  )
              ),
            ),

    new Align(
    alignment: new Alignment(0.0, 0.95),
    child: new GestureDetector(
      onTap: (){
        _warningMenu('Change In Settings', "In order to allow notifications, we can redirect you to settings", '').then((res)async{
          if(res){
            declined = true;
            _firMes.requestNotificationPermissions(const IosNotificationSettings(sound: true, badge: true, alert: true));
          }else{
            Navigator.pop(context,false);
          }
        });
      },
      child: new Text("No thanks"),
    )
    )
          ],
        )
    ));
  }


  void handleNotificationsRequest() async {
    _chan.setMessageHandler((msg)async{
      if(msg == 1){
        final prefs = await _prefs;
        prefs.setBool('notifications', true);
        Navigator.pop(context,false);
      }else{
        final prefs = await _prefs;
        prefs.setBool('notifications', false);

if(!declined){
  _warningMenu('Change in Settings', "In order to allow notifications, we can redirect you to settings", '').then((res){
    if(res){
      Navigator.pop(context,true);
    }else{
      Navigator.pop(context,false);
    }
  });
}else{
  Navigator.pop(context,true);
}
      }
    });
  }


  Future<bool> _warningMenu(String title, String primaryMsg, String secondaryMsg) async {
    var decision = await showDialog(
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
