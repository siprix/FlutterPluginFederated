// ignore_for_file: non_constant_identifier_names

import 'dart:collection';

import 'package:siprix_voip_sdk_platform_interface/siprix_voip_sdk_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'siprix_voip_sdk.dart';
import 'cdrs_model.dart';

/// Call destination -  contains lists of parameters for making outgoing call
class CallDestination implements ISiprixData {
  CallDestination(this.toExt, this.fromAccId, this.withVideo, [this.displName]);
  /// Extension (phone number) to dial
  final String toExt;
  /// Id of the account which should send INVITE request
  final int  fromAccId;
  /// Set to true when it should be video call
  final bool withVideo;
  /// How long wait reponse from remote server (value in seconds, by default 40)
  int?   inviteTimeout;
  /// List of custom headers/values which should be added to INVITE request
  Map<String, String>? xheaders={};
  /// Set display name in the SIP header From (overrides value set in the account specified by 'fromAccId')
  String? displName;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {
      'extension': toExt,
      'accId'    : fromAccId,
      'withVideo': withVideo
    };
    if(xheaders !=null)      ret['xheaders']      = xheaders;
    if(inviteTimeout !=null) ret['inviteTimeout'] = inviteTimeout;
    if(displName !=null)     ret['displName'] = displName;

    return ret;
  }
}


/// Call state
enum CallState{
  /// Outgoing call just initiated
  dialing(0, "Dialing"),
  /// Outgoing call in progress, received 100Trying or 180Ringing
  proceeding(1, "Proceeding"),
  /// Incoming call just received
  ringing(2, "Ringing"),
  /// Incoming call rejecting after invoke 'call.reject'
  rejecting(3, "Rejecting"),
  /// Incoming call accepting after invoke 'call.accept'
  accepting(4, "Accepting"),
  /// Call successfully established, RTP is flowing
  connected(5, "Connected"),
  /// Call disconnecting after invoke 'call.bye'
  disconnecting(6, "Disconnecting"),
  /// Call holding (renegotiating RTP stream states)
  holding(7, "Holding"),

  /// Call held, RTP is NOT flowing
  held(8, "Held"),
  /// Call transferring
  transferring(9, "Transferring");

  const CallState(this.id, this.name);
  /// Call state id
  final int id;
  /// Call state name
  final String name;

  /// Returns state which matches specified int value
  static CallState from(int val) {
    return CallState.values.where((e) => e.id == val).first;
  }
}


/// Hold state
enum HoldState {
  /// No hold, media flows in both directions
  none(SiprixVoipSdk.kHoldStateNone, "None"),
  /// Call put on hold by local side
  local(SiprixVoipSdk.kHoldStateLocal, "Local"),
  /// Call put on hold by remote side
  remote(SiprixVoipSdk.kHoldStateRemote, "Remote"),
  /// Call put on hold by local and remote side
  localAndRemote(SiprixVoipSdk.kHoldStateLocalAndRemote, "LocalAndRemote");

  const HoldState(this.id, this.name);
  /// Hold state id (one of the [SiprixVoipSdk.kHoldState*])
  final int id;
  /// Hold state name
  final String name;

  /// Returns hold state which matches specified int value
  static HoldState from(int val) {
    switch(val) {
      case SiprixVoipSdk.kHoldStateLocal: return HoldState.local;
      case SiprixVoipSdk.kHoldStateRemote: return HoldState.remote;
      case SiprixVoipSdk.kHoldStateLocalAndRemote: return HoldState.localAndRemote;
      default: return HoldState.none;
    }
  }
}



/// File player State
enum PlayerState {
  /// Player started
  started(SiprixVoipSdk.kPlayerStateStarted, "Started"),
  /// Player stopped
  stoppped(SiprixVoipSdk.kPlayerStateStopped,"Stopped"),
  /// Player failed
  failed(SiprixVoipSdk.kPlayerStateFailed,   "Failed");

  const PlayerState(this.id, this.name);
  /// Plater state id (one of the [SiprixVoipSdk.kPlayerState*])
  final int id;
  /// Plater state name
  final String name;

