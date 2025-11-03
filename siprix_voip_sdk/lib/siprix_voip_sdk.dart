// ignore_for_file: non_constant_identifier_names

import 'package:siprix_voip_sdk_platform_interface/siprix_voip_sdk_platform_interface.dart';
import 'package:flutter/services.dart';

import 'subscriptions_model.dart';
import 'accounts_model.dart';
import 'network_model.dart';
import 'calls_model.dart';


/// Helper class for handling 'onAccountRegState' event raised by library
class AccRegStateArg {
  int accId=0;
  RegState regState=RegState.success;
  String response="";

  /// Returns true when even's atrributes parsed successfully
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    int stateVal=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgAccId)&&(value is int))    { accId    = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kRegState)&&(value is int))    { stateVal = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kResponse)&&(value is String)) { response = value; argsCounter+=1; }
    });

    switch (stateVal) {
      case SiprixVoipSdk.kRegStateSuccess: regState = RegState.success;
      case SiprixVoipSdk.kRegStateFailed:  regState = RegState.failed;
      case SiprixVoipSdk.kRegStateRemoved: regState = RegState.removed;
    }
    return (argsCounter==3);
  }
}

/// Helper class for handling 'onSubscriptionState' event raised by library
class SubscriptionStateArg {
  int subscrId=0;
  SubscriptionState state=SubscriptionState.created;
  String response="";

  /// Returns true when even's atrributes parsed successfully
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    int stateVal=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgSubscrId)&&(value is int)) { subscrId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kSubscrState)&&(value is int)) { stateVal = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kResponse)&&(value is String)) { response = value; argsCounter+=1; }
    });

    switch (stateVal) {
      case SiprixVoipSdk.kSubscrStateCreated:   state = SubscriptionState.created;
      case SiprixVoipSdk.kSubscrStateUpdated:   state = SubscriptionState.updated;
      case SiprixVoipSdk.kSubscrStateDestroyed: state = SubscriptionState.destroyed;
    }
    return (argsCounter==3);
  }
}

/// Helper class for handling 'onNetworkState' event raised by library
class NetworkStateArg {
  String name="";
  NetState state=NetState.lost;
  /// Returns true when even's atrributes parsed successfully
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    int stateVal=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgName)&&(value is String)) { name     = value; argsCounter+=1; }
      if((key == SiprixVoipSdkPlatform.kNetState)&&(value is int))   { stateVal = value; argsCounter+=1; }
    });

    switch (stateVal) {
      case SiprixVoipSdk.kNetStateLost:      state = NetState.lost;
      case SiprixVoipSdk.kNetStateRestored:  state = NetState.restored;
      case SiprixVoipSdk.kNetStateSwitched:  state = NetState.switched;
    }

    return (argsCounter==2);
  }
}

/// Helper class for handling 'onPlayerState' event raised by library
class PlayerStateArg {
  int playerId=0;
  PlayerState state=PlayerState.failed;

  /// Returns true when even's atrributes parsed successfully
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgPlayerId)&&(value is int))    { playerId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kPlayerState)&&(value is int))    { state = PlayerState.from(value); argsCounter+=1; }
    });

    return (argsCounter==2);
  }
}

/// Helper class for handling 'onCallProceeding' event raised by library
class CallProceedingArg {
  int callId=0;
  String response="";
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgCallId)&&(value is int))   { callId   = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kResponse)&&(value is String)) { response = value; argsCounter+=1; }
    });
    return (argsCounter==2);
  }
}

/// Helper class for handling 'onCallIncoming' event raised by library
class CallIncomingArg {
  int accId=0;
  int callId=0;
  String from="";
  String to="";
  bool withVideo = false;
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgAccId)&&(value is int))      { accId     = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kArgCallId)&&(value is int))     { callId    = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kArgWithVideo)&&(value is bool)) { withVideo = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kFrom)&&(value is String))       { from      = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kTo)&&(value is String))         { to        = value; argsCounter+=1; }
    });
    return (argsCounter==5);
  }
}

/// Helper class for handling 'onCallAcceptNotif' event raised by library
class CallAcceptNotifArg {
  int callId=0;
  bool withVideo = false;
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgCallId)&&(value is int))     { callId = value;    argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kArgWithVideo)&&(value is bool)) { withVideo = value; argsCounter+=1; }
    });
    return (argsCounter==2);
  }
}

