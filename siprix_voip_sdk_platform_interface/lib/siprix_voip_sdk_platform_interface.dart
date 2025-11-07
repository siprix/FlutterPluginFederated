import 'dart:io';

import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

//////////////////////////////////////////////////////////////////////////////////////////
//Data interface

abstract interface class ISiprixData {
  Map<String, dynamic> toJson();
}

//////////////////////////////////////////////////////////////////////////////////////////
//SiprixVoipSdkPlatform interface

abstract class SiprixVoipSdkPlatform extends PlatformInterface {
  //Constants
  static const String kMethodModuleInitialize    = 'Module_Initialize';
  static const String kMethodModuleUnInitialize  = 'Module_UnInitialize';
  static const String kMethodModuleHomeFolder    = 'Module_HomeFolder';
  static const String kMethodModuleVersionCode   = 'Module_VersionCode';
  static const String kMethodModuleVersion       = 'Module_Version';

  static const String kMethodAccountAdd          = 'Account_Add';
  static const String kMethodAccountUpdate       = 'Account_Update';
  static const String kMethodAccountRegister     = 'Account_Register';
  static const String kMethodAccountUnregister   = 'Account_Unregister';
  static const String kMethodAccountDelete       = 'Account_Delete';
  static const String kMethodAccountGenInstId    = 'Account_GenInstId';

  static const String kMethodCallInvite          = 'Call_Invite';
  static const String kMethodCallReject          = 'Call_Reject';
  static const String kMethodCallAccept          = 'Call_Accept';
  static const String kMethodCallHold            = 'Call_Hold';
  static const String kMethodCallGetHoldState    = 'Call_GetHoldState';
  static const String kMethodCallGetSipHeader    = 'Call_GetSipHeader';
  static const String kMethodCallGetStats        = 'Call_GetStats';
  static const String kMethodCallMuteMic         = 'Call_MuteMic';
  static const String kMethodCallMuteCam         = 'Call_MuteCam';
  static const String kMethodCallSendDtmf        = 'Call_SendDtmf';
  static const String kMethodCallPlayFile        = 'Call_PlayFile';
  static const String kMethodCallStopPlayFile    = 'Call_StopPlayFile';
  static const String kMethodCallRecordFile      = 'Call_RecordFile';
  static const String kMethodCallStopRecordFile  = 'Call_StopRecordFile';
  static const String kMethodCallTransferBlind   = 'Call_TransferBlind';
  static const String kMethodCallTransferAttended= 'Call_TransferAttended';
  static const String kMethodCallStopRingtone    = 'Call_StopRingtone';
  static const String kMethodCallUpgradeToVideo  = 'Call_UpgradeToVideo';
  static const String kMethodCallBye             = 'Call_Bye';

  static const String kMethodMixerSwitchToCall   = 'Mixer_SwitchToCall';
  static const String kMethodMixerMakeConference = 'Mixer_MakeConference';

  static const String kMethodMessageSend         = 'Message_Send';

  static const String kMethodSubscriptionAdd     = 'Subscription_Add';
  static const String kMethodSubscriptionDelete  = 'Subscription_Delete';

  static const String kMethodDvcGetPushKitToken  = 'Dvc_GetPushKitToken';
  static const String kMethodDvcUpdCallKitDetails= 'Dvc_UpdCallKitDetails';
  static const String kMethodDvcGetCallKitUUID   = 'Dvc_GetCallKitUUID';

  static const String kMethodDvcSetForegroundMode= 'Dvc_SetForegroundMode';
  static const String kMethodDvcIsForegroundMode=  'Dvc_IsForegroundMode';
  static const String kMethodDvcGetPlayoutNumber = 'Dvc_GetPlayoutDevices';
  static const String kMethodDvcGetRecordNumber  = 'Dvc_GetRecordingDevices';
  static const String kMethodDvcGetVideoNumber   = 'Dvc_GetVideoDevices';
  static const String kMethodDvcGetPlayout       = 'Dvc_GetPlayoutDevice';
  static const String kMethodDvcGetRecording     = 'Dvc_GetRecordingDevice';
  static const String kMethodDvcGetVideo         = 'Dvc_GetVideoDevice';
  static const String kMethodDvcSetPlayout       = 'Dvc_SetPlayoutDevice';
  static const String kMethodDvcSetRecording     = 'Dvc_SetRecordingDevice';
  static const String kMethodDvcSetVideo         = 'Dvc_SetVideoDevice';
  static const String kMethodDvcSetVideoParams   = 'Dvc_SetVideoParams';
  static const String kMethodDvcSwitchCamera     = 'Dvc_SwitchCamera';

