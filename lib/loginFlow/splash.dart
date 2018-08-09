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
import 'package:cached_network_image/cached_network_image.dart';



class splash extends StatefulWidget {


  FirebaseApp app;
  static const routeName = 'loginPage';


  splash({this.app});

  _splashState createState() => new _splashState(app: app);

}




class _splashState extends State<splash> with TickerProviderStateMixin{
  FirebaseApp app;

  Animation<double> animation;
  Animation<double> animationBtn;
  Animation<double> firstTextAnimation;
  Animation<double> secondTextTextAnimation;
  Animation<double> thirdTextAnimation;
  Animation<double> titleAnimation;
  Animation<double> logoCloseAnimation;
  AnimationController firstTextAnimationController;
  AnimationController secondTextAnimationController;
  AnimationController thirdTextAnimationController;
  AnimationController titleController;
  AnimationController logoCloseAnimationController;
  double titleOpacity = 0.0;
  double firstTextOpacity = 0.0;
  double secondTextOpacity = 0.0;
  double thirdTextOpacity = 0.0;
  AnimationController controller;
  AnimationController btnAnimationController;
  bool firstText = false;
  bool secondText = false;
  bool thirdText = false;
  bool btnShowing = false;
  bool title = false;
  bool closing = false;
  Color gradientStart = Colors.yellowAccent; //Change start gradient color here
  Color gradientEnd = Colors.yellow[50]; //Change end gradient color here
  Color btnGradientEnd = Colors.yellowAccent[100];

  _splashState({this.app});


  void initState() {
    super.initState();



    controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);



    animation = CurvedAnimation(parent: controller, curve: Curves.bounceOut)..addListener((){
      setState(() {

      });
    });


    controller.forward();


    Future.delayed(new Duration(seconds: 2)).then((val){

      startAnimation(firstTextAnimation, firstTextAnimationController, 1);


      setState(() {
        firstText = true;
      });

    });
    Future.delayed(new Duration(milliseconds: 3600)).then((val){
      startAnimation(secondTextTextAnimation, secondTextAnimationController, 2);

      setState(() {
        secondText = true;
      });

    });
    Future.delayed(new Duration(milliseconds: 4800)).then((val){
      startAnimation(thirdTextAnimation, thirdTextAnimationController, 3);
      setState(() {
        thirdText = true;
      });

    });

    Future.delayed(new Duration(milliseconds: 5000)).then((val){
      startAnimation(titleAnimation, titleController, 4);
      setState(() {
        title = true;
      });

    });

    Future.delayed(new Duration(milliseconds: 5400)).then((val){

      btnAnimationController = AnimationController(
          duration: const Duration(milliseconds: 1000), vsync: this);

      animationBtn = Tween(begin: 0.0, end: 300.0).animate(btnAnimationController)
        ..addListener(() {
          setState(() {
            // the state that has changed here is the animation object’s value
            btnShowing = true;
          });
        });
      btnAnimationController.forward();


    });

  }

  void startAnimation(Animation animation, AnimationController controller, int text){

    controller = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);

    animation = Tween(begin: 0.0, end: 300.0).animate(controller)
      ..addListener(() {
        setState(() {
          // the state that has changed here is the animation object’s value
          switch (text) {
            case 1:
              firstTextOpacity = animation.value / 300;
              break;
            case 2:
              secondTextOpacity = animation.value / 300;
              break;
            case 3:
              thirdTextOpacity = animation.value / 300;
              break;
            case 4:
              titleOpacity = animation.value / 300;

          }
          });
      });
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    AssetImage fbIcon = new AssetImage('assets/thumbsOutLogo.png');
    return new Scaffold(
      body: new Stack(
          children: <Widget>[
      new Container(
      decoration: new BoxDecoration(
      gradient: new LinearGradient(colors: [Colors.white, Colors.white],
          begin: const FractionalOffset(0.5, 0.0),
          end: const FractionalOffset(0.0, 0.5),
          stops: [0.0,1.0],
          tileMode: TileMode.clamp
      ),
    ),
    ),

    new Center(
    child: new Container(
    child:  new Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.start,
    children: <Widget>[

    new SizedBox(height: 50.0,),


    new Container(
    height: MediaQuery.of(context).size.height/3.5,
    width: double.infinity,
    child: new Padding(padding: new EdgeInsets.only(left: 20.0, top: 50.0),
    child:  new Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.start,
    children: <Widget>[
    new Expanded(
    child:  (firstText) ? new AnimatedOpacity(
    opacity: firstTextOpacity,
    duration: new Duration(milliseconds: 1000),
    child:  new Text('Meet New People',
    style: new TextStyle(fontSize: 27.0),),): new Container(),
    ),
    new Expanded(
    child:    (secondText) ? new AnimatedOpacity(
    opacity: secondTextOpacity,
    duration: new Duration(milliseconds: 1000),
    child:  new Text('Save Money',
    style: new TextStyle(fontSize: 27.0),),): new Container(),
    ),
    new Expanded(
    child:     (thirdText) ? new AnimatedOpacity(
    opacity: thirdTextOpacity,
    duration: new Duration(milliseconds: 1000),
    child:  new Text('Get Home',
    style: new TextStyle(fontSize: 27.0),),): new Container(),
    ),







    ],
    ),
    ),

    ),

    new Expanded(
    child: new Container(
    child:   new Container(
    child: new Image(image: fbIcon),
    height: (!closing) ? animation.value * 150 : logoCloseAnimation.value *150,
    width: (!closing) ? animation.value * 150 : logoCloseAnimation.value *150,
    ),
    ),
    ),
    new Container(height: 20.0,width: double.infinity,
    child: (thirdText) ? new AnimatedOpacity(opacity: titleOpacity, duration: new Duration(seconds: 1),


    child: new Center(child: new Text('Thumbs-Out Ridsharing', style: new TextStyle(fontSize: 15.0),),)
    ) : new Container(),


    ),

    new Expanded(
    child: new Container(
    child: new Column(
    mainAxisAlignment: MainAxisAlignment.end,

    children: <Widget>[
    (btnShowing) ? AnimatedOpacity(
    // If the Widget should be visible, animate to 1.0 (fully visible). If
    // the Widget should be hidden, animate to 0.0 (invisible).
    opacity: animationBtn.value/300,
    duration: Duration(milliseconds: 800),
    // The green box needs to be the child of the AnimatedOpacity
    child: new Padding(padding: new EdgeInsets.only(bottom: animationBtn.value/6),
    child: new Container(
    child: new Center(
    child: new MaterialButton(
      onPressed: () {
        logoCloseAnimationController = AnimationController(
            duration: const Duration(milliseconds: 400), vsync: this);

        logoCloseAnimation = Tween(begin: 1.0, end: 0.0).animate(logoCloseAnimationController)
          ..addListener(() {

            if(logoCloseAnimation.value == 0){
              SelectSchool selectSchool = new SelectSchool(app: app);
              Navigator.pushReplacement(context, new MaterialPageRoute(builder: (context) => selectSchool));
              return;
            }
            setState(() {
              closing = true;
            });

          });
        logoCloseAnimationController.forward();
      },
      child: new Text('Continue',style: new TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),

    ) ),
    ),

    height: 75.0,
    width: 300.0,
    color: Colors.yellow,
    ),
    )
    ) : new Container()
    ],

    ),


    ),
    ),




    ],
    )
    ),
    )
    ],
    ),












    );
  }
  





}

