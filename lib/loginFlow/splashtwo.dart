import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'signup.dart';
import '../main.dart';
import '../globals.dart' as globals;
import '../postSubmission/placepicker.dart';
import '../homePage/feed.dart';
import 'package:flutter/cupertino.dart';
import '../homePage/home.dart';
import 'selectSchool.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:shared_preferences/shared_preferences.dart';



class splashtwo extends StatefulWidget {


  FirebaseApp app;
  static const routeName = 'loginPage';


  splashtwo({this.app});

  _splashtwoState createState() => new _splashtwoState(app: app);

}




class _splashtwoState extends State<splashtwo> with TickerProviderStateMixin{
  FirebaseApp app;
  Animation<double> animation;
  AnimationController controller;
  Animation<double> titleAnimation;
  AnimationController titleAnimationController;
  double titleOpacity = 0.0;
  double conWidth = 0.0;
  bool closing = false;
  bool title = false;
  bool pushed = false;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  bool firstTitleShowing = false;
  bool secondTitleShowing = false;
  bool thirdTitleShowing = false;
  bool arrowShowing = false;


  AssetImage fbIcon = new AssetImage('assets/thumbsOutLogo.png');

  _splashtwoState({this.app});


  void initState() {
    super.initState();
    /// first show the man running in - start in initState
    /// then show the 'meet new People' - delayed 7000
    /// then show the 'Get Home' - delayed 1700
    /// then show 'Thumbs-Out Ridesharing' - delayed 2400





    controller = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);

    animation = CurvedAnimation(parent: controller, curve: Curves.decelerate)..addListener((){
      setState(() {
          if(animation.value == 1){
            title = true;
            startAnimation(titleAnimation, titleAnimationController, 1);
          }
      });
    });
    controller.forward();


      Future.delayed(new Duration(milliseconds: 900)).then((d){
        setState(() {
          firstTitleShowing = true;
        });
        startAnimation(titleAnimation, controller, 1);
    });
    Future.delayed(new Duration(milliseconds: 2400)).then((d){
      setState(() {
        firstTitleShowing = false;
        secondTitleShowing = true;
      });
      startAnimation(titleAnimation, controller, 1);
    });
    Future.delayed(new Duration(milliseconds: 3700)).then((d){
      setState(() {
        secondTitleShowing = false;
        thirdTitleShowing = true;
      });
      startAnimation(titleAnimation, controller, 1);
    });

    Future.delayed(new Duration(milliseconds: 4500)).then((d){
      setState(() {
        arrowShowing = true;
      });

    });
  }

  Widget gradYearCell(String year){
    return new Container(
      height: 30.0,
      width: 80.0,
      child: new Text(year),

    );
  }



  @override
  Widget build(BuildContext context) {
    AssetImage fbIcon = new AssetImage('assets/thumbsOutLogo.png');
    return new Scaffold(
      backgroundColor: Colors.yellowAccent,

    //  body: yearListPicker(),

      body: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
        new Expanded(
          child: new Container(
            width: double.infinity,
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
           new Align(
            alignment: Alignment((!closing) ? (1- animation.value) * -5 : animation.value * 5 , 0.0),
          child: new Container(
            height: (!closing) ? 200.0 : (1-animation.value)*200,
            width: (!closing) ? 200.0 : (1-animation.value)*200,
            child: new Image(image: fbIcon),
          ),
        ),
           new Container(
             height: 40.0,
             width: double.infinity,
             child: (title) ? new Center(
               child: new AnimatedOpacity(opacity: (firstTitleShowing) ? animation.value : 1.0, duration: new Duration(seconds: 1),
                 child: (firstTitleShowing) ? new Text('Meet New People', style: new TextStyle(fontSize: 18.0),) : (secondTitleShowing) ? Text('Get Home', style: new TextStyle(fontSize: 18.0),) : Text('Link Ridesharing', style: new TextStyle(fontSize: 18.0),)
               ),
             ) : new Container(),
           ),

              ],
            ),
          ),
        ),
     new Padding(padding: new EdgeInsets.only(bottom: 70.0),
        child: new Container(
          height: 30.0,
          width: 30.0,
          color: Colors.transparent,
          child: (arrowShowing) ? new IconButton(icon: new Icon(Icons.arrow_forward), onPressed: () async{
            var prefs = await _prefs;
            prefs.setBool('opened', true);
            controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
            animation = CurvedAnimation(parent: controller, curve: Curves.linear)..addListener((){
              setState(() {closing = true;});
              if(animation.value > 0.75 && !pushed){
                pushed = true;
                SelectSchool selectSchool = new SelectSchool(app: app,userHasAlreadySignedIn: false);
                Navigator.pushReplacement(context, new MaterialPageRoute(builder: (context) => selectSchool));
                return;
              }
            });
            controller.forward();
          }) : new Container(),
    ),
        )

        ],
      ),


    );
  }

  void startAnimation(Animation animation, AnimationController controller, int text){
    titleOpacity = 0.0;

    controller = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);

    animation = Tween(begin: 0.0, end: 300.0).animate(controller)
      ..addListener(() {
        setState(() {
          // the state that has changed here is the animation object’s value
          switch (text) {
            case 1:
              titleOpacity = animation.value / 300;
              break;

          }
        });
      });
    controller.forward();
  }

}







class MyGraph {

  final String _baseGraphUrl = "https://graph.facebook.com/v2.8/";
  final String token;
  MyGraph(this.token);
  Future<Map<String, dynamic>> me(fields) async {
    String _fields = fields.join(",");
    final http.Response response = await http
        .get("$_baseGraphUrl/me?fields=${_fields}&access_token=${token}");
    //   return new PublicProfile.fromMap(JSON.decode(response.body));

    Map<String, dynamic>  info = JSON.decode(response.body);
    Map<String, dynamic> pic = info['picture'];
    Map<String, dynamic> data = pic['data'];
    info['url'] = data['url'];

    // as u can see i dont care about parsing json... I have more important issues


    return info;
  }
}