  static const String kMethodVideoRendererCreate  = 'Video_RendererCreate';
  static const String kMethodVideoRendererSetSrc  = 'Video_RendererSetSrc';
  static const String kMethodVideoRendererDispose = 'Video_RendererDispose';

  static const String kOnPushIncoming     = 'OnPushIncoming';
  static const String kOnTrialModeNotif   = 'OnTrialModeNotif';
  static const String kOnDevicesChanged   = 'OnDevicesChanged';

  static const String kOnAccountRegState  = 'OnAccountRegState';
  static const String kOnSubscriptionState= 'OnSubscriptionState';
  static const String kOnNetworkState     = 'OnNetworkState';
  static const String kOnPlayerState      = 'OnPlayerState';

  static const String kOnCallProceeding   = 'OnCallProceeding';
  static const String kOnCallTerminated   = 'OnCallTerminated';
  static const String kOnCallConnected    = 'OnCallConnected';
  static const String kOnCallIncoming     = 'OnCallIncoming';
  static const String kOnCallAcceptNotif  = 'OnCallAcceptNotif';
  static const String kOnCallDtmfReceived = 'OnCallDtmfReceived';
  static const String kOnCallTransferred  = 'OnCallTransferred';
  static const String kOnCallRedirected   = 'OnCallRedirected';
  static const String kOnCallVideoUpgraded= 'OnCallVideoUpgraded';
  static const String kOnCallSwitched     = 'OnCallSwitched';
  static const String kOnCallHeld         = 'OnCallHeld';

  static const String kOnMessageSentState = 'OnMessageSentState';
  static const String kOnMessageIncoming  = 'OnMessageIncoming';

  static const String kOnSipNotify        = 'OnSipNotify';
  static const String kOnVuMeterLevel     = 'OnVuMeterLevel';

  static const String kArgVideoTextureId = 'videoTextureId';
  static const String kArgForeground = 'foreground';
  static const String kArgStatusCode = 'statusCode';
  static const String kArgExpireTime = 'expireTime';
  static const String kArgWithVideo  = 'withVideo';
  static const String kArgDvcIndex   = 'dvcIndex';
  static const String kArgDvcName    = 'dvcName';
  static const String kArgDvcGuid    = 'dvcGuid';
  static const String kArgCallId     = 'callId';
  static const String kArgFromCallId = 'fromCallId';
  static const String kArgToCallId   = 'toCallId';
  static const String kArgToExt      = 'toExt';
  static const String kArgAccId      = 'accId';
  static const String kArgPlayerId   = 'playerId';
  static const String kArgSubscrId   = 'subscrId';
  static const String kArgMsgId      = 'msgId';

  static const String kArgCallKitUuid = 'callKitUuid';
  static const String kArgPushPayload = 'pushPayload';
  static const String kArgPushName    = 'pushName';
  static const String kArgPushHandle  = 'pushHandle';

  static const String kRegState      = 'regState';
  static const String kHoldState     = 'holdState';
  static const String kNetState      = 'netState';
  static const String kPlayerState   = 'playerState';
  static const String kSubscrState   = 'subscrState';
  static const String kResponse  = 'response';
  static const String kSuccess   = 'success';
  static const String kArgName   = 'name';
  static const String kArgTone   = 'tone';
  static const String kFrom      = 'from';
  static const String kEvent     = 'event';
  static const String kTo        = 'to';
  static const String kBody      = 'body';
  static const String kMicLevel  = 'mic';
  static const String kSpkLevel  = 'spk';

