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
import 'viewPicture.dart';
import '../pageTransitions.dart';
import 'package:flutter/services.dart';
import 'viewFbPage.dart';
import 'dart:ui' as ui;
import 'package:image_cropper/image_cropper.dart';

class ProfilePage extends StatefulWidget{


  static const String routeName = "home";

  _profilePageState createState() => new _profilePageState();

  final String id;
  final String profilePicURL;
  final String firstName;
  final String fullName;
  final String coverPlaceholder = "https://is4-ssl.mzstatic.com/image/thumb/Purple125/v4/b2/a7/91/b2a7916a-35be-5a7e-4c91-45317fb40d9c/AppIcon-1x_U007emarketing-0-0-GLES2_U002c0-512MB-sRGB-0-0-0-85-220-0-0-0-3.png/1200x630wa.jpg";
  final String riderOrDriver;
  final String destination;

  // id and profile pic url will ALWAYS be available, full name will be sometimes, and coverphoto never will be available
  ProfilePage({this.id, this.profilePicURL, this.firstName, this.fullName, this.riderOrDriver});
}

class _profilePageState extends State<ProfilePage> with TickerProviderStateMixin{
  // profilePage({Key key, this.layoutGroup, this.onLayoutToggle,}) : super(key: key);
  String coverPhoto;
  String fullName;
  String destination;
  String gradYear;
  String school;
  String bio;
  String riderOrDriver;
  bool hasContacts = false;
  String fbLink;
  Map contactNameInfo = new Map();
  Map contactImgInfo = new Map();
  List<String> contactsList = new List();
  Animation<double> contactsAnimation;
  AnimationController contactsController;
  bool contactsAnimationCompleted = false;
  AnimationController contactsDelayController;
  bool contactsDelayCompleted = false;
  SecureString secureString = new SecureString();
  AssetImage fbIcon = new AssetImage('assets/fb.png');
// for photos grid view
  bool userHasFbPhotos;
  bool userHasTempPhotos;
  Animation<double> fbGridAnimation;
  AnimationController fbGridController;
  bool fbGridAnimationReversing = false;
  bool fbGridanimationCompletedReversing = true;
  Map fbPhotoHash;
  String profilePicUrl;

  bool userIsViewingFbPhotos = false;
  List<dynamic> fbPhotos = new List();



  bool btnsEnabled = true;

  static const platform = const MethodChannel('thumbsOutChannel');