/// Helper class for handling 'onCallConnected' event raised by library
class CallConnectedArg {
  int callId=0;
  String from="";
  String to="";
  bool withVideo = false;
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgWithVideo)&&(value is bool)) { withVideo = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kArgCallId)&&(value is int))     { callId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kFrom)&&(value is String))       { from   = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kTo)&&(value is String))         { to     = value; argsCounter+=1; }
    });
    return (argsCounter==4);
  }
}

/// Helper class for handling 'onCallTerminated' event raised by library
class CallTerminatedArg {
  int callId=0;
  int statusCode=0;
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgCallId)&&(value is int))     { callId     = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kArgStatusCode)&&(value is int)) { statusCode = value; argsCounter+=1; }
    });
    return (argsCounter==2);
  }
}

/// Helper class for handling 'onCallDtmfReceived' event raised by library
class CallDtmfReceivedArg {
  int callId=0;
  int tone=0;
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgCallId)&&(value is int)) { callId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kArgTone)&&(value is int))   { tone   = value; argsCounter+=1; }
    });
    return (argsCounter==2);
  }
}

/// Helper class for handling 'onCallTransferred' event raised by library
class CallTransferredArg {
  int callId=0;
  int statusCode=0;
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgCallId)&&(value is int))     { callId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kArgStatusCode)&&(value is int)) { statusCode = value; argsCounter+=1; }
    });
    return (argsCounter==2);
  }
}

/// Helper class for handling 'onCallRedirected' event raised by library
class CallRedirectedArg {
  int origCallId=0;
  int relatedCallId=0;
  String referTo="";
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgFromCallId)&&(value is int)) { origCallId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kArgToCallId)&&(value is int))   { relatedCallId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kArgToExt)&&(value is String))   { referTo = value; argsCounter+=1; }
    });
    return (argsCounter==3);
  }
}

/// Helper class for handling 'onCallHeld' event raised by library
class CallHeldArg {
  int callId=0;
  HoldState state = HoldState.none;
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;

    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgCallId)&&(value is int)) { callId = value;               argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kHoldState)&&(value is int)) { state  = HoldState.from(value); argsCounter+=1; }
    });
    return (argsCounter==2);
  }
}

/// Helper class for handling 'onCallSwitched' event raised by library
class CallSwitchedArg {
  int callId=0;
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgCallId)&&(value is int)) { callId = value; argsCounter+=1; }
    });
    return (argsCounter==1);
  }
}

/// Helper class for handling 'onPushIncoming' event raised by library
class PushIncomingArg {
  String callUUID="";
  Map<String, dynamic> pushPayload={};
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgCallKitUuid)&&(value is String)) {
        callUUID = value; argsCounter+=1; }
      if((key == SiprixVoipSdkPlatform.kArgPushPayload)) {
        pushPayload = Map<String, dynamic>.from(value as Map);
        argsCounter+=1; }
    });
    return (argsCounter==2);
  }
}

/// Helper class for handling 'onMessageSentState' event raised by library
class MessageSentStateArg {
  int messageId = 0;
  bool success=false;
  String response="";
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgMsgId)&&(value is int)) { messageId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kSuccess)&&(value is bool)) { success = value;   argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kResponse)&&(value is String)) { response = value; argsCounter+=1; }
    });
    return (argsCounter==3);
  }
}

/// Helper class for handling 'onMessageIncoming' event raised by library
class MessageIncomingArg {
  int accId = 0, messageId=0;
  String from="";
  String body="";
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgMsgId)&&(value is int)) { messageId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kArgAccId)&&(value is int)) { accId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kFrom)&&(value is String))  { from = value;  argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kBody)&&(value is String))  { body = value;  argsCounter+=1; }
    });
    return (argsCounter==4);
  }
}

/// Helper class for handling 'onSipNotify' event raised by library
class SipNotifyArg {
  int accId = 0;
  String hdrEvent="";
  String body="";
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgAccId)&&(value is int)) { accId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kEvent)&&(value is String)) { hdrEvent = value;  argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kBody)&&(value is String))  { body = value;  argsCounter+=1; }
    });
    return (argsCounter==3);
  }
}

/// Helper class for handling 'onVuMeterLevel' event raised by library
class VuMeterArg {
  int micLevel=0, spkLevel=0;
  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kMicLevel)&&(value is int)) { micLevel = value; argsCounter+=1; } else
      if((key == SiprixVoipSdkPlatform.kSpkLevel)&&(value is int)) { spkLevel = value; argsCounter+=1; }
    });
    return (argsCounter==2);
  }
}


/// Helper class for managing audio/video devices
class MediaDevice {
  MediaDevice(this.index);
  String  name="";
  String  guid="";
  int index = 0;

