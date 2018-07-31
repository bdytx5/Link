import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../loginFlow/login_page.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import '../main.dart';
import 'placepicker.dart';
import '../globals.dart' as globals;
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

//hey


class PostPopUp extends StatefulWidget{

  static const String routeName = "/submitPost";

  _PostPopUpState createState() => new _PostPopUpState();


  FirebaseApp app;
  PostPopUp(this.app);


}

class _PostPopUpState extends State<PostPopUp> {
  bool loading = false;
  bool selected = false;
  String destination = '';
  String state = '';
  String name = '';
  bool fromHome = true;
  Map currentUsersPost = {};
  Map coordinates = {};
  DateTime currentlySelectedDate = new DateTime.now().add(new Duration(days: 1));
  TextEditingController postController = new TextEditingController();
  String originDescription = '';
  String destinationDescription = '';
  String logoURL = "https://is4-ssl.mzstatic.com/image/thumb/Purple125/v4/b2/a7/91/b2a7916a-35be-5a7e-4c91-45317fb40d9c/AppIcon-1x_U007emarketing-0-0-GLES2_U002c0-512MB-sRGB-0-0-0-85-220-0-0-0-3.png/246x0w.jpg";

  void initState() {
    super.initState();
    if(globals.imgURL == null){
      globals.imgURL = logoURL;
      grabUsersImg();
    }

    if(globals.city == null){
      globals.city = '';
      getCurrentUsersCity().then((c){
        getCurrentPost();

      });
    }else{
      getCurrentPost();


    }

  }

  Future<void> grabUsersImg()async{


    FirebaseDatabase database = FirebaseDatabase.instance;
    DataSnapshot snapshot = await database.reference().child(globals.cityCode).child('userInfo').child(globals.id).child('imgURL').once();
    setState(() {
      globals.imgURL = snapshot.value;
    });
  }

  Future<void> getCurrentUsersCity()async{
    FirebaseDatabase database = FirebaseDatabase.instance;
    final snap = await  database.reference().child('usersCities').child(globals.id).child('city').once();
    globals.city = snap.value;

  }

  Future<void>grabCoordinates(String riderOrDriver)async{
    FirebaseDatabase database = FirebaseDatabase.instance;
    final snap = await database.reference().child('coordinates').child(globals.cityCode).child(riderOrDriver).child(globals.id).child('coordinates').once();
    setState(() {
      coordinates = snap.value;
    });
  }



