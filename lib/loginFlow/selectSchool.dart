import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';
import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import '../main.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../postSubmission/placepicker.dart';
import 'package:flutter/services.dart';

import '../globals.dart' as globals;
import '../homePage/home.dart';
import '../homePage/feed.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signupPopup.dart';
import 'customizeProfile.dart';
import '../homePage/home.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

// select school will accept push the placeInfo and the snap graph to the profile customization page....


/// if the user has already logged in, we should show the continue button, otherwise, we will show the login button....
///

class SelectSchool extends StatefulWidget {
  _SelectSchoolState createState() => new _SelectSchoolState();

  final FirebaseApp app;
  final bool userHasAlreadySignedIn;
  final Map userInfo;

  SelectSchool({this.app, this.userHasAlreadySignedIn, this.userInfo});
}

class _SelectSchoolState extends State<SelectSchool> {
  FirebaseApp app;
  List<School> schoolList = List<School>();
  int selectedIndex = -1;
  bool userClickedFB = false;
  static final FacebookLogin facebookSignIn = new FacebookLogin();
  AssetImage fbIcon = new AssetImage('assets/fb.png');


  void initState() {
    super.initState();
      grabSchools();
  }



  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      resizeToAvoidBottomPadding: false,
        body: new Stack(
      children: <Widget>[
        new Column(
          children: <Widget>[
            new Padding(
              padding: new EdgeInsets.only(top: 85.0, bottom: 25.0),
              child: new Text(
                'Select Your School!',
                style:new TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
              ),
            ),

            new Divider(),

            new Expanded(
              child:new Padding(padding: new EdgeInsets.only(bottom: 100.0),
              child: (schoolList.length != 0) ? schoolListView() : new Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.black,
                ),
              ),
              )
            ),



          ],
        ),
        (userClickedFB)
            ? new Center(
          child: new CircularProgressIndicator(),
        )
            : new Container(),









