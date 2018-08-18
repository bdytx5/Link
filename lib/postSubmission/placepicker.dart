import 'package:google_maps_webservice/geocoding.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_maps_webservice/directions.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:collection/collection.dart';
import '../globals.dart' as globals;
import '../loginFlow/signup.dart';
import 'dart:async';
import '../main.dart';
import '../homePage/feed.dart';
import 'package:dio/dio.dart';

class PlacePicker extends StatefulWidget {

     PlacePicker({this.app,this.userIsSigningUp});
    final FirebaseApp app;
    final bool userIsSigningUp;


  @override
  _PickerState createState() => new _PickerState();
}


class _PickerState extends State<PlacePicker> {


  List<Place> returnedPlaces = new List();
  List<Map> popularCities = new List();
  Map placeData = {};


  final geocoding = new GoogleMapsGeocoding('AIzaSyDdmmVxh0XeFGrWGIjV0BUydtS8urN6DUI');
  final places = new GoogleMapsPlaces('AIzaSyDdmmVxh0XeFGrWGIjV0BUydtS8urN6DUI');
  final directions = new GoogleMapsDirections('AIzaSyDdmmVxh0XeFGrWGIjV0BUydtS8urN6DUI');

  final textContoller = new TextEditingController();
  bool cellTapEnabled = true;
  bool blankSearch = true;

  
void initState() {
    super.initState();
      grabPopularCities();
   }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body:new WillPopScope(
            onWillPop: () async {
              return false;
            },
            child: new Stack(
              children: <Widget>[
                buildPlacePickerInput(),
                new Center(
                    child: (!cellTapEnabled) ? new Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new CircularProgressIndicator(),
                      ],
                    ) : new Container()
                )
              ],
            )
        )
    );
  }



  Widget buildPlacePickerInput(){
    return new Container(
      child: new Column(
        children: <Widget>[
          new Container(
            height: 120.0,
            width: double.infinity,
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                new Expanded(
                  child: new Padding(padding: new EdgeInsets.only(top: 35.0),
                    child: (!widget.userIsSigningUp) ?  new IconButton(
                        icon:  new Icon(Icons.close),
                        onPressed: (){
                          Navigator.pop(context);
                        }) : new Container(),
                  ),
                ),
                new Padding(padding: new EdgeInsets.only(left: 12.0, bottom: 1.0),
                  child: new TextField(
                    autofocus: true,
                    controller: textContoller,
                    decoration: new InputDecoration(border: InputBorder.none, hintText:(widget.userIsSigningUp) ? 'Where do usually go?':'Where?'),
                    style: new TextStyle(fontSize: 24.0,color: Colors.black),
                    onChanged: (d){ searchBarChanged();},
                  ),
                ),
              ],
            ),
          ),
          new Divider(),
          new Expanded(
            child: (!blankSearch) ? placesListView() : popularCitiesListView(),
          )
        ],
      ),
    );
  }

  

void searchBarChanged() async{
  if(textContoller.text.length == 0 ){
    setState((){
      blankSearch = true;
      returnedPlaces.clear();
    });
 }else{
    PlacesAutocompleteResponse response3;
    try{
      response3 = await places.autocomplete(textContoller.text);
    }catch(e){
      return;
    }
    if(!response3.isOkay){
      return;
    }
    List<Prediction> placesList = response3.predictions;
    returnedPlaces.removeRange(0, returnedPlaces.length);
    if (this.mounted){
      setState(() {
        placesList.forEach((place) {
          Place thePlace = Place(place.placeId, place.description);
          returnedPlaces.add(thePlace);
          blankSearch = false;
        });
      });
    }
  }
}





