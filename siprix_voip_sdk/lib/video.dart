import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'siprix_voip_sdk.dart';


/// Contains video frame attributes provided by native plugins
class RTCVideoValue {
  const RTCVideoValue({
    this.width = 0.0,
    this.height = 0.0,
    this.rotation = 0,
  });

  ///Width of the video frame (pixels)
  final double width;
  ///Height of the video frame (pixels)
  final double height;
  ///Rotation of the video frame (degrees: 0/90/180/270)
  final int rotation;

  static const RTCVideoValue empty = RTCVideoValue();

  double get aspectRatio {
    if (width == 0.0 || height == 0.0) {
      return 1.0;
    }
    return (rotation == 90 || rotation == 270)
        ? height / width
        : width / height;
  }

  RTCVideoValue copyWith({
    double? width, double? height, int? rotation
  }) {
    return RTCVideoValue(
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
    );
  }

  @override
  String toString() =>
      '$runtimeType(width: $width, height: $height, rotation: $rotation)';
}


/// SiprixVideoRenderer - holds texture, created by native plugins, and listening video frame events raised by native plugins
class SiprixVideoRenderer extends ValueNotifier<RTCVideoValue> {
  SiprixVideoRenderer() : super(RTCVideoValue.empty);
  StreamSubscription<dynamic>? _eventSubscription;
  /// Invalid texture id constant
  static const int kInvalidTextureId = -1;
  /// Invalid call id constant
  static const int kInvalidCallId = -1;
  int _textureId = kInvalidTextureId;
  int _srcCallId = kInvalidCallId;
  late final ILogsModel? _logs;

  /// Width of the received video frame
  int get videoWidth => value.width.toInt();
  /// Height of the received video frame
  int get videoHeight => value.height.toInt();
  /// AspectRatio of the received video frame
  double get aspectRatio => value.aspectRatio;

  /// TextureId created for rendering
  int  get textureId => _textureId;
  /// Is created texture
  bool get hasTexture=> _textureId != kInvalidTextureId;
  /// Call id which displays video on this texture
  int  get srcCallId => _srcCallId;

  /// Frame resize handler
  Function(RTCVideoValue v, int callId)? onResize;

  /// Create texture id rendering video of the specifed call
  Future<void> init(int srcCallId, [ILogsModel? logs]) async {
    if (_textureId != kInvalidTextureId) return;
    _srcCallId = srcCallId;
    _logs = logs;

    try{
      _textureId = await SiprixVoipSdk().videoRendererCreate() ?? 0;
    } on PlatformException catch (err) {
      _logs?.print('Cant create renderer Err: ${err.code} ${err.message}');
    }

    if(_textureId != kInvalidTextureId) {
      _logs?.print('Created textureId: $textureId for callId:$_srcCallId');
      _eventSubscription = EventChannel('Siprix/Texture$textureId')
        .receiveBroadcastStream()
        .listen(eventListener, onError: errorListener);

        setSourceCall(srcCallId);
    }
  }

  /// Use created texture for rendering video of specified call
  void setSourceCall(int callId) async {
    if(callId==kInvalidCallId) return;
    _srcCallId = callId;

    try{
      await SiprixVoipSdk().videoRendererSetSourceCall(_textureId, callId);
      _logs?.print('Assign textureId: $textureId with callId:$_srcCallId');
    } on PlatformException catch (err) {
      _logs?.print('Cant set src call for renderer Err: ${err.code} ${err.message}');
    }
  }

  @override
  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    if (_textureId != kInvalidTextureId) {
      await SiprixVoipSdk().videoRendererDispose(_textureId);
      _logs?.print('Disposed texture: $_textureId');
      _textureId = 0;
    }
    return super.dispose();
  }

  /// Handle video frame changes
  void eventListener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    switch (map['event']) {
      case 'didTextureChangeRotation':
        value = value.copyWith(rotation: map['rotation']);
        break;
      case 'didTextureChangeVideoSize':
        value = value.copyWith(
            width: 0.0 + map['width'],
            height: 0.0 + map['height']);
        break;
    }
    onResize?.call(value, _srcCallId);
  }

  /// Handle video frame errors
  void errorListener(Object obj) {
    if (obj is Exception) {
      throw obj;
    }
  }

}//SiprixVideoRenderer


/// SiprixVideoView - widget which displays specified renderer
class SiprixVideoView extends StatelessWidget {
  /// Constructor
  const SiprixVideoView(this._renderer, {Key? key,}) : super(key: key);

  final SiprixVideoRenderer _renderer;

  /// Set texture quality
  final FilterQuality filterQuality = FilterQuality.low;

  @override
  Widget build(BuildContext context) {
    return _renderer.hasTexture
                    ? AspectRatio(aspectRatio: _renderer.aspectRatio,
                        child: Texture(textureId: _renderer.textureId, filterQuality: filterQuality))
                    : const Placeholder();
  }

  //Widget buildWithText(BuildContext context) {
  //  if(!_renderer.hasTexture) return const Placeholder();
  //  else return Stack(children: [
  //    AspectRatio(aspectRatio: _renderer.aspectRatio, child:
  //      Texture(textureId: _renderer.textureId, filterQuality: filterQuality)
  //    ),
  //    Text("w:${_renderer.videoWidth} h:${_renderer.videoHeight}")//Display resolution on UI
  //  ]);
  //}
}