        new Align(
          alignment: new Alignment(0.0, 1.0),
          child: new Container(
            color: Colors.white,
            height: 100.0,
            width: double.infinity,

            child:(selectedIndex != -1 && !widget.userHasAlreadySignedIn)
                ? new Padding(
              padding: new EdgeInsets.all(10.0),
              child: new InkWell(
                onTap: (userClickedFB) ? null : (){

                  _fbWarningMenu("Facebook Privacy Notice", "Link uses Facebook Login to recieve your Full Name, Profile Picture, and Profile Link, so other users can learn more about you.", "").then((res){

                    if(res){
                      _termsWarningMenu("Link Ridesharing Agreement", "By using Link, you agree to our terms of use.", '').then((agreed){
                        if(agreed){
                          handleFbLogin();
                        }
                      });
                    }

                  });
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child:  new Container(
                  height: 75.0,
                  width: 300.0,
                  decoration: new BoxDecoration(
                    borderRadius:
                    new BorderRadius.all(const Radius.circular(40.0)),
                    color: Colors.blue,
                  ),
                  child: new Center(
                    child: new Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        new Padding(padding: new EdgeInsets.only(top: 20.0,bottom: 20.0,left: 20.0,right: 1.0),
                            child: new Container(
                              height: 40.0,
                              width: 40.0,
                              child: new Image(image: fbIcon,color: Colors.white,),
                            )
                        ),


                        new Expanded(child: new Container(
                            height: 65.0,
                            width: 200.0 ,
                            child:  new Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                new Padding(padding: new EdgeInsets.only(right: 10.0),
                                    child: new FittedBox(
                                      child: new Text("Continue With Facebook!",style: new TextStyle(color: Colors.white, fontWeight: FontWeight.bold,),maxLines: 1,),
                                      fit: BoxFit.scaleDown,

                                    )
                                )
                              ],
                            )

                        ),)

                      ],
                    ),
                  ),
                ),
              ),
            ) : new Padding(
              padding: new EdgeInsets.all(10.0),
              child: new Container(
                  height: 75.0,
                  width: double.infinity,

                  decoration: new BoxDecoration(
                    borderRadius:
                    new BorderRadius.all(const Radius.circular(40.0)),

                    color: (selectedIndex != -1)
                        ? Colors.yellowAccent
                        : Colors.yellowAccent,
                  ),
                  child: new InkWell(
                    onTap: (selectedIndex == -1)
                        ? null
                        : () {
                      handleContinue();
                    },
                    child: new Center(
                      child: new Text(
                        (selectedIndex != -1) ?  'Continue' : 'Select Your School!',
                        style: new TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,fontSize: 15.0),
                      ),
                    ),
                  )
                 ),
            ),
          ),

        ),

      ],
        )
    );
  }






  // need a facebook login function that logs in, and gets the id of the user.


  Future<void> handleFbLogin()async{
    FacebookLoginResult result;
    bool userExists = false;
    try{//, 'user_photos'
      result = await facebookSignIn.logInWithReadPermissions(['public_profile', 'user_link']);
    }catch(e){
      _errorMenu("error", "There was an error logging in.", " Please make sure your Snap credentials are correct");
      return;
    }
    if(result.accessToken == null){
      return;
    }
    try{
      userExists = await checkIfUserExists(result.accessToken.userId);
    }catch(e){
      userExists = false;
    }
    if(userExists){
      Home homePage = Home(widget.app, result.accessToken.userId,true);
      globals.id = result.accessToken.userId;
      try{
        globals.cityCode = await getUserCityCode(result.accessToken.userId);
        Navigator.pushReplacement(context, new MaterialPageRoute(builder: (context) => homePage));
      }catch(e){
          _errorMenu('Error', "Please try logging in again.", '');
      }
    }else{
      // add selected user data to snap data
      Map userInfo = new Map();
      userInfo["city"] = schoolList[selectedIndex].city;
      userInfo['cityCode'] = schoolList[selectedIndex].cityCode;
      userInfo['school'] = schoolList[selectedIndex].schoolName;
      //do facebook graph stuff

      var fbInfo;
      try{
        fbInfo = await graphFb(result.accessToken.token);
      }catch(e){
        _errorMenu("error", 'Error logging into Facebbok, please try again.', '');
        return;
      }
      userInfo['first_name'] = fbInfo['first_name'];
      userInfo['last_name'] = fbInfo['last_name'];
      userInfo['imgURL'] = fbInfo['url'];
      userInfo['id'] = fbInfo['id'];

      if(fbInfo.containsKey('link')){
        userInfo['link'] = fbInfo['link'];
      }
      Map placeInfo = await  Navigator.push(context, new MaterialPageRoute(builder: (context) => new PlacePicker(app: widget.app, userIsSigningUp: true)));
      Navigator.pushReplacement(context, new MaterialPageRoute(builder: (context) => new customizeProfile(userInfo, placeInfo,widget.app)));
    }
  }


  Future<void> handleContinue()async{
    if(widget.userInfo != null){
      var result = widget.userInfo;
      // add selected user data to snap data
      result["city"] = schoolList[selectedIndex].city;
      result['cityCode'] = schoolList[selectedIndex].cityCode;
      result['school'] = schoolList[selectedIndex].schoolName;
      Map placeInfo = await  Navigator.push(context, new MaterialPageRoute(builder: (context) => new PlacePicker(app: widget.app, userIsSigningUp: true)));
      if(placeInfo != null){
        Navigator.pushReplacement(context, new MaterialPageRoute(builder: (context) => new customizeProfile(result, placeInfo,widget.app)));
      }
    }else{
        handleFbLogin();
    }
  }


  Future<Map>graphFb(String token)async{

    FbGraph graph = FbGraph(token);
    try{
      Map info = await graph.me(['id', 'name', 'first_name', 'last_name', 'picture.type(large)', 'email','link']);
      return info;
    }catch(e){
      throw new Exception();
    }
  }




  Future<bool>checkIfUserExists(String id)async{
    FirebaseDatabase database = FirebaseDatabase.instance;
    try{
      DataSnapshot snap = await database.reference().child('usersCities').child(id).once();
      if(snap.value != null){
        return true;
      } else{
        return false;
      }
    }catch(e){
      throw new Exception();
    }

  }


  Future<String>getUserCityCode(String id)async{
    FirebaseDatabase database = FirebaseDatabase.instance;
    try{
      DataSnapshot snap = await database.reference().child('usersCities').child(id).child('cityCode').once();
      return snap.value;
    }catch(e){
      throw new Exception();
    }
  }




