import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_scale_boundaries.dart';
import 'package:photo_view/photo_view_scale_state.dart';
import 'package:photo_view/photo_view_utils.dart';


class PhotoViewImageWrapper extends StatefulWidget{
  const PhotoViewImageWrapper({
    Key key,
    @required this.onDoubleTap,
    @required this.onStartPanning,
    @required this.imageInfo,
    @required this.scaleState,
    @required this.scaleBoundaries,
    @required this.imageProvider,
    @required this.size,
    this.backgroundColor,
    this.gaplessPlayback = false,
    this.heroTag,
    this.xTag,
    this.yTag
  }) : super(key:key);

  final Function onDoubleTap;
  final Function onStartPanning;
  final ImageInfo imageInfo;
  final PhotoViewScaleState scaleState;
  final Color backgroundColor;
  final ScaleBoundaries scaleBoundaries;
  final ImageProvider imageProvider;
  final bool gaplessPlayback;
  final Size size;
  final String heroTag;

  final double xTag;
  final double yTag;

  @override
  State<StatefulWidget> createState() {
    return new _PhotoViewImageWrapperState();
  }
}


class _PhotoViewImageWrapperState extends State<PhotoViewImageWrapper> with TickerProviderStateMixin{
  Offset _position;
  Offset _normalizedPosition;
  double _scale;
  double _scaleBefore;

  AnimationController _scaleAnimationController;
  Animation<double> _scaleAnimation;

  AnimationController _positionAnimationController;
  Animation<Offset> _positionAnimation;

  void handleScaleAnimation() {
    setState(() {
      _scale = _scaleAnimation.value;
    });
  }

  void handlePositionAnimate() {
    setState(() {
      _position = _positionAnimation.value;
    });
  }

  void onScaleStart(ScaleStartDetails details) {
    _scaleBefore = scaleStateAwareScale();
    _normalizedPosition= details.focalPoint - _position;
    _scaleAnimationController.stop();
    _positionAnimationController.stop();
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    final double newScale = _scaleBefore * details.scale;
    final Offset delta = details.focalPoint - _normalizedPosition;
    if(details.scale != 1.0){
      widget.onStartPanning();
    }
    setState(() {
      _scale = newScale;
      _position = clampPosition(delta * details.scale);
    });
  }

  void onScaleEnd(ScaleEndDetails details) {
    final double maxScale = widget.scaleBoundaries.computeMaxScale();
    final double minScale = widget.scaleBoundaries.computeMinScale();

    //animate back to maxScale if gesture exceeded the maxScale specified
    if(_scale > maxScale){
      final double scaleComebackRatio = maxScale / _scale;
      animateScale(_scale, maxScale);
      animatePosition(_position, clampPosition(_position * scaleComebackRatio, maxScale));
      return;
    }

    //animate back to minScale if gesture fell smaller than the minScale specified
    if(_scale < minScale){
      final double scaleComebackRatio = minScale / _scale;
      animateScale(_scale, minScale);
      animatePosition(_position, clampPosition(_position * scaleComebackRatio, maxScale));
    }
  }

  Offset clampPosition(Offset offset, [double scale]) {
    final double _scale = scale ?? scaleStateAwareScale();
    final double x = offset.dx;
    final double y = offset.dy;
    final double computedWidth = widget.imageInfo.image.width * _scale;
    final double computedHeight = widget.imageInfo.image.height * _scale;
    final double screenWidth = widget.size.width;
    final double screenHeight = widget.size.height;
    final double screenHalfX = screenWidth / 2;
    final double screenHalfY = screenHeight / 2;

    final double computedX = screenWidth < computedWidth ? x.clamp(
        0 - (computedWidth / 2) + screenHalfX,
        computedWidth / 2 - screenHalfX
    ) : 0.0;

    final double computedY = screenHeight < computedHeight ? y.clamp(
        0 - (computedHeight / 2) + screenHalfY,
        computedHeight / 2 - screenHalfY
    ) : 0.0;

    return Offset(
      computedX,
      computedY
    );
  }

  double scaleStateAwareScale(){
    return _scale != null || widget.scaleState == PhotoViewScaleState.zooming
      ? _scale
      : getScaleForScaleState(
        imageInfo: widget.imageInfo,
        scaleState: widget.scaleState,
        size: widget.size
      ).clamp(
        widget.scaleBoundaries.computeMinScale(),
        widget.scaleBoundaries.computeMaxScale()
      );
  }