  void initState() {
    super.initState();
    profilePicUrl = widget.profilePicURL;
    startContactsDelay();
    grabCoverPhoto();
    grabBio();
    grabSchoolAndGradYear();
    getContactInfo();
    makeSureAllDataIsLoaded();
    // checkIfUserHasFbPhotos();
    // decideWhetherToShowPhotosOrFbLinkBtn();

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        body: new Stack(
          alignment: Alignment.bottomCenter,

          children: <Widget>[
            (coverPhoto != null) ? new GestureDetector(
                child:  new Container(
                  height: double.infinity,
                  width: double.infinity,
                  decoration: new BoxDecoration(image: new DecorationImage(
                      image:  new CachedNetworkImageProvider((coverPhoto != null) ? coverPhoto : widget.coverPlaceholder),
                      fit: BoxFit.cover)),
                ),
                onTap:(btnsEnabled) ? (){
//                Navigator.push(context,
//                    new ShowRoute(widget: viewPicPage(cover: true,imgURL: coverPhoto,regularPhoto: false,userIsViewingTheirOwnPhoto:false,)));
                } : null
            ) : new Container(child:new Center(
              child: new CircularProgressIndicator(),
            )),
            new Align(
                alignment: new Alignment(-0.95, -0.9),
                child: new Container(
                  height: 30.0,
                  width: 30.0,
                  decoration: new BoxDecoration(color: Colors.transparent,shape: BoxShape.circle,),
                  child: new IconButton(
                      icon: new Icon(Icons.arrow_back, color: Colors.white,),

                      onPressed: (btnsEnabled) ? () {

                        Navigator.pop(context);

                      }: null),

                )
            ),

            profileView(),
          ],
        )
    );
  }

  Widget profileView() {
    return new Container(
        height: (hasContacts && !userIsViewingFbPhotos && !fbGridAnimationReversing) ? ((contactsController.value != null) ? (160.0 + (78.0 * contactsController.value)) : 238.0) : (!userIsViewingFbPhotos && !fbGridAnimationReversing) ?  160.0 : (fbGridAnimationReversing) ? ( ((hasContacts) ? 238.0 : 160.0) + (MediaQuery.of(context).size.height/3.0 * fbGridController.value)) : ( ((hasContacts) ? 238.0 : 160.0) + (MediaQuery.of(context).size.height/3 * fbGridController.value)) ,
        //height: MediaQuery.of(context).size.height - 100,
        decoration: new BoxDecoration(borderRadius: new BorderRadius.only(
            topLeft: new Radius.circular(25.0),
            topRight: new Radius.circular(25.0)), color: Colors.white),
        width: double.infinity,
        child: new Stack(
          children: <Widget>[
            new Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                new Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Padding(padding: new EdgeInsets.only(top: 8.0,left: 8.0),
                        child: new Column(
                          children: <Widget>[
                            new GestureDetector(
                                child: new CircleAvatar(radius: 35.0,
                                  backgroundImage: new CachedNetworkImageProvider(profilePicUrl),
                                  backgroundColor: Colors.transparent,// this should never be null!
                                ),
                                onTap: (btnsEnabled) ? (){
                                  Navigator.push(context,
                                      new ShowRoute(widget: viewPicPage(cover: false,imgURL: widget.profilePicURL,regularPhoto: false,userIsViewingTheirOwnPhoto:false,)));


                                } : null
                            ),
                            (globals.id == widget.id) ? new Padding(padding: new EdgeInsets.only(top: 5.0),
                                child: GestureDetector(
                                    child: new Icon(Icons.settings, size: 20.0,color: Colors.grey[800],), onTap: (btnsEnabled) ? (){

                                  _showProfileSettings('', '', '').then((d){

                                    if(d == null){
                                      return;
                                    }
                                    if(d){
                                      changeBio();
                                    }else{
                                      if(mounted){
                                        setState(() {});
                                      }
                                    }
                                  });
//                          showDialog(context: context, builder: (BuildContext context) => new EditProfilePopup()).then((changed){
//                            if(changed ==null){
//                              return;
//                            }
//                            if(changed){
//                              grabBio();
//                            }
//                          });
                                }: null)
                            ) : new Container()
                          ],
                        )
                    ),
                    new Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        new SizedBox(
                          height: 40.0,
                          width: MediaQuery.of(context).size.width - (136+48),
                          child: new FittedBox(
                            child:(fullName != null) ? new Text(fullName,textAlign: TextAlign.left,style: new TextStyle(fontWeight: FontWeight.bold,fontSize: 28.0),overflow: TextOverflow.clip,maxLines: 1,):new Container(),
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        new SizedBox(
                          height: 15.0,
                          width: MediaQuery.of(context).size.width - 136,
                          child: new FittedBox(
                            child: new Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                new Icon(
                                  Icons.location_on, color: Colors.grey[700],size: 15.0,),
                                new Padding(padding: new EdgeInsets.only(right: 5.0),
                                    child:   (destination != null) ? new Text(destination,
                                      style: new TextStyle(color: Colors.grey[700],fontWeight: FontWeight.bold,fontSize: 11.0),) : new Text('')
                                ),
                                new Text('|'),
                                new Padding(padding: new EdgeInsets.only(left: 5.0),
                                  child: new Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      new Icon(
                                        Icons.school, color: Colors.grey[700],size: 15.0,),
                                      (school != null && gradYear != null) ? new Text('${school}, ${gradYear}',
                                          style: new TextStyle(color: Colors.grey[700],fontWeight: FontWeight.bold,fontSize: 11.0)) : new Text(''),
                                      new Text(' | '),
                                      (riderOrDriver != null) ?  new Text(riderOrDriver, style: new TextStyle(color: Colors.grey[700],fontWeight: FontWeight.bold,fontSize: 11.0),) : new Container()
                                    ],
                                  ),
                                )
                              ],
                            ),
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        new Padding(padding: new EdgeInsets.only(top: 5.0,left:8.0),
                          child: new SizedBox(
                            height: 53.0,
                            width: MediaQuery.of(context).size.width - 138,
                            child: (bio != null) ? new Text(bio,textAlign: TextAlign.left,style: new TextStyle(fontSize: 18.0),overflow: TextOverflow.clip,maxLines: 3):new Container(),
                          ),
                        )
                      ],
                    )
                  ],
                ),
                new Divider(),

                //   (userHasFbPhotos != null ) ? ((userHasFbPhotos && userIsViewingFbPhotos) ? new Expanded(child: fbPhotosGrid()) : new Container()) : new Container(),

                (fullName != null && hasContacts && !userIsViewingFbPhotos && fbGridanimationCompletedReversing) ? new Text("${getFirstName(fullName)}'s contacts", style: new TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey[600]),) : (fullName != null && !userIsViewingFbPhotos && fbGridanimationCompletedReversing && contactsAnimationCompleted) ? new Text("${getFirstName(fullName)} doesn't have any contacts yet",style: new TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey[600])) : (!hasContacts && fullName != null &&  contactsAnimationCompleted ) ? new Text("${getFirstName(fullName)} doesn't have any contacts yet",style: new TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey[600])) : new Text(''),

                (hasContacts && !userIsViewingFbPhotos && fbGridanimationCompletedReversing && contactsAnimationCompleted)  ?
                new Expanded(
                    child: new Padding(padding:new EdgeInsets.only(bottom: 15.0),
                      child: new Container(
                          child: new Center(
                            child: contactsListBuilder(),
                          )
                      ),
                    )
                )
                    : new Container(),
              ],
            ),
            new Align(
                alignment: (hasContacts && !userIsViewingFbPhotos && fbGridanimationCompletedReversing) ? new Alignment(0.94, -1.2) : (!userIsViewingFbPhotos) ?  new Alignment(0.94, -1.2) : new Alignment(0.94, -1.08),
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    new Container(
                        height: 48.0,
                        width: 48.0,
                        decoration: new BoxDecoration(
                            color: Colors.yellowAccent, shape: BoxShape.circle),
                        child: new IconButton(
                            icon: new Icon((widget.id == globals.id) ? Icons.chat : Icons.chat, color: Colors.black,),
                            onPressed: (btnsEnabled) ? () async{
                              if(widget.id != globals.id){
                                showMessageScreen(widget.id);
                              }else{
                                // add image to photos
//                            try{
//                              await addRegularPhoto();
//                            }catch(e){
//                              print(e);
//                            }
                              }
                            }:null
                        )
                    ),
                    new Container(
                      height: 48.0,
                      width: 48.0,
                      decoration: new BoxDecoration(
                          color: Colors.blue, shape: BoxShape.circle),
//                    child:(userHasFbPhotos != null && userHasTempPhotos != null) ? new IconButton(
//                        icon: ((userHasFbPhotos && !userIsViewingFbPhotos )||userHasTempPhotos) ? new Icon(Icons.photo,color: Colors.white,) : (userIsViewingFbPhotos ) ? new Icon(Icons.keyboard_arrow_down,color: Colors.white,size: 28.0,) : (fbGridAnimationReversing) ? new Icon(Icons.keyboard_arrow_down,color: Colors.white,size: 28.0,) : new ImageIcon(fbIcon, color: Colors.white,),
//                        onPressed: (btnsEnabled) ? _handlePhotoBtnTap : null
//                    ) : new Container(),
                      child: new IconButton(
                        //   icon: ((userHasFbPhotos && !userIsViewingFbPhotos )||userHasTempPhotos) ? new Icon(Icons.photo,color: Colors.white,) : (userIsViewingFbPhotos) ? new Icon(Icons.keyboard_arrow_down,color: Colors.white,size: 28.0,) : new ImageIcon(fbIcon, color: Colors.white,),
                          icon: new ImageIcon(fbIcon, color: Colors.white,),
                          onPressed: (btnsEnabled) ? (){
                            showFb();
                          } :(){}
                      ),
                    ),
                  ],
                )
            ),
          ],
        )
    );
  }


  Widget fbPhotosGrid(){
    return new Padding(padding: new EdgeInsets.only(left: 5.0,right: 5.0),
        child: MediaQuery.removePadding(context: context,
            removeTop: true,
            removeLeft: true,
            removeRight: true,
            removeBottom: true,
            child: new GridView.builder(
                itemCount: (fbPhotos.length != 0) ? fbPhotos.length : 0,
                gridDelegate:
                new SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3
                ),
                itemBuilder: (BuildContext context, int index) {
                  return new InkWell(
                      borderRadius: new BorderRadius.all(new Radius.circular(20.0)),
                      child: new Padding(padding: new EdgeInsets.all(4.0),
                        child: Container(
                          height: 25.0,
                          width: 25.0,
                          decoration: new BoxDecoration(
                            image: new DecorationImage(image:  new CachedNetworkImageProvider(fbPhotos[index],),fit: BoxFit.cover,),
                            borderRadius: new BorderRadius.all(new Radius.circular(5.0),),
                          ),
//                    child: new Align(
//                      alignment: new Alignment(-1.0, -1.0),
//                      child: Icon(Icons.close,color: Colors.white,),
//                    )

                        ),
                      ),
                      onTap:(btnsEnabled) ? ()async{
                        // show img full screen
                        await handleFbPhotoTap(index);

                      } : null
                  );
                }))
    );
  }









  Future<void> handleFbPhotoTap(int index)async{

    if(userHasTempPhotos){
      // tell the user that images are still processing
      var na = await _showFbBSwarning('Images Processing', 'Your photos are still processing. Please refresh this page in a minute or so.', '');
      return;
    }
    var photoId;

    fbPhotoHash.forEach((key,val){
      if(fbPhotos[index] == val){
        photoId = key;
      }
    });



    if(widget.id == globals.id){
      Navigator.push(context,
          new ShowRoute(widget: viewPicPage(cover: true,imgURL: fbPhotos[index],regularPhoto: true,userIsViewingTheirOwnPhoto:true,allPhotos: fbPhotos,photoId:photoId))).then((urlDeleted){
        if(urlDeleted != null){
          setState(() {
            fbPhotos.remove(urlDeleted);
          });
        }
      });
    }else{
      Navigator.push(context,
          new ShowRoute(widget: viewPicPage(cover: true,imgURL: fbPhotos[index],regularPhoto: true,userIsViewingTheirOwnPhoto:false,)));
    }
  }


  void _handlePhotoBtnTap(){

    if(userIsViewingFbPhotos){
      setState(() {
        fbGridAnimationReversing = true;
        fbGridController.reverse().then((TickerFuture animationStatus){


          setState(() {
            fbGridanimationCompletedReversing = true;
            userIsViewingFbPhotos = false;

          });
        });
      });
      return;
    }
    if(!userHasFbPhotos){
      if(userHasTempPhotos){
        setState(() {
          userIsViewingFbPhotos = true;
        });
      }else{
        showFb();
      }
    }else{
      setState(() {
        animatePhotoGridUp();
        fbGridanimationCompletedReversing = false;
        userIsViewingFbPhotos = true;


      });
    }
  }


  void animatePhotoGridUp(){
    fbGridController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);

    fbGridAnimation = CurvedAnimation(parent: fbGridController, curve: Curves.linear)..addListener((){
      setState(() {});
    });
    // need to start from the time that would b
    fbGridController.forward();
  }

  void animateContactsListUp(){
    contactsController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);

    contactsAnimation = CurvedAnimation(parent: contactsController, curve: Curves.linear)..addListener((){
      setState(() {
      });
    });

    if(mounted){
      setState(() {
        hasContacts = true;
      });
    }

    // need to start from the time that would b

    if(contactsDelayCompleted ){
      contactsController.forward().then((TickerFuture animationStatus){
        if(mounted){
          setState(() {
            contactsAnimationCompleted = true;
          });
        }
      });
    }else if(contactsDelayController.value != null){
      int duration = ((1 - contactsDelayController.value) * 500.0).round();
      Future.delayed(new Duration(milliseconds: duration)).then((d){
        contactsController.forward().then((TickerFuture animationStatus){
          if(mounted){
            setState(() {
              contactsAnimationCompleted = true;
            });
          }
        });
      });

    }else{
      setState(() {
        contactsAnimationCompleted = true;
      });
    }


  }


  void startContactsDelay(){
    contactsDelayController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    contactsDelayController.forward().then((TickerFuture animationStatus){

      setState(() {
        contactsDelayCompleted = true;
      });
    });

  }



  Future<void> decideWhetherToShowPhotosOrFbLinkBtn()async{
    // first check if there are fbPhotos, and if there are, display the photo Icon, otherwise display the fbIcon
    bool hasPhotos = await checkIfUserHasFbPhotos();
    if(hasPhotos){
      setState(() {
        userHasFbPhotos = true;
      });
    }else{
      var hasTempPhotos = await checkIfUserHasTempPhotos();
    }
  }


  Future<bool> checkIfUserHasFbPhotos()async{
    var ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child('fbPhotos').child(widget.id).once();
    if(snap.value != null){
      fbPhotoHash = snap.value;
      fbPhotoHash.forEach((key,val){
        fbPhotos.add(val);
      });
      setState(() {
        userHasTempPhotos = false;
      });
      return true;
    }else{
      return false;
    }
  }

  Future<bool> checkIfUserHasTempPhotos()async{
    var ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child('tempPhotos').child(widget.id).once();
    if(snap.value != null){
      setState(() {
        userHasTempPhotos = true;
        userHasFbPhotos = true;
        fbPhotos = new List.from( snap.value);
      });
      return true;
    }else{
      return false;
    }
  }






  Future<void> showFb()async{

    String fbLink;
    try{
      fbLink = await getFBLink();
    }catch(e){
      _errorMenu("Error", "The user hasn't linked their Facebook yet. Try Searching their name on Facebook.", "");
      return;
    }

    if(fbLink.contains("scoped")){
      await  _showFbBSwarning("User May not be visible.", "Due to recent Facebook Privacy issues, this user must be at least a 'friend of a friend' on Facebook in order to see their profile. So, if you cant see their profile, just try searching their name", "");
    }


    if(Platform.isIOS){
      setState(() {
        // disable btns
        btnsEnabled = false;

      });
      platform.invokeMethod('showFb',
          <String, dynamic> {'url':fbLink}).then((d){
        Future.delayed(new Duration(milliseconds: 500)).then((d){
          // enable btns
          setState(() {
            btnsEnabled = true;
          });
        });
      });


    }else{

      Navigator.push(context, new MaterialPageRoute(builder: (context) => new WebviewScaffold(
          url: fbLink,
          appBar: new AppBar(
            iconTheme: new IconThemeData(color: Colors.black),
            backgroundColor: Colors.yellowAccent,
            title: new Text(fullName, style: new TextStyle(color: Colors.black),

            ),
            actions: <Widget>[
              new Icon(Icons.clear)
            ],
          ))));
    }
  }


  Future<String> getFBLink()async{
    DatabaseReference ref = FirebaseDatabase.instance.reference();

    try{
      DataSnapshot snap = await ref.child('fbLinks').child(widget.id).child('link').once();
      if(snap.value != null){
        return snap.value;
      }else{
        throw new Exception();
      }
    }catch(e){
      throw new Exception();
    }
  }






  Future<void>makeSureAllDataIsLoaded(){
    fullName = widget.fullName;
    riderOrDriver = widget.riderOrDriver;
    destination = widget.destination;

    if (fullName == null) {
      grabFullName();
    }
    if(destination == null){
      grabDestination();
    }
    if(riderOrDriver == null){
      grabRiderOrDriver();
    }
  }




  Future<void> grabFullName() async {
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child(globals.cityCode).child('userInfo').child(widget.id).child('fullName').once();
    setState(() {
      fullName = snap.value;
    });
  }

  Future<void> grabBio() async {
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child('bios').child(widget.id).child('bio').once();
    setState(() {
      bio = snap.value;
    });
  }

  Future<void> grabDestination() async {
    DatabaseReference ref = FirebaseDatabase().reference();
    DataSnapshot destinationSnap = await ref.child(globals.cityCode).child('posts')
        .child(widget.id).child('destination')
        .once();
    DataSnapshot stateSnap = await ref.child(globals.cityCode).child('posts')
        .child(widget.id).child('state')
        .once();
    setState(() {
      destination = '${destinationSnap.value}, ${stateSnap.value}';
    });
  }



  Future<void> grabCoverPhoto() async {
    DatabaseReference ref = FirebaseDatabase().reference();
    DataSnapshot snap = await ref.child('coverPhotos').child(widget.id).child('imgURL').once();
    if(snap.value != null){
      setState(() {
        coverPhoto = snap.value;
      });
    }else{
      setState(() {
        coverPhoto = widget.profilePicURL;
      });
    }

  }

  Future<void> grabSchoolAndGradYear()async{
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot schoolSnap = await ref.child('usersCities').child(widget.id).child('school').once();
    DataSnapshot gradSnap = await ref.child('gradYears').child(widget.id).child('gradYear').once();
    setState(() {
      gradYear = gradSnap.value;
      school = schoolSnap.value;
    });
  }

  Future<void> grabRiderOrDriver()async{
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot riderOrDriverSnap = await ref.child(globals.cityCode).child('posts').child(widget.id).child('riderOrDriver').once();
    if(riderOrDriverSnap.value == 'Driving'){
      setState(() {riderOrDriver = 'Driver';});
    }else{
      setState(() {riderOrDriver = 'Passenger';});
    }

  }

  String getFirstName(String fullName) {
    int i;
    String firstName;
    String lastName;
    for (i = 0; i < fullName.length; i++) {
      if (fullName[i] == " ") {
        String firstName = fullName.substring(0, i);
        return firstName;
      }
    }
    return '';
  }

  void showMessageScreen(String id)async{
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child('convoLists').child(globals.id).child(widget.id).child('convoID').once();
    print(globals.id);
    if (fullName == null) {
      await grabFullName();
    }
    if(snap.value != null){
      Navigator.push(context, new MaterialPageRoute(builder: (context) => new ChatScreen(convoId: snap.value,newConvo: false,recipFullName: fullName,recipID: widget.id,recipImgURL: widget.profilePicURL)));
    }else{
      var key = ref.push().key;
      Navigator.push(context, new MaterialPageRoute(builder: (context) => new ChatScreen(convoId: key,newConvo: true,recipFullName: fullName,recipID: widget.id,recipImgURL: widget.profilePicURL)));
    }
  }



  Future<void> getContactInfo()async{
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    DataSnapshot snap = await ref.child('contacts').child(widget.id).once();
    if(snap.value != null){
      List<String> contacts = List.from(snap.value);

      for(var id in contacts){
        var usersInfo = await ref.child(globals.cityCode).child('userInfo').child(id).once();
        contactsList.add(id);
        contactImgInfo[id] = usersInfo.value['imgURL'];
        contactNameInfo[id] = usersInfo.value['fullName'];
      }
      setState(() {
        hasContacts = true;
      });
      animateContactsListUp();

    }else{
      setState(() {
        contactsAnimationCompleted = true;
      });
    }
  }



  Widget contactsListBuilder(){
    return new Container(
        child: new ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: contactsList.length,
            itemBuilder: (BuildContext context, int index) {
              return new InkWell(
                onTap: (btnsEnabled) ? () {
                  Navigator.push(context, new MaterialPageRoute(
                      builder: (context) =>
                      new ProfilePage(id: contactsList[index],
                        profilePicURL: contactImgInfo[contactsList[index]],)));
                } : null,
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Padding(padding: new EdgeInsets.all(5.0),
                      child: new CircleAvatar(
                        radius: 23.0,
                        backgroundImage: new CachedNetworkImageProvider(
                            contactImgInfo[contactsList[index]]),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    new Card(
                      child: new Text(contactNameInfo[contactsList[index]],
                        style: new TextStyle(fontSize: 11.0,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              );
            }
        )
    );
  }



  FirebaseAnimatedList buildContactsList(BuildContext context){
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    print(globals.id);
    final contactsQuery = ref.child('contacts').child(widget.id).orderByKey();
    return new FirebaseAnimatedList(
        query: contactsQuery,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        reverse: false,
        itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, ___) {
          Map user = snapshot.value;
          return new InkWell(
            onTap: (btnsEnabled) ? (){
              Navigator.push(context, new MaterialPageRoute(builder: (context) => new ProfilePage(id: snapshot.key,profilePicURL: user['imgURL'],)));
            } : null,
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new Padding(padding: new EdgeInsets.all(5.0),
                  child: new CircleAvatar(
                    radius: 23.0,
                    backgroundImage: new CachedNetworkImageProvider(user['imgURL']),
                    backgroundColor: Colors.transparent,
                  ),
                ),
                new Text(user['name'], style: new TextStyle(fontSize: 11.0,color: Colors.grey[800], fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        });
  }


  Future<void> changeBio(){
    if(btnsEnabled){
      showDialog(context: context, builder: (BuildContext context) => new EditProfilePopup()).then((changed){
        if(changed ==null){
          return;
        }
        if(changed){
          grabBio();
        }
      });

    }
  }


  Future<void> changeCoverPhoto()async{
    File newCover = await _pickImage();
    if(newCover == null){
      return;
    }

    var croppedImg = await _cropImageForCover(newCover);
    File resizeImg = await FlutterNativeImage.compressImage(croppedImg.path, quality: getCoverPicQualityPercentage(croppedImg.lengthSync()));
    String coverURL = await uploadCoverPhoto(resizeImg, globals.id);
    coverPhoto = coverURL;
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    await ref.child('coverPhotos').child(globals.id).update({'imgURL':coverURL});

  }


  Future<void> addRegularPhoto()async{
    File newCover = await _pickImage();

    File resizeImg = await FlutterNativeImage.compressImage(newCover.path, quality: getCoverPicQualityPercentage(newCover.lengthSync()));
    String imgURL = await uploadRegularPhoto(resizeImg);
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    fbPhotos.add(imgURL);
    await ref.child('fbPhotos').child(globals.id).set(fbPhotos);
    if(mounted){
      setState(() {});
    }

  }


  Future<File> _pickImage() async {

    var imageFile = await  ImagePicker.pickImage(source: ImageSource.gallery);
    return imageFile;
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

  Future<String> uploadRegularPhoto(File img) async {
    try{
      final StorageReference ref = await FirebaseStorage.instance.ref().child("fbPhotos").child(FirebaseDatabase.instance.reference().push().key);
      final dataRes = await ref.putData(img.readAsBytesSync());
      final dwldUrl = await dataRes.future;
      return dwldUrl.downloadUrl.toString();
    }catch(e){
      print(e);
      throw new Exception(e);
    }
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


  Future<void> changeProfilePic()async{

    try{
      File newPic = await _pickImageForProfilePic();
      var croppedImg;
      if(newPic != null){
        croppedImg = await _cropImage(newPic);
      }else{
        return;
      }

      if(newPic != null){
        // File resizeImg = await FlutterNativeImage.compressImage(newPic.path, quality: 100,targetHeight: 200,targetWidth: 200);
        String picURL = await uploadPhoto(croppedImg, globals.id);
        DatabaseReference ref = FirebaseDatabase.instance.reference();
        await ref.child(globals.cityCode).child('posts').child(globals.id).update({'imgURL':picURL});
        await ref.child(globals.cityCode).child('userInfo').child(globals.id).update({'imgURL':picURL});
        await ref.child('usersCities').child(globals.id).update({'imgURL':picURL});


        profilePicUrl = picURL;


      }
    }catch(e){
      return;
    }
  }

  Future<File> _pickImageForProfilePic() async {

    var imageFile = await  ImagePicker.pickImage(source: ImageSource.gallery);
    return imageFile;
  }

  Future<File> _cropImage(File imageFile) async {
    File croppedFile = await ImageCropper.cropImage(
      sourcePath: imageFile.path,
      ratioX: 1.0,
      ratioY: 1.0,
      maxWidth: 200,
      maxHeight: 200,
    );

    return croppedFile;
  }


  Future<File> _cropImageForCover(File imageFile) async {
    File croppedFile = await ImageCropper.cropImage(
      sourcePath: imageFile.path,
      ratioX: 1.0,
      ratioY: 2.0,
      maxWidth: 200,
      maxHeight: 200,
    );

    return croppedFile;
  }


  Future<String> uploadPhoto(File img, String id) async {

    try{
      final StorageReference ref = await FirebaseStorage.instance.ref().child("profilePics").child(id).child(secureString.generate(length: 10,charList: ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s']));
      final dataRes = await ref.putData(img.readAsBytesSync());
      final dwldUrl = await dataRes.future;
      setState(() {
        globals.imgURL = dwldUrl.downloadUrl.toString();
      });
      return dwldUrl.downloadUrl.toString();

    }catch(e){
      print(e);
      throw new Exception(e);
    }

  }






  Future<bool> _showFbBSwarning(String title, String primaryMsg, String secondaryMsg) async {
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
                    child: new Text('OK', style: new TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
                    onPressed: (btnsEnabled) ? () {
                      Navigator.of(context).pop(true);
                    } : null
                ),
              ],
            )
          ],
        );
      },
    );
    return decision;
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
                onPressed: (btnsEnabled) ? () {
                  Navigator.of(context).pop();
                } : null
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showProfileSettings(String title, String primaryMsg, String secondaryMsg) async {

    // change bio
    //change cover
    // change profile pic
    //



    var res = await showDialog(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Center(
            child: new Text('Profile Settings', style: new TextStyle(fontWeight: FontWeight.bold),),
          ),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new InkWell(
                  child: new Container(height: 60.0,width: MediaQuery.of(context).size.width/1.5,child:
                  new Card(
                    color: Colors.yellowAccent,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        new Padding(padding: new EdgeInsets.only(left: 10.0,right: 20.0,top: 10.0,bottom: 10.0),
                          child: new Icon(Icons.border_color,),
                        ),
                        new Text('Edit Bio',style: new TextStyle(fontWeight: FontWeight.bold),)

                      ],
                    ),
                  )
                    ,),
                  onTap: (){
                    changeBio();
                  },
                ),
                new Container(height: 60.0,width: MediaQuery.of(context).size.width/1.5,child:
                new InkWell(
                  child: new Card(
                    color: Colors.yellowAccent,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        new Padding(padding: new EdgeInsets.only(left: 10.0,right: 20.0,top: 10.0,bottom: 10.0),
                          child: new Icon(Icons.photo,),
                        ),
                        new Text('Edit Cover Photo',style: new TextStyle(fontWeight: FontWeight.bold),)
                      ],
                    ),
                  ),
                  onTap: ()async{
                    try{
                      await changeCoverPhoto();
                    }catch(e){

                    }
                    Navigator.of(context).pop(false);

                  },
                )
                ),
                new Container(height: 60.0,width: MediaQuery.of(context).size.width/1.5,child:
                new InkWell(
                  child:  new Card(
                    color: Colors.yellowAccent,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        new Padding(padding: new EdgeInsets.only(left: 10.0,right: 20.0,top: 10.0,bottom: 10.0),
                          child: new Icon(Icons.perm_identity,),
                        ),
                        new Text('Edit Profile Pic',style: new TextStyle(fontWeight: FontWeight.bold),)

                      ],
                    ),
                  ),
                  onTap: ()async {
                    try{
                      await changeProfilePic();

                    }catch(e){
                      //
                    }
                    Navigator.of(context).pop(false);
                  },
                )
                  ,)
              ],
            ),
          ),
          actions: <Widget>[


          ],
        );
      },
    );

    return res;
  }





}