Widget popularCitiesListView(){
 return new MediaQuery.removePadding(
    removeTop: true,
    context: context,
    child: new Container(
      child: new ListView.builder(
          itemCount: popularCities.length,
          itemBuilder: (context,index){
            return _buildPopularCitiesCell(index);
          }
      ),
    ),
  );
}


  Widget placesListView(){
    return new MediaQuery.removePadding(
      removeTop: true,
      context: context,
      child: new Container(
        child: new ListView.builder(
            itemCount: returnedPlaces.length,
            itemBuilder: (context,index){
              return(index < returnedPlaces.length) ? _buildPlacesCell(index) : new Container();
            }
        ),
      ),
    );
  }




  Widget _buildPlacesCell(int index){
      return new InkWell(
          onTap: (!cellTapEnabled) ? null : () {_handlePlacePickerCellSelection(returnedPlaces[index]);},
          child: new Container(
            padding: new EdgeInsets.all(10.0),
            child: new Row(
              children: <Widget>[
                new Icon(Icons.place),
                new Flexible(
                  child:  new Text(returnedPlaces[index].description, overflow: TextOverflow.ellipsis),
                )
              ],
            )
          )
      );
   }


  Widget _buildPopularCitiesCell(int index){
    Map city = popularCities[index];
    Place place = new Place(city['placeID'], city['longName']);
    return new InkWell(
        onTap: (!cellTapEnabled) ? null : () {_handlePopularCitySelection(place);},
        child: new Container(
            padding: new EdgeInsets.all(10.0),
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                new Icon(Icons.place),
               new Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisAlignment: MainAxisAlignment.start,
                 children: <Widget>[
                   new Padding(padding: new EdgeInsets.only(bottom: 5.0),

                   child:  new Text(city['city'], overflow: TextOverflow.ellipsis, style: new TextStyle(fontSize: 16.0),),
                     ),

                   new Text(city['state'], style: new TextStyle(color: Colors.grey),),
                 ],
               )
              ],
            )
        )
    );
  }


    void _handlePlacePickerCellSelection(Place place) async {
      setState(() {cellTapEnabled = false;});
          var placeInfo;
          try{
             placeInfo = await getCityData(place.id);
          }catch(e){
            _errorMenu('Error', "Couldn't find sufficient information for this location..", 'Sorry');
            setState(() {
              cellTapEnabled = true;
            });
            return;
          }
           placeInfo['longName'] = place.description;
           if(placeInfoIsOkay(placeInfo)){
             Navigator.pop(context, placeInfo);
           }else{
             setState(() {cellTapEnabled = true;});

             _errorMenu('Error', 'Please Choose a different location', 'One of your locations were not found');

             return;
           }
    }




  void _handlePopularCitySelection(Place place) async {
    setState(() {cellTapEnabled = false;});

      var placeInfo;
      try{
         placeInfo = await getCityData(place.id);
      }catch(e){
        _errorMenu('Error', "Couldn't find sufficient information for this location..", 'Sorry');
        setState(() {cellTapEnabled = true;});
        return;
      }
      placeInfo['longName'] = place.description;
      if(placeInfoIsOkay(placeInfo)){
        placeInfo['fromHomeCity'] = true;
        Navigator.pop(context, placeInfo);
      }else{
        setState(() {cellTapEnabled = true;});
        _errorMenu('Error', 'Please Choose a different location', 'One of your locations were not found');
        return;
      }
  }



