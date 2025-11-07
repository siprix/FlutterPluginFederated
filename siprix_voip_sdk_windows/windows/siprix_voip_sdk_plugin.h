#ifndef FLUTTER_PLUGIN_SIPRIX_VOIP_SDK_PLUGIN_H_
#define FLUTTER_PLUGIN_SIPRIX_VOIP_SDK_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/encodable_value.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/texture_registrar.h>

#include <memory>
#include <map>

#include "siprix.framework/include/Siprix.h"

namespace siprix_voip_sdk {
class FlutterVideoRenderer;

class SiprixVoipSdkPlugin : public flutter::Plugin, public Siprix::ISiprixEventHandler {
 public:
  typedef std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> MethodChannelPtr;
  typedef flutter::MethodCall<flutter::EncodableValue> MethodCallEncVal;
  typedef std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> MethodResultEncValPtr;
  typedef std::function<void(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)> HandleFunc;

  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  SiprixVoipSdkPlugin()=default;
  SiprixVoipSdkPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~SiprixVoipSdkPlugin();

  // Disallow copy and assign.
  SiprixVoipSdkPlugin(const SiprixVoipSdkPlugin&) = delete;
  SiprixVoipSdkPlugin& operator=(const SiprixVoipSdkPlugin&) = delete;


  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(const MethodCallEncVal& method, MethodResultEncValPtr result);
  
  void handleModuleInitialize(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleModuleUnInitialize(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleModuleHomeFolder(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleModuleVersionCode(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleModuleVersion(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  
  void handleAccountAdd(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleAccountUpdate(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleAccountRegister(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleAccountUnregister(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleAccountDelete(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleAccountGenInstId(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  
  void handleCallInvite(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallReject(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallAccept(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallHold(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallGetHoldState(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallGetSipHeader(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallGetStats(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallMuteMic(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallMuteCam(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallSendDtmf(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallPlayFile(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallStopPlayFile(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallRecordFile(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallStopRecordFile(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallTransferBlind(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallTransferAttended(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallUpgradeToVideo(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallStopRingtone(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleCallBye(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);

  void handleMixerSwitchToCall(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleMixerMakeConference(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);

  void handleMessageSend(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);

  void handleSubscriptionAdd(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleSubscriptionDelete(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);

  void handleDvcGetPlayoutNumber(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleDvcGetRecordNumber(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleDvcGetVideoNumber(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleDvcGetPlayout(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleDvcGetRecording(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleDvcGetVideo(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleDvcSetPlayout(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleDvcSetRecording(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleDvcSetVideo(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleDvcSetVideoParams(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);

  void handleVideoRendererCreate(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleVideoRendererSetSrc(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);
  void handleVideoRendererDispose(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);  

  template <typename F>
  void doGetDevice(F getDeviceF, const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result);

  template <typename T>
  T parseValue(const char* name, const flutter::EncodableMap& argsMap, bool& bFound);
  
  void sendResult(Siprix::ErrorCode err, MethodResultEncValPtr& result);
  void sendBadArgResult(MethodResultEncValPtr& result);
    
  Siprix::AccData* parseAccountData(const flutter::EncodableMap& argsMap);
  void buildHandlersTable();

protected:
  //Event handlers
  void OnTrialModeNotified();
  void OnDevicesAudioChanged() override;
    
  void OnAccountRegState(Siprix::AccountId accId, Siprix::RegState state, const char* response) override;
  void OnSubscriptionState(Siprix::SubscriptionId subId, Siprix::SubscriptionState state, const char* response) override;
  void OnNetworkState(const char* name, Siprix::NetworkState state) override;
  void OnPlayerState(Siprix::PlayerId playerId, Siprix::PlayerState state) override;
  void OnRingerState(bool started) override;

  void OnCallProceeding(Siprix::CallId callId, const char* response) override;
  void OnCallTerminated(Siprix::CallId callId, uint32_t statusCode) override;
  void OnCallConnected(Siprix::CallId callId, const char* hdrFrom, const char* hdrTo, bool withVideo) override;
  void OnCallIncoming(Siprix::CallId callId, Siprix::AccountId accId, bool withVideo, const char* hdrFrom, const char* hdrTo) override;
  void OnCallDtmfReceived(Siprix::CallId callId, uint16_t tone) override;
  void OnCallTransferred(Siprix::CallId callId, uint32_t statusCode) override;
  void OnCallRedirected(Siprix::CallId origCallId, Siprix::CallId relatedCallId, const char* referTo)override;
  void OnCallVideoUpgraded(Siprix::CallId callId, bool withVideo) override;
  void OnCallHeld(Siprix::CallId callId, Siprix::HoldState state) override;
  void OnCallSwitched(Siprix::CallId callId) override;

  void OnMessageSentState(Siprix::MessageId messageId, bool success, const char* response);
  void OnMessageIncoming(Siprix::MessageId messageId, Siprix::AccountId accId, const char* hdrFrom, const char* body);

  void OnSipNotify(Siprix::AccountId accId, const char* hdrEvent, const char* body);
  void OnVuMeterLevel(int micLevel, int spkLevel);

protected:
   MethodChannelPtr channel_;
   flutter::TextureRegistrar* const textureRegistrar_ = nullptr;
   flutter::BinaryMessenger* const messenger_ = nullptr;
   std::map<int64_t, std::unique_ptr<FlutterVideoRenderer>> renderers_;
   std::map<std::string, HandleFunc> handlers_;
   Siprix::ISiprixModule* module_ = nullptr;
   
};

}  // namespace siprix_voip_sdk

#endif  // FLUTTER_PLUGIN_SIPRIX_VOIP_SDK_PLUGIN_H_