  void animateScale(double from, double to){
    _scaleAnimation = new Tween<double>(
      begin: from,
      end: to,
    ).animate(_scaleAnimationController);
    _scaleAnimationController
      ..value = 0.0
      ..fling(velocity: 0.4);
  }

  void animatePosition(Offset from, Offset to){
    _positionAnimation = new Tween<Offset>(
        begin: from,
        end: to
    ).animate(_positionAnimationController);
    _positionAnimationController
      ..value = 0.0
      ..fling(velocity: 0.4);
  }

  @override
  void initState(){
    super.initState();
    _position = Offset.zero;
    _scale = null;
    _scaleAnimationController = new AnimationController(vsync: this)
      ..addListener(handleScaleAnimation);

    _positionAnimationController = new AnimationController(vsync: this)
      ..addListener(handlePositionAnimate);
  }

  @override
  void dispose(){
    _positionAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PhotoViewImageWrapper oldWidget){
    super.didUpdateWidget(oldWidget);
    if(
      oldWidget.scaleState != widget.scaleState && widget.scaleState != PhotoViewScaleState.zooming
    ){
      animateScale(
          _scale == null ? getScaleForScaleState(
            imageInfo: widget.imageInfo,
            scaleState: PhotoViewScaleState.contained,
            size: widget.size
          ).clamp(
            widget.scaleBoundaries.computeMinScale(),
            widget.scaleBoundaries.computeMaxScale()
          ) : _scale,
          getScaleForScaleState(
            imageInfo: widget.imageInfo,
            scaleState: widget.scaleState,
            size: widget.size
          ).clamp(
            widget.scaleBoundaries.computeMinScale(),
            widget.scaleBoundaries.computeMaxScale()
          )
      );
      animatePosition(_position, Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matrix = new Matrix4.identity()
      ..translate(_position.dx, _position.dy)
      ..scale(scaleStateAwareScale());

    return new GestureDetector(
      child: new Stack(
        children: <Widget>[
          new Container(
            child: new Center(
                child: new Transform(
                  child: new CustomSingleChildLayout(
                    delegate: new ImagePositionDelegate(
                        widget.imageInfo.image.width /1,
                        widget.imageInfo.image.height /1
                    ),
                    child: new Hero(
                        tag: widget.heroTag ?? "nohero",
                        child: new Stack(
                          children: <Widget>[
                            new Image(
                              image: widget.imageProvider,
                              gaplessPlayback: widget.gaplessPlayback,
                            ),
                            (widget.xTag != null && widget.yTag != null) ?  new Positioned(child: new Container(
                              height: 80.0,
                              width: 80.0,
                              decoration: new BoxDecoration(color: Colors.transparent,border: new Border.all(color: Colors.white,width: 5.0)),

                            ),
                              top: ((widget.imageInfo.image.height *( widget.yTag * .01)) - 40.0),
                              left: ((widget.imageInfo.image.width * (widget.xTag  * .01)) - 40.0),
//                              top: widget.imageInfo.image.height * (0.333) ,
//                              left:widget.imageInfo.image.width * (0.701 ),
                            ) : new Container(),
                          ],
                        )
                    ),
                  ),
                  transform: matrix,
                  alignment: Alignment.center,
                )
            ),
            decoration: new BoxDecoration(
                color: widget.backgroundColor
            ),
          ),



        ],
      ),
      onDoubleTap: widget.onDoubleTap,
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      onScaleEnd: onScaleEnd,
    );
  }
}


class ImagePositionDelegate extends SingleChildLayoutDelegate{
  final double imageWidth;
  final double imageHeight;
  const ImagePositionDelegate(this.imageWidth, this.imageHeight);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double offsetX = (size.width - imageWidth) / 2;
    final double offsetY = (size.height - imageHeight) / 2;
    return new Offset(offsetX, offsetY);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return new BoxConstraints(
      maxWidth: imageWidth,
      maxHeight: imageHeight,
      minHeight: imageHeight,
      minWidth: imageWidth,
    );
  }

  @override
  bool shouldRelayout(SingleChildLayoutDelegate oldDelegate) {
    return true;
  }
}