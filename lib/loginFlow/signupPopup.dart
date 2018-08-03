import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import '../main.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../postSubmission/placepicker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:secure_string/secure_string.dart';
import 'package:flutter_native_image/flutter_native_image.dart';

import '../globals.dart' as globals;
import '../homePage/home.dart';
import '../homePage/feed.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class SignupPopUp extends StatefulWidget{



_SignupPopUpState createState() => new _SignupPopUpState();


final Map userInfo;
final Map placeInfo;
final FirebaseApp app;
final File coverPhoto;
//SignupPopUp(this.app, this.id, this.post, this.notificationInfo, this.city, this.userInfo, this.cityCode);/// FOR FACEBOOK

SignupPopUp(this.userInfo, this.placeInfo, this.coverPhoto);

}

class _SignupPopUpState extends State<SignupPopUp> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String id;
  Map post;
  Map imgInfo;
  Map notificationInfo;
  String cityCode;
  SecureString secureString = new SecureString();
  Color btn1 = Colors.yellowAccent;
  Color btn2 = Colors.yellowAccent;
  Color btn3 = Colors.yellowAccent;
  Color btn4 = Colors.yellowAccent;
  bool stage1 = true;
  bool stage2 = false;
  bool loading = false;
  String logoURL = "https://is4-ssl.mzstatic.com/image/thumb/Purple125/v4/b2/a7/91/b2a7916a-35be-5a7e-4c91-45317fb40d9c/AppIcon-1x_U007emarketing-0-0-GLES2_U002c0-512MB-sRGB-0-0-0-85-220-0-0-0-3.png/246x0w.jpg";
  String coverPhotoURL;
  String gradYear = '';
  TextEditingController postController = new TextEditingController();
  List<String> yearList = ['2019', '2020','2021','2022']; // could get this from the database maybe
  void initState() {
    super.initState();

    cityCode = widget.userInfo['cityCode'];

  }


  @override
  void dispose() {
// Clean up the controller when the Widget is removed from the Widget tree
    super.dispose();
  }

