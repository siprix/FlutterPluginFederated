// ignore_for_file: constant_identifier_names

import 'package:siprix_voip_sdk_platform_interface/siprix_voip_sdk_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'dart:math';
import 'dart:convert';
import 'logs_model.dart';
import 'siprix_voip_sdk.dart';
import 'network_model.dart';


/// Holds lists of parameters using for initialization siprix module
class InitData implements ISiprixData {
  /// License credentials. When missed - library works in trial mode
  String? license;

  /// Replaces default product name string in logs and version
  String? brandName;

  /// Log level for file output (default level .info)
  LogLevel? logLevelFile;

  /// Log level for IDE output (default level .info)
  LogLevel? logLevelIde;

  /// RTP start port number (not implemented yet, library uses random port numbers)
  int?  rtpStartPort;

  /// Enable verify server's certificate (common option for all accounts, by default disabled)
  bool? tlsVerifyServer;

  /// Enable single call mode when library can make/accept only one call
  bool? singleCallMode;

  /// Use same UDP transport for all accounts (by default enabled)
  bool? shareUdpTransport;

  ///Android only. Enables TelStateListener which holds SIP calls when GSM call started (Valid only for Android, disabled by default, requires permission 'READ_PHONE_STATE')
  bool? listenTelState;

  ///Android only. Enables listening VOLUME_CHANGED_ACTION and mute ringtone sound when detected (Valid only for Android, disabled by default)
  bool? listenVolChange;

  /// iOS only. Enable PushKit support
  bool? enablePushKit;

  /// iOS only. Enable CallKit support
  bool? enableCallKit;

  /// iOS only. Enable include a call in the system's Recents list after the call ends
  bool? enableCallKitRecents;

  /// Android only. Class name of the service which allows to customize notifications and implemented as part of the android app. Example: `com.siprix.siprix_voip_sdk_example.MyNotifService`
  String? serviceClassName;

  /// Unregister accounts on destroy library instance (by default `true`). Set to `false` when PushNotif is using
  bool? unregOnDestroy;

  /// Set using DNS SRV for resolve IP address of SIP server/proxy (by default `true`).
  bool? useDnsSrv;

  /// Set recording call sound in stereo mode (keep sent/received sound in separate channels) (by default `false`).
  bool? recordStereo;

  /// Enable using video call feature (by default `true`). Recommended to set `false` when video call is not required
  bool? enableVideoCall;

  /// Expiremental option which forces using IPv4 interface even when NetMonitor doesn't detect it
  bool? transpForceIPv4;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {};
    if(license!=null)           ret['license'] = license;
    if(brandName!=null)         ret['brandName'] = brandName;
    if(logLevelFile!=null)      ret['logLevelFile'] = logLevelFile!.id;
    if(logLevelIde!=null)       ret['logLevelIde']  = logLevelIde!.id;
    if(rtpStartPort!=null)      ret['rtpStartPort'] = rtpStartPort;
    if(tlsVerifyServer!=null)   ret['tlsVerifyServer'] = tlsVerifyServer;
    if(singleCallMode!=null)    ret['singleCallMode'] = singleCallMode;
    if(shareUdpTransport!=null) ret['shareUdpTransport'] = shareUdpTransport;
    if(listenTelState!=null)    ret['listenTelState'] = listenTelState;
    if(listenVolChange!=null)   ret['listenVolChange'] = listenVolChange;
    if(enablePushKit!=null)     ret['enablePushKit'] = enablePushKit;
    if(enableCallKit!=null)     ret['enableCallKit'] = enableCallKit;
    if(enableCallKitRecents!=null) ret['enableCallKitRecents'] = enableCallKitRecents;
    if(serviceClassName!=null)  ret['serviceClassName'] = serviceClassName;
    if(unregOnDestroy!=null)    ret['unregOnDestroy'] = unregOnDestroy;
    if(useDnsSrv!=null)         ret['useDnsSrv'] = useDnsSrv;
    if(recordStereo!=null)      ret['recordStereo'] = recordStereo;
    if(enableVideoCall!=null)   ret['enableVideoCall'] = enableVideoCall;
    if(transpForceIPv4!=null)   ret['transpForceIPv4'] = transpForceIPv4;
    return ret;
  }
}//InitData



