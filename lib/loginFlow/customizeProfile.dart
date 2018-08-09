import 'package:flutter/material.dart';
import '../homePage/chatList.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'imageResizer.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'signupPopup.dart';
import 'package:image_picker/image_picker.dart';
import '../textFieldFix.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import '../homePage/home.dart';
import '../globals.dart' as globals;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'bitmojiPicker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';



class customizeProfile extends StatefulWidget {
 final Map userInfo;
 final Map placeInfo;
  FirebaseApp app;

  customizeProfile(this.userInfo, this.placeInfo, this.app);



  _customizeProfileState createState() => new _customizeProfileState();


}
class _customizeProfileState extends State<customizeProfile> {
  String logoURL = "https://is4-ssl.mzstatic.com/image/thumb/Purple125/v4/b2/a7/91/b2a7916a-35be-5a7e-4c91-45317fb40d9c/AppIcon-1x_U007emarketing-0-0-GLES2_U002c0-512MB-sRGB-0-0-0-85-220-0-0-0-3.png/246x0w.jpg";
  FocusNode commentNode = new FocusNode();
  TextEditingController commentController = new TextEditingController();
  bool userHasFeedback = true;
  String url;
  File imgFile;
  String firstName = '';
  String bio = '';

  bool loading = false;
  TextEditingController firstNameController = new TextEditingController();
  TextEditingController lastNameController = new TextEditingController();
  TextEditingController bioController = new TextEditingController();
  FocusNode firstNameNode = new FocusNode();
  FocusNode lastNameNode = new FocusNode();
  FocusNode bioNode = new FocusNode();
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String bitmojiURL;
  Map userInfo;




