

import 'dart:async';
import 'dart:core';
import 'package:flutter/material.dart';
import 'photo_view_image_wrapper.dart';
import 'package:photo_view/photo_view_scale_boundaries.dart';
import 'package:photo_view/photo_view_scale_state.dart';
import 'package:photo_view/photo_view_utils.dart';
import 'package:after_layout/after_layout.dart';

export 'package:photo_view/photo_view_scale_boundary.dart';


/// A [StatefulWidget] that contains all the photo view rendering elements.
///
/// Internally, the image is rendered within an [Image] widget.
///
/// To use along a hero animation, provide [heroTag] param.
///
/// Sample code:
///
/// ```
/// PhotoView(
///  imageProvider: imageProvider,
///  loadingChild: new LoadingText(),
///  backgroundColor: Colors.white,
///  minScale: PhotoViewScaleBoundary.contained,
///  maxScale: 2.0,
///  gaplessPlayback: false,
///  size:MediaQuery.of(context).size,
///  heroTag: "someTag"
/// );
/// ```
///

class PhotoView extends StatefulWidget{

  /// Creates a widget that displays an zoomable image.
  ///
  /// To show an image from the network or from an asset bundle, use their respective
  /// image providers, ie: [AssetImage] or [NetworkImage]
  ///
  /// The [maxScale] and [minScale] arguments may be [double] or a [PhotoViewScaleBoundary] constant
  ///
  /// Sample using [maxScale] and [minScale]
  ///
  /// ```
  /// PhotoView(
  ///  imageProvider: imageProvider,
  ///  minScale: PhotoViewScaleBoundary.contained * 1.8,
  ///  maxScale: PhotoViewScaleBoundary.covered * 1.1
  /// );
  /// ```
  /// [size] is used to define the viewPort size in which the image will be
  /// scaled to. This argument is rarely used. By befault is the size of the
  /// screen. [PhotoViewInline] defines is as the size of the widget.
  ///
  /// The argument [gaplessPlayback] is used to continue showing the old image
  /// (`true`), or briefly show nothing (`false`), when the [imageProvider]
  /// changes.By default it's set to `false`.
  ///
  /// To use within an hero animation, specify [heroTag]. When [heroTag] is
  /// specified, the image provider retrieval process should be sync.
  ///
  /// Sample using hero animation
  /// ```
  /// // screen1
  ///   ...
  ///   Hero(
  ///     tag: "someTag",
  ///     child: Image.asset(
  ///       "assets/large-image.jpg",
  ///       width: 150.0
  ///     ),
  ///   )
  /// // screen2
  /// ...
  /// child: PhotoView(
  ///   imageProvider: AssetImage("assets/large-image.jpg"),
  ///   heroTag: "someTag",
  /// )
  /// ```
  ///
  const PhotoView({
    Key key,
    @required this.imageProvider,
    this.loadingChild,
    this.backgroundColor = const Color.fromRGBO(0, 0, 0, 1.0),
    this.minScale,
    this.maxScale,
    this.gaplessPlayback = false,
    this.size,
    this.heroTag,
    this.xTag,
    this.yTag
  }) : super(key: key);

  /// Given a [imageProvider] it resolves into an zoomable image widget using. It
  /// is required
  final ImageProvider imageProvider;

  /// While [imageProvider] is not resolved, [loadingChild] is build by [PhotoView]
  /// into the screen, by default it is a centered [CircularProgressIndicator]
  final Widget loadingChild;

  /// Changes the background behind image, defaults to `Colors.black`.
  final Color backgroundColor;

  /// Defines the minimal size in which the image will be allowed to assume, it
  /// is proportional to the original image size. Can be either a double or a
  /// [PhotoViewScaleBoundary]
  final dynamic minScale;

  /// Defines the maximal size in which the image will be allowed to assume, it
  /// is proportional to the original image size. Can be either a double or a
  /// [PhotoViewScaleBoundary]
  final dynamic maxScale;

  /// This is used to continue showing the old image (`true`), or briefly show
  /// nothing (`false`), when the `imageProvider` changes. By default it's set
  /// to `false`.
  final bool gaplessPlayback;