///Holds video capturer params
class VideoData implements ISiprixData {
  /// Path to jpg file path to the jpg file with image, which library will send when video device not available.
  String? noCameraImgPath;

  /// Capturer framerate (by default 15)
  int?  framerateFps;

  /// Encoder bitrate, allows specify video bandwith (by default 600)
  int?  bitrateKbps;

  /// Capturer video frame height (by default 480)
  int?  height;

  /// Capturer video frame width (by default 600)
  int?  width;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {};
    if(noCameraImgPath!=null) ret['noCameraImgPath'] = noCameraImgPath;
    if(framerateFps!=null)    ret['framerateFps'] = framerateFps;
    if(bitrateKbps!=null)     ret['bitrateKbps']  = bitrateKbps;
    if(height!=null)          ret['height'] = height;
    if(width!=null)           ret['width'] = width;
    return ret;
  }
}//VideoData


///Helper class for manipulating account' scodec settings
class Codec {
  Codec(this.id, {this.selected=true});
  /// Codec id (one of the [SiprixVoipSdk.kAudioCodec*])
  int  id;
  /// Is this codec selected
  bool selected;

  /// Returns codec name which matches specified codec id
  static String name(int codecId) {
    switch(codecId) {
      case SiprixVoipSdk.kAudioCodecOpus: return "OPUS/48000";
      case SiprixVoipSdk.kAudioCodecISAC16: return "ISAC/16000";
      case SiprixVoipSdk.kAudioCodecISAC32: return "ISAC/32000";
      case SiprixVoipSdk.kAudioCodecG722: return "G722/8000";
      case SiprixVoipSdk.kAudioCodecG729: return "G729/8000";
      case SiprixVoipSdk.kAudioCodecILBC: return "ILBC/8000";
      case SiprixVoipSdk.kAudioCodecPCMU: return "PCMU/8000";
      case SiprixVoipSdk.kAudioCodecPCMA: return "PCMA/8000";
      case SiprixVoipSdk.kAudioCodecDTMF: return "DTMF/8000";
      case SiprixVoipSdk.kAudioCodecCN:   return "CN/8000";
      case SiprixVoipSdk.kVideoCodecH264: return "H264";
      case SiprixVoipSdk.kVideoCodecVP8:  return "VP8";
      case SiprixVoipSdk.kVideoCodecVP9:  return "VP9";
      case SiprixVoipSdk.kVideoCodecAV1:  return "AV1";
      default: return "Undefined";
    }
  }

  /// Returns list of all available audio/video codecs
  static List<int> availableCodecs(bool audio) {
    if(audio) {
      return [
        SiprixVoipSdk.kAudioCodecOpus,
        SiprixVoipSdk.kAudioCodecISAC16,
        SiprixVoipSdk.kAudioCodecISAC32,
        SiprixVoipSdk.kAudioCodecG722,
        SiprixVoipSdk.kAudioCodecG729,
        SiprixVoipSdk.kAudioCodecILBC,
        SiprixVoipSdk.kAudioCodecPCMU,
        SiprixVoipSdk.kAudioCodecPCMA,
        SiprixVoipSdk.kAudioCodecILBC,
        SiprixVoipSdk.kAudioCodecCN,
        SiprixVoipSdk.kAudioCodecDTMF
      ];
    }else {
      return [
        SiprixVoipSdk.kVideoCodecH264,
        SiprixVoipSdk.kVideoCodecVP8,
        SiprixVoipSdk.kVideoCodecVP9,
        SiprixVoipSdk.kVideoCodecAV1,
      ];
    }
  }

