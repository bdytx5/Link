import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';


class cropImage extends StatefulWidget {



  _cropImageState createState() => new _cropImageState();


}
class _cropImageState extends State<cropImage> {
  String logoURL = "https://is4-ssl.mzstatic.com/image/thumb/Purple125/v4/b2/a7/91/b2a7916a-35be-5a7e-4c91-45317fb40d9c/AppIcon-1x_U007emarketing-0-0-GLES2_U002c0-512MB-sRGB-0-0-0-85-220-0-0-0-3.png/246x0w.jpg";
  FocusNode commentNode = new FocusNode();
  bool userHasFeedback = true;
  TextEditingController feedbackController = new TextEditingController();

  void initState() {
    super.initState();


  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
      child:  new IconButton(
          icon: new Icon(Icons.call_made),

            onPressed: ()async{
              File fl = await _pickImage();
              File fl2 = await _cropImage(fl);
            },

        ),
      ),
    );
  }

  String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();


  Future<File> _pickImage() async {
    var response = await http.get('https://scontent-ort2-2.xx.fbcdn.net/v/t1.0-9/13620865_1065184220244060_5634727786461410103_n.jpg?_nc_cat=0&oh=7bb88d5a24ca3f14d140d2acda3be308&oe=5BD7E478');
    var result;
    final Directory systemTempDir = Directory.systemTemp;
    final Directory extDir = await getTemporaryDirectory();
    final String dirPath = '${extDir.path}/${timestamp()}';
    await new Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';
    result = await new File('${filePath}.png').create();
    await result.writeAsBytes(response.bodyBytes);
    if (result != null) {
     return result;
    }else{
      throw new Exception("err");
    }
  }

  Future<File> _cropImage(File file) async {
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: file.path,
        ratioX: 1.0,
        ratioY: 2.0,
        maxHeight: 50,
        maxWidth: 50,
        toolbarTitle: 'Cropper',
        toolbarColor: Colors.blue
    );
    return croppedFile;
  }


}