  /// Defines the size of the scaling base of the image inside [PhotoView],
  /// by default it is `MediaQuery.of(context).size`. This argument is used by
  /// [PhotoViewInline] class.
  final Size size;

  /// Assists the activation of a hero animation within [PhotoView]
  final Object heroTag;


  final double xTag;

  final double yTag;


  @override
  State<StatefulWidget> createState() {
    return new _PhotoViewState();
  }
}


class _PhotoViewState extends State<PhotoView>{
  PhotoViewScaleState _scaleState;
  GlobalKey containerKey = GlobalKey();
  ImageInfo _imageInfo;

  Future<ImageInfo> _getImage(){
    final Completer completer = Completer<ImageInfo>();
    final ImageStream stream = widget.imageProvider.resolve(const ImageConfiguration());
    final listener = (ImageInfo info, bool synchronousCall) {
      if(!completer.isCompleted){
        completer.complete(info);
        setState(() {
          _imageInfo = info;
        });
      }
    };
    stream.addListener(listener);
    completer.future.then((_){ stream.removeListener(listener); });
    return completer.future;
  }

  void onDoubleTap () {
    setState(() {
      _scaleState = nextScaleState(_scaleState);
    });
  }

  void onStartPanning () {
    setState(() {
      _scaleState = PhotoViewScaleState.zooming;
    });
  }

  @override
  void initState(){
    super.initState();
    _getImage();
    _scaleState = PhotoViewScaleState.contained;
  }
  @override
  Widget build(BuildContext context) {
    return widget.heroTag == null ? buildWithFuture(context) : buildSync(context);
  }

  Widget buildWithFuture(BuildContext context){
    return FutureBuilder(
        future: _getImage(),
        builder: (BuildContext context, AsyncSnapshot<ImageInfo> info) {
          if(info.hasData){
            return buildWrapper(context, info.data);
          } else {
            return buildLoading();
          }
        }
    );
  }

  Widget buildSync(BuildContext context){
    if (_imageInfo == null) {
      return buildLoading();
    }
    return buildWrapper(context, _imageInfo);
  }

  Widget buildWrapper(BuildContext context, ImageInfo info){
    return PhotoViewImageWrapper(
      onDoubleTap: onDoubleTap,
      onStartPanning: onStartPanning,
      imageProvider: widget.imageProvider,
      imageInfo: info,
      scaleState: _scaleState,
      backgroundColor: widget.backgroundColor,
      gaplessPlayback: widget.gaplessPlayback,
      size: widget.size ?? MediaQuery.of(context).size,
      scaleBoundaries: ScaleBoundaries(
        widget.minScale ?? 0.0,
        widget.maxScale ?? 100000000000.0,
        imageInfo: info,
        size: widget.size ?? MediaQuery.of(context).size,
      ),
      heroTag: widget.heroTag,
      xTag: widget.xTag,
      yTag: widget.yTag,
    );
  }

  Widget buildLoading() {
    return widget.loadingChild != null
      ? widget.loadingChild
      : Center(
      child: Container(
        width: 20.0,
        height: 20.0,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

/// A [StatelessWidget] which the only child is a [PhotoView] with an automacally
/// calculated [size]. All but [size] arguments are the same as [PhotoView].
class PhotoViewInline extends StatefulWidget{
  final ImageProvider imageProvider;
  final Widget loadingChild;
  final Color backgroundColor;
  final dynamic minScale;
  final dynamic maxScale;

  const PhotoViewInline({
    Key key,
    @required this.imageProvider,
    this.loadingChild,
    this.backgroundColor = const Color.fromRGBO(0, 0, 0, 1.0),
    this.minScale,
    this.maxScale,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => new _PhotoViewInlineState();
}

class _PhotoViewInlineState extends State<PhotoViewInline> with AfterLayoutMixin<PhotoViewInline>{

  Size _size;

  @override
  void afterFirstLayout(BuildContext context) {
    setState(() {
      _size = context.size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new PhotoView(
      imageProvider: widget.imageProvider,
      loadingChild: widget.loadingChild,
      backgroundColor: widget.backgroundColor,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      size: _size,
    );
  }



}