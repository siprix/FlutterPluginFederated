import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'siprix_voip_sdk.dart';


/// Devices list model (contains list of avaialable audio/video devices)
class DevicesModel extends ChangeNotifier {
  final List<MediaDevice> _playout = [];
  final List<MediaDevice> _recording = [];
  final List<MediaDevice> _video = [];

  int _selPlayoutIndex=-1;
  int _selRecordingIndex=-1;
  int _selVideoIndex=-1;
  bool _foregroundModeEnabled = false;

  final ILogsModel? _logs;
  bool _loaded = false;

  /// Create instance and set event handler
  DevicesModel([this._logs]) {
    SiprixVoipSdk().dvcListener = DevicesStateListener(
      devicesChanged : onAudioDevicesChanged
    );
  }

  /// List of audio speaker devices
  List<MediaDevice> get playout   => List.unmodifiable(_playout);
  /// List of audio microphone devices
  List<MediaDevice> get recording => List.unmodifiable(_recording);
  /// List of audio camera devices
  List<MediaDevice> get video     => List.unmodifiable(_video);

  /// Index of selected speaker device
  int get playoutIndex   => _selPlayoutIndex;
  /// Index of selected microphone device
  int get recordingIndex => _selRecordingIndex;
  /// Index of selected camera device
  int get videoIndex     => _selVideoIndex;

  /// Returns true if android service works in foreground mode (Android only!)
  bool get foregroundModeEnabled => _foregroundModeEnabled;

  /// Load list of available devices
  void load() {
    if(_loaded) return;
    _loadPlayoutDevices();
    _loadRecordingDevices();
    _loadVideoDevices();
    _loadForegroundMode();
    _loaded = true;
  }

  void _loadPlayoutDevices() async {
    try {
      _playout.clear();
      int dvcsNumber = await SiprixVoipSdk().getPlayoutDevices() ?? 0;
      for(int index=0; index < dvcsNumber; ++index) {
        MediaDevice? dvc = await SiprixVoipSdk().getPlayoutDevice(index);
        if((dvc != null) && (_playout.indexWhere((p) => p.guid==dvc.guid) ==-1))   _playout.add(dvc);
      }
      _selPlayoutIndex = -1;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t load playoutDevices. Err: ${err.code} ${err.message}');
    }
  }

  void _loadRecordingDevices() async {
    try {
      _recording.clear();
      int dvcsNumber = await SiprixVoipSdk().getRecordingDevices() ?? 0;
      for(int index=0; index < dvcsNumber; ++index) {
        MediaDevice? dvc = await SiprixVoipSdk().getRecordingDevice(index);
        if((dvc != null) && (_recording.indexWhere((p) => p.guid==dvc.guid) ==-1))   _recording.add(dvc);
      }
      _selRecordingIndex = -1;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t load recordingDevices. Err: ${err.code} ${err.message}');
    }
  }

  void _loadVideoDevices() async {
    try {
      _video.clear();
      int dvcsNumber = await SiprixVoipSdk().getVideoDevices() ?? 0;
      for(int index=0; index < dvcsNumber; ++index) {
        MediaDevice? dvc = await SiprixVoipSdk().getVideoDevice(index);
        if((dvc != null) && (_video.indexWhere((p) => p.guid==dvc.guid) ==-1))   _video.add(dvc);
      }
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t load videoDevices. Err: ${err.code} ${err.message}');
    }
  }

  /// Handle event raised by library (notifies that list of audio devices has changed)
  void onAudioDevicesChanged() {
    _logs?.print('onAudioDevicesChanged');
    _loadPlayoutDevices();
    _loadRecordingDevices();
  }

  /// Set current speaker device by its index
  Future<void> setPlayoutDevice(int? index) async{
    if(index==null) return;
    _logs?.print('set playoutDevice - $index');

    try {
      await SiprixVoipSdk().setPlayoutDevice(index);
      _selPlayoutIndex = index;
    } on PlatformException catch (err) {
      _logs?.print('Can\'t set playoutDevice. Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Set current microphone device by its index
  Future<void> setRecordingDevice(int? index) async{
    if(index==null) return;
    _logs?.print('set recordingDevice - $index');

    try {
      await SiprixVoipSdk().setRecordingDevice(index);
      _selRecordingIndex = index;
    } on PlatformException catch (err) {
      _logs?.print('Can\'t set recordingDevice. Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Set current camera device by its index
  Future<void> setVideoDevice(int? index) async{
    if(index==null) return;
    _logs?.print('set videoDevice - $index');

    try {
      await SiprixVoipSdk().setVideoDevice(index);
      _selVideoIndex = index;
    } on PlatformException catch (err) {
      _logs?.print('Can\'t set videoDevice. Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Set foreground mode of the CallNotifService service (Android only)
  Future<void> setForegroundMode(bool enabled) async{
    if(Platform.isAndroid) {
      if(_foregroundModeEnabled==enabled) return;
      _logs?.print('set foreground mode - $enabled');

      try {
        await SiprixVoipSdk().setForegroundMode(enabled);

        _foregroundModeEnabled = enabled;

        notifyListeners();

      } on PlatformException catch (err) {
        _logs?.print('Can\'t setForegroundMode. Err: ${err.code} ${err.message}');
        return Future.error((err.message==null) ? err.code : err.message!);
      }
    }
  }

  /// Retrives mode of the CallNotifService service (Android only)
  void _loadForegroundMode() async {
    if(Platform.isAndroid) {
      try {
        bool? mode = await SiprixVoipSdk().isForegroundMode();
        if(mode != null) {
          _foregroundModeEnabled = mode;
          notifyListeners();
        }
      } on PlatformException catch (err) {
        _logs?.print('Can\'t load foreground mode. Err: ${err.code} ${err.message}');
      }
    }
  }

}//DevicesModel



/// VuMeterModel
class VuMeterModel extends ChangeNotifier {
  int _micLevel = 0;
  int _spkLevel = 0;

  int get micLevel => _micLevel;
  int get spkLevel => _spkLevel;

  /// Constructor (set event handler)
  VuMeterModel() {
    SiprixVoipSdk().vuMeterListener = VuMeterListener(vu : onVuMeterLevel);
  }

  /// Handle event, update UI
  void onVuMeterLevel(int micLevel, int spkLevel) {
    _micLevel = micLevel;
    _spkLevel = spkLevel;
    notifyListeners();
  }
}