  static const String kChannelName = 'siprix_voip_sdk';

  ////////////////////////////////////////////////////////////////////////////////////////
  //Channel and instance implementation
  SiprixVoipSdkPlatform() : super(token: _token);
  static final Object _token = Object();

  static SiprixVoipSdkPlatform _instance = _StubImplementation();

  static SiprixVoipSdkPlatform get instance => _instance;

  static set instance(SiprixVoipSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  //Channel and instance implementation
  final _methodChannel = const MethodChannel(kChannelName);

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix module methods implementation

  void setEventsHandler(Future<dynamic> Function(MethodCall call)? eventsHandler) {
     _methodChannel.setMethodCallHandler(eventsHandler);
  }

  Future<void> initialize(ISiprixData iniData) {
    return _methodChannel.invokeMethod<void>(kMethodModuleInitialize, iniData.toJson());
  }

  Future<void> unInitialize() {
    return _methodChannel.invokeMethod<void>(kMethodModuleUnInitialize, {});
  }

  Future<String?> homeFolder() async {
    return _methodChannel.invokeMethod<String>(kMethodModuleHomeFolder, {});
  }

  Future<String?> version() async {
    return _methodChannel.invokeMethod<String>(kMethodModuleVersion, {});
  }

  Future<int?> versionCode() async {
    return _methodChannel.invokeMethod<int>(kMethodModuleVersionCode, {});
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Account methods implementation

  Future<int?> addAccount(ISiprixData newAccount) {
    return _methodChannel.invokeMethod<int>(kMethodAccountAdd, newAccount.toJson());
  }

  Future<void> updateAccount(ISiprixData updAccount) {
    return _methodChannel.invokeMethod<void>(kMethodAccountUpdate, updAccount.toJson());
  }

  Future<void> deleteAccount(int accId) {
    return _methodChannel.invokeMethod<void>(kMethodAccountDelete,
      {kArgAccId:accId} );
  }

  Future<void> unRegisterAccount(int accId) {
    return _methodChannel.invokeMethod<void>(kMethodAccountUnregister,
      {kArgAccId:accId} );
  }

  Future<void> registerAccount(int accId, int expireTime) {
    return _methodChannel.invokeMethod<void>(kMethodAccountRegister,
      {kArgAccId:accId, kArgExpireTime:expireTime} );
  }

  Future<String?> genAccInstId() {
    return _methodChannel.invokeMethod<String>(kMethodAccountGenInstId, {});
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Calls methods implementation

  Future<int?> invite(ISiprixData destData) {
    return _methodChannel.invokeMethod<int>(kMethodCallInvite, destData.toJson());
  }

  Future<void> reject(int callId, int statusCode) {
    return _methodChannel.invokeMethod<void>(kMethodCallReject,
      {kArgCallId:callId, kArgStatusCode:statusCode} );
  }

  Future<void> accept(int callId, bool withVideo) {
    return _methodChannel.invokeMethod<void>(kMethodCallAccept,
      {kArgCallId:callId, kArgWithVideo:withVideo} );
  }

  Future<void> sendDtmf(int callId, String tones, int durationMs, int intertoneGapMs, int method) {
    return _methodChannel.invokeMethod<void>(kMethodCallSendDtmf,
      {kArgCallId:callId, 'dtmfs':tones,
        'durationMs':durationMs, 'intertoneGapMs':intertoneGapMs, 'method':method} );
  }

  Future<void> bye(int callId) {
    return _methodChannel.invokeMethod<void>(kMethodCallBye,
      {kArgCallId:callId} );
  }

  Future<void> hold(int callId) {
    return _methodChannel.invokeMethod<void>(kMethodCallHold,
      {kArgCallId:callId} );
  }

  Future<int?> getHoldState(int callId) {
    return _methodChannel.invokeMethod<int>(kMethodCallGetHoldState,
        {kArgCallId:callId} );
  }

  Future<String?> getSipHeader(int callId, String headerName) {
    return _methodChannel.invokeMethod<String>(kMethodCallGetSipHeader,
        {kArgCallId:callId, 'hdrName':headerName} );
  }

  Future<String?> getStats(int callId) {
    return _methodChannel.invokeMethod<String>(kMethodCallGetStats,
        {kArgCallId:callId });
  }

  Future<void> muteMic(int callId, bool mute) {
    return _methodChannel.invokeMethod<void>(kMethodCallMuteMic,
      {kArgCallId:callId, 'mute':mute} );
  }

  Future<void> muteCam(int callId, bool mute) {
    return _methodChannel.invokeMethod<void>(kMethodCallMuteCam,
      {kArgCallId:callId, 'mute':mute} );
  }

  Future<int?> playFile(int callId, String pathToMp3File, bool loop) {
    return _methodChannel.invokeMethod<int>(kMethodCallPlayFile,
      {kArgCallId:callId, 'pathToMp3File':pathToMp3File, 'loop':loop} );
  }

  Future<void> stopPlayFile(int playerId) {
    return _methodChannel.invokeMethod<void>(kMethodCallStopPlayFile,
      {kArgPlayerId:playerId} );
  }

  Future<void> recordFile(int callId, String pathToMp3File) {
    return _methodChannel.invokeMethod<void>(kMethodCallRecordFile,
      {kArgCallId:callId, 'pathToMp3File':pathToMp3File} );
  }

  Future<void> stopRecordFile(int callId) {
    return _methodChannel.invokeMethod<void>(kMethodCallStopRecordFile,
      {kArgCallId:callId} );
  }

  Future<void> transferBlind(int callId, String toExt) {
    return _methodChannel.invokeMethod<void>(kMethodCallTransferBlind,
      {kArgCallId:callId, kArgToExt:toExt} );
  }

  Future<void> transferAttended(int fromCallId, int toCallId) {
    return _methodChannel.invokeMethod<void>(kMethodCallTransferAttended,
      {kArgFromCallId:fromCallId, kArgToCallId:toCallId} );
  }

  Future<void> upgradeToVideo(int callId) {
    return _methodChannel.invokeMethod<void>(kMethodCallUpgradeToVideo, 
      {kArgCallId:callId} );
  }

  Future<void> stopRingtone() {
    return _methodChannel.invokeMethod<void>(kMethodCallStopRingtone, {});
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Mixer methods implementation

  Future<void> switchToCall(int callId) {
    return _methodChannel.invokeMethod<void>(kMethodMixerSwitchToCall,
      {kArgCallId:callId} );
  }

  Future<void> makeConference() {
    return _methodChannel.invokeMethod<void>(kMethodMixerMakeConference, {} );
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix subscriptions

  Future<int?> addSubscription(ISiprixData subscriptionData) {
    return _methodChannel.invokeMethod<int>(kMethodSubscriptionAdd,
      subscriptionData.toJson());
  }

  Future<void> deleteSubscription(int subscriptionId) {
    return _methodChannel.invokeMethod<void>(kMethodSubscriptionDelete,
      {kArgSubscrId:subscriptionId} );
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix message

  Future<int?> sendMessage(ISiprixData messageData) {
    return _methodChannel.invokeMethod<int>(kMethodMessageSend,
      messageData.toJson());
  }


  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Devices methods implementation

  Future<int?> getPlayoutDevices() {
    return _methodChannel.invokeMethod<int>(kMethodDvcGetPlayoutNumber, {});
  }

  Future<int?> getRecordingDevices() {
    return _methodChannel.invokeMethod<int>(kMethodDvcGetRecordNumber, {});
  }

  Future<int?> getVideoDevices() {
    return _methodChannel.invokeMethod<int>(kMethodDvcGetVideoNumber, {});
  }

  Future<Map<dynamic, dynamic>?> getMediaDevice(int index, String methodName) {
    return _methodChannel.invokeMethod<Map<dynamic, dynamic>>(methodName,
      {kArgDvcIndex:index});
  }

  Future<Map<dynamic, dynamic>?> getPlayoutDevice(int index) async {
    return _methodChannel.invokeMethod<Map<dynamic, dynamic>>(kMethodDvcGetPlayout,
      {kArgDvcIndex:index});
  }

  Future<Map<dynamic, dynamic>?> getRecordingDevice(int index) async {
    return _methodChannel.invokeMethod<Map<dynamic, dynamic>>(kMethodDvcGetRecording,
      {kArgDvcIndex:index});
  }

  Future<Map<dynamic, dynamic>?> getVideoDevice(int index) async {
    return _methodChannel.invokeMethod<Map<dynamic, dynamic>>(kMethodDvcGetVideo,
      {kArgDvcIndex:index});
  }

  Future<void> setPlayoutDevice(int index) {
    return _methodChannel.invokeMethod<void>(kMethodDvcSetPlayout,
      {kArgDvcIndex:index} );
  }

  Future<void> setRecordingDevice(int index) {
    return _methodChannel.invokeMethod<void>(kMethodDvcSetRecording,
      {kArgDvcIndex:index} );
  }

  Future<void> setVideoDevice(int index) {
    return _methodChannel.invokeMethod<void>(kMethodDvcSetVideo,
      {kArgDvcIndex:index} );
  }

  Future<void> setVideoParams(ISiprixData videoData) {
    return _methodChannel.invokeMethod<void>(kMethodDvcSetVideoParams, videoData.toJson() );
  }

  Future<void>? switchCamera() {
    if(Platform.isIOS || Platform.isAndroid){
      return _methodChannel.invokeMethod<void>(kMethodDvcSwitchCamera, {});
    }
    return null;
  }

  //Future<void> routeAudioTo(iOSAudioRoute route) {
  //  return _methodChannel.invokeMethod<void>(kMethodDvcRouteAudio, {kArgIOSRoute:route} );
  //}


  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix video renderers

  Future<int?> videoRendererCreate() {
    return _methodChannel.invokeMethod<int>(kMethodVideoRendererCreate, {});
  }

  Future<void> videoRendererSetSourceCall(int textureId, int callId) {
    return _methodChannel.invokeMethod<void>(kMethodVideoRendererSetSrc,
      {kArgVideoTextureId:textureId, kArgCallId:callId} );
  }

  Future<void> videoRendererDispose(int textureId) {
    return _methodChannel.invokeMethod<void>(kMethodVideoRendererDispose,
      {kArgVideoTextureId:textureId} );
  }


  ////////////////////////////////////////////////////////////////////////////////////////
  //iOS specific implementation

  Future<String?>? getPushKitToken() {
    if(Platform.isIOS) {
      return _methodChannel.invokeMethod<String>(kMethodDvcGetPushKitToken, {});
    }
    return null;
  }

  Future<void>? updateCallKitCallDetails(String callkit_CallUUID, int? sip_callId,
                      [String? localizedCallerName, String? genericHandle, bool? withVideo]) {
    if(Platform.isIOS) {
      return _methodChannel.invokeMethod<void>(kMethodDvcUpdCallKitDetails,
        {kArgCallKitUuid:callkit_CallUUID, kArgCallId:sip_callId,
         kArgPushName:localizedCallerName, kArgPushHandle:genericHandle, kArgWithVideo:withVideo});
    }
    return null;
  }

  Future<String?>? getCallKitCallUUID(int sip_callId) {
    if(Platform.isIOS) {
      return _methodChannel.invokeMethod<String>(kMethodDvcGetCallKitUUID, 
         {kArgCallId:sip_callId});
    }
    return null;
  }


  ////////////////////////////////////////////////////////////////////////////////////////
  //Android specific implementation

  Future<void>? setForegroundMode(bool enabled) {
    if(Platform.isAndroid) {
      return _methodChannel.invokeMethod<void>(kMethodDvcSetForegroundMode,
        {kArgForeground:enabled} );
    }
    return null;
  }

  Future<bool?>? isForegroundMode() {
    if(Platform.isAndroid) {
      return _methodChannel.invokeMethod<bool?>(kMethodDvcIsForegroundMode, {});
    }
    return null;
  }

}//SiprixVoipSdkPlatform


class _StubImplementation extends SiprixVoipSdkPlatform {}