import 'package:flutter/material.dart';
import '../homePage/chatList.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import '../globals.dart' as globals;

class AddFeedback extends StatefulWidget {


  Map userInfo;
  AddFeedback({this.userInfo});
  _AddFeedbackState createState() => new _AddFeedbackState();


}
class _AddFeedbackState extends State<AddFeedback> {
  String logoURL = "https://is4-ssl.mzstatic.com/image/thumb/Purple125/v4/b2/a7/91/b2a7916a-35be-5a7e-4c91-45317fb40d9c/AppIcon-1x_U007emarketing-0-0-GLES2_U002c0-512MB-sRGB-0-0-0-85-220-0-0-0-3.png/246x0w.jpg";
  FocusNode commentNode = new FocusNode();
  bool userHasFeedback = true;
  TextEditingController feedbackController = new TextEditingController();

  void initState() {
    super.initState();


  }


  @override
  Widget build(BuildContext context) {
    return new SimpleDialog(
      children: <Widget>[
        new Container(
          child: new Column(
            children: <Widget>[
              new Padding(padding: new EdgeInsets.only(left: 5.0),
                child: new TextField(
                  autofocus: true,
                  controller: feedbackController,
                  keyboardType: TextInputType.multiline,
                  decoration: new InputDecoration(
                    border: InputBorder.none,
                    hintText:  ('Say what you need to say'),
                  ),
                  maxLines: 10,
                ),
              ),
              new Container(
                color: Colors.yellow,
                height: 40.0,
                width: double.infinity,
                child: new InkWell(
                  onTap: (){
                    //send feedback
                    sendFeedBack();
                  },
                  child: new Center(
                    child: new Text('Add Anonymous Feedback', style: new TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  void sendFeedBack() {
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    if(feedbackController.text.length != 0){
      ref.child('feedback').child(widget.userInfo['id']).child(globals.id).set({'feedback':feedbackController.text});
      Navigator.pop(context);
    }

  }

  FirebaseAnimatedList buildFirebaseList(BuildContext context, String userID)  {
    DatabaseReference ref = FirebaseDatabase.instance.reference();

    final falQuery = ref.child('userInfo').child(userID).child('feedback').orderByKey();

    return new FirebaseAnimatedList(
        query: falQuery,
        defaultChild: new CircularProgressIndicator(),
        sort: (DataSnapshot a, DataSnapshot b) => b.key.compareTo(a.key),
        reverse: false,
        itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, ___) {

          return new Container(
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Padding(padding: new EdgeInsets.all(5.0),
                  child:  new CircleAvatar(
                    backgroundImage: new NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png'),
                  ),
                ),
                new Flexible(child: new Column(
                  children: <Widget>[
                    new Padding(padding: new EdgeInsets.only(top: 5.0, left: 5.0),
                      child: new Text('Anonymous Says...', style: new TextStyle(fontWeight: FontWeight.bold),),
                    ),

                    new Padding(padding: new EdgeInsets.all(5.0),
                      child:  new Text(snapshot.value['comment'],softWrap: true,),
                    ),
                  ],
                  crossAxisAlignment: CrossAxisAlignment.start,
                ))


              ],
            ),
          );
        });
  }

}