  /// Converts list of int id's to list of Codecs. When input list not specified - returns default codecs settings
  static List<Codec> getCodecsList(List<int>? selectedCodecsIds, {bool audio=true}) {
    List<Codec> ret = <Codec>[];
    if(selectedCodecsIds != null) {
      for(var c in selectedCodecsIds) {
        ret.add(Codec(c, selected:true));
      }

      for(var c in Codec.availableCodecs(audio)) {
        if(ret.indexWhere((codec) => (codec.id == c))==-1) {
          ret.add(Codec(c, selected:false));
        }
      }
    }
    else {
      //Build codecs selected by default
      for(var c in Codec.availableCodecs(audio)) {
        bool sel = audio ? ((c==SiprixVoipSdk.kAudioCodecDTMF)||(c==SiprixVoipSdk.kAudioCodecOpus)||(c==SiprixVoipSdk.kAudioCodecPCMA))
                         : ((c==SiprixVoipSdk.kVideoCodecVP8)||(c==SiprixVoipSdk.kVideoCodecH264));
        ret.add(Codec(c, selected:sel));
      }
    }

    return ret;
  }

  /// Returns list of int values which matches selected codecs id's
  static List<int> getSelectedCodecsIds(List<Codec> codecsList) {
    List<int> ret = <int>[];
    for(var c in codecsList) {
      if(c.selected) ret.add(c.id);
    }
    return ret;
  }

  /// Returns true when selected at least one codec in the input list
  static bool validateSel(List<Codec> items) {
    for(Codec c in items) {
      if(c.selected) return true;
    }
    return false;
  }
}


/// SecureMedia options (audio/video encryption setting)
enum SecureMedia {
  /// Secure media disabled
  Disabled(SiprixVoipSdk.kSecureMediaDisabled, "Disabled"),
  /// Encryption audio/video using SDES SRTP
  SdesSrtp(SiprixVoipSdk.kSecureMediaSdesSrtp, "SDES SRTP"),
  /// Encryption audio/video using DTLS SRTP
  DtlsSrtp(SiprixVoipSdk.kSecureMediaDtlsSrtp, "DTLS SRTP");

  const SecureMedia(this.id, this.name);
  /// Value
  final int id;
  /// User friendly name of the selected option
  final String name;

  /// Returns enum item which matches int constant
  static SecureMedia from(int val) {
    switch(val) {
      case SiprixVoipSdk.kSecureMediaSdesSrtp: return SecureMedia.SdesSrtp;
      case SiprixVoipSdk.kSecureMediaDtlsSrtp: return SecureMedia.DtlsSrtp;
      default:                                 return SecureMedia.Disabled;
    }
  }
}


/// Account's registration state
enum RegState {
  /// Registration success
  success,
  /// Registration failed
  failed,
  /// Registration removed
  removed,
  /// Registration in progress (request sent, waiting on response)
  inProgress
}



/// Holds properties of SIP Account model
class AccountModel implements ISiprixData {
  AccountModel({this.sipServer="", this.sipExtension="", this.sipPassword="", this.expireTime});
  /// Unique account id assigned by library (valid only during current session)
  int      myAccId=0;
  /// Registration state
  RegState regState=RegState.inProgress;
  /// Registration text, got from SIP response, received fro, remote server
  String   regText="";

  /// SIP Server (domain)
  String  sipServer="";
  /// SIP Extension (phone number, user)
  String  sipExtension="";
  /// SIP Password (used for registration on server)
  String  sipPassword="";

  ///AuthId (used for authentification, in case when server requires specific user name which doesn't match 'sipExtension')
  String? sipAuthId;
  /// Proxy server (used when 'sipServer' can't be resolved by DNS or need to override destination, where to send SIP requests)
  String? sipProxy;
  ///Display name (caller Id) which library sends in the To/From headers. Example: "displayName"<sip:extension@server>
  String? displName;
  /// UserAgent string which library sends in the 'User-Agent' header of SIP requests. Default value 'siprix'.
  String? userAgent;
  /// Registration expire time in seconds (how long server has to remember registration of this account). When app set 0 - registration disabled.
  int?    expireTime;
  /// SIP transport for this account
  SipTransport? transport = SipTransport.udp;
  /// Local SIP port number for this account (by default 0 which means using random port)
  int?    port;
  /// Path to the CA certificate file which library will use for verify server's certificate when establishes TLS connection
  String? tlsCaCertPath;
  /// Use 'sip' scheme when TLS transport selected (By default 'false', library uses 'sips' scheme)
  bool?   tlsUseSipScheme;
  /// Use RtcpMux (sending RTP and RTCP packets trough the same port, by default disabled).
  bool?   rtcpMuxEnabled;
  /// Use ICE (establish connection by collect and exchange transport candidates, webrtc compatible mode, by default disabled).
  bool?   iceEnabled;
  /// Unique instance ID of this account and device (set value using method 'genAccInstId', see more RFC 5626)
  String? instanceId;
  /// Path to the ringtone file which library will play when incoming call received
  String? ringTonePath;