  /// Returns player state which matches specified int value
  static PlayerState from(int val) {
    switch (val) {
      case SiprixVoipSdk.kPlayerStateStarted: return PlayerState.started;
      case SiprixVoipSdk.kPlayerStateStopped: return PlayerState.stoppped;
      default:  return PlayerState.failed;
    }
  }
}


/// Call model (contains call attributes, methods for managing them, handles library events)
class CallModel extends ChangeNotifier implements ISiprixData {
  CallModel(this.myCallId, this.accUri, this.remoteExt, this.isIncoming, this.hasSecureMedia, this._hasVideo, [this._logs]) {
    _state = isIncoming ? CallState.ringing : CallState.dialing;
  }

  /// Unique call id assigned by library
  final int myCallId;
  /// Account URI used to accept/make this call
  final String accUri;

  /// Phone number(extension) of remote side of this call
  final String remoteExt;

  /// Contact name (resolved by app)
  String displName="";

  String _receivedDtmf="";
  String _response="";
  CallState _state = CallState.dialing;
  HoldState _holdState = HoldState.none;
  DateTime _startTime = DateTime.now();
  Duration _duration = const Duration(seconds: 0);
  bool _hasVideo;
  int _playerId=0;
  /// Is call incoming
  final bool isIncoming;
  /// Has call encrypted audio/video
  final bool hasSecureMedia;
  bool _isMicMuted=false;
  bool _isCamMuted=false;
  bool _isRecStarted=false;
  bool _isUpgradingToVideo=false;
  bool _hasVideoUpgradeRequest=false;
  final ILogsModel? _logs;

  /// State of this call
  CallState get state => _state;

  /// Hold state of this call
  HoldState get holdState => _holdState;

  /// Name and extenstion of the remote side of this call
  String get nameAndExt => displName.isEmpty ? remoteExt : "$displName ($remoteExt)";

  /// Duration of this call as string representation
  String get durationStr => formatDuration(_duration);
  /// Duration of this call
  Duration get duration => _duration;

  /// Timestamp when call has been connected (accepted by local or remeote side)
  DateTime get startTime => _startTime;

  /// List of received DTMFs
  String get receivedDtmf => _receivedDtmf;
  /// Status line of the 1xx SIP response received from remote side when app makes outgoing call
  String get response => _response;

  bool get isMicMuted => _isMicMuted;
  bool get isCamMuted => _isCamMuted;
  bool get isRecStarted => _isRecStarted;
  bool get isFilePlaying => _playerId!=0;
  bool get hasVideo   => _hasVideo;
  int  get playerId   => _playerId;


  /// Returns true if app has invoked 'upgradeToVideo' (requested upgrade to video) and is waiting on response
  bool get isUpgradingToVideo => _isUpgradingToVideo;
  /// Returns true if app received request 'upgrade to video' from remote side (happens only if acc.upgradeToVideo=UpgradeToVideoMode.Manual)
  bool get hasVideoUpgradeRequest => _hasVideoUpgradeRequest;

  /// Returns true if call put on hold by local side
  bool get isLocalHold => (_holdState==HoldState.local)||(_holdState==HoldState.localAndRemote);
  /// Returns true if call put on hold by remote side
  bool get isRemoteHold => (_holdState==HoldState.remote)||(_holdState==HoldState.localAndRemote);