void grabSchools(){
  Map schoolData = {};
  // get current users post info
  FirebaseDatabase database = FirebaseDatabase.instance;
  database.reference().child('schools').once().then((snap) {
    schoolData = snap.value;
    print(schoolData.toString());

    schoolData.forEach((key, val) {
      School school = School(key, val['city'], val['coordinates'],val['cityCode']);
      setState(() {
        schoolList.add(school);
      });
    });
  });
}

  Widget schoolListView() {
    return new Container(
      child: new ListView.builder(
          itemCount: schoolList.length,
          itemBuilder: (context, index) {
            return new Container(
                width: double.infinity,
                height: 80.0,
                child: InkWell(
                    child: new Card(
                      color: Colors.yellowAccent,
                      child: new Row(
                        children: <Widget>[
                          new Expanded(
                            child: new Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                new Padding(
                                  padding: new EdgeInsets.only(
                                      left: 25.0, bottom: 5.0),
                                  child: new Text(
                                    schoolList[index].schoolName,
                                    style: new TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                new Padding(
                                    padding: new EdgeInsets.only(left: 25.0),
                                    child: new Text(schoolList[index].city,
                                        style: new TextStyle(fontSize: 15.0))),
                              ],
                            ),
                          ),
                          (selectedIndex == index)
                              ? new Padding(
                            padding: new EdgeInsets.only(
                                right: 20.0, left: 10.0),
                            child: new Icon(Icons.check),
                          )
                              : new Container()
                        ],
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        (!userClickedFB) ? selectedIndex = index : (){};
                      });
                    }));
          }),
    );
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




  Future<bool> _fbWarningMenu(String title, String primaryMsg, String secondaryMsg) async {
    var decision = await showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
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
              child: new Text('Agree', style: new TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
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

  Future<bool> _termsWarningMenu(String title, String primaryMsg, String secondaryMsg) async {
    var decision = await showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
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
              new Row(
                children: <Widget>[
                  new FlatButton(
                    child: new Text('View Terms', style: new TextStyle(color: Colors.black),),
                    onPressed: () {
                      Navigator.push(context, new MaterialPageRoute(builder: (context) => new WebviewScaffold(
                          url: 'https://bdytx5.github.io/termsOfService/',
                          appBar: new AppBar(
                            iconTheme: new IconThemeData(color: Colors.black),
                            backgroundColor: Colors.yellowAccent,
                            title: new Text("Terms of Service", style: new TextStyle(color: Colors.black),

                            ),
                            actions: <Widget>[
                              new Icon(Icons.clear)
                            ],
                          ))));
                    },
                  ),
                  new MediaQuery.removePadding(context: context, child:  new FlatButton(
                    child: new Text('Cancel', style: new TextStyle(color: Colors.black),),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),),
                  new FlatButton(
                    child: new Text('Agree', style: new TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              )
          ],
        );
      },
    );

    return decision;
  }




}

class schoolCell extends StatelessWidget {
  School school;
  int index;

  schoolCell(this.school, this.index);
  @override
  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        new Padding(
            padding: new EdgeInsets.all(10.0),
            child: new Container(
              child: new Image.network(school.imgURL),
              height: 35.0,
              width: 35.0,
            )),
        new Padding(
          padding: new EdgeInsets.all(10.0),
          child: new Text(school.schoolName,
              style: new TextStyle(fontSize: 40.0, color: Colors.black87)),
        ),
        (index != -1) ? new Icon(Icons.check) : new Container(),
      ],
    );
  }
}





class School {
  School(this.schoolName, this.city, this.coordinates, this.cityCode);
  String schoolName;
  String city;
  String imgURL;
  Map coordinates = {};
  String cityCode;
}



class FbGraph {