  /// Timeout in seconds which library uses for sending short packets (prevents closing ports between device and server, by default 30)
  int?    keepAliveTime;
  /// Enable rewrite IP address of Contact header with address got from received SIP response's 'Via/received=...'
  bool?   rewriteContactIp;
  /// Enables verify SDP of the incoming call. When enabled and received call with SDP which can't be answered library silently rejects this call
  bool?   verifyIncomingCall;
  /// Use specified proxy for all requests (by default disabled)
  bool?   forceSipProxy;
  /// Audio/video encryption setting (by default disabled)
  SecureMedia?  secureMedia;

  /// STUN Server
  String? stunServer;
  /// TURN Server
  String? turnServer;
  /// TURN User
  String? turnUser;
  /// TURN Password
  String? turnPassword;

  /// List of custom headers/values which should be added to REGISTER request
  Map<String, String>? xheaders;
  /// List of custom params which should be added to Contact's URI
  Map<String, String>? xContactUriParams;
  /// Selected audio codecs (use Codec.getCodecsList/Codec.getSelectedCodecsIds to retrive and set values)
  List<int>? aCodecs;
  /// Selected video codecs (use Codec.getCodecsList/Codec.getSelectedCodecsIds to retrive and set values)
  List<int>? vCodecs;

  ///URI of this account
  String get uri => '$sipExtension@$sipServer';