  bool fromMap(Map<dynamic, dynamic> argsMap) {
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdkPlatform.kArgDvcName)&&(value is String)) { name = value; argsCounter+=1; }
      if((key == SiprixVoipSdkPlatform.kArgDvcGuid)&&(value is String)) { guid = value; argsCounter+=1; }
    });
    return (argsCounter==2);
  }
}


//-//////////////////////////////////////////////////////////////////////////
//-Listeners using by models

/// Account state listener, usign by 'AccountsModel'
class AccStateListener {
  AccStateListener({required this.regStateChanged});
  void Function(int accId, RegState state, String response) regStateChanged;
}

/// Subscription state listener, usign by 'SubscriptionsModel'
class SubscrStateListener {
  SubscrStateListener({required this.subscrStateChanged});
  void Function(int subscrId, SubscriptionState state, String response) subscrStateChanged;
}

/// Network state listener, usign by 'NetworkModel'
class NetStateListener {
  NetStateListener({required this.networkStateChanged});
  void Function(String name, NetState state) networkStateChanged;
}

/// Call state listener, usign by 'CallsModel'
class CallStateListener {
  CallStateListener({this.proceeding, this.incoming, this.incomingPush, this.acceptNotif,
    this.connected, this.terminated, this.dtmfReceived,
    this.transferred, this.redirected, this.held, this.switched,
    this.playerStateChanged});

  ///Triggered by library when changed player state in specific call
  void Function(int playerId, PlayerState s)? playerStateChanged;
  ///Triggered by library when it makes outgoing call and received 1xx response.
  void Function(int callId, String response)?  proceeding;
  ///Triggered by library when received incoming call (SIP INVITE request)
  void Function(int callId, int accId, bool withVideo, String from, String to)? incoming;
  ///Triggered by library when received remote push notification (iOS only)
  void Function(String callkit_CallUUID, Map<String, dynamic> pushPayload)? incomingPush;
  ///Triggered by library when call accepted by tap on notification (Android only)
  void Function(int callId, bool withVideo)? acceptNotif;
  ///Triggered by library when call successfully connected (received/sent 200 OK response on the SIP INVITE request/response).
  void Function(int callId, String from, String to, bool withVideo)? connected;
  ///Triggered by library when call terminated.
  void Function(int callId, int statusCode)? terminated;
  ///Triggered by library when received response on the previously sent REFER request (or timeout expired).
  void Function(int callId, int statusCode)? transferred;
  ///Triggered by library when received redirect request from remote side (remote side transfers call to new destination).
  void Function(int origCallId, int relatedCallId, String referTo)? redirected;
  ///Triggered by library when received DTMF tone from remote side.
  void Function(int callId, int tone)? dtmfReceived;
  ///Triggered by library when local or remote side has put call on hold
  void Function(int callId, HoldState)? held;
  ///Triggered by library when new call gives audio focus
  void Function(int callId)? switched;
}

/// Messages state listener, usign by 'MessagesModel'
class MessagesStateListener {
  MessagesStateListener({required this.incoming, required this.sentState});
  ///Triggered by library when received confirmation on sent message or expired timeout
  void Function(int messageId, bool success, String response) sentState;
  ///Triggered by library when new text message received
  void Function(int messageId, int accountId, String from, String body) incoming;
}

/// Sip notify listener, allows detect SIP NOTIFY events
class SipNotifyListener {
  SipNotifyListener({required this.notifyReceived});
  ///Triggered by library when SIP NOTIFY received
  void Function(int accId, String hdrEvent, String body)  notifyReceived;
}

/// Vu meter listener, allows detect mic/spk levels
class VuMeterListener {
  VuMeterListener({required this.vu});
  ///Triggered by library 10 times per sec, provided mic/spk volume level in range [0..9]
  void Function(int micLevel, int spkLevel) vu;
}

/// Devices state listener, usign by 'DevicesModel'
class DevicesStateListener {
  DevicesStateListener({required this.devicesChanged});
  void Function() devicesChanged;
}

/// Trial mode listener, usign by 'LogsModel'
class TrialModeListener {
  TrialModeListener({required this.notified});
  void Function() notified;
}

/// Inteface of the log model, allows others models to display debug output
abstract interface class ILogsModel {
  void print(String s);
}

/// Inteface of the accounts model, allows others models to resolve accountUri from Id and vice versa
abstract interface class IAccountsModel {
  ///Get accountUri by its id
  String getUri(int accId);
  ///Get accountId by its uri
  int getAccId(String uri);
  ///Returns true when account with specified id enabled secure media
  bool hasSecureMedia(int accId);
}