  final String _baseGraphUrl = "https://graph.facebook.com/v3.0/";
  final String token;
  FbGraph(this.token);



Future<Map<String, dynamic>> me(fields) async {
    String _fields = fields.join(",");
    var response;
    try{
      response = await http.get("$_baseGraphUrl/me?fields=${_fields}&access_token=${token}");
    }catch(e){
      throw new Exception();
    }

        Map<String, dynamic>  info = json.decode(response.body);
        Map<String, dynamic> pic = info['picture'];
        Map<String, dynamic> data = pic['data'];
        info['url'] = data['url'];

      return info;
  }
}


////////////////////////////// deprecated Snap code ///////////////////////////////////////////////
//static const platform = const MethodChannel('thumbsOutChannel');

//  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
//Widget yearCell(Color color, int index){
//  return new Container(
//    height: 30.0,
//    width: 75.0,
//    child: new InkWell(
//        onTap: (){
//          setColors(index);
//        }
//    ),
//    decoration: new BoxDecoration(
//        border: new Border.all(color: color)
//    ),
//  );
//}
//
//Color btn1 = Colors.yellowAccent;
//Color btn2 = Colors.yellowAccent;
//Color btn3 = Colors.yellowAccent;
//Color btn4 = Colors.yellowAccent;
//
//void setColors(int button){
//  setState(() {
//    switch (button){
//      case 1:
//        btn1 = Colors.black;
//        btn2 = Colors.yellowAccent;
//        btn3 = Colors.yellowAccent;
//        btn4 = Colors.yellowAccent;
//        break;
//      case 2:
//        btn1 = Colors.yellowAccent;
//        btn2 = Colors.black;
//        btn3 = Colors.yellowAccent;
//        btn4 = Colors.yellowAccent;
//        break;
//      case 3:
//        btn1 = Colors.yellowAccent;
//        btn2 = Colors.yellowAccent;
//        btn3 = Colors.black;
//        btn4 = Colors.yellowAccent;
//        break;
//      case 4:
//        btn1 = Colors.yellowAccent;
//        btn2 = Colors.yellowAccent;
//        btn3 = Colors.yellowAccent;
//        btn4 = Colors.black;
//        break;
//    }
//  });
//
//
//}





////////////////////////////////// OLD FACEBOOK LOGIN CODE ///////////////////////////////////////////////////////

//
//
//Future<Null> _loginWithFacebook() async {
//  if (userClickedFB) {
//    return;
//  }
//  setState(() {
//    userClickedFB = true;
//  });
//
//  final FacebookLoginResult result = await facebookSignIn
//      .logInWithReadPermissions(['public_profile', 'user_link']);
//  switch (result.status) {
//    case FacebookLoginStatus.loggedIn:
//      final FacebookAccessToken accessToken = result.accessToken;
//      final FirebaseDatabase database = new FirebaseDatabase(app: widget.app);
//      DataSnapshot snap = await database
//          .reference().child(schoolList[selectedIndex].cityCode)
//          .child("userInfo")
//          .child(accessToken.userId)
//          .once();
//      if (snap.value != null) {
//        /// if the user IS in the database....
//        // updateGlobalInfo(accessToken.userId);
//        Home home = Home(widget.app, accessToken.userId);
//        setState(() {
//          userClickedFB = false;
//        });
//        Navigator.pushReplacement(
//          context,
//          new MaterialPageRoute(builder: (context) => home),
//        );
//      } else {
//        /// if the user is NOT in the database....
//        globals.id = accessToken.userId;
//        globals.city = schoolList[selectedIndex].city;
//        MyGraph graph = MyGraph(accessToken.token);
//        var fbInfo = await graph.me(['id', 'name', 'first_name', 'last_name', 'picture.type(large)', 'email', 'link']);
//        if (await checkIfUserExists(fbInfo['id'])) {
//          Home homePage = Home(app, globals.id);
//          final SharedPreferences prefs = await _prefs;
//          prefs.setBool('signedUp', true);
//          globals.id = fbInfo['id'];
//          Navigator.pushReplacement(
//              context, new MaterialPageRoute(builder: (context) => homePage));
//        }else{
//          signUserUpWithFacebook(fbInfo);
//        }
//      }
//      break;
//    case FacebookLoginStatus.cancelledByUser:
//      setState(() {
//        userClickedFB = false;
//      });
//      break;
//    case FacebookLoginStatus.error:
//      setState(() {
//        userClickedFB = false;
//      });
//      break;
//  }
//}