  ///Returns true when enabled audio/video encryption
  bool get hasSecureMedia => (secureMedia!=null)&&(secureMedia!=SecureMedia.Disabled);

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {
      'accId' : myAccId,
      'sipServer': sipServer,
      'sipExtension' : sipExtension,
      'sipPassword' : sipPassword
    };
    if(sipAuthId       !=null) ret['sipAuthId']       = sipAuthId;
    if(sipProxy        !=null) ret['sipProxy']        = sipProxy;
    if(displName       !=null) ret['displName']       = displName;
    if(userAgent       !=null) ret['userAgent']       = userAgent;
    if(expireTime      !=null) ret['expireTime']      = expireTime;
    if(transport       !=null) ret['transport']       = transport?.id;
    if(port            !=null) ret['port']            = port;
    if(tlsCaCertPath   !=null) ret['tlsCaCertPath']   = tlsCaCertPath;
    if(tlsUseSipScheme !=null) ret['tlsUseSipScheme'] = tlsUseSipScheme;
    if(rtcpMuxEnabled  !=null) ret['rtcpMuxEnabled']  = rtcpMuxEnabled;
    if(iceEnabled      !=null) ret['iceEnabled']      = iceEnabled;
    if(instanceId      !=null) ret['instanceId']      = instanceId;
    if(ringTonePath    !=null) ret['ringTonePath']    = ringTonePath;
    if(keepAliveTime   !=null) ret['keepAliveTime']   = keepAliveTime;
    if(rewriteContactIp!=null) ret['rewriteContactIp']= rewriteContactIp;
    if(forceSipProxy   !=null) ret['forceSipProxy']   = forceSipProxy;
    if(verifyIncomingCall!=null) ret['verifyIncomingCall']= verifyIncomingCall;
    if(secureMedia     !=null) ret['secureMedia']     = secureMedia?.id;
    if(stunServer      !=null) ret['stunServer']      = stunServer;
    if(turnServer      !=null) ret['turnServer']      = turnServer;
    if(turnUser        !=null) ret['turnUser']        = turnUser;
    if(turnPassword    !=null) ret['turnPassword']    = turnPassword;
    if(xContactUriParams !=null) ret['xContactUriParams'] = xContactUriParams;
    if(xheaders        !=null) ret['xheaders']        = xheaders;
    if(aCodecs         !=null) ret['aCodecs']         = aCodecs;
    if(vCodecs         !=null) ret['vCodecs']         = vCodecs;
    return ret;
  }

  /// Creates instance of AccountModel with values read from json
  factory AccountModel.fromJson(Map<String, dynamic> jsonMap) {
    AccountModel acc = AccountModel();
    jsonMap.forEach((key, value) {
      if((key == 'sipServer')&&(value is String))     { acc.sipServer = value;    } else
      if((key == 'sipExtension')&&(value is String))  { acc.sipExtension = value; } else
      if((key == 'sipPassword')&&(value is String))   { acc.sipPassword = value;  } else
      if((key == 'sipAuthId')&&(value is String))     { acc.sipAuthId = value;    } else
      if((key == 'sipProxy')&&(value is String))      { acc.sipProxy = value;     } else
      if((key == 'displName')&&(value is String))     { acc.displName = value;    } else
      if((key == 'userAgent')&&(value is String))     { acc.userAgent = value;    } else
      if((key == 'expireTime')&&(value is int))       { acc.expireTime = value;   } else
      if((key == 'transport')&&(value is int))        { acc.transport = SipTransport.from(value);  } else
      if((key == 'port')&&(value is int))             { acc.port = value;           } else
      if((key == 'tlsCaCertPath')&&(value is String)) { acc.tlsCaCertPath = value;  } else
      if((key == 'tlsUseSipScheme')&&(value is bool)) { acc.tlsUseSipScheme = value;} else
      if((key == 'rtcpMuxEnabled')&&(value is bool))  { acc.rtcpMuxEnabled = value; } else
      if((key == 'iceEnabled')&&(value is bool))      { acc.iceEnabled = value;     } else
      if((key == 'instanceId')&&(value is String))    { acc.instanceId = value;     } else
      if((key == 'ringTonePath')&&(value is String))  { acc.ringTonePath = value;   } else
      if((key == 'keepAliveTime')&&(value is int))    { acc.keepAliveTime = value;  } else
      if((key == 'rewriteContactIp')&&(value is bool)) { acc.rewriteContactIp = value; } else
      if((key == 'verifyIncomingCall')&&(value is bool)) { acc.verifyIncomingCall = value; } else
      if((key == 'forceSipProxy')&&(value is bool))   { acc.forceSipProxy = value; } else
      if((key == 'secureMedia')&&(value is int))      { acc.secureMedia = SecureMedia.from(value);  } else
      if((key == 'stunServer')&&(value is String))    { acc.stunServer = value;   } else
      if((key == 'turnServer')&&(value is String))    { acc.turnServer = value;   } else
      if((key == 'turnUser')&&(value is String))      { acc.turnUser = value;     } else
      if((key == 'turnPassword')&&(value is String))  { acc.turnPassword = value; } else
      if((key == 'xContactUriParams')&&(value is Map)) { acc.xContactUriParams = Map<String, String>.from(value); } else
      if((key == 'xheaders')&&(value is Map))         { acc.xheaders = Map<String, String>.from(value); } else
      if((key == 'aCodecs')&&(value is List))         { acc.aCodecs = List<int>.from(value); } else
      if((key == 'vCodecs')&&(value is List))         { acc.vCodecs = List<int>.from(value); }
    });
    return acc;
  }

}//AccountModel


/// Model invokes this callback when has changes which should be saved by the app
typedef SaveChangesCallback = void Function(String jsonStr);


/// Accounts list model (contains list of accounts, methods for managing them, handlers of library events)
class AccountsModel extends ChangeNotifier implements IAccountsModel {
  final List<AccountModel> _accounts = [];
  final ILogsModel? _logs;
  int? _selAccountIndex;

  AccountsModel([this._logs]) {
    SiprixVoipSdk().accListener = AccStateListener(
      regStateChanged : onRegStateChanged
    );
  }

  /// Returns true when list of accounts is empty
  bool get isEmpty => _accounts.isEmpty;
  /// Returns number of accounts in list
  int get length => _accounts.length;
  /// Returns id of the selected account
  int? get selAccountId => (_selAccountIndex==null) ? null : _accounts[_selAccountIndex!].myAccId;
  /// Returns account by its index in list
  AccountModel operator [](int i) => _accounts[i];