// used to make sure google map data is correctly returned!
 bool placeInfoIsOkay(Map placeInfo){
    if(placeInfo == null){
      return false;
       }else{
      // make sure the placeInfo has all the neccessary data!!
      Map info = placeInfo;
      if(info.keys.length != 4){
        // tell the user that we can't find enough info on their place!!
        return false;
        }else {
        return true;
      }
    }
  }



  Future<Map<dynamic,dynamic>> getCityData(String id)async{
    var cityData = Map<dynamic,dynamic>();
    Map coordinates = {};
    GeocodingResponse response3;
    try{
      response3 = await geocoding.searchByPlaceId(id);
    }catch(e){
      throw new Exception();
    }

    if(response3.isOkay){
      var lat = response3.results.first.geometry.location.lat.toString();
      var lng = response3.results.first.geometry.location.lng.toString();
      coordinates['lat'] = lat;
      coordinates['lon'] = lng;
      cityData['coordinates'] = coordinates;
      response3.results.first.addressComponents.forEach((res){

        List<String> stateComponents = ["administrative_area_level_1", "political"];
        List<String> cityComponents = ["locality", "political"];

        Function eq = const ListEquality().equals;
        if(eq(stateComponents, res.types)){
//initials
          cityData['state'] = res.shortName;
        }
        if(eq(cityComponents, res.types)){
//city short name
          cityData['city'] = res.shortName;
        }
      });
      if(cityData['state'] == null || cityData['city'] == null || lng == null || lat == null){
        throw new Exception();
      }
      return cityData;
    }else{
      throw new Exception('error');
    }

  }





  void grabPopularCities()async{
    DatabaseReference ref = FirebaseDatabase.instance.reference();
    try{
      final snap = await ref.child('popularCities').once();
      Map cities = snap.value;
      cities.forEach((key,val){
        setState(() {
          popularCities.add(val);
        });
      });
    }catch(e){
      _errorMenu('Error', 'There was an error connecting to the Link Servers. Please try again later.', '');
      throw new Exception();
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



}

class Post{
   Post({this.name,this.fullName,this.imgURL,this.id,this.phoneNumber,this.destination,this.state});

  String fullName;
  String id;
  String name;
  String imgURL;
  String phoneNumber;
  String destination;
  String state;

   toJson() {
    return {
      
      "fullName": fullName,
      "id": id,
      "name": name,
       "imgURL": imgURL,
      "phone": phoneNumber,
      "destination": destination,
      "state":state
    };
  }


}




class Place{

  String description;
  String longDescription;
  String id;
  String longitude;
  String latitude;
  

  Place(this.id,this.description);
}




// Future<String> getCity(String id)async{

//   List<String> cityComponents = ["locality", "political"];
// String city = "";
// GeocodingResponse response3 = await geocoding.searchByPlaceId(id);

// response3.results.first.addressComponents.forEach((res){



//   print(res.types);

// Function eq = const ListEquality().equals;
// if(eq(cityComponents, res.types)){

  
// city = res.shortName;

// }


// });

// return city;

// }


// void go() async{

//      final places = new GoogleMapsPlaces("AIzaSyC_s7kYr0hEbExTd_GglEUfyP_7KOXlzTs");
// final geocoding = new GoogleMapsGeocoding("AIzaSyC_s7kYr0hEbExTd_GglEUfyP_7KOXlzTs");


//     PlacesSearchResponse reponse = await places.searchByText("1600 Amphitheatre Parkway, Mountain View, CA 94043, USA");
//      List<PlacesSearchResult> placesList = reponse.results;

//      //placesList.first.add

// // PlacesDetailsResponse response2 = await places.getDetailsByPlaceId(placesList.first.id);
// // print(response2.result.addressComponents[5].shortName);

// GeocodingResponse response3 = await geocoding.searchByPlaceId(placesList.first.placeId);

// response3.results.first.addressComponents.forEach((res){

// List<String> stateComponents = ["administrative_area_level_1", "political"];
// List<String> cityComponents = ["locality", "political"];



//   print(res.types);

// Function eq = const ListEquality().equals;
// if(eq(stateComponents, res.types)){

//   print(res.shortName);


// };

// if(eq(cityComponents, res.types)){

//   print(res.shortName);


// };



// });

// }




//
//
//new Center(
//child: new Column(
//children: <Widget>[
//new Container(
//height: 25.0,
//width: 25.0,
//color: Colors.black,
//),
//new Container(
//height: 80.0,
//width: double.infinity,
//color: Colors.white,
//
//child: new Container(
//child: new Column(
//mainAxisAlignment: MainAxisAlignment.end,
//crossAxisAlignment: CrossAxisAlignment.start,
//children: <Widget>[
//(widget.userIsSigningUp) ? new Container():new Padding(
//padding: new EdgeInsets.all(10.0),
//child: new Container(
//height: 20.0,
//width: 20.0,
//child: new IconButton(
//icon: new Icon(Icons.close),
//onPressed: (){
//Navigator.pop(context);
//},
//),
//),
//),
//
//new Padding(
//padding: EdgeInsets.only(left: 10.0),
//
//child: new TextField(
//autofocus: true,
//controller: textContoller,
//style: new TextStyle(fontSize: 25.0,fontWeight: FontWeight.bold,color: Colors.black),
//
//decoration: new InputDecoration(
//hintText: "Where to next?",
//
//border: InputBorder.none
//
//),
//),
//),
//
//],
//),
//
//
//),
//),
//MediaQuery.removePadding(
//removeTop: true,
//context: context,
//child: new Expanded(
//child:   new Container(
//height: double.infinity,
//color: Colors.white,
//
//child: new ListView.builder(
//itemCount: myPlaces.length,
//
//itemBuilder: (BuildContext context, int index){
//
//return _buildCell(index);
//
//},
//)
//),
//
//)
//)
//
//],
//),
//
//),


///was in handle popular city selection function
//        var distanceInMeters;
//        try{
//          distanceInMeters = await getDistanceBetweenTwoCities(globals.city, place.description);
//        }catch(e){
//          _errorMenu('Error', "Couldn't find enough information on this location.", 'Please choose a new location.');
//          setState(() {
//            cellTapEnabled = true;
//          });
//          return;
//        }
//        if(distanceInMeters < 50000) {
//          placeInfo['fromHomeCity'] = 'true';
//        }else{
//          var originData = await geocoding.searchByAddress(place.description);
//          var originID = originData.results.first.placeId;
//          var originInfo;
//          try{
//            originInfo = await getCityData(originID);
//
//          }catch(e){
//            _errorMenu('Error', "Couldn't find sufficient information for this location..", 'Sorry');
//            setState(() {
//              cellTapEnabled = true;
//            });
//            return;
//          }
//          if(originInfo.containsKey('state')){
//            placeInfo['fromHomeCity'] = 'false';
//            placeInfo['originState'] = originInfo['state'];
//          }
//        }