//
//
//
//void signUserUpWithFacebook(Map fbInfo) async {
//  final destination = await Navigator.push(context, new MaterialPageRoute(builder: (context) => new PlacePicker(app: widget.app, userIsSigningUp: true)));
//  Map firstPost = await buildFirstPostWithFacebook(destination, fbInfo);
//  Map userInfo = buildUserInfo(firstPost['imgURL'],fbInfo['name']);
//  Map notificationInfo = buildNotificationInfo();
//  showDialog(context: context, barrierDismissible: false, builder: (BuildContext context) => new SignupPopUp(app, fbInfo['id'], firstPost, notificationInfo, schoolList[selectedIndex].city, userInfo, schoolList[selectedIndex].cityCode)).then((v) async{
//    Home homePage = Home(app, globals.id);
//    final SharedPreferences prefs = await _prefs;
//    prefs.setBool('signedUp', true);
//    Navigator.pushReplacement(
//        context, new MaterialPageRoute(builder: (context) => homePage));
//  });
//}
//
//void signUpUserOnOldDeviceWithFacebook() async {
//  setState(() {
//    userClickedFB = true;
//  });
//  final destination = await Navigator.push(context, new MaterialPageRoute(builder: (context) => new PlacePicker(app: widget.app, userIsSigningUp: true)));
//  final FacebookLogin userState = new FacebookLogin();
//  FacebookAccessToken currentAccessToken = await userState.currentAccessToken;
//  MyGraph graph = MyGraph(currentAccessToken.token);
//  var fbInfo = await graph.me(['id', 'name', 'first_name', 'last_name', 'picture.type(large)', 'email', 'link']);
//  Map firstPost = await buildFirstPostWithFacebook(destination, fbInfo);
//  Map userInfo = buildUserInfo(firstPost['imgURL'],fbInfo['name']);
//  Map notificationInfo = buildNotificationInfo();
//  showDialog(context: context,barrierDismissible: false, builder: (BuildContext context) => new SignupPopUp(app, fbInfo['id'], firstPost, notificationInfo, schoolList[selectedIndex].city, userInfo, schoolList[selectedIndex].cityCode )).then((v) async{
//    Home homePage = Home(app, globals.id);
//    final SharedPreferences prefs = await _prefs;
//    prefs.setBool('signedUp', true);
//    Navigator.pushReplacement(
//        context, new MaterialPageRoute(builder: (context) => homePage));
//  });
//}
//
//
//void updateGlobalsUsingLocalInfo(String id, String name, String imgURL, String city, String fullName) {
//  globals.id = id;
//  globals.imgURL = imgURL;
//  globals.city = city;
//  globals.fullName = fullName;
//  globals.name = name;
//}
//
//Future<Map> buildFirstPostWithFacebook(Map placeInfo, Map fbInfo) async {
//  var imgURL = await uploadImg(fbInfo['url']);
//  var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
//  Map post = {
//    'destination': placeInfo['city'],
//    'destinationCoordinates': placeInfo['coordinates'],
//    'fromHome': true,
//    'ghost': false,
//    'imgURL': imgURL,
//    'leaveDate': formatter.format(new DateTime.now()), // need to format...
//    'riderOrDriver': '', // user input..
//    'state': placeInfo['state'],
//    'name': fbInfo['first_name'],
//  };
//  return post;
//}
//
//Map buildUserInfo(String imgURL, String fullName) {
//  //  UsersNumber signUp = UsersNumber(app: app, name: info['first_name'], imgURL: info['url'],fullName: info['name'],id: info['id'],fbLink: info['link']); //
//  Map info = {
//    'fullName': fullName,
//    'imgURL': imgURL,
//  };
//  return info;
//}
//
//Map buildFbLinkInfo(String fbLink) {
//  return {'fbLink': fbLink};
//}
//Map buildNotificationInfo() {
//  return {'newAlert': false};
//}
//
//Map buildSocialMediaLinks(String link) {
//  return {'fbLink': link};
//}