  void initState() {
    super.initState();
    firstName = widget.userInfo['name'];
    firstNameController.text = firstName;
    if(widget.userInfo['url'] != null){
      bitmojiURL = widget.userInfo['url'];
    }
    userInfo = widget.userInfo;
  }





  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: new Container(
          child: MediaQuery.removePadding(
             removeTop: true, removeBottom: true, context: context,
            child: new ListView(
              children: <Widget>[
                customizeProfile()
              ],
            )
        )



    ),
    );
  }
  
  
  
  Widget customizeProfile(){

    return new Container(
      child: new Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
           new Container(
             color:Colors.yellowAccent,
             height: MediaQuery.of(context).size.height,
             width: MediaQuery.of(context).size.width,
             child: new MediaQuery.removePadding(context: context,removeRight: true, child:
             new Stack(
               children: <Widget>[

            new Align(
              alignment: Alignment.center,
              child: new Container(
                  child: new Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      new IconButton(
                          icon: new Icon(Icons.camera_alt, color: Colors.black,),
                          onPressed: ()async {

                            // File im = await  _cropImage(await _pickImage());
                            File im =  await _pickImage();
                            // var imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

                            setState(() {
                              imgFile = im;
                              //  imgFile = imageFile;
                            });
                          }),
                      new Text('Add Cover Photo',style: new TextStyle(fontSize: 11.0),)
                    ],
                  )
              ),
            ),
            new Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: (imgFile != null) ? new Image.file(imgFile,fit: BoxFit.cover,) : new Container(),
            ),

//             (imgFile == null)  ?  new Align(
//                     alignment: new Alignment(0.0, 0.0),
//                     child: new Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: <Widget>[
//                         new IconButton(
//                             icon: new Icon(Icons.camera_alt, color: Colors.black,),
//                             onPressed: ()async {
//
//                              // File im = await  _cropImage(await _pickImage());
//                               File im =  await _pickImage();
//                               // var imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
//
//                               setState(() {
//                               imgFile = im;
//                               //  imgFile = imageFile;
//                               });
//                             }),
//                         new Text('Add Cover Photo',style: new TextStyle(fontSize: 11.0),)
//                       ],
//                     )
//                 ) : new Container(),
                 new Align(
                   alignment: new Alignment(-0.95, -0.9),
                   child: new IconButton(
                       icon: new Icon(Icons.close, color: Colors.yellowAccent,),
                       onPressed: () {
                         setState(() {imgFile = null;});
                       }),
                 )
               ],
             ))
           ),



          new Container(
            height: 250.0,
            width: double.infinity,
            decoration: new BoxDecoration(borderRadius: new BorderRadius.only(
                topLeft: new Radius.circular(25.0),
                topRight: new Radius.circular(25.0)), color: Colors.white),

            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                (bitmojiURL != null) ?
                new InkWell(
                  child: new CircleAvatar(radius: 45.0,
                    backgroundImage:  new CachedNetworkImageProvider(bitmojiURL),
                    backgroundColor: Colors.transparent,),
                  onTap: (){
                    BitmojiPicker picker = new BitmojiPicker();
                    Navigator.push(context, new MaterialPageRoute(builder: (context) => picker)).then((url){
                      if(url != null){
                        setState(() {
                          bitmojiURL = url;
                        });
                      }
                    });
                  },
                )
                    : new Padding(padding: new EdgeInsets.all(5.0),
                child: new InkWell(
                  child: CircleAvatar(
                      radius: 45.0,backgroundColor: Colors.yellowAccent,
                      child: new Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          new Icon(Icons.camera_alt, color: Colors.black,),
                          new Text('Add Avatar',style: new TextStyle(color: Colors.black, fontSize: 11.0),)
                        ],
                      )
                  ),

                  onTap: (){
                    BitmojiPicker picker = new BitmojiPicker();
                    globals.cityCode = widget.userInfo['cityCode'];
                    Navigator.push(context, new MaterialPageRoute(builder: (context) => picker)).then((url){
                      if(url != null){
                        setState(() {bitmojiURL = url;});
                      }

                    });
                  },
                ),


                ),
                    new Column(
                      children: <Widget>[
                        new Expanded(child: new Row(
                          children: <Widget>[
                            firstNameField(),
                            lastNameField()

                          ],
                        ),),
                        new EnsureVisibleWhenFocused(child: bioField(), focusNode: bioNode),
                        continueBtn()
                      ],
                    ),

              ],
            ),

          ),


        ],
      ),
    );
  }












  void _firstNameChange(){
    setState(() {
      firstName = firstNameController.text;
    });

  }

  void _lastNameChange(){
    setState(() {
      bio = bioController.text;
    });

  }

  Map sortName(String fullName) {
    int i;
    String firstName;
    String lastName;
    for (i = 0; i < fullName.length; i++) {
      if (fullName[i] == " " && fullName[i+1] != " ") {
        String firstName = fullName.substring(0, i);
        String lastName = fullName.substring(i + 1, fullName.length);
        return {"firstName":firstName, "lastName":lastName};
    }
  }
 return null;

    }

  Future<File> _pickImage() async {

    var imageFile = await  ImagePicker.pickImage(source: ImageSource.gallery);
    imgFile = imageFile;


    return imageFile;
  }

  Future<File> _cropImage(File file) async {
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: file.path,
        ratioX: 1.0,
        ratioY: 2.0,
        toolbarTitle: 'Cropper',
        toolbarColor: Colors.yellowAccent
    );
    return croppedFile;
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




  Widget firstNameField(){
    return new Padding(padding: new EdgeInsets.all(5.0),

      child:new Container(
        height: 55.0,
        width: 100.0,
        decoration: new BoxDecoration(border: new Border(bottom: new BorderSide(color: Colors.grey[600])),),
        child: new EnsureVisibleWhenFocused(
            focusNode:firstNameNode,
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Text('First Name',style: new TextStyle(fontSize: 11.0,color: Colors.grey),),
                new TextField(

                  onSubmitted: (txt){
                    FocusScope.of(context).requestFocus(lastNameNode);
                  },
                  style: new TextStyle(fontSize: 14.0,color: Colors.black,),
                  textAlign: TextAlign.left,
                  focusNode: firstNameNode,
                  decoration: new InputDecoration( border:InputBorder.none, ),
                  onChanged:(k){_firstNameChange();},
                  controller: firstNameController,
                ),
              ],
            )
        ),
      ),
    );
  }
  Widget lastNameField(){
    return new Padding(padding: new EdgeInsets.all(5.0),

      child:new Container(
        height: 55.0,
        width: 100.0,
        decoration: new BoxDecoration(border: new Border(bottom: new BorderSide(color: Colors.grey[600])),),
        child: new EnsureVisibleWhenFocused(
            focusNode:lastNameNode,
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Text('Last Name',style: new TextStyle(fontSize: 11.0,color: Colors.grey),),
                new TextField(

                  onSubmitted: (txt){
                    FocusScope.of(context).requestFocus(bioNode);
                  },
                  style: new TextStyle(fontSize: 14.0,color: Colors.black,),
                  textAlign: TextAlign.left,
                  focusNode: lastNameNode,
                  decoration: new InputDecoration( border:InputBorder.none, ),
                  onChanged:(k){_firstNameChange();},
                  controller: lastNameController,
                ),
              ],
            )
        ),
      ),
    );
  }



  Widget bioField(){
    return new Padding(padding: new EdgeInsets.all(5.0),

      child:new Container(
        width: 200.0,
        height: 77.0,
         decoration: new BoxDecoration(border: new Border(bottom:new BorderSide(color: Colors.grey[600]))),
          child: new EnsureVisibleWhenFocused(
            focusNode:bioNode,
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Text('Bio',style: new TextStyle(fontSize: 11.0,color: Colors.grey),),
                new TextField(
                  style: new TextStyle(fontSize: 14.0,color: Colors.black),
                  textAlign: TextAlign.left,
                  focusNode: bioNode,
                  decoration: new InputDecoration( border:InputBorder.none ),
                  onChanged:(k){_firstNameChange();},
                  controller: bioController,
                  maxLength: 30,
                ),
              ],
            )
        ),
      ),
    );
  }


  Widget continueBtn(){
    return  new Padding(padding: new EdgeInsets.all(10.0),
        child: new Center(
            child:    (loading) ?  new CircularProgressIndicator()
                : new IconButton(icon: new Icon(Icons.arrow_forward, color: Colors.black,), onPressed: ()async{

              if(imgFile == null){
                setState(() {
                  loading = false;
                });
                _errorMenu("Error", "Please add a Cover Photo, a First Name, a Last Name, and a Bio!", '');
                return;
              }
              if(bitmojiURL == null){
                _errorMenu("Error", "Please select a bitmoji!", '');
              }
              setState(() {loading = true;});

              //28237



              continueToSignUpPopup(userInfo, widget.placeInfo);

              })
        )

    );

  }






  void continueToSignUpPopup(Map userInfo, Map placeInfo) async{

    Map nameInfo = sortName(firstNameController.text);
    var firstName = firstNameController.text;
    var lastName = lastNameController.text;
    var bio = bioController.text;
    if(firstName != null && lastName != null && bio != '' && imgFile != null ){
      userInfo['url'] = bitmojiURL;



      // good to go, we can now upload the users info
      userInfo['firstName'] = nameInfo['firstName'];
      userInfo['lastName'] = nameInfo['lastName'];
      userInfo['bio'] = bioController.text;
      setState(() {loading = false;});
      showDialog(context: context, barrierDismissible: false, builder: (BuildContext context) => new SignupPopUp(userInfo,placeInfo, imgFile)).then((val)async{
        if(val == "success"){
          globals.id = widget.userInfo['id'];
          Home homePage = Home(widget.app, widget.userInfo['id'],true);
          final SharedPreferences prefs = await _prefs;
          prefs.setBool('signedUp', true);
          DatabaseReference ref =  FirebaseDatabase.instance.reference();
          globals.cityCode = widget.userInfo['cityCode'];
          Navigator.pushReplacement(context, new MaterialPageRoute(builder: (context) => homePage));
        }else{
          _errorMenu("Error", "Please try again.", '');
          setState(() {loading = false;});

        }
      });
    }else{
      _errorMenu("Error", "Please add a Cover Photo, a First Name, a Last Name, and a Bio!", '');
      setState(() {loading = false;});

    }
  }




}