  /// Returns true if call state is `connected`
  bool get isConnected => (_state==CallState.connected);

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {
      'myCallId' : myCallId,
      'accUri': accUri,
      'remoteExt' : remoteExt,
      'displName' : displName,
      'receivedDtmf' : receivedDtmf,
      'response' : response,
      'state' : state.id,
      'holdState' : holdState.id,
      'startTime' : startTime.millisecondsSinceEpoch,
      'hasVideo' : hasVideo,
      'playerId' : playerId,
      'isIncoming' : isIncoming,
      'hasSecureMedia' : hasSecureMedia,
      'isMicMuted' : isMicMuted,
      'isCamMuted' : isCamMuted,
      'isRecStarted' : isRecStarted,
      'isUpgradingToVideo' : isUpgradingToVideo,
      'hasVideoUpgradeRequest' : hasVideoUpgradeRequest
    };
    return ret;
  }

  /// Creates instance of CallModel with values read from json
  static CallModel? fromJson(Map<dynamic, dynamic> jsonMap, ILogsModel? logs) {
    //Read required attributes
    int? _myCallId; String? _accUri, _remoteExt;
    bool? _isIncoming, _hasSecureMedia, _hasVideo;
    jsonMap.forEach((key, value) {
      if((key == 'myCallId')&&(value is int))        { _myCallId = value;    } else
      if((key == 'accUri')&&(value is String))       { _accUri = value; } else
      if((key == 'remoteExt')&&(value is String))    { _remoteExt = value; } else
      if((key == 'isIncoming')&&(value is bool))     { _isIncoming = value;} else
      if((key == 'hasSecureMedia')&&(value is bool)) { _hasSecureMedia = value;} else
      if((key == 'hasVideo')&&(value is bool))       { _hasVideo = value;}
    });
    //Check if present
    if((_myCallId==null)||(_accUri==null)||(_remoteExt==null)||
       (_isIncoming==null)||(_hasSecureMedia==null)||(_hasVideo==null)) return null;

    //Create new inst
    CallModel call = CallModel(_myCallId!, _accUri!, _remoteExt!, _isIncoming!, _hasSecureMedia!, _hasVideo!, logs);

    //Read the rest values
    jsonMap.forEach((key, value) {
      if((key == 'displName')&&(value is String))    { call.displName = value;     } else
      if((key == 'receivedDtmf')&&(value is String)) { call._receivedDtmf = value; } else
      if((key == 'response')&&(value is String))     { call._response = value;     } else
      if((key == 'state')&&(value is int))           { call._state = CallState.from(value);} else
      if((key == 'holdState')&&(value is int))       { call._holdState = HoldState.from(value);} else
      if((key == 'startTime')&&(value is int))       { call._startTime = DateTime.fromMillisecondsSinceEpoch(value); }
      if((key == 'playerId')&&(value is int))        { call._playerId = value;    } else
      if((key == 'isMicMuted')&&(value is bool))     { call._isMicMuted = value;  } else
      if((key == 'isCamMuted')&&(value is bool))     { call._isCamMuted = value;  } else
      if((key == 'isRecStarted')&&(value is bool))   { call._isRecStarted = value;} else
      if((key == 'isUpgradingToVideo')&&(value is bool)) { call._isUpgradingToVideo = value;} else
      if((key == 'hasVideoUpgradeRequest')&&(value is bool)) { call._hasVideoUpgradeRequest = value;}
    });
    //Update duration
    call.calcDuration();
    return call;
  }

  /// Format call duration as 'hh:mm:ss' or 'mm:ss'
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    int hours = duration.inHours;
    if(hours != 0) {
      return "${twoDigits(hours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  /// Calculate duration of this call (invoke by 1sec timer)
  void calcDuration() {
    if(_state != CallState.connected) return;

    _duration = DateTime.now().difference(_startTime);
    notifyListeners();
  }

  /// Update display name
  void updateDisplName(String newDisplName) {
    displName = newDisplName;
    notifyListeners();
  }

  ///End this call (send BYE request)
  Future<void> bye() async{
    _logs?.print('Ending callId:$myCallId');
    try{
      await SiprixVoipSdk().bye(myCallId);
      _state = CallState.disconnecting;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Cant end callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Accept (answer) this call
  Future<void> accept([bool withVideo=true]) async{
    _logs?.print('Accepting callId:$myCallId withVideo:$withVideo');
    try{
      await SiprixVoipSdk().accept(myCallId, withVideo);
      _state = CallState.accepting;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t accept callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Reject this call
  Future<void> reject() async{
    _logs?.print('Rejecting callId:$myCallId');
    try {
      await SiprixVoipSdk().reject(myCallId, 486);//Send '486 Busy now'
      _state = CallState.rejecting;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t reject callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Mute microphone for this call
  Future<void> muteMic(bool mute) async{
    _logs?.print('Muting $mute mic of call $myCallId');

    try {
      await SiprixVoipSdk().muteMic(myCallId, mute);
      _isMicMuted = mute;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t mute call. Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Mute camera for this call
  Future<void> muteCam(bool mute) async{
    _logs?.print('Muting $mute camera of call $myCallId');

    try {
      await SiprixVoipSdk().muteCam(myCallId, mute);
      _isCamMuted = mute;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t mute camera of call. Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Send DTMF (single tone or sequence of tones) to remote side of this call
  Future<void> sendDtmf(String tones, [int durationMs=200, int intertoneGapMs=50, int method = SiprixVoipSdk.kDtmfMethodRtp]) async {
    _logs?.print('Sending dtmf callId:$myCallId tone:$tones');
    try{
      await SiprixVoipSdk().sendDtmf(myCallId, tones, durationMs, intertoneGapMs, method);
    } on PlatformException catch (err) {
      _logs?.print('Can\'t send dtmf callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Play file to remote side of this call
  Future<void> playFile(String pathToMp3File, {bool loop=false}) async {
    _logs?.print('Starting play file callId:$myCallId $pathToMp3File loop:$loop');
    try {
      _playerId = await SiprixVoipSdk().playFile(myCallId, pathToMp3File, loop) ?? 0;
    } on PlatformException catch (err) {
      _logs?.print('Can\'t start playing file callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Stop playing file
  Future<void> stopPlayFile() async {
    if(_playerId==0) return;
    _logs?.print('Stop play file callId:$myCallId playerId:$_playerId');
    try {
      await SiprixVoipSdk().stopPlayFile(_playerId);
    } on PlatformException catch (err) {
      _logs?.print('Can\'t stop playing file playerId:$_playerId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Record received sound to file (current implementation records to wav file)
  Future<void> recordFile(String pathToMp3File) async {
    _logs?.print('Starting record file callId:$myCallId $pathToMp3File');
    try {
      await SiprixVoipSdk().recordFile(myCallId, pathToMp3File);
      _isRecStarted = true;
    } on PlatformException catch (err) {
      _logs?.print('Can\'t start recording file callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Stop recording
  Future<void> stopRecordFile() async {
    if(!_isRecStarted) return;
    _logs?.print('Stop record file callId:$myCallId');
    try {
      await SiprixVoipSdk().stopRecordFile(myCallId);
      _isRecStarted = false;
    } on PlatformException catch (err) {
      _logs?.print('Can\'t stop recording file callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Toggle hold of this call (hold means stop send/receive audio/video RTP streams)
  Future<void> hold() async {
    _logs?.print('Hold callId:$myCallId');
    try{
      await SiprixVoipSdk().hold(myCallId);
      _state = CallState.holding;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t hold callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Transfer this call to specified extension
  Future<void> transferBlind(String toExt) async {
    _logs?.print('Transfer blind callId:$myCallId to:"$toExt"');
    if(toExt.isEmpty) return;
    try{
      await SiprixVoipSdk().transferBlind(myCallId, toExt);

      _state = CallState.transferring;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t transfer callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Transfer this call to specified call
  Future<void> transferAttended(int toCallId) async {
    _logs?.print('Transfer attended callId:$myCallId to callId $toCallId');

    try{
      await SiprixVoipSdk().transferAttended(myCallId, toCallId);

      _state = CallState.transferring;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t transfer callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Send to remote side request 'Upgrade call from audio only to audio+video'
  Future<void> upgradeToVideo()async {
    _logs?.print('Upgrade callId:$myCallId to audio+video');

    try{
      await SiprixVoipSdk().upgradeToVideo(myCallId);
      _isUpgradingToVideo = true;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t upgrade callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Get value of the SIP header from last received response (when input param empty returns whole SIP response)
  Future<String?> getSipHeader(String headerName) async {
    try{
      String? hdrVal = await SiprixVoipSdk().getSipHeader(myCallId, headerName);
      _logs?.print('GetSipHeader of callId:$myCallId "$headerName" = "$hdrVal"');
      return hdrVal;
    } on PlatformException catch (err) {
      _logs?.print('Can\'t get getSipHeader callId:$myCallId Err: ${err.code} ${err.message}');
      return "";
    }
  }

  /// Get statistics of this call
  Future<String?> getStats() async {
    try{
      String? statsVal = await SiprixVoipSdk().getStats(myCallId);
      return statsVal;
    } on PlatformException catch (err) {
      _logs?.print('Can\'t getStats callId:$myCallId Err: ${err.code} ${err.message}');
      return "";
    }
  }

  /// Accept request 'upgrade to video' received from remote side. 'withVideo=false' - means [don't allow to start video]
  Future<void> acceptVideoUpgrade([bool withVideo=true]) async{
    _logs?.print('AcceptVideoUpgrade callId:$myCallId withVideo:$withVideo');
    try{
      await SiprixVoipSdk().acceptVideoUpgrade(myCallId, withVideo);
      _hasVideoUpgradeRequest = false;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t accept video upgrade callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Event handlers-------------

  /// Handles 1xx responses received from remote side
  void onProceeding(String resp) {
    _state = CallState.proceeding;
    _response = resp;
    notifyListeners();
  }

  /// Handles 2xx responses
  void onConnected(String hdrFrom, String hdrTo, bool withVideo) {
    _state = CallState.connected;
    _startTime = DateTime.now();
    _hasVideo = withVideo;
    _duration = const Duration(seconds: 0);
    notifyListeners();
  }

  /// Handle response of the upgrade to video request
  void onVideoUpgraded(bool withVideo, bool isUpgradeModeRecvOnly) {
    //Siprix mutes camera when upgrade video request received from remote side AND mode set as recvOnly
    if(withVideo && isUpgradeModeRecvOnly && !_isUpgradingToVideo) _isCamMuted = true;

    _hasVideo = withVideo;
    _isUpgradingToVideo = false;
    notifyListeners();
  }

  /// Handle request 'upgrade to video' received from remote side
  /// [!] In the event handler app HAS invoke 'acceptVideoUpgrade(true/false)'
  void onVideoUpgradeRequested() {
    _hasVideoUpgradeRequest = true;
    notifyListeners();
  }

  /// Handle received DTMF tone
  void onDtmfReceived(int tone) {
    if(tone == 10) { _receivedDtmf += '*'; }else
    if(tone == 11) { _receivedDtmf += '#'; }
    else           { _receivedDtmf += tone.toString(); }
    notifyListeners();
  }

  /// Handle response of the 'transfer' request
  void onTransferred(int statusCode) {
    _state = CallState.connected;
    notifyListeners();
  }

  /// Handle hold state changes
  void onHeld(HoldState holdState) {
    _holdState = holdState;
    _state = (holdState==HoldState.none) ?  CallState.connected : CallState.held;
    notifyListeners();
  }

  /// Handle mute state changes (iOS/CallKit only)
  void onMuted(bool mute) {
    _isMicMuted = mute;
    notifyListeners();
  }

  /// Handle player state changes
  bool onPlayerStateChanged(int playerId, PlayerState state) {
    if(_playerId != playerId) return false;//player doesn't belong to this call
    if(state != PlayerState.started) {
      _playerId = 0;//player finished or failed
      notifyListeners();
    }
    return true;
  }

}//CallModel



/// Callback function which is raised by model when it need to resolve contact name of the new callreceived
typedef ResolveContactNameCallback = String Function(String phoneNumber);
/// Callback function which is raised by model when call switched
typedef CallSwitchedCallCallback = void Function(int callId);
/// Callback function which is raised by model when upgrade to video requeste received
typedef CallVideoUpgradeRequestedCallback = void Function(int callId);
/// Callback function which is raised by model when new incoming call received
typedef NewIncomingCallCallback = void Function();

//--------------------------------------------------------------------------

/// Calls list model (contains list of calls, methods for managing them, handlers of library events)
class CallsModel extends ChangeNotifier with IterableMixin<CallModel> implements ISiprixData {
  final List<CallModel> _callItems = [];
  final IAccountsModel _accountsModel;
  final CdrsModel? _cdrs;
  final ILogsModel? _logs;

  static const int kEmptyCallId=0;
  int _switchedCallId = kEmptyCallId;
  bool _confModeStarted = false;

  /// Constructor (set event handler)
  CallsModel(this._accountsModel, [this._logs, this._cdrs]) {
    SiprixVoipSdk().callListener = CallStateListener(
      syncState : onSyncCallsState,
      playerStateChanged: onPlayerStateChanged,
      proceeding : onProceeding,
      incoming : onIncomingSip,
      incomingPush : onIncomingPush,
      acceptNotif: onAcceptNotif,
      connected : onConnected,
      terminated : onTerminated,
      transferred : onTransferred,
      redirected : onRedirected,
      videoUpgraded : onVideoUpgraded,
      videoUpgradeRequested : onVideoUpgradeRequested,
      dtmfReceived : onDtmfReceived,
      switched : onSwitched,
      muted : onMuted,
      held : onHeld
    );
  }

  /// Callback function which is raised by model when it need to resolve contact name of the new call
  ResolveContactNameCallback? onResolveContactName;
  /// Callback function which is raised by model when call switched
  CallSwitchedCallCallback? onSwitchedCall;
  /// Callback function which is raised by model when new incoming call received
  NewIncomingCallCallback? onNewIncomingCall;
  /// Callback function which is raised by model when video upgrade request received
  CallVideoUpgradeRequestedCallback? onVideoUpgradeRequestReceived;

  /// Returns call by its index in list
  CallModel operator [](int i) => _callItems[i]; // get

  @override
  Iterator<CallModel> get iterator => _callItems.iterator;

  @protected List<CallModel> get callItems => _callItems;
  @protected IAccountsModel  get accountsModel => _accountsModel;

  /// Returns id of the switched call (or kEmptyCallId when there are no calls)
  int get switchedCallId => _switchedCallId;
  /// Returns switched call instance (or null when there are no calls)
  CallModel? switchedCall() {
    return _findCall(_switchedCallId);
  }

  CallModel? _findCall(int callId) {
    int index = _callItems.indexWhere((c) => c.myCallId==callId);
    return (index == -1) ? null : _callItems[index];
  }

  /// Returns true if conference mode started
  bool get confModeStarted => _confModeStarted;
  /// Returns true if present at least 2 calls in connected/held state
  bool hasConnectedFewCalls() {
    int counter = 0;
    for(CallModel m in _callItems) {
      counter += (m.state == CallState.connected)||(m.state==CallState.held) ? 1 : 0;
    }
    return counter > 1;
  }

  /// Calculate duration of connected calls in list (invoke it by 1sec timer)
  void calcDuration() {
    for(var c in _callItems) {
      c.calcDuration();
    }
  }

  /// Initiate new outgoing call via sending INVITE request (creates new call instance, adds it to list, notifies UI)
  Future<void> invite(CallDestination dest) async {
    _logs?.print('Trying to invite ${dest.toExt} from account:${dest.fromAccId}');
    try {
      int callId = await SiprixVoipSdk().invite(dest) ?? 0;

      String accUri       = _accountsModel.getUri(dest.fromAccId);
      bool hasSecureMedia = _accountsModel.hasSecureMedia(dest.fromAccId);

      CallModel newCall = CallModel(callId, accUri, dest.toExt, false, hasSecureMedia, dest.withVideo, _logs);
      newCall.displName = dest.displName ?? "";
      _callItems.add(newCall);
      _cdrs?.add(newCall);
      _postResolveContactName(newCall);
      _logs?.print('Added new call $callId');

      if(_switchedCallId == kEmptyCallId) {
         _switchedCallId = callId;
      }

      notifyListeners();

    } on PlatformException catch (err) {
      _logs?.print('Can\'t invite Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Switch to call with specified id (configure mixer to send sound from mic to this call and play received sound of this call to speaker)
  Future<void> switchToCall(int callId) async{
    _logs?.print('Switching mixer to call $callId');

    try {
      await SiprixVoipSdk().switchToCall(callId);
      _confModeStarted = false;
      //Value '_switchedCallId' will set in the callback 'onSwitched'

    } on PlatformException catch (err) {
      _logs?.print('Can\'t switch to call. Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Join all calls to conference (configures mixer to send sound from mic to all calls and play received sound from all calls to speaker)
  Future<void> makeConference() async{
    try {
      if(_confModeStarted){
        _logs?.print('Ending conference, switch mixer to call $_switchedCallId');
        await SiprixVoipSdk().switchToCall(_switchedCallId);
        _confModeStarted = false;
      }
      else {
        _logs?.print('Joining all calls to conference');
        await SiprixVoipSdk().makeConference();
        _confModeStarted = true;
      }

    } on PlatformException catch (err) {
      _logs?.print('Can\'t make conference. Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  //Events handlers

  /// Handle 1xx response event raised by library and route it to matched call instance
  void onProceeding(int callId, String response) {
    _logs?.print('onProceeding callId:$callId response:$response');
    _findCall(callId)?.onProceeding(response);
  }



  /// Handle pushkit notification received by library (parse payload, update CallKit window, wait on SIP call)
  void onIncomingPush(String callkit_CallUUID, Map<String, dynamic> pushPayload) {
    _logs?.print('onIncomingPush callkit_CallUUID:$callkit_CallUUID $pushPayload');
  }

  ///Handle incoming call event raised by library when received INVITE request
  void onIncomingSip(int callId, int accId, bool withVideo, String hdrFrom, String hdrTo) {
    _logs?.print('onIncoming callId:$callId accId:$accId from:$hdrFrom to:$hdrTo withVideo:$withVideo');

    if(_findCall(callId) != null) return;//Call already exists, skip

    String accUri = _accountsModel.getUri(accId);
    bool hasSecureMedia = _accountsModel.hasSecureMedia(accId);

    CallModel newCall = CallModel(callId, accUri, parseExt(hdrFrom), true, hasSecureMedia, withVideo, _logs);
    newCall.displName = parseDisplayName(hdrFrom);
    _callItems.add(newCall);

    if(_switchedCallId == kEmptyCallId) {
       _switchedCallId = callId;
    }

    notifyListeners();

    _cdrs?.add(newCall);

    _postResolveContactName(newCall);
    onNewIncomingCall?.call();
  }

  /// Handle case when call answered by tapping notification button (Android only)
  void onAcceptNotif(int callId, bool withVideo) {
    _findCall(callId)?.accept(withVideo);
  }

  /// Handles 2xx responses raised by library and route it to matched call instance
  void onConnected(int callId, String from, String to, bool withVideo) {
    _logs?.print('onConnected callId:$callId from:$from to:$to withVideo:$withVideo');
    _cdrs?.setConnected(callId, from, to, withVideo);

    _findCall(callId)?.onConnected(from, to, withVideo);
    notifyListeners();
  }

  /// Handle teminated call event raised by library (removes call instance from list and notifies UI)
  void onTerminated(int callId, int statusCode) async {
    _logs?.print('onTerminated callId:$callId statusCode:$statusCode');

    CallModel? call = _findCall(callId);
    if(call != null) {
      String reason = await SiprixVoipSdk().getSipHeader(callId, "Reason") ?? "-";
      _cdrs?.setTerminated(callId, statusCode, reason, call.displName, call.durationStr);

      _callItems.remove(call);
      _logs?.print('Removed call: $callId');

      if(_confModeStarted && !hasConnectedFewCalls()) {
        _confModeStarted = false;
      }

      notifyListeners();
    }
  }

  /// Handle transfer response event raised by library and route it to matched call instance
  void onTransferred(int callId, int statusCode) {
    _logs?.print('onTransferred callId:$callId statusCode:$statusCode');

    _findCall(callId)?.onTransferred(statusCode);
  }

  /// Handle redirect response event raised by library and route it to matched call instance
  void onRedirected(int origCallId, int relatedCallId, String referTo) {
    _logs?.print('onRedirected origCallId:$origCallId relatedCallId:$relatedCallId to:$referTo');

    //Find 'origCallId'
    CallModel? origCall = _findCall(origCallId);
    if(origCall == null) return;

    //Clone 'origCallId' and add to collection of calls as related one
    CallModel relatedCall = CallModel(relatedCallId, origCall.accUri, parseExt(referTo), false, origCall.hasSecureMedia, origCall.hasVideo, _logs);
    _callItems.add(relatedCall);
    notifyListeners();
  }

  ///Handle case when remote side requested to start send/receive video and request accepted.
  void onVideoUpgraded(int callId, bool withVideo) {
    _logs?.print('onVideoUpgraded callId:$callId withVideo:$withVideo');

    CallModel? call = _findCall(callId);
    if(call == null) return;

    bool isUpgradeModeRecvOnly = _accountsModel.isUpgradeToVideoModeRecvOnly(call.accUri);
    call.onVideoUpgraded(withVideo, isUpgradeModeRecvOnly);
  }

  /// Handle request 'upgrade to video' received from remote side
  void onVideoUpgradeRequested(int callId) {
    _logs?.print('onVideoUpgradeRequested callId:$callId');

    _findCall(callId)?.onVideoUpgradeRequested();
    onVideoUpgradeRequestReceived?.call(callId);
  }

  /// Handle receive DTMF event raised by library and route it to matched call instance
  void onDtmfReceived(int callId, int tone) {
    _logs?.print('onDtmfReceived callId:$callId tone:$tone');

    _findCall(callId)?.onDtmfReceived(tone);
  }

  /// Handle hold event raised by library and route it to matched call instance
  void onHeld(int callId, HoldState s) {
    _logs?.print('onHeld callId:$callId $s');

    _findCall(callId)?.onHeld(s);
    notifyListeners();
  }

  /// Handle muted event raised by CallKit (iOS/CallKit only)
  void onMuted(int callId, bool mute) {
    _logs?.print('onMuted callId:$callId $mute');

    _findCall(callId)?.onMuted(mute);
    notifyListeners();
  }

  /// Handle call switched event raised by library
  void onSwitched(int callId) {
    _logs?.print('onSwitched callId:$callId');

    if(_switchedCallId != callId) {
      _switchedCallId = callId;
      notifyListeners();
      onSwitchedCall?.call(_switchedCallId);
    }
  }

  /// Handle call switched event raised by library
  void onPlayerStateChanged(int playerId, PlayerState state) {
    _logs?.print('onPlayerStateChanged playerId:$playerId $state');
    for(final call in _callItems)
      if(call.onPlayerStateChanged(playerId, state)) break;
  }

  /// Serialize list of accounts+calls to json
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {};
    if(_callItems.isNotEmpty) {
      List<Map<String, dynamic>> callsList=[];
      for(final call in _callItems) callsList.add(call.toJson());
      ret['callsList'] = callsList;
      ret['switchedCallId'] = _switchedCallId;
    }
    return ret;
  }

  /// Restore saved calls when Activity re-created while service has been running (Android only)
  void onSyncCallsState(Map<String, dynamic> argsMap) {
    for (var c in argsMap['callsList'] ?? []) {
      CallModel? newCall = CallModel.fromJson(Map<String, dynamic>.from(c), _logs);
      if(newCall != null) _callItems.add(newCall);
    }
    _switchedCallId = argsMap['switchedCallId'] ?? kEmptyCallId;
    _logs?.print('onSyncState calls:${_callItems.length}');

    if(_callItems.isNotEmpty) {
      notifyListeners();
      onNewIncomingCall?.call();
    }
  }

  /// Parse SIP uri and return extension
  static String parseExt(String uri) {
    //uri format: "displName" <sip:ext@domain:port>
    final int startIndex = uri.indexOf(':');
    if(startIndex == -1) return "";

    final int endIndex = uri.indexOf('@', startIndex + 1);
    return (endIndex == -1) ? "" : uri.substring(startIndex+1, endIndex);
  }

  /// Parse SIP uri and return display name
  static String parseDisplayName(String uri) {
    //uri format: "displName" <sip:ext@domain:port>
    final int startIndex = uri.indexOf('"');
    if(startIndex == -1) return "";

    final int endIndex = uri.indexOf('"', startIndex + 1);
    return (endIndex == -1) ? "" : uri.substring(startIndex+1, endIndex);
  }

  /// Resolve contact name from SIP uri using callback function specified by app
  void _postResolveContactName(CallModel c) {
    if(onResolveContactName != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
          String? name = onResolveContactName?.call(c.remoteExt);
          if((name != null)&&(name != "")) c.updateDisplName(name);
      });
    }
  }

}//CallsModel