/// Root of the library implementation
class SiprixVoipSdk {
  ///Log level constants
  static const int kLogLevelStack   = 0;
  static const int kLogLevelDebug   = 1;
  static const int kLogLevelInfo    = 2;
  static const int kLogLevelWarning = 3;
  static const int kLogLevelError   = 4;
  static const int kLogLevelNone    = 5;

  ///Sip transport constants
  static const int kSipTransportUdp = 0;
  static const int kSipTransportTcp = 1;
  static const int kSipTransportTls = 2;

  ///Secure media constants
  static const int kSecureMediaDisabled = 0;
  static const int kSecureMediaSdesSrtp = 1;
  static const int kSecureMediaDtlsSrtp = 2;

  ///Account registration state constants
  static const int kRegStateSuccess = 0;
  static const int kRegStateFailed  = 1;
  static const int kRegStateRemoved = 2;

  ///Subscription state constants
  static const int kSubscrStateCreated = 0;
  static const int kSubscrStateUpdated = 1;
  static const int kSubscrStateDestroyed = 2;

  ///Network state constants
  static const int kNetStateLost     = 0;
  static const int kNetStateRestored = 1;
  static const int kNetStateSwitched = 2;

  ///Player state constants
  static const int kPlayerStateStarted = 0;
  static const int kPlayerStateStopped = 1;
  static const int kPlayerStateFailed  = 2;

  ///Audio codec constants
  static const int kAudioCodecOpus  = 65;
  static const int kAudioCodecISAC16= 66;
  static const int kAudioCodecISAC32= 67;
  static const int kAudioCodecG722  = 68;
  static const int kAudioCodecILBC  = 69;
  static const int kAudioCodecPCMU  = 70;
  static const int kAudioCodecPCMA  = 71;
  static const int kAudioCodecDTMF  = 72;
  static const int kAudioCodecCN    = 73;
  static const int kAudioCodecG729  = 74;

  ///Video codec constants
  static const int kVideoCodecH264  = 80;
  static const int kVideoCodecVP8   = 81;
  static const int kVideoCodecVP9   = 82;
  static const int kVideoCodecAV1   = 83;

  ///DTMF method constants
  static const int kDtmfMethodRtp  = 0;
  static const int kDtmfMethodInfo = 1;

  ///Hold state constants
  static const int kHoldStateNone   = 0;
  static const int kHoldStateLocal  = 1;
  static const int kHoldStateRemote = 2;
  static const int kHoldStateLocalAndRemote = 3;

  ///Error codes constants
  static const int eOK = 0;
  static const int eDuplicateAccount=-1021;
  static const int eSubscrAlreadyExist=-1083;

  ///Special callId used for creating renderer of the local camera
  static const int kLocalVideoCallId=0;

  //-//////////////////////////////////////////////////////////////////////////////////////
  //-Channel and instance implementation

  static final SiprixVoipSdk _instance = SiprixVoipSdk._internal();
  static  SiprixVoipSdk get instance => _instance;
  factory SiprixVoipSdk() { return _instance; }

  SiprixVoipSdk._internal();

  static SiprixVoipSdkPlatform get _platform => SiprixVoipSdkPlatform.instance;

  ///Network state listener
  NetStateListener? netListener;
  ///Account state listener
  AccStateListener? accListener;
  ///Subscription state listener
  SubscrStateListener? subscrListener;
  ///Call state listener
  CallStateListener? callListener;
  ///Device changes listener
  DevicesStateListener? dvcListener;
  ///Trial mode listenerer
  TrialModeListener? trialListener;
  ///Messages listenerer
  MessagesStateListener? messagesListener;
  ///SipNotify listenerer
  SipNotifyListener? sipNotifyListener;
  ///VuMeter listenerer
  VuMeterListener? vuMeterListener;

  /// Initialize siprix module
  Future<void> initialize(InitData iniData, [ILogsModel? logsModel]) async {
    _platform.setEventsHandler(_eventsHandler);
    String brand = iniData.brandName ?? "Siprix";
    try {
      await _platform.initialize(iniData);
      String verStr = await version() ?? "???";
      //int verCode = await versionCode() ?? 0;
      logsModel?.print('$brand module initialized successfully');
      logsModel?.print('Version: $verStr');
    } on PlatformException catch (err) {
      logsModel?.print('Can\'t initialize $brand module Err: ${err.code} ${err.message}');
    }
  }

  /// UnInitialize siprix module
  void unInitialize(ILogsModel? logsModel) async {
    try {
      await _platform.unInitialize();
      logsModel?.print('Siprix module uninitialized');
    } on PlatformException catch (err) {
      logsModel?.print('Can\'t uninitilize Siprix module Err: ${err.code} ${err.message}');
    }
  }

