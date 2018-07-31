import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../loginFlow/login_page.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import '../main.dart';
import 'placepicker.dart';


//hey


class SubmitPost extends StatefulWidget{

  static const String routeName = "/submitPost";

  _submitPostState createState() => new _submitPostState();


     FirebaseApp app;
  SubmitPost(this.app); 


}

class _submitPostState extends State<SubmitPost>{
final originTextContoller = new TextEditingController();
   

    final destinationTextContoller = new TextEditingController();
    String origin = 'hey';
    String destination = 'hi';
    Map data = {};

   void initState() {
    super.initState();

    // get current users post info 
    FirebaseDatabase database = FirebaseDatabase.instance;

    database.reference().child('posts').child('1822686981097984').once().then((snap){

       data = snap.value;
        print(data.toString());
        setState(() {
                origin = data['longOrigin'];
                destination = data['longDestination'];

                });
    });

 
originTextContoller.addListener(_onOriginTouch);


       

   }


   _onOriginTouch() {
    
     print('find a way to win');

//Navigator.push(context,
          //      new MaterialPageRoute(builder: (context) => new PlacePicker(app: widget.app,userIsSigningUp: false)));


     

     

     


    //  final place = await Navigator.push(context,
    //             new MaterialPageRoute(builder: (context) => new PlacePicker(app: widget.app,userIsSigningUp: false)),
    //             ).then((val){

              //    print(val);

                //  print(originTextContoller.hasListeners.toString());


       
          // originTextContoller.text = place;
 //  });



   }

   
  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree

     originTextContoller.removeListener(_onOriginTouch);
    originTextContoller.dispose();

    super.dispose();
  }
 

    @override
  Widget build(BuildContext context) {
        return new Scaffold(
          body: new Center(
          child:new Column(
            children: <Widget>[
              new Padding(
                padding: new EdgeInsets.all(15.0),
                child: new Container(
                  width: double.infinity,
                  child: new Column(
                    children: <Widget>[
                      new SizedBox(
                        height: 60.0,
                      ),
                       new Container(
                            width: double.infinity,
                            height: 40.0,
                        decoration: new BoxDecoration(
                          color:  Theme.of(context).primaryColorLight,
                          border:new Border(
                            bottom: new BorderSide(
                           //  color: Colors.black
                            ),
                          ),
                        ),
                        child: new Row(
                         children: <Widget>[
                           new Container(
                             height: 20.0,
                             width: 20.0,
                             color: Colors.white,
                             child: new Icon(Icons.pin_drop)
                           ),
                           new Expanded(
                             child:new Padding(
                               padding: new EdgeInsets.only(left: 8.0),
                               child:  new Container(
                                height: 40.0,
                                width: double.infinity,
                                color: Colors.green,
                            child:  new MaterialButton(
                              color: Colors.blue,
                              child: new Text(
                                origin
                              ),
                            ),
                           ),
                             ),
                           )
                         ],
                        ),
                      ),
                       ],
                  ),
                ),
              ),
              new Padding(
                padding: new EdgeInsets.only(left: 15.0, right: 15.0),
                child: new Container(
                  width: double.infinity,
                  child: new Column(
                    children: <Widget>[
                       new Container(
                            width: double.infinity,
                            height: 40.0,
                            decoration: new BoxDecoration(
                            color:  Theme.of(context).primaryColorLight,
                              border:new Border(
                                bottom: new BorderSide(
                            ),
                          ),
                        ),
                        child: new Row(
                         children: <Widget>[
                           new Container(
                             height: 20.0,
                             width: 20.0,
                             color: Colors.white,
                             child: new Icon(Icons.pin_drop)
                           ),
                           new Expanded(
                             child:new Padding(
                               padding: new EdgeInsets.only(left: 8.0),
                               child:         new Container(
                                height: 40.0,
                                width: double.infinity,
                                color: Colors.green,
                            child: new MaterialButton(
                              color: Colors.blue,
                              child: new Text(
                                destination
                              ),
                              onPressed: () async {
                                // present place picker and then retrieve updated data
                            final place = await Navigator.push(context,
                       new MaterialPageRoute(builder: (context) => new PlacePicker(app: widget.app,userIsSigningUp: false)),
                    ).then((placeInfo){
                               print(placeInfo.toString()); 
                               data['longDestination'] = placeInfo[''];
                    });
                                
                              },
                            ),
                           ),
                             ),
                           )
                         ],
                        ),
                      ),


                      // insert text field two here i think
                       ],
                  ),
                ),
              ),

            new Padding(
              padding: new EdgeInsets.all(10.0),
              child: new Center(

                child: new Text(
                  'When will you be leaving?',
                  style: new TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
                new Container(
                  color: Colors.white,
                      height: 400.0,
                      width: double.infinity,
          child: new MonthPicker(
             firstDate:  DateTime.parse("-2020-12-24"),
             lastDate:  DateTime.parse("-2017-12-24"),
             selectedDate: DateTime.parse("-2018-12-24"),
             onChanged: (date){
             },
          )
        ),
        new Container(
          height: 70.0,
          width: double.infinity,
          color: Colors.yellow,
            child: new InkWell(
   
              onTap: (){
        //Navigator.push(context,
         //     new MaterialPageRoute(builder: (context) => new PlacePicker(app: widget.app,userIsSigningUp: false)));


    setState(() {
          
        });
              },
              child: new Center(
                child:   new Text(
                'Click to Add Custom Message',
                style: new TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                ),
                
               ),
              )
            ),
        )

            ],
          )
          
         
        )
        
        );
        
   
}
}