//
//
//Widget profileView(){
//  return new Container(
//      height: 230.0,
//      decoration: new BoxDecoration(borderRadius: new BorderRadius.only(
//          topLeft: new Radius.circular(25.0),
//          topRight: new Radius.circular(25.0)), color: Colors.white),
//      width: double.infinity,
//      child: new Stack(
//        children: <Widget>[
//          new Column(
//            crossAxisAlignment: CrossAxisAlignment.center,
//            children: <Widget>[
//              new Row(
//                crossAxisAlignment: CrossAxisAlignment.start,
//                children: <Widget>[
//                  (widget.userInfo['url'] != null) ?  new CircleAvatar(radius: 45.0,
//                    backgroundImage: new NetworkImage(widget.userInfo['url']),
//                    backgroundColor: Colors.transparent,) : CircleAvatar(
//                    radius: 45.0,backgroundColor: Colors.white,
//                  ),
//
//                  firstNameField(),
//
//
//
//
//
//                ],
//              ),
//
//            ],
//          ),
//
//
//        ],
//      )
//
//
//  );
//}
//                new Column(
//                  crossAxisAlignment: CrossAxisAlignment.center,
//                  children: <Widget>[
//                    new Container(
//                      height: MediaQuery.of(context).size.height/2,
//                      width: double.infinity,
//                      color: Colors.yellowAccent,
//                      child: new Stack(
//                        fit: StackFit.expand,
//                        children: <Widget>[
//                          (imgFile != null) ? new Image.file(imgFile,fit: BoxFit.cover,) :   new Center(
//                            child: new Column(
//                              mainAxisAlignment: MainAxisAlignment.center,
//                              children: <Widget>[
//                                new Padding(padding: new EdgeInsets.all(5.0),
//
//                                  child: new IconButton(icon: new Icon(Icons.camera_alt,color: Colors.black,), onPressed: ()async{
//                                    File im = await  _cropImage(await _pickImage());
//
//
//
//                                    // var imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
//
//                                    setState(() {
//
//                                        imgFile = im;
//                                    });
//                                  }),
//
//                                ),
//                                new Text('Add Cover Photo', style: new TextStyle(color: Colors.black, fontSize: 11.0),)
//                              ],
//                            )
//                          ),
//
//
//                          new Padding(padding: new EdgeInsets.all(15.0),
//                            child: new Align(
//                                alignment: Alignment(-1.0, 1.0),
//                                child:new Row(
//                                  children: <Widget>[
//                                    new Container(
//                                      height: 75.0,
//                                      width: 75.0,
//                                      decoration: new BoxDecoration(shape: BoxShape.circle, color: Colors.transparent,
//                                          image: new DecorationImage(image: new NetworkImage(widget.userInfo['bitmojiURL']),
//                                              fit: BoxFit.fill)
//                                      ),
//                                    ),
//                                    new Expanded(
//                                      child:new Text('${firstName} ${lastName}',style: new TextStyle(fontSize: 25.0,color: (imgFile == null) ? Colors.black : Colors.white),)
//
//                                    )
//
//                                  ],
//                                )
//                            ),
//
//                          ),
//
//                          (imgFile != null ) ? new Padding(padding: new EdgeInsets.all(15.0),
//                            child: new Align(
//                                alignment: Alignment(1.0, 1.0),
//                                child: new IconButton(icon: new Icon(Icons.camera_alt,color: Colors.yellowAccent,), onPressed: ()async{
//                                  File im = await  _cropImage(await _pickImage());
//                                  // var imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
//
//                                  setState(() {
//                                    imgFile = im;
//                                    //  imgFile = imageFile;
//                                  });
//                                })
//                            ),
//                          ) : new Container()
//                        ],
//                      ),
//                    ),
//
//                    new Divider(),
//
//
//
//                    new Column(
//                      crossAxisAlignment: CrossAxisAlignment.center,
//                              children: <Widget>[
//
//                          new Padding(padding: new EdgeInsets.all(25.0),
//
//                          child:new Container(
//                            width: 200.0,
//                            height: 60.0,
//                            decoration: new BoxDecoration(border: new Border(bottom: new BorderSide(color: Colors.black)),),
//                            child: new EnsureVisibleWhenFocused(
//                              focusNode:firstNameNode,
//                              child: new Column(
//                                crossAxisAlignment: CrossAxisAlignment.start,
//                                children: <Widget>[
//                                  new Text('First Name',style: new TextStyle(fontSize: 11.0,color: Colors.grey),),
//                                  new TextField(
//                                    style: new TextStyle(fontSize: 18.0,color: Colors.black,),
//                                    textAlign: TextAlign.center,
//                                    focusNode: firstNameNode,
//                                    decoration: new InputDecoration( border:InputBorder.none, ),
//                                    onChanged:(k){_firstNameChange();},
//                                    controller: firstNameController,
//                                  ),
//                                ],
//                              )
//
//
//                            ),
//                          ),
//
//
//
//                          ),
//
//
//                          new Padding(padding: new EdgeInsets.all(25.0),
//
//                            child:new Container(
//                              width: 200.0,
//                              height: 65.0,
//                              decoration: new BoxDecoration(border: new Border(bottom: new BorderSide(color: Colors.black)),),
//                              child: new EnsureVisibleWhenFocused(
//                                  focusNode:lastNameNode,
//                                  child: new Column(
//                                    crossAxisAlignment: CrossAxisAlignment.start,
//                                    children: <Widget>[
//                                      new Text('Last Name',style: new TextStyle(fontSize: 11.0,color: Colors.grey),),
//                                      new TextField(
//                                        style: new TextStyle(fontSize: 18.0,color: Colors.black),
//                                        textAlign: TextAlign.center,
//                                        focusNode: lastNameNode,
//                                        decoration: new InputDecoration( border:InputBorder.none, ),
//                                        onChanged:(k){_lastNameChange();},
//                                        controller: lastNameController,
//                                      ),
//                                    ],
//                                  )
//
//
//                              ),
//                            ),
//                          ),
//
//                         new Padding(padding: new EdgeInsets.all(25.0),
//                         child:   new Center(
//                             child: new IconButton(icon: new Icon(Icons.arrow_forward, color: Colors.black,), onPressed: ()async{
//
//
//
//                               img.Image newImage = img.decodeImage(imgFile.readAsBytesSync());
//                               img.Image resizedImage = img.copyResize(newImage, 960);
//
//                               final Directory systemTempDir = Directory.systemTemp;
//// im a dart n00b and this is my code, and it runs s/o to dart async
//                               final file = await new File('${systemTempDir.path}/test.png').create();
//                               imgFile = await file.writeAsBytes(img.encodePng(resizedImage));
//
//
//                             //  imgFile = new File('cover.png')
//                               //  ..writeAsBytesSync(img.encodePng(resizedImage));
//
//
//                               continueToSignUpPopup(widget.userInfo, widget.placeInfo);
//
//
//                             })
//
//                         )
//
//
//                         )
//
//                              ]
//                          ),
//
//                  ],
//                ),
//
//Future<String> uploadImg(String url, String path1, String path2,String path3) async {
//
//  try{
//    var response = await http.get(url);
//    final Directory systemTempDir = Directory.systemTemp;
//// im a dart n00b and this is my code, and it runs s/o to dart async
//    final file = await new File('${systemTempDir.path}/test.png').create();
//    var result = await file.writeAsBytes(response.bodyBytes);
//    final StorageReference ref = await FirebaseStorage.instance.ref().child("profilePics").child(path1).child(path2).child(path3);
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