  /// Path to the home folder created by library on device
  Future<String?> homeFolder() async {
    return _platform.homeFolder();
  }

  /// Version (build date) of the library
  Future<String?> version() async {
    return _platform.version();
  }

  /// Version code of the library (similar to Android API level)
  Future<int?> versionCode() async {
    return _platform.versionCode();
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Account methods implementation

  /// Add new account, return unique id assigned by library
  Future<int?> addAccount(AccountModel newAccount) {
    return _platform.addAccount(newAccount);
  }

  /// Update existing account with new attributes
  Future<void> updateAccount(AccountModel updAccount) {
    return _platform.updateAccount(updAccount);
  }

  /// Delete account specified by its id
  Future<void> deleteAccount(int accId) {
    return _platform.deleteAccount(accId);
  }

  /// Unregister account specified by its id
  Future<void> unRegisterAccount(int accId) {
    return _platform.unRegisterAccount(accId);
  }

  /// Reresh registration of account specified by its id
  Future<void> registerAccount(int accId, int expireTime) {
    return _platform.registerAccount(accId, expireTime);
  }

  /// Generate unique instance id. Used as value of AccountModel.instanceId
  Future<String?> genAccInstId() {
    return _platform.genAccInstId();
  }

  //-//////////////////////////////////////////////////////////////////////////////////////

  /// Iniate new outgoing call
  Future<int?> invite(CallDestination destData) {
    return _platform.invite(destData);
  }

  /// Reject incoming call specified by its id, send response with status code
  Future<void> reject(int callId, int statusCode) {
    return _platform.reject(callId, statusCode);
  }

  /// Accept incoming call specified by its id. Use 'withVideo' to set audio-only or video call
  Future<void> accept(int callId, bool withVideo) {
    return _platform.accept(callId, withVideo);
  }

  /// Send DTMF tone to remote side of the specified call
  Future<void> sendDtmf(int callId, String tones, int durationMs, int intertoneGapMs, [int method = kDtmfMethodRtp]) {
    return _platform.sendDtmf(callId, tones, durationMs, intertoneGapMs, method);
  }

  /// End specified call
  Future<void> bye(int callId) {
    return _platform.bye(callId);
  }

  /// Hold/unhold specified call
  Future<void> hold(int callId) {
    return _platform.hold(callId);
  }

  /// Get hold state of the specified call
  Future<int?> getHoldState(int callId) {
    return _platform.getHoldState(callId);
  }

  /// Get value of the SIP header from last received response
  Future<String?> getSipHeader(int callId, String headerName) {
    return _platform.getSipHeader(callId, headerName);
  }

  /// Get call stats as json encoded string
  Future<String?> getStats(int callId) {
    return _platform.getStats(callId);
  }

  /// Mute microphone for the specified call
  Future<void> muteMic(int callId, bool mute) {
    return _platform.muteMic(callId, mute);
  }

  /// Mute camera for the specified call
  Future<void> muteCam(int callId, bool mute) {
    return _platform.muteCam(callId, mute);
  }

  /// Play file to remote side of the specified call
  Future<int?> playFile(int callId, String pathToMp3File, bool loop) {
    return _platform.playFile(callId, pathToMp3File, loop);
  }

  /// Stop play file
  Future<void> stopPlayFile(int playerId) {
    return _platform.stopPlayFile(playerId);
  }

  /// Start recording sound, received from remote side to specified file
  Future<void> recordFile(int callId, String pathToMp3File) {
    return _platform.recordFile(callId, pathToMp3File);
  }

  /// Stop recording file
  Future<void> stopRecordFile(int callId) {
    return _platform.stopRecordFile(callId);
  }

  /// Make blind transfer of the call to specified extension
  Future<void> transferBlind(int callId, String toExt) {
    return _platform.transferBlind(callId, toExt);
  }

  /// Make attended transfer of the call to specified call
  Future<void> transferAttended(int fromCallId, int toCallId) {
    return _platform.transferAttended(fromCallId, toCallId);
  }

  /// Upgrade audio only call to audio+video
  Future<void> upgradeToVideo(int callId) async {
    return _platform.upgradeToVideo(callId);
  }

  /// Stop playing (mute) ringtone.
  Future<void> stopRingtone() async {
    return _platform.stopRingtone();
  }

  //-//////////////////////////////////////////////////////////////////////////////////////
  //-Siprix Mixer methods implmentation

  /// Switch to the selected call (sound from microphone is sending to this call and speaker plays sound received from this call)
  Future<void> switchToCall(int callId) {
    return _platform.switchToCall(callId);
  }

  /// Join all calls to conference (configures mixer gains and handles audio streams in way when each call can hear other calls)
  Future<void> makeConference() {
    return _platform.makeConference();
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix message

  Future<int?> sendMessage(ISiprixData messageData) {
    return _platform.sendMessage(messageData);
  }

  //-//////////////////////////////////////////////////////////////////////////////////////
  //-Siprix subscriptions

  /// Add new subscription (sends SUBSCRIBE request)
  Future<int?> addSubscription(SubscriptionModel newSubscription) {
    return _platform.addSubscription(newSubscription);
  }

  /// Delete subscription
  Future<void> deleteSubscription(int subscriptionId) {
    return _platform.deleteSubscription(subscriptionId);
  }

  //-//////////////////////////////////////////////////////////////////////////////////////
  //-Siprix Devices methods implementation

  /// Get number of avialable spekaer devices
  Future<int?> getPlayoutDevices() {
    return _platform.getPlayoutDevices();
  }

  /// Get number of avialable microphone devices
  Future<int?> getRecordingDevices() {
    return _platform.getRecordingDevices();
  }

  /// Get number of camera devices
  Future<int?> getVideoDevices() {
    return _platform.getVideoDevices();
  }

  Future<MediaDevice?> _getMediaDevice(int index, String methodName) async {
     try {
      Map<dynamic, dynamic>? argsMap = await _platform.getMediaDevice(index, methodName);
      if(argsMap==null) return null;

      MediaDevice dvc = MediaDevice(index);
      return dvc.fromMap(argsMap) ? dvc : null;
    } on PlatformException catch (err) {
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Get speaker device details by its index
  Future<MediaDevice?> getPlayoutDevice(int index) async {
    return _getMediaDevice(index, SiprixVoipSdkPlatform.kMethodDvcGetPlayout);
  }

  /// Get microphone device details by its index
  Future<MediaDevice?> getRecordingDevice(int index) async {
    return _getMediaDevice(index, SiprixVoipSdkPlatform.kMethodDvcGetRecording);
  }

  /// Get camera details by its index
  Future<MediaDevice?> getVideoDevice(int index) async {
    return _getMediaDevice(index, SiprixVoipSdkPlatform.kMethodDvcGetVideo);
  }

  /// Set speaker device by its index
  Future<void> setPlayoutDevice(int index) {
    return _platform.setPlayoutDevice(index);
  }

  /// Set microphone device by its index
  Future<void> setRecordingDevice(int index) {
    return _platform.setRecordingDevice(index);
  }

  /// Set camera device by its index
  Future<void> setVideoDevice(int index) {
    return _platform.setVideoDevice(index);
  }

  /// Set video capturer params (common for all calls)
  Future<void> setVideoParams(VideoData videoData) {
    return _platform.setVideoParams(videoData);
  }

  /// Toggle front/back camera (iOS/Android platfroms only)
  Future<void>? switchCamera() {
    return _platform.switchCamera();
  }

  //Future<void> routeAudioTo(iOSAudioRoute route) {
  //  return _platform.routeAudioTo(route);
  //}


  //-//////////////////////////////////////////////////////////////////////////////////////
  //-Siprix video renderers

  /// Create video renderer
  Future<int?> videoRendererCreate() {
    return _platform.videoRendererCreate();
  }

  /// Set call whose video should be using as source for rendering
  Future<void> videoRendererSetSourceCall(int textureId, int callId) {
    return _platform.videoRendererSetSourceCall(textureId, callId);
  }

  ///Dispose renderer
  Future<void> videoRendererDispose(int textureId) {
    return _platform.videoRendererDispose(textureId);
  }

  //-//////////////////////////////////////////////////////////////////////////////////////
  //-iOS specific implementation

  ///Get PushKit token (iOS only)
  Future<String?>? getPushKitToken() {
    return _platform.getPushKitToken();
  }

  ///Update CallKit call details (app can invoke it twice:
  /// - first when got and extracted some data from push payload and second - when received INVITE and got 'sip_callId')
  Future<void>? updateCallKitCallDetails(String callkit_CallUUID, int? sip_callId,
                      [String? localizedCallerName, String? genericHandle, bool? withVideo]) {
    return _platform.updateCallKitCallDetails(callkit_CallUUID, sip_callId, localizedCallerName, genericHandle, withVideo);
  }

  ///Get CallKit call UUID assigned with SIP callId (iOS only)
  Future<String?>? getCallKitCallUUID(int sip_callId) {
    return _platform.getCallKitCallUUID(sip_callId);
  }

  //-//////////////////////////////////////////////////////////////////////////////////////
  //-Android specific implementation

  ///Set foreground mode of the android service (android only, allows app to stay in background)
  Future<void>? setForegroundMode(bool enabled) {
    return _platform.setForegroundMode(enabled);
  }

  ///Returns true if android service is running in foreground mode
  Future<bool?>? isForegroundMode() {
    return _platform.isForegroundMode();
  }


  //-//////////////////////////////////////////////////////////////////////////////////////
  //-Siprix callbacks handler

  ///Handles signals received from event channel
  Future<void> _eventsHandler(MethodCall methodCall) async {
    //debugPrint('event ${methodCall.method.toString()} ${methodCall.arguments.toString()}');
    if(methodCall.arguments is! Map<dynamic, dynamic>) {
      return;
    }

    Map<dynamic, dynamic> argsMap = methodCall.arguments as Map<dynamic, dynamic>;
    switch(methodCall.method) {
      case SiprixVoipSdkPlatform.kOnAccountRegState  : _onAccountRegState(argsMap);  break;
      case SiprixVoipSdkPlatform.kOnSubscriptionState: _onSubscriptionState(argsMap);break;
      case SiprixVoipSdkPlatform.kOnNetworkState     : _onNetworkState(argsMap);     break;
      case SiprixVoipSdkPlatform.kOnPlayerState      : _onPlayerState(argsMap);      break;

      case SiprixVoipSdkPlatform.kOnPushIncoming     : _onPushIncoming(argsMap);     break;
      case SiprixVoipSdkPlatform.kOnTrialModeNotif   : _onTrialModeNotif(argsMap);   break;
      case SiprixVoipSdkPlatform.kOnDevicesChanged   : _onDevicesChanged(argsMap);   break;

      case SiprixVoipSdkPlatform.kOnCallIncoming     : _onCallIncoming(argsMap);     break;
      case SiprixVoipSdkPlatform.kOnCallAcceptNotif  : _onCallAcceptNotif(argsMap);  break;
      case SiprixVoipSdkPlatform.kOnCallConnected    : _onCallConnected(argsMap);    break;
      case SiprixVoipSdkPlatform.kOnCallTerminated   : _onCallTerminated(argsMap);   break;
      case SiprixVoipSdkPlatform.kOnCallProceeding   : _onCallProceeding(argsMap);   break;
      case SiprixVoipSdkPlatform.kOnCallDtmfReceived : _onCallDtmfReceived(argsMap); break;
      case SiprixVoipSdkPlatform.kOnCallTransferred  : _onCallTransferred(argsMap);  break;
      case SiprixVoipSdkPlatform.kOnCallRedirected   : _onCallRedirected(argsMap);   break;
      case SiprixVoipSdkPlatform.kOnCallSwitched     : _onCallSwitched(argsMap);     break;
      case SiprixVoipSdkPlatform.kOnCallHeld         : _onCallHeld(argsMap);         break;

      case SiprixVoipSdkPlatform.kOnMessageSentState : _onMessageSentState(argsMap); break;
      case SiprixVoipSdkPlatform.kOnMessageIncoming  : _onMessageIncoming(argsMap);  break;

      case SiprixVoipSdkPlatform.kOnSipNotify        : _onSipNotify(argsMap);        break;
      case SiprixVoipSdkPlatform.kOnVuMeterLevel     : _onVuMeterLevel(argsMap);     break;
    }
  }

  void _onAccountRegState(Map<dynamic, dynamic> argsMap) {
    AccRegStateArg arg = AccRegStateArg();
    if(arg.fromMap(argsMap)) {
      accListener?.regStateChanged.call(arg.accId, arg.regState, arg.response);
    }
  }

  void _onSubscriptionState(Map<dynamic, dynamic> argsMap) {
    SubscriptionStateArg arg = SubscriptionStateArg();
    if(arg.fromMap(argsMap)) {
      subscrListener?.subscrStateChanged.call(arg.subscrId, arg.state, arg.response);
    }
  }

  void _onNetworkState(Map<dynamic, dynamic> argsMap) {
    NetworkStateArg arg = NetworkStateArg();
    if(arg.fromMap(argsMap)) {
      netListener?.networkStateChanged.call(arg.name, arg.state);
    }
  }

  void _onPlayerState(Map<dynamic, dynamic> argsMap) {
    PlayerStateArg arg =PlayerStateArg();
    if(arg.fromMap(argsMap)) {
      callListener?.playerStateChanged?.call(arg.playerId, arg.state);
    }
  }

  void _onCallProceeding(Map<dynamic, dynamic> argsMap) {
    CallProceedingArg arg = CallProceedingArg();
    if(arg.fromMap(argsMap)) {
      callListener?.proceeding?.call(arg.callId, arg.response);
    }
  }

  void _onCallTerminated(Map<dynamic, dynamic> argsMap) {
    CallTerminatedArg arg = CallTerminatedArg();
    if(arg.fromMap(argsMap)) {
      callListener?.terminated?.call(arg.callId, arg.statusCode);
    }
  }

  void _onCallConnected(Map<dynamic, dynamic> argsMap) {
    CallConnectedArg arg = CallConnectedArg();
    if(arg.fromMap(argsMap)) {
      callListener?.connected?.call(arg.callId, arg.from, arg.to, arg.withVideo);
    }
  }

  void _onCallIncoming(Map<dynamic, dynamic> argsMap) {
    CallIncomingArg arg = CallIncomingArg();
    if(arg.fromMap(argsMap)) {
      callListener?.incoming?.call(arg.callId, arg.accId, arg.withVideo, arg.from, arg.to);
    }
  }

  void _onCallAcceptNotif(Map<dynamic, dynamic> argsMap) {
    CallAcceptNotifArg arg = CallAcceptNotifArg();
    if(arg.fromMap(argsMap)) {
      callListener?.acceptNotif?.call(arg.callId, arg.withVideo);
    }
  }

  void _onCallDtmfReceived(Map<dynamic, dynamic> argsMap) {
    CallDtmfReceivedArg arg = CallDtmfReceivedArg();
    if(arg.fromMap(argsMap)) {
      callListener?.dtmfReceived?.call(arg.callId, arg.tone);
    }
  }

  void _onCallTransferred(Map<dynamic, dynamic> argsMap) {
    CallTransferredArg arg = CallTransferredArg();
    if(arg.fromMap(argsMap)) {
      callListener?.transferred?.call(arg.callId, arg.statusCode);
    }
  }

  void _onCallRedirected(Map<dynamic, dynamic> argsMap) {
    CallRedirectedArg arg = CallRedirectedArg();
    if(arg.fromMap(argsMap)) {
      callListener?.redirected?.call(arg.origCallId, arg.relatedCallId, arg.referTo);
    }
  }

  void _onCallHeld(Map<dynamic, dynamic> argsMap) {
    CallHeldArg arg = CallHeldArg();
    if(arg.fromMap(argsMap)) {
      callListener?.held?.call(arg.callId, arg.state);
    }
  }

  void _onCallSwitched(Map<dynamic, dynamic> argsMap) {
    CallSwitchedArg arg = CallSwitchedArg();
    if(arg.fromMap(argsMap)) {
      callListener?.switched?.call(arg.callId);
    }
  }

  void _onPushIncoming(Map<dynamic, dynamic> argsMap) {
    PushIncomingArg arg = PushIncomingArg();
    if(arg.fromMap(argsMap)) {
      callListener?.incomingPush?.call(arg.callUUID, arg.pushPayload);
    }
  }

  void _onMessageSentState(Map<dynamic, dynamic> argsMap) {
    MessageSentStateArg arg = MessageSentStateArg();
    if(arg.fromMap(argsMap)) {
      messagesListener?.sentState.call(arg.messageId, arg.success, arg.response);
    }
  }

  void _onMessageIncoming(Map<dynamic, dynamic> argsMap) {
    MessageIncomingArg arg = MessageIncomingArg();
    if(arg.fromMap(argsMap)) {
      messagesListener?.incoming.call(arg.messageId, arg.accId, arg.from, arg.body);
    }
  }

  void _onDevicesChanged(Map<dynamic, dynamic> argsMap) {
    dvcListener?.devicesChanged.call();
  }

  void _onTrialModeNotif(Map<dynamic, dynamic> argsMap) {
    trialListener?.notified.call();
  }

  void _onSipNotify(Map<dynamic, dynamic> argsMap) {
    SipNotifyArg arg = SipNotifyArg();
    if(arg.fromMap(argsMap)) {
      sipNotifyListener?.notifyReceived.call(arg.accId, arg.hdrEvent, arg.body);
    }
  }

  void _onVuMeterLevel(Map<dynamic, dynamic> argsMap) {
    VuMeterArg arg = VuMeterArg();
    if(arg.fromMap(argsMap)) {
      vuMeterListener?.vu.call(arg.micLevel, arg.spkLevel);
    }
  }

}//SiprixVoipSdk