  @protected List<AccountModel> get accounts => _accounts;

  /// Callback which model invokes when accounts changes should be saved
  SaveChangesCallback? onSaveChanges;

  void _selectAccount(int? index) {
    if((index != null)&&(index >=0)&&(index < length)&&(_selAccountIndex != index)){
      _selAccountIndex = index;
      _raiseSaveChanges();
      notifyListeners();
    }
  }

  ///Set account as selected by its id
  void setSelectedAccountById(int accId) {
    int index = _accounts.indexWhere((a) => a.myAccId==accId);
    if(index != -1) _selectAccount(index);
  }

  ///Set account as selected by its uri
  void setSelectedAccountByUri(String uri) {
    int index = _accounts.indexWhere((a) => a.uri==uri);
    if(index != -1) _selectAccount(index);
  }

  @override
  int getAccId(String uri) {
    int index = _accounts.indexWhere((a) => a.uri==uri);
    return (index != -1) ? _accounts[index].myAccId : 0;
  }

  @override
  String getUri(int accId) {
    int index = _accounts.indexWhere((a) => a.myAccId==accId);
    return (index == -1) ? "?" : _accounts[index].uri;
  }

  @override
  bool hasSecureMedia(int accId) {
    int index = _accounts.indexWhere((a) => a.myAccId==accId);
    return (index == -1) ? false : _accounts[index].hasSecureMedia;
  }

  ///Add new account
  Future<void> addAccount(AccountModel acc, {bool saveChanges=true}) async {
    _logs?.print('Adding new account: ${acc.uri}');

    try {
      _generateRandomLocalPort(acc);

      acc.myAccId  = await SiprixVoipSdk().addAccount(acc) ?? 0;
      acc.regState = (acc.expireTime==0) ? RegState.removed : RegState.inProgress;
      acc.regText = (acc.expireTime==0) ? "Removed" : "In progress...";

      _integrateAddedAccount(acc, saveChanges);

    } on PlatformException catch (err) {
      if(err.code == SiprixVoipSdk.eDuplicateAccount.toString()) {
        int existingAccId = err.details;
        int idx = _accounts.indexWhere((account) => (account.myAccId == existingAccId));
        if(idx==-1) {
          //This case is possible in Android when:
          // - activity started as usual and initialized SDK Core
          // - activity destroyed, but SDK Core is still running (as Service)
          // - activity started again, loaded saved state and has to sync it
          acc.myAccId = existingAccId;
          acc.regState = (acc.expireTime==0) ? RegState.removed : RegState.success;
          acc.regText = (acc.expireTime==0) ? "Removed" : "200 OK";
          _integrateAddedAccount(acc, saveChanges);
        }
      }
      else {
        _logs?.print('Can\'t add account: ${err.code} ${err.message} ');
        return Future.error((err.message==null) ? err.code : err.message!);
      }
    } on Exception catch (err) {
         _logs?.print('Can\'t add account: ${err.toString()}');
        return Future.error(err.toString());
    }
  }

  void _integrateAddedAccount(AccountModel acc, bool saveChanges) {
    _accounts.add(acc);
      _logs?.print('Added successfully with id: ${acc.myAccId}');
    if(saveChanges) {
      _selAccountIndex ??= 0;
      _raiseSaveChanges();
    }
    notifyListeners();
  }

  void _generateRandomLocalPort(AccountModel acc) {
    if((acc.port==null)||(acc.port==0)) {
      acc.port = Random().nextInt(65535-1024) + 1024;
    }
  }

