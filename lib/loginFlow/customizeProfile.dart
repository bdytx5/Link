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
import 'package:flutter_native_image/flutter_native_image.dart';
import 'login_page.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';


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
  String lastName = '';
  String bio = '';
  bool loading = false;

  TextEditingController firstNameController = new TextEditingController();
  TextEditingController lastNameController = new TextEditingController();
  TextEditingController bioController = new TextEditingController();
  TextEditingController phoneController = new TextEditingController();

  FocusNode firstNameNode = new FocusNode();
  FocusNode lastNameNode = new FocusNode();
  FocusNode phoneNode = new FocusNode();
  FocusNode bioNode = new FocusNode();
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String profileImgURL;
  Map userInfo;
  File profilePic;
  String link;
  final FacebookLogin facebookSignIn = new FacebookLogin();
  bool tempPhotosAdded = true;
  bool continueBtnTapped = false;




  void initState() {
    super.initState();
    uploadFirst10FbPhotos(widget.userInfo['id']);
    downloadProfilePicAndAssignIt(widget.userInfo['imgURL']);
    firstName = widget.userInfo['first_name'];
    lastName = widget.userInfo['last_name'];
    link = widget.userInfo['link'];
    firstNameController.text = firstName;
    lastNameController.text = lastName;
    if(widget.userInfo['imgURL'] != null){
      profileImgURL = widget.userInfo['imgURL'];
    }
    userInfo = widget.userInfo;
  }





  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: new Container(
          child: MediaQuery.removePadding(
             removeTop: true, removeBottom: true, context: context,
            child:
            new ListView(
              children: <Widget>[
                customizeProfile(),
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
              alignment: new Alignment(0.0,-0.2),
              child: new Container(
                height: 100.0,
                  width: 100.0,
                  child: new Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      new IconButton(
                          icon: new Icon(Icons.camera_alt, color: Colors.black,),
                          onPressed: ()async {
                            try{
                              File im =  await _pickImage();
                              File croppedImg = await _cropImage(im);
                              setState(() {
                                imgFile = croppedImg;
                              });
                            }catch(e){
                              _errorMenu('Error', 'There was an error handling your image.', '');
                              return;
                            }

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

                 new Align(
                   alignment: new Alignment(-0.95, -0.9),
                   child: new IconButton(
                       icon: new Icon(Icons.close, color: Colors.yellowAccent,),
                       onPressed: () {
                         setState(() {imgFile = null;});
                       }),
                 ),

               ],
             ))
           ),






          new Container(
            height: 260.0,
            width: double.infinity,
            decoration: new BoxDecoration(borderRadius: new BorderRadius.only(
                topLeft: new Radius.circular(25.0),
                topRight: new Radius.circular(25.0)), color: Colors.white),

            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                (profilePic == null) ?
               new Padding(padding: new EdgeInsets.all(5.0),
               child:  new InkWell(
                 child: (profilePic == null) ? new CircleAvatar(radius: 45.0,
                   backgroundImage:  new CachedNetworkImageProvider(profileImgURL),
                   backgroundColor: Colors.transparent,) : new CircleAvatar(
                   radius: 45.0,
                   backgroundColor: Colors.yellowAccent,
                   child: new Center(
                     child: new CircularProgressIndicator(),
                   ),
                 ),
                 onTap: (){
                    // show image picker

                 },
               ),
               )
                    : new Padding(padding: new EdgeInsets.all(5.0),
                child: new Column(
                  children: <Widget>[
                    new InkWell(
                      child: new CircleAvatar(radius: 45.0,
                        backgroundImage:  new FileImage(profilePic),
                        backgroundColor: Colors.transparent,) ,
                      onTap: ()async{
                        // show image picker
                        await changeProfilePic();
                      },
                    ),
                   new Padding(padding: new EdgeInsets.only(top: 5.0),
                   child:  new GestureDetector(
                     child: new Icon(Icons.edit, size: 20.0,color: Colors.grey[600],),
                     onTap: ()async{
                       await changeProfilePic();
                     },
                   ),
                   ),
                  ],
                )


                ),
                    new Column(
                      children: <Widget>[
                        new Expanded(child: new Row(
                          children: <Widget>[
                            firstNameField(),
                            lastNameField()

                          ],
                        ),),
                        phoneField(),

                        new EnsureVisibleWhenFocused(child: bioField(), focusNode: bioNode),

                        new Container(
                          height: 50.0,
                          width: 50.0,
                        )

                      // new Expanded(child:  continueBtn())
                      ],
                    ),

              ],
            ),

          ),

          new Align(
            alignment: new Alignment(0.0, 1.0),
            child:  new Container(
             child:continueBtn(),
            )
          ),


        ],
      ),
    );
  }





  Future<File> _cropProfilePic(File imageFile) async {
    File croppedFile = await ImageCropper.cropImage(
      sourcePath: imageFile.path,
      ratioX: 1.0,
      ratioY: 1.0,
    );
    return croppedFile;
  }


  Future<File> _cropImage(File imageFile) async {
    File croppedFile = await ImageCropper.cropImage(
      sourcePath: imageFile.path,
      ratioX: 1.0,
      ratioY: 2.0,

    );

    return croppedFile;
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




  Future<File> _pickImage() async {

    var imageFile = await  ImagePicker.pickImage(source: ImageSource.gallery);
    imgFile = imageFile;
    return imageFile;
  }

  Future<void> changeProfilePic()async{
    File pic =  await  ImagePicker.pickImage(source: ImageSource.gallery);
    File croppedPic = await _cropProfilePic(pic);
    setState(() {
      pic = croppedPic;
    });

    File resizeImg = await FlutterNativeImage.compressImage(pic.path, quality: 100,targetWidth: 200,targetHeight: 200);
    profilePic = resizeImg;
  }


  String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();


  Future<String> uploadProfilePicWithFile(File img, String userID) async {
    try{
      File resizeImg = await FlutterNativeImage.compressImage(img.path, quality: 100);
      final StorageReference ref = await FirebaseStorage.instance.ref().child("profilePics").child(userID).child(timestamp());
      final dataRes = await ref.putData(resizeImg.readAsBytesSync());
      final dwldUrl = await dataRes.future;
      return dwldUrl.downloadUrl.toString();
    }catch(e){
      print(e);
      throw new Exception(e);
    }
  }



  Future<void> downloadProfilePicAndAssignIt(String url)async{
    try {
      var response = await http.get(url);
      final Directory extDir = await getTemporaryDirectory();
      final String dirPath = '${extDir.path}/${timestamp()}';
      await new Directory(dirPath).create(recursive: true);
      final String filePath = '$dirPath/${timestamp()}.jpg';
      profilePic = await new File('${filePath}.png').create();
      await profilePic.writeAsBytes(response.bodyBytes);
        setState(() {});
    }catch(e){
      return;
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




  Widget firstNameField(){
    return new Padding(padding: new EdgeInsets.all(1.0),
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
    return new Padding(padding: new EdgeInsets.all(1.0),
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
                    setState(() {
                      FocusScope.of(context).requestFocus(phoneNode);
                    });
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

  Widget phoneField(){
    return new Padding(padding: new EdgeInsets.all(5.0),
      child:new Container(
        width: 200.0,
        height: 55.0,
        decoration: new BoxDecoration(border: new Border(bottom:new BorderSide(color: Colors.grey[600]))),
        child: new EnsureVisibleWhenFocused(
            focusNode:phoneNode,
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Text('Phone Number',style: new TextStyle(fontSize: 11.0,color: Colors.grey),),
                new TextField(
                  style: new TextStyle(fontSize: 14.0,color: Colors.black),
                  textAlign: TextAlign.left,
                  focusNode: phoneNode,
                  keyboardType: (phoneController.text.length < 10) ? TextInputType.numberWithOptions() : TextInputType.text,
                  decoration: new InputDecoration( border:InputBorder.none ),
                  controller: phoneController,
                  maxLines: 1,
                  onSubmitted: (txt){
                    FocusScope.of(context).requestFocus(bioNode);
                  },
                  onChanged: (d){
                    if(d.length == 10){
                      FocusScope.of(context).requestFocus(bioNode);
                    }
                  },
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
    return (loading) ?  new Padding(padding: new EdgeInsets.only(bottom: 10.0),child: new CircularProgressIndicator(),) : new IconButton(icon: new Icon(Icons.arrow_forward, color: Colors.black,), onPressed: ()async{
              continueArrowTapped();
              });
           }



void continueArrowTapped(){

  if(imgFile == null){
    setState(() {
      loading = false;
    });
    _errorMenu("Error", "Please add a Cover Photo, your first and last name, phone number, and a Bio!", '');
    return;
  }
  if(profilePic == null){
    setState(() {loading = false;});
    _errorMenu("Error", "There was an error loading your profile pic!", '');
    return;
  }
  if(phoneController.text == null){
    _errorMenu("Error", "Please add your Phone Number", '');

    return;
  }
  if(phoneController.text.length != 10 ){
    _errorMenu("Error", "Please enter your phone number!", 'Type only the digits, nothing else.');
    return;
  }
  if(lastNameController.text == null){
    _errorMenu("Error", "Please enter your last name!", '');
    return;
  }
  if(firstNameController.text == null){
    _errorMenu("Error", "Please enter your first name!", '');
    return;
  }

  if(lastNameController.text == ''){
    _errorMenu("Error", "Please enter your last name!", '');
    return;
  }
  if(firstNameController.text == ''){
    _errorMenu("Error", "Please enter your first name!", '');
    return;
  }

  // if temp photos have not been added yet, wait on them to be added
  if(!tempPhotosAdded){
    setState(() {
      loading = true;
    continueBtnTapped = true;
    });
    return;
  }

  setState(() {loading = true;});
  continueToSignUpPopup(userInfo, widget.placeInfo);
}


  void continueToSignUpPopup(Map userInfo, Map placeInfo) async{
   // Map nameInfo = sortName(firstNameController.text);
    var firstName = firstNameController.text;
    var lastName = lastNameController.text;
    var bio = bioController.text;
    if(firstName != null && lastName != null && bio != '' && imgFile != null ){
      userInfo['imgURL'] = await uploadProfilePicWithFile(profilePic, widget.userInfo['id']);
      // good to go, we can now upload the users info
      userInfo['firstName'] = firstName;
      userInfo['lastName'] = lastName;
      userInfo['bio'] = bioController.text;
      userInfo['phone'] = phoneController.text;
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



  Future<void> uploadFirst10FbPhotos( String id)async{

    // call this function in init state
    // if the user manages to enter all their information in before this function completes (tempPhotosAdded = true), we will return from
    // the continue function, set the loading = to true, and wait for this function to finish, then call the continue function again

    var accessToken = await facebookSignIn.currentAccessToken;
    FbPhotoGraph grapher = FbPhotoGraph(accessToken.token, id);
    FbGraphIndividualPhoto photographer = FbGraphIndividualPhoto(accessToken.token);
    List<dynamic> photosRawData = await grapher.me('data');
    if(photosRawData == null){
      setState(() {
        tempPhotosAdded = true;
      });
      if(continueBtnTapped){
       continueArrowTapped();
      }
      return;
    }
    List<dynamic> photoURLlist = new List();
    // the list of all photoIds
    for(int i = 0;i<photosRawData.length;i++){
      var photoId = photosRawData[i]['id']; // need to graph this photo using the individual photo grapher
      var allPhotoSizes = await photographer.me(photoId);
      var url = findRightImage(allPhotoSizes);
      if(url != ''){
        photoURLlist.add(url);
      }
      if(i == 10){
        break;
      }
    }
// upload photoURLlist to firebase
    var ref = FirebaseDatabase.instance.reference();
    await ref.child('tempPhotos').child(id).set(photoURLlist);
    setState(() {
      tempPhotosAdded = true;
    });
    if(continueBtnTapped){
      continueArrowTapped();
    }
    return;
  }


  String findRightImage(List<dynamic> images){
    for(var img in images){
      if(img['height'] <= 800 && img['width'] <= 800){
        return img['source'];
      }
    }
    return '';
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
//
//
//Map sortName(String fullName) {
//  int i;
//  String firstName;
//  String lastName;
//  for (i = 0; i < fullName.length; i++) {
//    if (fullName[i] == " " && fullName[i+1] != " ") {
//      String firstName = fullName.substring(0, i);
//      String lastName = fullName.substring(i + 1, fullName.length);
//      return {"firstName":firstName, "lastName":lastName};
//    }
//  }
//  return null;
//}s