  Future<void> getCurrentPost() async {

 //    get current users post info AKA "from home", "destination", "state", "post",and "destination coordinates".
    // if the destination coordinates change, then we will have to update them,

    FirebaseDatabase database = FirebaseDatabase.instance;
    final snap = await  database.reference().child(globals.cityCode).child('posts').child(globals.id).once();
    Map post = snap.value;
    grabCoordinates(post['riderOrDriver']);

    setState(() {

      currentUsersPost = post;

      if(post['fromHome']){
        destinationDescription = "${post['destination']}, ${post['state']}";
        originDescription = globals.city;
      }else{
        originDescription = "${post['destination']}, ${post['state']}";
        destinationDescription = globals.city;
      }

      destination = post['destination'];
      state = post['state'];
      name = post['name'];
    });

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
      title: (!selected) ? new Text('When would you like to leave?', textAlign: TextAlign.center) : new Row(
       // mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Padding(
            padding: new EdgeInsets.only(right: 30.0),
            child:      new InkWell(
              child: new Icon(Icons.arrow_back),
              onTap: (){
                setState(() {
                  selected = false;
                });
              },
            ),
          ),

     new Center(
       child: new Text('Add a message'),
     ),
        ],
    ),
      children: <Widget>[
        (!selected) ? buildCalendar() :
         new   Stack(
            children: <Widget>[
              buildPostSubmitScreen(),
              new Center(
                child: (loading) ? new CircularProgressIndicator() : new Container(),
              )
            ],
          ),


    (!selected) ? new InkWell(
          child: new Icon(Icons.arrow_forward),
          onTap: (){
            setState(() {
              selected = true;
            });
          },
        ) : new Container()
      ],
    );
  }


  Widget buildCalendar(){
    DateTime berlinWallFell = new DateTime(2020, 11, 9);

    return new MonthPicker(

      selectedDate: currentlySelectedDate,

        onChanged: (d) {

      setState(() {
       currentlySelectedDate = d;
      });
        },
        firstDate:new DateTime.now(),
        lastDate: berlinWallFell,
    );
  }


  Widget buildPostSubmitScreen(){

    return new Container(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          buildLocationFields(true),
          buildLocationFields(false),

          new Padding(padding: new EdgeInsets.all(10.0),
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new CircleAvatar(backgroundColor: Colors.yellowAccent, backgroundImage: new NetworkImage(globals.imgURL)),
                new Expanded(child: new Container(
                  height: 100.0,
                  width: 50.0,
                  child: new Padding(padding: new EdgeInsets.only(left: 5.0),
                    child: new TextField(
                      autofocus: true,
                      controller: postController,
                      keyboardType: TextInputType.multiline,
                      decoration: new InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter a message...',
                      ),
                      maxLines: 40,
                    ),
                  ),
                 )
                )
              ],
            ),
          ),
          new Padding(
            padding: new EdgeInsets.only(top: 10.0),
            child: new Container(
                height: 50.0,
                width: double.infinity,
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Padding(padding: new EdgeInsets.all(3.0),

                    child: ridingBtn(),
                    ),
                    new Padding(padding: new EdgeInsets.all(3.0),

                      child: drivingBtn()
                    ),

                  ],
                )
            ),
          )
        ],
      ),
    );
  }

  Widget ridingBtn(){
    return   new Container(
            height: 40.0,
            width: 114.0,
            child: new MaterialButton(onPressed: ()async{

              if(await checkIfThereAreComments()){
                var decision = await _warningMenu('Warning', "Updating your status will delete all current coomments.", '');
                if(decision == 'Okay'){
                  uploadPost(currentUsersPost, 'Riding');
                }else{
                  return;
                }
              }else{
                uploadPost(currentUsersPost, 'Riding');

              }

            },color: Colors.yellowAccent,child: new Text("Passenger", maxLines: 1,),

            )
    );
  }

  Widget drivingBtn(){
    return  new Container(
            height: 40.0,
            width: 114.0,
            child: new MaterialButton(onPressed: ()async{

              if(await checkIfThereAreComments()){
                var decision = await _warningMenu('Warning', "Updating your status will delete all current coomments.", '');
                if(decision == 'Okay'){
                  uploadPost(currentUsersPost, 'Driving');
                }else{
                  return;
                }
              }else{
                uploadPost(currentUsersPost, 'Driving');
              }

            },
              color: Colors.yellowAccent,child: new Text("Driver"),)
    );


  }

  Widget buildLocationFields(bool origin){
    return new Container(
      height: 50.0,
      width: double.infinity,

        child: new Column(
          children: <Widget>[
            new Expanded(
                child: new Row(

              children: <Widget>[
                    (origin) ? new Icon(Icons.pin_drop) : new Icon(Icons.flag) ,
                new Expanded(
                    child: new Padding(
                      padding: new EdgeInsets.all(5.0),
                      child: new Container(
                        decoration: new BoxDecoration(
                          border: new Border(bottom: new BorderSide(color: Colors.black, )),
                        ),
                        width: 55.0,
                        child: new MaterialButton(
                            onPressed: () async{
                              if(origin){
                                final origin = await Navigator.push(context, new MaterialPageRoute(builder: (context) => new PlacePicker(app: widget.app,userIsSigningUp: false)));
                                if(origin != null){
                                  fromHome = false;
                                  coordinates = origin['coordinates'];
                                  destination = origin['city'];
                                  state = origin['state'];
                                  // determines if the user's origin is within 30 miles of their home city
                                  setState(() {
                                    originDescription = origin['longName'];
                                    destinationDescription = globals.city;
                                  });
                                  }
                              }else{
                              final destinationInfo = await Navigator.push(context, new MaterialPageRoute(builder: (context) => new PlacePicker(app: widget.app,userIsSigningUp: false)));
                              if(destinationInfo != null) {
                                coordinates = destinationInfo['coordinates'];
                                destination = destinationInfo['city'];
                                state = destinationInfo['state'];
                                setState(() {
                                  destinationDescription = destinationInfo['longName'];
                                  originDescription = globals.city;

                                });
                              }
                              }
                            },
                          child: new Align(
                            alignment: Alignment.centerLeft,
                            child: new Text(
                              (origin) ? originDescription : destinationDescription,
                              style: new TextStyle(
                              ),
                            ),
                          ),
                        ),

                      )
                    )
                 )
              ],
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
             )
            )
          ],
        ),
    );
  }

  void uploadPost(Map post, String riderOrDriver)async {

      // var userLocationsAreOk = await checkThatHomeCityIsIncluded();
    // format dates
    if(postController.text == null){
      _errorMenu('Add a Message', "Don't be shy.", '');
    }

    if(!makeSureAllPostDataIsPresent()){
      _errorMenu('Network Error', "Pleae message thumbs-out.", '');
    }

      setState(() {loading = true;});
      var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss a');
      var leaveDate = formatter.format(currentlySelectedDate);
      var now = formatter.format(new DateTime.now());
      post['leaveDate'] = leaveDate;
      // add message text and riderOrDriver
      post['post'] = postController.text;
      post['riderOrDriver'] = riderOrDriver;
      post['destination'] = destination;
      post['state']= state;
      post['name'] = name;
      post['fromHome'] = fromHome;
      post['commentCount'] = null;
      post['key'] = FirebaseDatabase.instance.reference().push().key;
      post['time'] = formatter.format(new DateTime.now());
      post['expiredCommentCount'] = null;

      FirebaseDatabase database = FirebaseDatabase.instance;
      database.reference().child(globals.cityCode).child('posts').child(globals.id).set(post);



      coordinates = {'time': now};         // allows the cloud function to be triggered.... idk any other way to do this but yeah...
      database.reference().child('coordinates').child(globals.cityCode).child(riderOrDriver).child(globals.id).update({'coordinates':coordinates});

       database.reference().child('comments').child(globals.id).remove();
       database.reference().child('expiredComments').child(globals.id).remove();
       database.reference().child(globals.cityCode).child('posts').child(globals.id).child('ghost').remove();


//      if(riderOrDriver == 'Driving'){
//        database.reference().child('coordinates').child(globals.cityCode).child('Riding').child(globals.id).remove();
//      }else{
//        database.reference().child('coordinates').child(globals.cityCode).child('Driving').child(globals.id).remove();
//      }
    setState(() {loading = false;});
    Navigator.pop(context);


  }


  Future<bool> checkIfThereAreComments()async{
    FirebaseDatabase database = FirebaseDatabase.instance;
    DataSnapshot snap = await database.reference().child(globals.cityCode).child('posts').child(globals.id).child('commentCount').once();
    if(snap.value == null){
      return false;
    }else{
      return true;
    }
  }

  bool makeSureAllPostDataIsPresent(){
    if(coordinates == {} || destination == '' || state == '' || fromHome == ''){
      return false;
    }else{
      return true;
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

  Future<String> _warningMenu(String title, String primaryMsg, String secondaryMsg) async {
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
                Navigator.of(context).pop("Okay");
              },
            ),
            new FlatButton(
              child: new Text('Cancel', style: new TextStyle(color: Colors.black),),
              onPressed: () {
                Navigator.of(context).pop("cancel");
              },
            ),
          ],
        );
      },
    );

    return decision;
  }



}


//
//Future<int> getDistanceBetweenTwoCities(String origin, String destination)async{
//  Dio dio = new Dio();
//  Response response= await dio.get("https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=${origin}&destinations=${destination}&key=AIzaSyC_s7kYr0hEbExTd_GglEUfyP_7KOXlzTs");
//  var rows = response.data['rows'];
//  var elements = rows[0];
//  var distance = elements['elements'];
//  var distance2 = distance[0];
//  var val = distance2['distance'];
//  var val2 = val['value'];
//  //val 2 is the distance in meters
//  return val2;
//}

//Future<bool> checkThatHomeCityIsIncluded() async{
//  int originDistanceFromHomeCity = await getDistanceBetweenTwoCities(globals.city, originDescription);
//  if(originDistanceFromHomeCity < 5000){
//    //good to go
//    return true;
//  }else{
//    //check destination
//    int destinationDistanceFromHome = await getDistanceBetweenTwoCities(globals.city, destinationDescription);
//    if(destinationDistanceFromHome < 5000){
//      // good to go
//      return true;
//    }else{
//      // locations aren't affiliated with home city
//      return false;
//    }
//  }
//}