  /// Refresh registration of the all existing accounts (with default or specified regExpire>0)
  Future<void> refreshRegistration() async {
    try {
      for(AccountModel acc in _accounts) {
        final int expireSec = (acc.expireTime==null) ? 300 : acc.expireTime!;
        if(expireSec != 0) {
          SiprixVoipSdk().registerAccount(acc.myAccId, expireSec);
        }
      }
    } on PlatformException catch (err) {
      _logs?.print('Can\'t refresh accounts registration: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  ///Update existing account with new params values
  Future<void> updateAccount(AccountModel acc) async {
     try {
      int index = _accounts.indexWhere((a) => a.myAccId==acc.myAccId);
      if(index == -1) return Future.error("Account with specified id not found");

      await SiprixVoipSdk().updateAccount(acc);

      _accounts[index] = acc;

      notifyListeners();
      _raiseSaveChanges();
      _logs?.print('Updated account accId:${acc.myAccId}');

    } on PlatformException catch (err) {
      _logs?.print('Can\'t update account: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Delete account specified by its index in the list
  Future<void> deleteAccount(int index) async {
    try {
      int accId = _accounts[index].myAccId;
      await SiprixVoipSdk().deleteAccount(accId);

      _accounts.removeAt(index);

      if(_selAccountIndex! >= length) {
        _selAccountIndex = _accounts.isEmpty ? null : length-1;
      }

      notifyListeners();
      _raiseSaveChanges();
      _logs?.print('Deleted account accId:$accId');

    } on PlatformException catch (err) {
      _logs?.print('Can\'t delete account: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  ///Unregister account specified by its index in the list
  Future<void> unregisterAccount(int index) async {
    try {
      //Send register request
      int accId = _accounts[index].myAccId;
      await SiprixVoipSdk().unRegisterAccount(accId);

      //Update UI
      _accounts[index].expireTime = 0;
      _accounts[index].regState = RegState.inProgress;

      notifyListeners();
      _raiseSaveChanges();
      _logs?.print('Unregistering accId:$accId');

    } on PlatformException catch (err) {
      _logs?.print('Can\'t unregister account: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  ///Refresh registration of the account specified by its index in the list
  Future<void> registerAccount(int index) async {
    try {
      //Send register request (use 300sec as expire time when account not registered)
      int accId      = _accounts[index].myAccId;
      int? expireSec = _accounts[index].expireTime;
      if((expireSec == null)||(expireSec == 0)) { expireSec = 300; }
      await SiprixVoipSdk().registerAccount(accId, expireSec);

      //Update UI
      _accounts[index].expireTime = expireSec;
      _accounts[index].regState = RegState.inProgress;
      notifyListeners();

      //Save changes
      _raiseSaveChanges();
      _logs?.print('Refreshing registration accId:$accId');

    } on PlatformException catch (err) {
      _logs?.print('Can\'t register account: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  /// Generates unique instance id. Used as value of AccountModel.instanceId
  Future<String?> genAccInstId() {
    return SiprixVoipSdk().genAccInstId();
  }

  void _raiseSaveChanges() {
    if(onSaveChanges != null) {
      Future.delayed(Duration.zero, () {
          onSaveChanges?.call(storeToJson());
      });
    }
  }

  ///Handles registtation state changes when received response from server
  void onRegStateChanged(int accId, RegState state, String response) {
    _logs?.print('onRegStateChanged accId:$accId resp:\'$response\' ${state.toString()}');
    int idx = _accounts.indexWhere((account) => (account.myAccId == accId));
    if(idx == -1) return;

    AccountModel acc = _accounts[idx];
    acc.regText = response;
    acc.regState = state;

    notifyListeners();
  }

  /// Load list of accounts from json string
  Future<bool> loadFromJson(String accJsonStr) async {
    try {
      if(accJsonStr.isEmpty) return false;

      Map<String, dynamic> map = jsonDecode(accJsonStr);
      if(!map.containsKey('accList')) return false;

      final parsedList = map['accList'];
      for (var parsedAcc in parsedList) {
        await addAccount(AccountModel.fromJson(parsedAcc), saveChanges:false);
      }

      _selAccountIndex = map['selAccIndex']?? 0;
      return parsedList.isNotEmpty;
    }catch (e) {
      _logs?.print('Can\'t load accounts from json. Err: $e');
      return false;
    }
  }

  /// Store list of accounts to json string
  String storeToJson() {
    Map<String, dynamic> ret = {
      'selAccIndex': _selAccountIndex,
      'accList': _accounts};

    return jsonEncode(ret);
  }

}//AccountsModel
