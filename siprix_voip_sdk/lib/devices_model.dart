import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'siprix_voip_sdk.dart';


class _DevicesList {
  _DevicesList(this._listName, [this._logs]);
  final List<MediaDevice> _dvcs = [];
  final ILogsModel? _logs;
  final String _listName;
  String _selGuid="";
  int _selIndex=-1;

  List<MediaDevice> get list => List.unmodifiable(_dvcs);
  int get selIndex   => _selIndex;

  void _load(Future<int?> Function() getDevicesNumber, Future<MediaDevice?> Function(int) getDevice) async {
    try {
      _dvcs.clear();
      bool selDevFound=false;
      int dvcsNumber = await getDevicesNumber() ?? 0;
      for(int index=0; index < dvcsNumber; ++index) {
        MediaDevice? dev = await getDevice(index);
        if(dev == null) continue;

        if(_dvcs.indexWhere((p) => p.guid==dev.guid) == -1) _dvcs.add(dev);
        if((_selGuid == dev.guid)||dev.isSelected) { _selIndex = index; _selGuid = dev.guid; selDevFound=true; }
      }

      if(!selDevFound) {
        _selIndex = -1;
        _selGuid = "";
      }
    } on PlatformException catch (err) {
      _logs?.print('Can\'t load ${_listName}Devices. Err: ${err.code} ${err.message}');
    }
  }

  Future<void> set(int? index, Future<void> Function(int) setDevice) async{
    if(index==null) return;
    _logs?.print('set ${_listName}Device - $index');

    try {
      await setDevice(index);
      _selGuid = ((index >= 0)&&(index < _dvcs.length)) ? _dvcs[index].guid : "";
      _selIndex = index;
    } on PlatformException catch (err) {
      _logs?.print('Can\'t set ${_listName}Device. Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }
}//_DevicesList


/// Devices model (contains list of avaialable audio/video devices and status of foreground mode)
class DevicesModel extends ChangeNotifier {
  final _DevicesList _playout;
  final _DevicesList _recording;
  final _DevicesList _video;

  bool _foregroundModeEnabled = false;

  final ILogsModel? _logs;
  bool _loaded = false;

  /// Create instance and set event handler
  DevicesModel([this._logs])
    : _playout = _DevicesList("playout", _logs),
      _recording = _DevicesList("recording", _logs),
      _video = _DevicesList("video", _logs) {
    SiprixVoipSdk().dvcListener = DevicesStateListener(
      devicesChanged : onAudioDevicesChanged
    );
  }

  /// List of audio speaker devices
  List<MediaDevice> get playout   => _playout.list;
  /// List of audio microphone devices
  List<MediaDevice> get recording => _recording.list;
  /// List of audio camera devices
  List<MediaDevice> get video     => _video.list;

  /// Index of selected speaker device
  int get playoutIndex   => _playout.selIndex;
  /// Index of selected microphone device
  int get recordingIndex => _recording.selIndex;
  /// Index of selected camera device
  int get videoIndex     => _video.selIndex;

  /// Returns true if android service works in foreground mode (Android only!)
  bool get foregroundModeEnabled => _foregroundModeEnabled;

  /// Load list of available devices
  void load() {
    if(_loaded) return;
    _loaded = true;

    _loadPlayoutDevices();
    _loadRecordingDevices();
    _loadVideoDevices();
    _loadForegroundMode();

    notifyListeners();
  }

  void _loadPlayoutDevices() async {
    _playout._load(SiprixVoipSdk().getPlayoutDevices, SiprixVoipSdk().getPlayoutDevice);
  }

  void _loadRecordingDevices() async {
    _recording._load(SiprixVoipSdk().getRecordingDevices, SiprixVoipSdk().getRecordingDevice);
  }

  void _loadVideoDevices() async {
    _video._load(SiprixVoipSdk().getVideoDevices, SiprixVoipSdk().getVideoDevice);
  }

  /// Handle event raised by library (notifies that list of audio devices has changed)
  void onAudioDevicesChanged() {
    _logs?.print('onAudioDevicesChanged');
    _loadPlayoutDevices();
    _loadRecordingDevices();

    notifyListeners();
  }

  /// Set current speaker device by its index
  Future<void> setPlayoutDevice(int? index) async{
    return _playout.set(index, SiprixVoipSdk().setPlayoutDevice);
  }

  /// Set current speaker as system's default device (Windows only)
  Future<void> setPlayoutDeviceSysDef() async{
    if(Platform.isWindows)
      return _playout.set(-1, SiprixVoipSdk().setPlayoutDevice);
  }

  /// Set current microphone device by its index
  Future<void> setRecordingDevice(int? index) async{
    return _recording.set(index, SiprixVoipSdk().setRecordingDevice);
  }

/// Set current microphone device as system's default device (Windows only)
  Future<void> setRecordingDeviceSysDef() async{
    if(Platform.isWindows)
      return _recording.set(-1, SiprixVoipSdk().setRecordingDevice);
  }

  /// Set current camera device by its index
  Future<void> setVideoDevice(int? index) async{
    return _video.set(index, SiprixVoipSdk().setVideoDevice);
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