// popup menu
  @override
  Widget build(BuildContext context) {
    return new SimpleDialog(
      title: new Row(
            mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
              (stage2) ? new InkWell(child: new Icon(Icons.keyboard_arrow_left), onTap: (){
              setState(() {
                stage2 = false;
                stage1 = true;
              });
            }) : new Container(),
              new Expanded(child: new Text((stage1) ? 'Graduation Year?' : (stage2 && !loading) ? 'Which best describes you?' : 'loading...', textAlign: TextAlign.center,))
          ],
        ),
      children: <Widget>[
        new Stack(
          children: <Widget>[
            (stage1) ?  selectGradYear() : (stage2 && !loading) ? selectRiderOrDriverForSnap() : new Container(),
    (loading) ? new Align(
      alignment: new Alignment(0.0, -2.0),
      child: new CircularProgressIndicator(
        backgroundColor: Colors.black,
      )
    ): new Container(),
          ],
        )
      ],
    );
  }





  Widget selectGradYear(){
    return new Container(
      height: 170.0,
      width: double.infinity,
      child: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                yearCell(btn1, 1),
                yearCell(btn2, 2),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                yearCell(btn3, 3),
                yearCell(btn4, 4),
              ],
            )
          ],
        ),
      )
    );
  }

  Widget yearCell(Color color, int index){
    return new Padding(
      padding: new EdgeInsets.all(5.0),
      child: new Container(
        height: 50.0,
        width: 90.0,
        child: new InkWell(
          child: new Center(
            child: new Text(yearList[index - 1],style: new TextStyle(fontWeight: FontWeight.bold),),
          ),
            onTap: (){

              setState(() {
                setColors(index);
                stage1 = false;
                stage2 = true;
                gradYear = yearList[index - 1];
              });
            }
        ),
        decoration: new BoxDecoration(
            border: new Border.all(color: color),
            borderRadius: new BorderRadius.all(new Radius.circular(10.0)),
           color: Colors.yellowAccent
        ),
      ),
    );
  }



  void setColors(int button){
    setState(() {
      switch (button){
        case 1:
          btn1 = Colors.black;
          btn2 = Colors.yellowAccent;
          btn3 = Colors.yellowAccent;
          btn4 = Colors.yellowAccent;
          break;
        case 2:
          btn1 = Colors.yellowAccent;
          btn2 = Colors.black;
          btn3 = Colors.yellowAccent;
          btn4 = Colors.yellowAccent;
          break;
        case 3:
          btn1 = Colors.yellowAccent;
          btn2 = Colors.yellowAccent;
          btn3 = Colors.black;
          btn4 = Colors.yellowAccent;
          break;
        case 4:
          btn1 = Colors.yellowAccent;
          btn2 = Colors.yellowAccent;
          btn3 = Colors.yellowAccent;
          btn4 = Colors.black;
          break;
      }
    });


  }









  Widget selectRiderOrDriverForSnap(){
    return new Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Padding(padding: new EdgeInsets.all(5.0),
          child: new Container(
            decoration: new BoxDecoration(
              borderRadius: new BorderRadius.all(new Radius.circular(10.0)),
            ),
            child:new FlatButton(
              color: Colors.yellowAccent,
              child: new Text(
                'Passenger',
                style: new TextStyle(color: Colors.black),
              ),
              onPressed: () async {
                if(!loading){
                  var post =  buildFirstPostForSnap(widget.placeInfo, widget.userInfo);
                  var info = buildUserInfo(widget.userInfo['url'],'${widget.userInfo['firstName']} ${widget.userInfo['lastName']}' );
                   uploadInfoForSnap('Riding', post, info, buildNotificationInfo(), widget.userInfo['id']);
                  Navigator.pop(context);
                  return;
                }

              },
            ),
          ),
        ),

        new Padding(padding: new EdgeInsets.all(5.0),
          child: new Container(
            decoration: new BoxDecoration(
              borderRadius: new BorderRadius.all(new Radius.circular(40.0)),
            ),
            child:new FlatButton(
              color: Colors.yellowAccent,
              child: new Text(
                'Driver',
                style: new TextStyle(color: Colors.black),
              ),
              onPressed: () async {
                if(!loading){
                  setState(() {
                    loading = true;
                  });
                  var post =  await buildFirstPostForSnap(widget.placeInfo, widget.userInfo);
                  var info = await buildUserInfo(widget.userInfo['url'],'${widget.userInfo['firstName']} ${widget.userInfo['lastName']}');
                   uploadInfoForSnap('Driving', post, info, buildNotificationInfo(), widget.userInfo['id']);
                }
              },
            ),
          ),
        ),
      ],
    );
  }



  void uploadInfoForSnap(String riderOrDriver,Map post, Map usersInfo, Map notificationInfo, String id)async{
    FirebaseDatabase database = FirebaseDatabase.instance;

    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
   var now = formatter.format(new DateTime.now());
   var key = database.reference().push().key;

   if(id == null || key == null || now == null){
     _errorMenu('Error', 'Please Try again', "");
     return;
   }

    Map feedbackConvoInfo = {
      'convoID':id,
    'formattedTime':now,
    'imgURL':logoURL,
    'new':false,
    'recentMsg':'Tell us how we can improve!',
    'recipFullName':'Link Ridesharing',
    'recipID':'Link',
    'time':key,
    };


    File resizeImg;
    var cover;
    File backUpCoverSmall;
    var backupProfilePic;
    String bitmojiURL;

    try{
      resizeImg = await FlutterNativeImage.compressImage(widget.coverPhoto.path, quality: getCoverPicQualityPercentage(widget.coverPhoto.lengthSync()));
      cover = await uploadCoverPhoto(resizeImg, widget.userInfo['id']);
      backUpCoverSmall = await FlutterNativeImage.compressImage(widget.coverPhoto.path, targetHeight: 200, targetWidth: 200);
      bitmojiURL  = await uploadBitmoji(usersInfo['imgURL'], widget.userInfo['id']);
      backupProfilePic = await uploadCoverPhoto(backUpCoverSmall, widget.userInfo['id']);
    }catch(e){
      setState(() {loading = false;});
      _errorMenu('Error', 'There was an error.', 'Please try again.');
      return;
    }

    if(bitmojiURL ==null || cover ==null || backUpCoverSmall == null || backupProfilePic == null  || resizeImg == null){
      _errorMenu('Error', 'There was an error, please try again later.', '');
      return;
    }

    usersInfo['imgURL'] = bitmojiURL;
    post['imgURL'] = bitmojiURL;
    post['riderOrDriver'] = riderOrDriver;

    try{
      await database.reference().child("bios").child(id).set({'bio':widget.userInfo['bio']});
      await database.reference().child("gradYears").child(id).set(buildGraduationYear(gradYear));
      await database.reference().child(widget.userInfo['cityCode']).child("posts").child(id).set(post);
      await database.reference().child(widget.userInfo['cityCode']).child("userInfo").child(id).set(usersInfo); // more efficient for grabbing entire userbase for a search
      await database.reference().child("notificationReciepts").child(id).set(notificationInfo);
      await database.reference().child("usersCities").child(id).set({'city':widget.userInfo["city"], 'cityCode':widget.userInfo["cityCode"], 'school':widget.userInfo['school'], 'fullName':usersInfo['fullName'],'imgURL':usersInfo['imgURL']});
      await database.reference().child('commentNotificationReciepts').child(id).set({'newAlert':false});
      await database.reference().child('messageNotificationReciepts').child(id).set({'newAlert':false});
      await database.reference().child('rideNotificationReciepts').child(id).set({'newAlert':false});
      await database.reference().child("backupProfilePics").child(id).set({'imgURL':backupProfilePic});
      await database.reference().child("coverPhotos").child(id).set({'imgURL':cover});
      await database.reference().child('convoLists').child(id).child(id).set(feedbackConvoInfo);
      await database.reference().child('coordinates').child(widget.userInfo["cityCode"]).child(post['riderOrDriver']).child(id).child('coordinates').set(buildCoordinatesInfo(widget.placeInfo));
    }catch(e){
      setState(() {loading = false;});
      _errorMenu('error', 'Please try again.', '');
      return;
    }
    setState(() {loading = false;});
    final SharedPreferences prefs = await _prefs;


    Navigator.pop(context, 'success');
  }




  Future<String> uploadCoverPhoto(File img, String id) async {

    try{
      final StorageReference ref = await FirebaseStorage.instance.ref().child("coverPhotos").child(id).child(secureString.generate(length: 10,charList: ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s']));
    final dataRes = await ref.putData(img.readAsBytesSync());
    final dwldUrl = await dataRes.future;
    return dwldUrl.downloadUrl.toString();

    }catch(e){
      print(e);
      throw new Exception(e);
    }

  }

  Future<String> uploadBitmoji(String url, String userID) async {
    var key =  secureString.generate(length: 10,charList: ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s']);
    try{
      var response = await http.get(url);
//      final Directory systemTempDir = Directory.systemTemp;
//      final file = await new File('${systemTempDir.path}/${key}.png').create();
//      var result = await file.writeAsBytes(response.bodyBytes);
//      File resizeImg = await FlutterNativeImage.compressImage(result.path, quality: 100);
      final StorageReference ref = await FirebaseStorage.instance.ref().child("bitmojis").child(userID).child(key);
      final dataRes = await ref.putData(response.bodyBytes);
      final dwldUrl = await dataRes.future;
      return dwldUrl.downloadUrl.toString();
    }catch(e){
      print(e);
      throw new Exception(e);
    }
  }


  Map buildGraduationYear(String year){
    return {'gradYear': year};
  }

  Map buildNotificationInfo() {
    return {'newAlert': false};
  }


  Map buildUserInfo(String imgURL, String fullName) {
    Map info = {
      'fullName': fullName,
      'imgURL': imgURL,
    };
    return info;
  }
  Map buildUsersCities(String cityName, String cityCode) {
    Map info = {
      'cityName': cityName,
      'cityCode': cityCode,
    };
    return info;
  }
  Map buildFirstPostForSnap(Map placeInfo, Map userInfo)  {

    var nowKey = FirebaseDatabase.instance.reference().push().key;
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
    Map post = {
      'destination': placeInfo['city'],
      'fromHome': true,
      'imgURL': userInfo['imgURL'], // chaneged upload func
      'leaveDate': formatter.format(new DateTime.now()), // need to format...
      'riderOrDriver': '', // user input..
      'state': placeInfo['state'],
      'name': userInfo['firstName'],
      'key':nowKey,
      'time':formatter.format(new DateTime.now()),
      'coordinates':buildCoordinatesInfo(placeInfo),

    };
    return post;
  }

  Map buildCoordinatesInfo(Map placeInfo){
    Map coordinate = placeInfo['coordinates'];
    coordinate['time'] = FirebaseDatabase.instance.reference().push().key;
    return coordinate;
  }


  int  getCoverPicQualityPercentage(int size){
    var qualityPercentage = 100;

    if(size > 6000000){
      qualityPercentage = 80;
    }
    if(size <= 6000000 && size > 4000000){
      qualityPercentage = 85;
    }
    if(size <= 4000000 && size > 2000000){
      qualityPercentage = 90;
    }
    if(size <= 2000000 && size > 1000000){
      qualityPercentage = 95;
    }
    if(size <= 1000000){
      qualityPercentage = 100;
    }

    return qualityPercentage;

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

//
//
//Widget addPhotoAndNameForSnapchat(){
//  return new Container(
//
//    height: 170.0,
//    width: 140.0,
//    child: new Column(
//      children: <Widget>[
//        new Container(
//          height: 75.0,
//          width: 75.0,
//          decoration: new BoxDecoration(shape: BoxShape.circle, color: Colors.yellowAccent, border: new Border.all(color: Colors.black)),
//          child: new Center(
//            child: new IconButton(icon: new Icon(Icons.add_a_photo), onPressed: (){}),
//          ),
//        ),
//        new Padding(padding: new EdgeInsets.only(top: 20.0),
//          child: new Container(
//            height: 45.0,
//            width: double.infinity,
//            child: new Row(
//              children: <Widget>[
//                new Expanded(child: new TextField(
//                  decoration: new InputDecoration(hintText: 'First Name'),
//                ),),
//                new Expanded(child: new TextField(
//                  textAlign: TextAlign.center,
//                  decoration: new InputDecoration(hintText: 'Last Name',),
//                ),),
//              ],
//            ),
//          ),
//
//        )
//
//      ],
//    ),
//  );
//}



////////////////////////////// OLD FACEBOOK LOGIN FUNCTIONS/WIDGETS  /////////////////////////////////////////////////////////////

//Widget selectRiderOrDriverForFacebook(){
//  return new Row(
//    mainAxisAlignment: MainAxisAlignment.center,
//    children: <Widget>[
//      new Padding(padding: new EdgeInsets.all(5.0),
//        child: new Container(
//          decoration: new BoxDecoration(
//            borderRadius: new BorderRadius.all(new Radius.circular(10.0)),
//          ),
//          child:new FlatButton(
//            color: Colors.yellowAccent,
//            child: new Text(
//              'Passenger',
//              style: new TextStyle(color: Colors.black),
//            ),
//            onPressed: () async {
//              uploadInfoForFacebook('Rider', widget.post, widget.userInfo, widget.imgInfo, widget.notificationInfo, widget.id);
//              Navigator.pop(context);
//              return;
//              //  Navigator.pushNamedAndRemoveUntil(context, 'home', ModalRoute.withName('loginPage'));
//            },
//          ),
//        ),
//      ),
//
//      new Padding(padding: new EdgeInsets.all(5.0),
//        child: new Container(
//          decoration: new BoxDecoration(
//            borderRadius: new BorderRadius.all(new Radius.circular(40.0)),
//          ),
//          child:new FlatButton(
//            color: Colors.yellowAccent,
//            child: new Text(
//              'Driver',
//              style: new TextStyle(color: Colors.black),
//            ),
//            onPressed: () async {
//              uploadInfoForFacebook('Driver', widget.post, widget.userInfo, widget.imgInfo, widget.notificationInfo, widget.id);
//              Navigator.pop(context);
//              return;
//              //  Navigator.pushNamedAndRemoveUntil(context, 'home', ModalRoute.withName('loginPage'));
//            },
//          ),
//        ),
//      ),
//    ],
//  );
//}
//
//
//void uploadInfoForFacebook(String riderOrDriver,Map post, Map userInfo, Map imgInfo, Map notificationInfo, String id){
//  post['riderOrDriver'] = riderOrDriver;
//
//  final FirebaseDatabase database = new FirebaseDatabase(app: widget.app);
//  database.reference().child("gradYears").child(id).set(buildGraduationYear(gradYear));
//  database.reference().child(widget.cityCode).child("posts").child(id).set(post);
//  database.reference().child(widget.cityCode).child("userInfo").child(id).set(userInfo); // more efficient for grabbing entire userbase for a search
//  database.reference().child("notificationReciepts").child(id).set(notificationInfo);
//  database.reference().child("usersCities").child(id).set({'city':widget.userInfo["city"], 'cityCode':widget.cityCode});
//  updateGlobalsUsingLocalInfoForFacebook(id, post['name'], userInfo['imgURL'], widget.cityCode, userInfo['fullName'],widget.cityCode);
//  Navigator.pop(context);
//  return;
//}
//
//
//void updateGlobalsUsingLocalInfoForFacebook(String id, String name, String imgURL, String city, String fullName, String cityCode) {
//  globals.id = id;
//  globals.imgURL = imgURL;
//  globals.city = city;
//  globals.fullName = fullName;
//  globals.name = name;
//  globals.cityCode = cityCode;


//
//
//Future<String> uploadImg(String url, String id) async {
//
//
//  try{
//    var response = await http.get(url);
//    final Directory systemTempDir = Directory.systemTemp;
//// im a dart n00b and this is my code, and it runs s/o to dart async
//    final file = await new File('${systemTempDir.path}/${secureString.generate(length: 10,charList: ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s'])}.png').create();
//    var result = await file.writeAsBytes(response.bodyBytes);
//    final StorageReference ref = await FirebaseStorage.instance.ref().child("profilePics").child(id).child('idk');
//    final dataRes = await ref.putData(response.bodyBytes);
//    final dwldUrl = await dataRes.future;
//    return dwldUrl.downloadUrl.toString();
//
//  }catch(e){
//    print(e);
//    throw new Exception(e);
//  }
//
//}
//
//


//    var url = Uri.parse('http://example.com');
//  var httpClient = new HttpClient();
//  httpClient.getUrl(url)
//    .then((HttpClientRequest request) {
//      return request.close();
//    })
//    .then((HttpClientResponse response) {
//      response.transform(new StringDecoder()).toList().then((data)async {
//        var body = data.join('');
//        print(body);
//        var file = new File('foo.txt');
//
//        await file.writeAsString(body);
// var httpClient = new HttpClient();
//  httpClient.getUrl(url)
//          final StorageReference ref = await FirebaseStorage.instance.ref().child("bitmojis").child(path1).child(path2);
//          final dataRes = await ref.putData(file.readAsBytesSync());
//          final dwldUrl = await dataRes.future;
//          return dwldUrl.downloadUrl.toString();
//
//          httpClient.close();
//
//      });
//    });


//    try{
//      var req = await HttpClient().getUrl(Uri.parse("https://firebasestorage.googleapis.com/v0/b/mu-ridesharing.appspot.com/o/profilePics%2Fbitmoji%2F-LICat3jHqQy9Ic0nT93?alt=media&token=86498d4b-360f-4baa-99f9-e04316e0d7d7"));
//      var res = await req.close();
//      var data = await res.first;
//      final StorageReference ref = await FirebaseStorage.instance.ref().child("bitmojis").child(path1).child(path2);
//      final dataRes = await ref.putData(data);
//      final dwldUrl = await dataRes.future;
//      return dwldUrl.downloadUrl.toString();
//
//    }catch(e){
//      print(e);
//    }






//      new HttpClient().getUrl(Uri.parse('http://example.com'))
//          .then((HttpClientRequest request) => request.close())
//          .then((HttpClientResponse response) =>
//
////          var data = response.first
//
//              );


//    final Directory systemTempDir = await getTemporaryDirectory();
// im a dart n00b and this is my code, and it runs s/o to dart async
//   final file = await new File('${systemTempDir.path}/${'dsjbfbbsdfjdksnfh'}.png').create();
//  var result = await file.writeAsBytes(response.);