//try{
//  if(widget.newDevice){
//    result = await logInWithSnapchat();
//    globals.id = result['id'];
//
//
//    setState(() {
//      userClickedFB = true;
//    });
//    // here we want to check if the user exists, and if they do, we want to go to the home screen
//    bool userExists = await checkIfUserExists(result['id']);
//    if(userExists){
//      Home homePage = Home(widget.app, globals.id);
//      globals.cityCode = widget.userInfo['cityCode'];
//      Navigator.pushReplacement(context, new MaterialPageRoute(builder: (context) => homePage));
//      return;
//    }
//  }else{
//    result = widget.userInfo;
//    globals.id = result['id'];
//    setState(() {
//      userClickedFB = true;
//    });
//
//
//    // here we want to check if the user exists, and if they do, we want to go to the home screen
//    bool userExists = await checkIfUserExists(result['id']);
//    if(userExists){
//      Home homePage = Home(widget.app, globals.id);
//      globals.cityCode = widget.userInfo['cityCode'];
//      Navigator.pushReplacement(context, new MaterialPageRoute(builder: (context) => homePage));
//      return;
//    }
//
//  }
//
//}catch(e){
//  print(e);
//_errorMenu("error", "There was an error logging in.", " Please make sure your Snap credentials are correct");
//  return;
//}



//Future<String> uploadImg(String url, String path1, String path2) async {
//  try{
//    var response = await http.get(url);
//    final Directory systemTempDir = Directory.systemTemp;
//// im a dart n00b and this is my code, and it runs s/o to dart async
//    final file = await new File('${systemTempDir.path}/test.png').create();
//    var result = await file.writeAsBytes(response.bodyBytes);
//    final StorageReference ref = await FirebaseStorage.instance.ref().child("bitmoji").child(path1).child(path2);
//    final dataRes = await ref.putData(response.bodyBytes);
//    final dwldUrl = await dataRes.future;
//    return dwldUrl.downloadUrl.toString();
//
//  }catch(e){
//    setState(() {
//      userClickedFB = false;
//    });
//    print(e);
//    throw new Exception(e);
//  }
//}

//
//
//Future<void> handleSnapLogin()async{
//  var result;
//  try{
//    result = await logInWithSnapchat();
//  }catch(e){
//    _errorMenu("error", "There was an error logging in.", " Please make sure your Snap credentials are correct");
//    return;
//  }
//  bool userExists = await checkIfUserExists(result['id']);
//  if(userExists){
//    Home homePage = Home(widget.app, result['id'],true);
//    globals.id = result['id'];
//    globals.cityCode = await getUserCityCode(result['id']);
//    Navigator.pushReplacement(context, new MaterialPageRoute(builder: (context) => homePage));
//    return;
//  }else{
//    // add selected user data to snap data
//    result["city"] = schoolList[selectedIndex].city;
//    result['cityCode'] = schoolList[selectedIndex].cityCode;
//    result['school'] = schoolList[selectedIndex].schoolName;
//    Map placeInfo = await  Navigator.push(context, new MaterialPageRoute(builder: (context) => new PlacePicker(app: widget.app, userIsSigningUp: true)));
//    Navigator.pushReplacement(context, new MaterialPageRoute(builder: (context) => new customizeProfile(result, placeInfo,widget.app)));
//  }
//
//}

//
//Future<dynamic> logInWithSnapchat()async{
//  try{
//    dynamic result = await  platform.invokeMethod('snapchatLogin');
//    return result;
//  }catch(e){
//    print(e);
//    throw new Exception('error');
//  }
//}
//


//
//Map buildUserInfo(String imgURL, String fullName) {
//  //  UsersNumber signUp = UsersNumber(app: app, name: info['first_name'], imgURL: info['url'],fullName: info['name'],id: info['id'],fbLink: info['link']); //
//  Map info = {
//    'fullName': fullName,
//    'imgURL': imgURL,
//  };
//  return info;
//}

