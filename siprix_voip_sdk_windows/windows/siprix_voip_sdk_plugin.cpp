#include "siprix_voip_sdk_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_stream_handler_functions.h>

#include <sstream>
#include <memory>
#include <mutex>

namespace siprix_voip_sdk {

const char kNoArgumentsError[]         = "No argument. Map with fields expected";
const char kBadArgumentsError[]        = "Name/type of fields doesn't match expected";
const char kModuleNotInitializedError[] = "Siprix module has not initialized yet";

const char kChannelName[]               = "siprix_voip_sdk";

const char kMethodModuleInitialize[]    = "Module_Initialize";
const char kMethodModuleUnInitialize[]  = "Module_UnInitialize";
const char kMethodModuleHomeFolder[]    = "Module_HomeFolder";
const char kMethodModuleVersionCode[]   = "Module_VersionCode";
const char kMethodModuleVersion[]       = "Module_Version";
                                        
const char kMethodAccountAdd[]          = "Account_Add";
const char kMethodAccountUpdate[]       = "Account_Update";
const char kMethodAccountRegister[]     = "Account_Register";
const char kMethodAccountUnregister[]   = "Account_Unregister";
const char kMethodAccountDelete[]       = "Account_Delete";
const char kMethodAccountGenInstId[]    = "Account_GenInstId";

const char kMethodCallInvite[]          = "Call_Invite";
const char kMethodCallReject[]          = "Call_Reject";
const char kMethodCallAccept[]          = "Call_Accept";
const char kMethodCallHold[]            = "Call_Hold";
const char kMethodCallGetHoldState[]    = "Call_GetHoldState";
const char kMethodCallGetSipHeader[]    = "Call_GetSipHeader";
const char kMethodCallMuteMic[]         = "Call_MuteMic";
const char kMethodCallMuteCam[]         = "Call_MuteCam";
const char kMethodCallSendDtmf[]        = "Call_SendDtmf";
const char kMethodCallPlayFile[]        = "Call_PlayFile";
const char kMethodCallStopPlayFile[]    = "Call_StopPlayFile";
const char kMethodCallRecordFile[]      = "Call_RecordFile";
const char kMethodCallStopRecordFile[]  = "Call_StopRecordFile";
const char kMethodCallTransferBlind[]   = "Call_TransferBlind";
const char kMethodCallTransferAttended[]= "Call_TransferAttended";
const char kMethodCallStopRingtone[]    = "Call_StopRingtone";
const char kMethodCallBye[]             = "Call_Bye";

const char kMethodMixerSwitchToCall[]   = "Mixer_SwitchToCall";
const char kMethodMixerMakeConference[] = "Mixer_MakeConference";

const char kMethodMessageSend[]         = "Message_Send";

const char kMethodSubscriptionAdd[]     = "Subscription_Add";
const char kMethodSubscriptionDelete[]  = "Subscription_Delete";

const char kMethodDvcGetPlayoutNumber[] = "Dvc_GetPlayoutDevices";
const char kMethodDvcGetRecordNumber[]  = "Dvc_GetRecordingDevices";
const char kMethodDvcGetVideoNumber[]   = "Dvc_GetVideoDevices";
const char kMethodDvcGetPlayout[]       = "Dvc_GetPlayoutDevice";
const char kMethodDvcGetRecording[]     = "Dvc_GetRecordingDevice";
const char kMethodDvcGetVideo[]         = "Dvc_GetVideoDevice";
const char kMethodDvcSetPlayout[]       = "Dvc_SetPlayoutDevice";
const char kMethodDvcSetRecording[]     = "Dvc_SetRecordingDevice";
const char kMethodDvcSetVideo[]         = "Dvc_SetVideoDevice";
const char kMethodDvcSetVideoParams[]   = "Dvc_SetVideoParams";

const char kMethodVideoRendererCreate[] = "Video_RendererCreate";
const char kMethodVideoRendererSetSrc[] = "Video_RendererSetSrc";
const char kMethodVideoRendererDispose[]= "Video_RendererDispose";

const char kOnTrialModeNotif[]   = "OnTrialModeNotif";
const char kOnDevicesChanged[]   = "OnDevicesChanged";

const char kOnAccountRegState[]  = "OnAccountRegState";
const char kOnSubscriptionState[]= "OnSubscriptionState";
const char kOnNetworkState[]     = "OnNetworkState";
const char kOnPlayerState[]      = "OnPlayerState";
const char kOnRingerState[]      = "OnRingerState";

const char kOnCallProceeding[]   = "OnCallProceeding";
const char kOnCallTerminated[]   = "OnCallTerminated";
const char kOnCallConnected[]    = "OnCallConnected";
const char kOnCallIncoming[]     = "OnCallIncoming";
const char kOnCallDtmfReceived[] = "OnCallDtmfReceived";
const char kOnCallTransferred[]  = "OnCallTransferred";
const char kOnCallRedirected[]   = "OnCallRedirected";
const char kOnCallSwitched[]     = "OnCallSwitched";
const char kOnCallHeld[]         = "OnCallHeld";

const char kOnMessageSentState[] = "OnMessageSentState";
const char kOnMessageIncoming[]  = "OnMessageIncoming";

const char kArgVideoTextureId[]  = "videoTextureId";

const char kArgStatusCode[] = "statusCode";
const char kArgExpireTime[] = "expireTime";
const char kArgWithVideo[]  = "withVideo";

const char kArgDvcIndex[]   = "dvcIndex";
const char kArgDvcName[]    = "dvcName";
const char kArgDvcGuid[]    = "dvcGuid";

const char kArgCallId[]     = "callId";
const char kArgFromCallId[] = "fromCallId";
const char kArgToCallId[]   = "toCallId";
const char kArgToExt[]      = "toExt";
  
const char kArgAccId[]    = "accId";
const char kArgPlayerId[] = "playerId";
const char kArgSubscrId[] = "subscrId";
const char kArgMsgId[]    = "msgId";
const char kRegState[]    = "regState";
const char kHoldState[]   = "holdState";
const char kNetState[]    = "netState";
const char kPlayerState[] = "playerState";
const char kSubscrState[] = "subscrState";

const char kResponse[] = "response";
const char kSuccess[]  = "success";
const char kArgName[]  = "name";
const char kArgTone[]  = "tone";
const char kFrom[]     = "from";
const char kTo[]       = "to";
const char kBody[]     = "body";

// static
void SiprixVoipSdkPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  
  auto plugin = std::make_unique<SiprixVoipSdkPlugin>(registrar);

  registrar->AddPlugin(std::move(plugin));
}

SiprixVoipSdkPlugin::SiprixVoipSdkPlugin(flutter::PluginRegistrarWindows* registrar)
  : textureRegistrar_(registrar->texture_registrar()), 
    messenger_(registrar->messenger())
{
    channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), kChannelName,
            &flutter::StandardMethodCodec::GetInstance());

    channel_->SetMethodCallHandler(
        [plugin_pointer = this](const auto& call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        }
    );

    buildHandlersTable();
}

SiprixVoipSdkPlugin::~SiprixVoipSdkPlugin()
{
  if (module_) {
      Siprix::Callback_SetEventHandler(module_, nullptr);
      Siprix::Module_UnInitialize(module_);
      module_ = nullptr;

      for(auto& r : renderers_)
        textureRegistrar_->UnregisterTexture(r.first);
  }

  renderers_.clear();
}

void SiprixVoipSdkPlugin::buildHandlersTable()
{
     handlers_[kMethodModuleInitialize]     = std::bind(&SiprixVoipSdkPlugin::handleModuleInitialize,   this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodModuleUnInitialize]   = std::bind(&SiprixVoipSdkPlugin::handleModuleUnInitialize, this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodModuleHomeFolder]     = std::bind(&SiprixVoipSdkPlugin::handleModuleHomeFolder,   this, std::placeholders::_1, std::placeholders::_2);     
     handlers_[kMethodModuleVersionCode]    = std::bind(&SiprixVoipSdkPlugin::handleModuleVersionCode,  this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodModuleVersion]        = std::bind(&SiprixVoipSdkPlugin::handleModuleVersion,      this, std::placeholders::_1, std::placeholders::_2);
                                     
     handlers_[kMethodAccountAdd]           = std::bind(&SiprixVoipSdkPlugin::handleAccountAdd,         this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodAccountUpdate]        = std::bind(&SiprixVoipSdkPlugin::handleAccountUpdate,      this, std::placeholders::_1, std::placeholders::_2);
                                     
     handlers_[kMethodAccountRegister]      = std::bind(&SiprixVoipSdkPlugin::handleAccountRegister,    this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodAccountUnregister]    = std::bind(&SiprixVoipSdkPlugin::handleAccountUnregister,  this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodAccountDelete]        = std::bind(&SiprixVoipSdkPlugin::handleAccountDelete,      this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodAccountGenInstId]     = std::bind(&SiprixVoipSdkPlugin::handleAccountGenInstId,   this, std::placeholders::_1, std::placeholders::_2);

     handlers_[kMethodCallInvite]           = std::bind(&SiprixVoipSdkPlugin::handleCallInvite,         this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodCallReject]           = std::bind(&SiprixVoipSdkPlugin::handleCallReject,         this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodCallAccept]           = std::bind(&SiprixVoipSdkPlugin::handleCallAccept,         this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodCallHold]             = std::bind(&SiprixVoipSdkPlugin::handleCallHold,           this, std::placeholders::_1, std::placeholders::_2);    
     handlers_[kMethodCallGetHoldState]     = std::bind(&SiprixVoipSdkPlugin::handleCallGetHoldState,   this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodCallGetSipHeader]     = std::bind(&SiprixVoipSdkPlugin::handleCallGetSipHeader,   this, std::placeholders::_1, std::placeholders::_2);     
     handlers_[kMethodCallMuteMic]          = std::bind(&SiprixVoipSdkPlugin::handleCallMuteMic,        this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodCallMuteCam]          = std::bind(&SiprixVoipSdkPlugin::handleCallMuteCam,        this, std::placeholders::_1, std::placeholders::_2);     
     handlers_[kMethodCallSendDtmf]         = std::bind(&SiprixVoipSdkPlugin::handleCallSendDtmf,       this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodCallPlayFile]         = std::bind(&SiprixVoipSdkPlugin::handleCallPlayFile,       this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodCallStopPlayFile]     = std::bind(&SiprixVoipSdkPlugin::handleCallStopPlayFile,   this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodCallRecordFile]       = std::bind(&SiprixVoipSdkPlugin::handleCallRecordFile,     this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodCallStopRecordFile]   = std::bind(&SiprixVoipSdkPlugin::handleCallStopRecordFile, this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodCallTransferBlind]    = std::bind(&SiprixVoipSdkPlugin::handleCallTransferBlind,  this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodCallTransferAttended] = std::bind(&SiprixVoipSdkPlugin::handleCallTransferAttended, this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodCallStopRingtone]     = std::bind(&SiprixVoipSdkPlugin::handleCallStopRingtone,   this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodCallBye]              = std::bind(&SiprixVoipSdkPlugin::handleCallBye,            this, std::placeholders::_1, std::placeholders::_2);
     
     handlers_[kMethodMixerSwitchToCall]    = std::bind(&SiprixVoipSdkPlugin::handleMixerSwitchToCall,   this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodMixerMakeConference]  = std::bind(&SiprixVoipSdkPlugin::handleMixerMakeConference, this, std::placeholders::_1, std::placeholders::_2);

     handlers_[kMethodMessageSend]          = std::bind(&SiprixVoipSdkPlugin::handleMessageSend,         this, std::placeholders::_1, std::placeholders::_2);

     handlers_[kMethodSubscriptionAdd]      = std::bind(&SiprixVoipSdkPlugin::handleSubscriptionAdd,     this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodSubscriptionDelete]   = std::bind(&SiprixVoipSdkPlugin::handleSubscriptionDelete,  this, std::placeholders::_1, std::placeholders::_2);

     handlers_[kMethodDvcGetPlayoutNumber]  = std::bind(&SiprixVoipSdkPlugin::handleDvcGetPlayoutNumber, this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodDvcGetRecordNumber]   = std::bind(&SiprixVoipSdkPlugin::handleDvcGetRecordNumber,  this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodDvcGetVideoNumber]    = std::bind(&SiprixVoipSdkPlugin::handleDvcGetVideoNumber,   this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodDvcGetPlayout]        = std::bind(&SiprixVoipSdkPlugin::handleDvcGetPlayout,       this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodDvcGetRecording]      = std::bind(&SiprixVoipSdkPlugin::handleDvcGetRecording,     this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodDvcGetVideo]          = std::bind(&SiprixVoipSdkPlugin::handleDvcGetVideo,         this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodDvcSetPlayout]        = std::bind(&SiprixVoipSdkPlugin::handleDvcSetPlayout,       this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodDvcSetRecording]      = std::bind(&SiprixVoipSdkPlugin::handleDvcSetRecording,     this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodDvcSetVideo]          = std::bind(&SiprixVoipSdkPlugin::handleDvcSetVideo,         this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodDvcSetVideoParams]    = std::bind(&SiprixVoipSdkPlugin::handleDvcSetVideoParams,   this, std::placeholders::_1, std::placeholders::_2);     

     handlers_[kMethodVideoRendererCreate]  = std::bind(&SiprixVoipSdkPlugin::handleVideoRendererCreate, this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodVideoRendererSetSrc]  = std::bind(&SiprixVoipSdkPlugin::handleVideoRendererSetSrc, this, std::placeholders::_1, std::placeholders::_2);
     handlers_[kMethodVideoRendererDispose] = std::bind(&SiprixVoipSdkPlugin::handleVideoRendererDispose,this, std::placeholders::_1, std::placeholders::_2);
}


void SiprixVoipSdkPlugin::HandleMethodCall(const MethodCallEncVal& method, MethodResultEncValPtr result)
{
  const flutter::EncodableMap* argsMap = std::get_if<flutter::EncodableMap>(method.arguments());
  if (!argsMap) {
    result->Error("-", std::string(kNoArgumentsError));
    return;
  }

  if(module_) {
    auto it = handlers_.find(method.method_name());
    if(it != handlers_.end())
        it->second(*argsMap, result);
    else
        result->NotImplemented();
  }
  else{
    if(method.method_name().compare(kMethodModuleInitialize)  == 0)  
        handleModuleInitialize(*argsMap, result);
    else 
        result->Error(std::string("UNAVAILABLE"), std::string(kModuleNotInitializedError));
  }
  
}//HandleMethodCall



////////////////////////////////////////////////////////////////////////////////////////
//FlutterVideoRenderer

class FlutterVideoRenderer : public Siprix::IVideoRenderer
{
public:    
    FlutterVideoRenderer(flutter::TextureRegistrar* registrar);
    ~FlutterVideoRenderer();

    int64_t registerTextureAndCreateChannel(flutter::BinaryMessenger* messenger);
    
    void initialize(flutter::TextureRegistrar* registrar,
        std::unique_ptr<flutter::TextureVariant> texture, int64_t texture_id,
        flutter::BinaryMessenger* messenger);

    const FlutterDesktopPixelBuffer* CopyPixelBuffer(size_t width, size_t height);

    void OnFrame(Siprix::IVideoFrame* frame) override;

    Siprix::CallId getSrcCallId() const { return srcCallId_; }
    void setSrcCallId(Siprix::CallId id) { srcCallId_ = id;  }

private:
    void eventChannelSend(const flutter::EncodableValue& event, bool cache_event = true);
    void createEventChannel(flutter::BinaryMessenger* messenger);
    void convertToRgb(Siprix::IVideoFrame* frame);
    void sendEvent(Siprix::IVideoFrame* frame);    

    flutter::TextureRegistrar* const textureRegistrar_;

    struct EventData { 
        int width = 0; 
        int height= 0; 
        Siprix::IVideoFrame::Rotation rotation_ = Siprix::IVideoFrame::kRotation_0;
    };
    EventData event_data_;
    
    //Event channel    
    std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
    std::list<flutter::EncodableValue> event_queue_;
    bool on_listen_called_ = false;

    //Texture
    int64_t texture_id_ = -1;
    std::unique_ptr<flutter::TextureVariant> texture_;
    struct FrameData {
        std::shared_ptr<FlutterDesktopPixelBuffer> pixel_buffer_;
        std::shared_ptr<uint8_t> rgb_buffer_;
        bool fresh_ = false;
    };
    std::mutex mutex_;
    FrameData first_;
    FrameData second_;

    Siprix::CallId srcCallId_ = 0;
    bool isRemote_ = false;
};


////////////////////////////////////////////////////////////////////////////////////////
//Siprix module methods implementation

void SiprixVoipSdkPlugin::handleModuleInitialize(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    //Check already created
    if (module_) {
        result->Success(flutter::EncodableValue("Already created"));
        return;
    }

    //Create
    module_ = Siprix::Module_Create();
    if (!module_) {
        result->Error("-", "Can't create module instance");
        return;
    }

    //Get params
    Siprix::IniData* iniData = Siprix::Ini_GetDefault();
    
    for(const auto& val : argsMap) {
        const std::string* valName = std::get_if<std::string>(&val.first);
        if(!valName) continue;

        const std::string* strVal = std::get_if<std::string>(&val.second);
        if(strVal) {
            if(valName->compare("license")   == 0)   Siprix::Ini_SetLicense(iniData,      strVal->c_str());else
            if(valName->compare("brandName") == 0)   Siprix::Ini_SetBrandName(iniData,    strVal->c_str());
            continue;
        }

        const int32_t* intVal = std::get_if<int32_t>(&val.second);
        if(intVal) {
          if(valName->compare("logLevelFile") == 0) Siprix::Ini_SetLogLevelFile(iniData, static_cast<uint8_t>(*intVal)); else
          if(valName->compare("logLevelIde") == 0)  Siprix::Ini_SetLogLevelIde(iniData, static_cast<uint8_t>(*intVal)); else
          if(valName->compare("rtpStartPort") == 0) Siprix::Ini_SetRtpStartPort(iniData, static_cast<uint16_t>(*intVal));
          continue;
        }

        const bool* boolVal = std::get_if<bool>(&val.second);
        if(boolVal) {
          if(valName->compare("tlsVerifyServer") == 0)   Siprix::Ini_SetTlsVerifyServer(iniData, *boolVal); else
          if(valName->compare("singleCallMode") == 0)    Siprix::Ini_SetSingleCallMode(iniData, *boolVal); else
          if(valName->compare("shareUdpTransport") == 0) Siprix::Ini_SetShareUdpTransport(iniData, *boolVal); else
          if(valName->compare("unregOnDestroy") == 0)    Siprix::Ini_SetUnregOnDestroy(iniData, *boolVal); else
          if(valName->compare("useDnsSrv") == 0)         Siprix::Ini_SetUseDnsSrv(iniData, *boolVal); else
          if(valName->compare("recordStereo") == 0)      Siprix::Ini_SetRecordStereo(iniData, *boolVal); else
          if(valName->compare("enableVideoCall") == 0)   Siprix::Ini_SetVideoCallEnabled(iniData, *boolVal); else
          if(valName->compare("transpForceIPv4") == 0)   Siprix::Ini_SetTranspForceIPv4(iniData, *boolVal);
          continue;
        }  
    
    }//for
    
    //Initialize
    const Siprix::ErrorCode err = Siprix::Module_Initialize(module_, iniData);

    //Set event handler
    if (err == Siprix::EOK)
      Siprix::Callback_SetEventHandler(module_, this);

    //Send result
    sendResult(err, result);

}//handleModuleInitialize


void SiprixVoipSdkPlugin::handleModuleUnInitialize(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    const Siprix::ErrorCode err = Siprix::Module_UnInitialize(module_);
    module_ = nullptr;
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleModuleHomeFolder(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    std::string path = Siprix::Module_HomeFolder(module_);
    result->Success(flutter::EncodableValue(path));
}

void SiprixVoipSdkPlugin::handleModuleVersionCode(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    const int32_t versionCode = Siprix::Module_VersionCode(module_);
    result->Success(flutter::EncodableValue(versionCode));
}

void SiprixVoipSdkPlugin::handleModuleVersion(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    std::string version = Siprix::Module_Version(module_);
    result->Success(flutter::EncodableValue(version));
}

////////////////////////////////////////////////////////////////////////////////////////
//Siprix Account methods implementation

Siprix::AccData* SiprixVoipSdkPlugin::parseAccountData(const flutter::EncodableMap& argsMap)
{
  Siprix::AccData* accData = Siprix::Acc_GetDefault();

  for(const auto& val : argsMap) {
    const std::string* valName = std::get_if<std::string>(&val.first);
    if(!valName) continue;

    const std::string* strVal = std::get_if<std::string>(&val.second);
    if(strVal) {
        if(valName->compare("sipServer")     == 0) Siprix::Acc_SetSipServer(accData,      strVal->c_str()); else
        if(valName->compare("sipExtension")  == 0) Siprix::Acc_SetSipExtension(accData,   strVal->c_str()); else
        if(valName->compare("sipAuthId")     == 0) Siprix::Acc_SetSipAuthId(accData,      strVal->c_str()); else
        if(valName->compare("sipPassword")   == 0) Siprix::Acc_SetSipPassword(accData,    strVal->c_str()); else        
        if(valName->compare("sipProxy")      == 0) Siprix::Acc_SetSipProxyServer(accData, strVal->c_str()); else
        if(valName->compare("displName")     == 0) Siprix::Acc_SetDisplayName(accData,    strVal->c_str()); else
        if(valName->compare("userAgent")     == 0) Siprix::Acc_SetUserAgent(accData,      strVal->c_str()); else
        if(valName->compare("tlsCaCertPath") == 0) Siprix::Acc_SetTranspTlsCaCert(accData,strVal->c_str()); else
        if(valName->compare("ringTonePath")  == 0) Siprix::Acc_SetRingToneFile(accData,   strVal->c_str()); else
        if(valName->compare("instanceId")    == 0) Siprix::Acc_SetInstanceId(accData,     strVal->c_str()); else
        if(valName->compare("stunServer")    == 0) Siprix::Acc_SetStunServer(accData,     strVal->c_str()); else
        if(valName->compare("turnServer")    == 0) Siprix::Acc_SetTurnServer(accData,     strVal->c_str()); else
        if(valName->compare("turnUser")      == 0) Siprix::Acc_SetTurnUser(accData,       strVal->c_str()); else
        if(valName->compare("turnPassword")  == 0) Siprix::Acc_SetTurnPassword(accData,   strVal->c_str());
        continue;
    }

    const int32_t* intVal = std::get_if<int32_t>(&val.second);
    if(intVal) {
      if(valName->compare("expireTime") == 0)    Siprix::Acc_SetExpireTime(accData,     *intVal); else
      if(valName->compare("secureMedia") == 0)   Siprix::Acc_SetSecureMediaMode(accData,static_cast<Siprix::SecureMedia>(*intVal)); else
      if(valName->compare("transport") == 0)     Siprix::Acc_SetTranspProtocol(accData, static_cast<Siprix::SipTransport>(*intVal)); else
      if(valName->compare("port")      == 0)     Siprix::Acc_SetTranspPort(accData,     static_cast<uint16_t>(*intVal));else
      if(valName->compare("keepAliveTime") == 0) Siprix::Acc_SetKeepAliveTime(accData,  static_cast<uint32_t>(*intVal));
      continue;
    }

    const bool* boolVal = std::get_if<bool>(&val.second);
    if(boolVal) {
      if(valName->compare("rewriteContactIp") == 0)   Siprix::Acc_SetRewriteContactIp(accData,   *boolVal);else
      if(valName->compare("verifyIncomingCall") == 0) Siprix::Acc_SetVerifyIncomingCall(accData, *boolVal);else
      if(valName->compare("forceSipProxy") == 0)      Siprix::Acc_SetForceSipProxy(accData,      *boolVal);else
      if(valName->compare("tlsUseSipScheme") == 0)  Siprix::Acc_SetUseSipSchemeForTls(accData, *boolVal);else
      if(valName->compare("rtcpMuxEnabled") == 0)   Siprix::Acc_SetRtcpMuxEnabled(accData,     *boolVal);else
      if(valName->compare("iceEnabled") == 0)       Siprix::Acc_SetIceEnabled(accData, *boolVal);        
      continue;
    }
    
    const auto* mapVal = std::get_if<flutter::EncodableMap>(&val.second);
    if(mapVal && (valName->compare("xheaders") == 0)) {
      for(const auto& xHdr : *mapVal) {
        const std::string* xHdrName  = std::get_if<std::string>(&xHdr.first);
        const std::string* xHdrValue = std::get_if<std::string>(&xHdr.second);
        if(xHdrName && xHdrValue) Siprix::Acc_AddXHeader(accData, xHdrName->c_str(), xHdrValue->c_str());
      }
    }

    if(mapVal && (valName->compare("xContactUriParams") == 0)) {
      for(const auto& xHdr : *mapVal) {
        const std::string* xParamName  = std::get_if<std::string>(&xHdr.first);
        const std::string* xParamValue = std::get_if<std::string>(&xHdr.second);
        if(xParamName && xParamValue) Siprix::Acc_AddXContactUriParam(accData, xParamName->c_str(), xParamValue->c_str());
      }
    }

    const auto* listVal = std::get_if<flutter::EncodableList>(&val.second);
    if(listVal && (valName->compare("aCodecs") == 0)) {
        Siprix::Acc_ResetAudioCodecs(accData);
        for(const auto& listItem : *listVal) {
            const int32_t* codecVal = std::get_if<int32_t>(&listItem);
            if(codecVal) Siprix::Acc_AddAudioCodec(accData, static_cast<Siprix::AudioCodec>(*codecVal));
        }
    }

    if(listVal && (valName->compare("vCodecs") == 0)) {
        Siprix::Acc_ResetVideoCodecs(accData);
        for(const auto& listItem : *listVal) {
            const int32_t* codecVal = std::get_if<int32_t>(&listItem);
            if(codecVal) Siprix::Acc_AddVideoCodec(accData, static_cast<Siprix::VideoCodec>(*codecVal));
        }
    }
    
  }//for

  return accData;
}


void SiprixVoipSdkPlugin::handleAccountAdd(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
  Siprix::AccData* accData = parseAccountData(argsMap);

  Siprix::AccountId accId=0;
  const Siprix::ErrorCode err = Siprix::Account_Add(module_, accData, &accId);
  auto accIdVal = flutter::EncodableValue(static_cast<int32_t>(accId));
  if(err == Siprix::EOK){
    result->Success(accIdVal);
  }else{
    result->Error(std::to_string(err), std::string(Siprix::GetErrorText(err)), accIdVal);
  }
}

void SiprixVoipSdkPlugin::handleAccountUpdate(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
  bool bFound;
  Siprix::AccData* accData = parseAccountData(argsMap);
  Siprix::AccountId accId  = parseValue<int32_t>(kArgAccId, argsMap, bFound);
  if (!bFound) { sendBadArgResult(result); return; }

  const Siprix::ErrorCode err = Siprix::Account_Update(module_, accData, accId);  
  sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleAccountRegister(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound1, bFound2;
    Siprix::AccountId accId = parseValue<int32_t>(kArgAccId, argsMap, bFound1);
    int32_t expireTime      = parseValue<int32_t>(kArgExpireTime, argsMap, bFound2);
    if (!bFound1 || !bFound2) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Account_Register(module_, accId, expireTime);
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleAccountUnregister(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound;
    Siprix::AccountId accId = parseValue<int32_t>(kArgAccId, argsMap, bFound);
    if (!bFound) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Account_Unregister(module_, accId);
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleAccountDelete(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound;
    Siprix::AccountId accId = parseValue<int32_t>(kArgAccId, argsMap, bFound);
    if (!bFound) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Account_Delete(module_, accId);
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleAccountGenInstId(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    std::string instId = Siprix::Acc_GenerateInstanceId();
    result->Success(flutter::EncodableValue(instId));
}

////////////////////////////////////////////////////////////////////////////////////////
//Siprix Calls methods implementation

void SiprixVoipSdkPlugin::handleCallInvite(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
  Siprix::DestData* destData = Siprix::Dest_GetDefault();
  
  for(const auto& val : argsMap) {
    const std::string* valName = std::get_if<std::string>(&val.first);
    if(!valName) continue;

    const std::string* strVal = std::get_if<std::string>(&val.second);
    if(strVal) {
        if(valName->compare("extension")   == 0) Siprix::Dest_SetExtension(destData, strVal->c_str());
        if(valName->compare("displName")   == 0) Siprix::Dest_SetDisplayName(destData, strVal->c_str());
        continue;
    }

    const int32_t* intVal = std::get_if<int32_t>(&val.second);
    if(intVal) {
      if(valName->compare(kArgAccId)       == 0)   Siprix::Dest_SetAccountId(destData,     *intVal);
      if(valName->compare("inviteTimeout") == 0)   Siprix::Dest_SetInviteTimeout(destData, *intVal);
      
      continue;
    }

    const bool* boolVal = std::get_if<bool>(&val.second);
    if (boolVal) {
        if (valName->compare(kArgWithVideo) == 0)   Siprix::Dest_SetVideoCall(destData, *boolVal);
        continue;
    }
    
    const auto* mapVal = std::get_if<flutter::EncodableMap>(&val.second);
    if(mapVal && (valName->compare("xheaders") == 0)) {
      for(const auto& xHdr : *mapVal) {
        const std::string* xHdrName  = std::get_if<std::string>(&xHdr.first);
        const std::string* xHdrValue = std::get_if<std::string>(&xHdr.second);
        if(xHdrName && xHdrValue) Siprix::Dest_AddXHeader(destData, xHdrName->c_str(), xHdrValue->c_str());
      }
    }
    
  }//for

  Siprix::CallId callId=0;
  const Siprix::ErrorCode err = Siprix::Call_Invite(module_, destData, &callId);
  if(err == Siprix::EOK){
    result->Success(flutter::EncodableValue(static_cast<int32_t>(callId)));
  }else{
    result->Error(std::to_string(err), std::string(Siprix::GetErrorText(err)));
  }
}

void SiprixVoipSdkPlugin::handleCallReject(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound1, bFound2;
    Siprix::CallId callId = parseValue<int32_t>(kArgCallId,     argsMap, bFound1);
    int32_t statusCode    = parseValue<int32_t>(kArgStatusCode, argsMap, bFound2);
    if (!bFound1 || !bFound2) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Call_Reject(module_, callId, static_cast<uint16_t>(statusCode));
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleCallAccept(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound1, bFound2;
    Siprix::CallId callId = parseValue<int32_t>(kArgCallId, argsMap, bFound1);
    bool withVideo        = parseValue<bool>(kArgWithVideo, argsMap, bFound2);
    if (!bFound1 || !bFound2) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Call_Accept(module_, callId, withVideo);
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleCallHold(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound;
    Siprix::CallId callId = parseValue<int32_t>(kArgCallId, argsMap, bFound);
    if (!bFound) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Call_Hold(module_, callId);

    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleCallGetHoldState(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound;
    Siprix::HoldState state;
    Siprix::CallId callId = parseValue<int32_t>(kArgCallId, argsMap, bFound);
    if (!bFound) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Call_GetHoldState(module_, callId, &state);

    if (err == Siprix::EOK) result->Success(flutter::EncodableValue(static_cast<int32_t>(state)));
    else                    result->Error(std::to_string(err), std::string(Siprix::GetErrorText(err)));
}

void SiprixVoipSdkPlugin::handleCallGetSipHeader(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound, bFound2;
    Siprix::CallId callId = parseValue<int32_t>(kArgCallId, argsMap, bFound);
    std::string hdrName = parseValue<std::string>("hdrName", argsMap, bFound2);
    if (!bFound || !bFound2) { sendBadArgResult(result); return; }

    std::string headerVal;
    uint32_t headerValLen = 0;
    Siprix::Call_GetSipHeader(module_, callId, hdrName.c_str(), nullptr, &headerValLen);
    if (headerValLen > 0) {
        headerVal.resize(headerValLen);
        Siprix::Call_GetSipHeader(module_, callId, hdrName.c_str(), &headerVal[0], &headerValLen);
    }
    result->Success(flutter::EncodableValue(headerVal));
}

void SiprixVoipSdkPlugin::handleCallMuteMic(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound1, bFound2;
    Siprix::CallId callId = parseValue<int32_t>(kArgCallId, argsMap, bFound1);
    bool mute             = parseValue<bool>("mute", argsMap, bFound2);
    if (!bFound1 || !bFound2) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Call_MuteMic(module_, callId, mute);
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleCallMuteCam(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound1, bFound2;
    Siprix::CallId callId = parseValue<int32_t>(kArgCallId, argsMap, bFound1);
    bool mute             = parseValue<bool>("mute", argsMap, bFound2);
    if (!bFound1 || !bFound2) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Call_MuteCam(module_, callId, mute);
    sendResult(err, result);
}


void SiprixVoipSdkPlugin::handleCallSendDtmf(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound1, bFound2, bFound3, bFound4, bFound5;
    Siprix::CallId callId = parseValue<int32_t>(kArgCallId, argsMap, bFound1);
    int32_t durationMs    = parseValue<int32_t>("durationMs", argsMap, bFound2);
    int32_t intertoneGapMs= parseValue<int32_t>("intertoneGapMs", argsMap, bFound3);
    int32_t method        = parseValue<int32_t>("method", argsMap, bFound4);
    std::string dtmfs     = parseValue<std::string>("dtmfs", argsMap, bFound5);
    if (!bFound1 || !bFound2 || !bFound3 || !bFound4 || !bFound5) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Call_SendDtmf(module_, callId, dtmfs.c_str(), 
        static_cast<uint16_t>(durationMs), static_cast<uint16_t>(intertoneGapMs), 
        static_cast<Siprix::DtmfMethod>(method));
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleCallPlayFile(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{    
    bool bFound1, bFound2, bFound3;
    Siprix::CallId callId     = parseValue<int32_t>(kArgCallId, argsMap, bFound1);
    std::string pathToMp3File = parseValue<std::string>("pathToMp3File", argsMap, bFound2);
    const bool loop           = parseValue<bool>("loop", argsMap, bFound3);
    if (!bFound1 || !bFound2 || !bFound3) { sendBadArgResult(result); return; }

    Siprix::PlayerId playerId = 0;
    const Siprix::ErrorCode err = Siprix::Call_PlayFile(module_, callId, pathToMp3File.c_str(), loop, &playerId);

    if (err == Siprix::EOK) result->Success(flutter::EncodableValue(static_cast<int32_t>(playerId)));
    else                    result->Error(std::to_string(err), std::string(Siprix::GetErrorText(err)));
}

void SiprixVoipSdkPlugin::handleCallStopPlayFile(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound;
    Siprix::PlayerId playerId = parseValue<int32_t>(kArgPlayerId, argsMap, bFound);
    if (!bFound) { sendBadArgResult(result); return; }
    
    const Siprix::ErrorCode err = Siprix::Call_StopPlayFile(module_, playerId);
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleCallRecordFile(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound1, bFound2;
    Siprix::CallId callId     = parseValue<int32_t>(kArgCallId, argsMap, bFound1);
    std::string pathToMp3File = parseValue<std::string>("pathToMp3File", argsMap, bFound2);
    if (!bFound1 || !bFound2) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Call_RecordFile(module_, callId, pathToMp3File.c_str());
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleCallStopRecordFile(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound;
    Siprix::CallId playerId = parseValue<int32_t>(kArgCallId, argsMap, bFound);
    if (!bFound) { sendBadArgResult(result); return; }
    
    const Siprix::ErrorCode err = Siprix::Call_StopRecordFile(module_, playerId);
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleCallTransferBlind(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound1, bFound2;
    Siprix::CallId callId = parseValue<int32_t>(kArgCallId, argsMap, bFound1);
    std::string toExt     = parseValue<std::string>(kArgToExt, argsMap, bFound2);
    if (!bFound1 || !bFound2) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Call_TransferBlind(module_, callId, toExt.c_str());
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleCallStopRingtone(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    const Siprix::ErrorCode err = Siprix::Call_StopRingtone(module_);
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleCallTransferAttended(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound1, bFound2;
    Siprix::CallId fromCallId = parseValue<int32_t>(kArgFromCallId, argsMap, bFound1);
    Siprix::CallId toCallId   = parseValue<int32_t>(kArgToCallId, argsMap, bFound2);
    if (!bFound1 || !bFound2) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Call_TransferAttended(module_, fromCallId, toCallId);
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleCallBye(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound;
    Siprix::CallId callId = parseValue<int32_t>(kArgCallId, argsMap, bFound);
    if (!bFound) { sendBadArgResult(result); return; }
    
    const Siprix::ErrorCode err = Siprix::Call_Bye(module_, callId);
    sendResult(err, result);
}

////////////////////////////////////////////////////////////////////////////////////////
//Siprix Mixer methods implementation

void SiprixVoipSdkPlugin::handleMixerSwitchToCall(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound;
    Siprix::CallId callId = parseValue<int32_t>(kArgCallId, argsMap, bFound);
    if (!bFound) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Mixer_SwitchToCall(module_, callId);
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleMixerMakeConference(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    const Siprix::ErrorCode err = Siprix::Mixer_MakeConference(module_);
    sendResult(err, result);
}

////////////////////////////////////////////////////////////////////////////////////////
//Siprix message

void SiprixVoipSdkPlugin::handleMessageSend(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
  Siprix::MsgData* msgData = Siprix::Msg_GetDefault();
  
  for(const auto& val : argsMap) {
    const std::string* valName = std::get_if<std::string>(&val.first);
    if(!valName) continue;

    const std::string* strVal = std::get_if<std::string>(&val.second);
    if(strVal) {
        if(valName->compare("extension") == 0) Siprix::Msg_SetExtension(msgData, strVal->c_str());
        if(valName->compare(kBody) == 0)       Siprix::Msg_SetBody(msgData, strVal->c_str());
        continue;
    }

    const int32_t* intVal = std::get_if<int32_t>(&val.second);
    if(intVal) {
      if(valName->compare(kArgAccId)    == 0)   Siprix::Msg_SetAccountId(msgData,  *intVal);
      continue;
    }
  }//for

  Siprix::MessageId msgId=0;
  const Siprix::ErrorCode err = Siprix::Message_Send(module_, msgData, &msgId);
  auto msgIdVal = flutter::EncodableValue(static_cast<int32_t>(msgId));
  if(err == Siprix::EOK){
    result->Success(msgIdVal);
  }else{
    result->Error(std::to_string(err), std::string(Siprix::GetErrorText(err)));
  }
}

////////////////////////////////////////////////////////////////////////////////////////
//Siprix subscriptions

void SiprixVoipSdkPlugin::handleSubscriptionAdd(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
  Siprix::SubscrData* subscrData = Siprix::Subscr_GetDefault();
  
  for(const auto& val : argsMap) {
    const std::string* valName = std::get_if<std::string>(&val.first);
    if(!valName) continue;

    const std::string* strVal = std::get_if<std::string>(&val.second);
    if(strVal) {
        if(valName->compare("extension")   == 0) Siprix::Subscr_SetExtension(subscrData, strVal->c_str());
        if(valName->compare("mimeSubType") == 0) Siprix::Subscr_SetMimeSubtype(subscrData, strVal->c_str());
        if(valName->compare("eventType")   == 0) Siprix::Subscr_SetEventType(subscrData, strVal->c_str());
        continue;
    }

    const int32_t* intVal = std::get_if<int32_t>(&val.second);
    if(intVal) {
      if(valName->compare(kArgAccId)    == 0)   Siprix::Subscr_SetAccountId(subscrData,  *intVal);
      if(valName->compare("expireTime") == 0)   Siprix::Subscr_SetExpireTime(subscrData, *intVal);
      continue;
    }
  }//for

  Siprix::SubscriptionId subscrId=0;
  const Siprix::ErrorCode err = Siprix::Subscription_Create(module_, subscrData, &subscrId);
  auto subscrIdVal = flutter::EncodableValue(static_cast<int32_t>(subscrId));
  if(err == Siprix::EOK){
    result->Success(subscrIdVal);
  }else{
    result->Error(std::to_string(err), std::string(Siprix::GetErrorText(err)), subscrIdVal);
  }
}

void SiprixVoipSdkPlugin::handleSubscriptionDelete(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound;
    Siprix::SubscriptionId subscrId = parseValue<int32_t>(kArgSubscrId, argsMap, bFound);
    if (!bFound) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Subscription_Destroy(module_, subscrId);
    sendResult(err, result);
}

////////////////////////////////////////////////////////////////////////////////////////
//Siprix Devices methods implementation

void SiprixVoipSdkPlugin::handleDvcGetPlayoutNumber(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    uint32_t numberOfDevices = 0;
    Siprix::Dvc_GetPlayoutDevices(module_, &numberOfDevices);
    result->Success(flutter::EncodableValue(static_cast<int32_t>(numberOfDevices)));    
}

void SiprixVoipSdkPlugin::handleDvcGetRecordNumber(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    uint32_t numberOfDevices = 0;
    Siprix::Dvc_GetRecordingDevices(module_, &numberOfDevices);
    result->Success(flutter::EncodableValue(static_cast<int32_t>(numberOfDevices)));
}

void SiprixVoipSdkPlugin::handleDvcGetVideoNumber(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    uint32_t numberOfDevices = 0;
    Siprix::Dvc_GetVideoDevices(module_, &numberOfDevices);
    result->Success(flutter::EncodableValue(static_cast<int32_t>(numberOfDevices)));
}


template <typename F>
void SiprixVoipSdkPlugin::doGetDevice(F getDeviceF, const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound;
    const int32_t dvcIndex = parseValue<int32_t>(kArgDvcIndex, argsMap, bFound);
    if (!bFound) { sendBadArgResult(result); return; }

    char name[128] = "";
    char guid[128] = "";
    const Siprix::ErrorCode err = getDeviceF(module_, static_cast<uint16_t>(dvcIndex),
        name, sizeof(name), guid, sizeof(guid));

    if (err == Siprix::EOK) {
        flutter::EncodableMap retMap;
        retMap[flutter::EncodableValue(kArgDvcName)] = flutter::EncodableValue(std::string(name));
        retMap[flutter::EncodableValue(kArgDvcGuid)] = flutter::EncodableValue(std::string(guid));
        result->Success(flutter::EncodableValue(std::move(retMap)));
    }
    else {
        result->Error(std::to_string(err), std::string(Siprix::GetErrorText(err)));
    }
}

void SiprixVoipSdkPlugin::handleDvcGetPlayout(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    doGetDevice(Siprix::Dvc_GetPlayoutDevice, argsMap, result);
}

void SiprixVoipSdkPlugin::handleDvcGetRecording(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    doGetDevice(Siprix::Dvc_GetRecordingDevice, argsMap, result);
}

void SiprixVoipSdkPlugin::handleDvcGetVideo(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    doGetDevice(Siprix::Dvc_GetVideoDevice, argsMap, result);
}


void SiprixVoipSdkPlugin::handleDvcSetPlayout(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound;
    const int32_t dvcIndex = parseValue<int32_t>(kArgDvcIndex, argsMap, bFound);
    if (!bFound) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Dvc_SetPlayoutDevice(module_, static_cast<uint16_t>(dvcIndex));
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleDvcSetRecording(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound;
    const int32_t dvcIndex = parseValue<int32_t>(kArgDvcIndex, argsMap, bFound);
    if (!bFound) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Dvc_SetRecordingDevice(module_, static_cast<uint16_t>(dvcIndex));
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleDvcSetVideo(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound;
    const int32_t dvcIndex = parseValue<int32_t>(kArgDvcIndex, argsMap, bFound);
    if (!bFound) { sendBadArgResult(result); return; }

    const Siprix::ErrorCode err = Siprix::Dvc_SetVideoDevice(module_, static_cast<uint16_t>(dvcIndex));
    sendResult(err, result);
}

void SiprixVoipSdkPlugin::handleDvcSetVideoParams(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    Siprix::VideoData* vdoData = Siprix::Vdo_GetDefault();
    for(const auto& val : argsMap) {
        const std::string* valName = std::get_if<std::string>(&val.first);
        if(!valName) continue;

        const std::string* strVal = std::get_if<std::string>(&val.second);
        if(strVal) {
            if(valName->compare("noCameraImgPath")   == 0) Siprix::Vdo_SetNoCameraImgPath(vdoData, strVal->c_str());
            continue;
        }

        const int32_t* intVal = std::get_if<int32_t>(&val.second);
        if(intVal) {
            if(valName->compare("framerateFps")== 0)   Siprix::Vdo_SetFramerate(vdoData, *intVal);
            if(valName->compare("bitrateKbps") == 0)   Siprix::Vdo_SetBitrate(vdoData, *intVal);
            if(valName->compare("height")      == 0)   Siprix::Vdo_SetHeight(vdoData, *intVal);
            if(valName->compare("width")       == 0)   Siprix::Vdo_SetWidth(vdoData, *intVal);
        }
    }

    const Siprix::ErrorCode err = Siprix::Dvc_SetVideoParams(module_, vdoData);
    sendResult(err, result);
}



////////////////////////////////////////////////////////////////////////////////////////
//Siprix video renderers

void SiprixVoipSdkPlugin::handleVideoRendererCreate(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    auto renderer = std::make_unique<FlutterVideoRenderer>(textureRegistrar_);
    auto texture_id = renderer->registerTextureAndCreateChannel(messenger_);

    renderers_[texture_id] = std::move(renderer);
    
    result->Success(flutter::EncodableValue(texture_id));
}

void SiprixVoipSdkPlugin::handleVideoRendererSetSrc(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    bool bFound1, bFound2;
    Siprix::CallId callId = parseValue<int32_t>(kArgCallId, argsMap, bFound1);
    int64_t textureId     = parseValue<int64_t>(kArgVideoTextureId, argsMap, bFound2);

    if (!bFound1) { sendBadArgResult(result); return; }//ignore when missed 'textureId' - it's possible when flutter sends it as int32

    auto it = renderers_.find(textureId);
    if(it != renderers_.end()){
        FlutterVideoRenderer* renderer = it->second.get();
        
        const Siprix::ErrorCode err = Siprix::Call_SetVideoRenderer(module_, callId, renderer);
        renderer->setSrcCallId(callId);
        sendResult(err, result);
    }
    else{
        result->Success();
    }
}

void SiprixVoipSdkPlugin::handleVideoRendererDispose(const flutter::EncodableMap& argsMap, MethodResultEncValPtr& result)
{
    //Parse argument
    bool bFound;
    int64_t textureId = parseValue<int64_t>(kArgVideoTextureId, argsMap, bFound);
    if(!bFound) { sendBadArgResult(result); return; }

    auto it = renderers_.find(textureId);
    if (it == renderers_.end()) {
        result->Error("VideoRendererDispose failed", std::string("texture not found!"));
        return;
    }

    FlutterVideoRenderer* renderer = it->second.get();
    Siprix::Call_SetVideoRenderer(module_, renderer->getSrcCallId(), nullptr);

    textureRegistrar_->UnregisterTexture(textureId,
        [&, it] { renderers_.erase(it); });

    result->Success();
}

////////////////////////////////////////////////////////////////////////////////////////
//Helpers methods


void SiprixVoipSdkPlugin::sendResult(Siprix::ErrorCode err, MethodResultEncValPtr& result)
{
    if (err == Siprix::EOK) {
        result->Success(flutter::EncodableValue("Success"));
    }
    else {
        result->Error(std::to_string(err), std::string(Siprix::GetErrorText(err)));
    }
}

void SiprixVoipSdkPlugin::sendBadArgResult(MethodResultEncValPtr& result)
{
    result->Error("Bad argument", std::string(kBadArgumentsError));
}


template <typename T>
T SiprixVoipSdkPlugin::parseValue(const char* name, const flutter::EncodableMap& argsMap, bool& bFound)
{
    T retVal = T();
    bFound = false;
    auto it = argsMap.find(flutter::EncodableValue(name));
    if (it != argsMap.end()) {
        const T* val = std::get_if<T>(&it->second);
        if (val) { retVal = *val; bFound = true; }
    }
    return retVal;
}



//////////////////////////////////////////////////////////////////////////
//Event handlers

void SiprixVoipSdkPlugin::OnTrialModeNotified()
{
    flutter::EncodableMap argsMap;
    channel_->InvokeMethod(kOnTrialModeNotif,
        std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}

void SiprixVoipSdkPlugin::OnDevicesAudioChanged()
{
    flutter::EncodableMap argsMap;
    channel_->InvokeMethod(kOnDevicesChanged,
        std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}

void SiprixVoipSdkPlugin::OnNetworkState(const char* name, Siprix::NetworkState state)
{
    flutter::EncodableMap argsMap;
    argsMap[flutter::EncodableValue(kArgName)]  = flutter::EncodableValue(name);
    argsMap[flutter::EncodableValue(kNetState)] = flutter::EncodableValue(state);
    channel_->InvokeMethod(kOnNetworkState,
        std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}

void SiprixVoipSdkPlugin::OnRingerState(bool started)
{
}

void SiprixVoipSdkPlugin::OnAccountRegState(Siprix::AccountId accId, Siprix::RegState state, const char* response)
{
    flutter::EncodableMap argsMap;
    argsMap[flutter::EncodableValue(kArgAccId)] = flutter::EncodableValue(static_cast<int32_t>(accId));
    argsMap[flutter::EncodableValue(kRegState)] = flutter::EncodableValue(static_cast<int32_t>(state));
    argsMap[flutter::EncodableValue(kResponse)] = flutter::EncodableValue(response);

    channel_->InvokeMethod(kOnAccountRegState,
       std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}

void SiprixVoipSdkPlugin::OnSubscriptionState(Siprix::SubscriptionId subscrId, Siprix::SubscriptionState state, const char* response)
{
    flutter::EncodableMap argsMap;
    argsMap[flutter::EncodableValue(kArgSubscrId)] = flutter::EncodableValue(static_cast<int32_t>(subscrId));
    argsMap[flutter::EncodableValue(kSubscrState)] = flutter::EncodableValue(static_cast<int32_t>(state));
    argsMap[flutter::EncodableValue(kResponse)]    = flutter::EncodableValue(response);

    channel_->InvokeMethod(kOnSubscriptionState,
       std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}

void SiprixVoipSdkPlugin::OnPlayerState(Siprix::PlayerId playerId, Siprix::PlayerState state)
{
    flutter::EncodableMap argsMap;
    argsMap[flutter::EncodableValue(kArgPlayerId)] = flutter::EncodableValue(static_cast<int32_t>(playerId));
    argsMap[flutter::EncodableValue(kPlayerState)] = flutter::EncodableValue(static_cast<int32_t>(state));    

    channel_->InvokeMethod(kOnPlayerState,
        std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}


void SiprixVoipSdkPlugin::OnCallProceeding(Siprix::CallId callId, const char* response)
{
    flutter::EncodableMap argsMap;
    argsMap[flutter::EncodableValue(kArgCallId)] = flutter::EncodableValue(static_cast<int32_t>(callId));
    argsMap[flutter::EncodableValue(kResponse)]  = flutter::EncodableValue(response);

    channel_->InvokeMethod(kOnCallProceeding,
        std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}

void SiprixVoipSdkPlugin::OnCallTerminated(Siprix::CallId callId, uint32_t statusCode)
{
    flutter::EncodableMap argsMap;
    argsMap[flutter::EncodableValue(kArgCallId)]     = flutter::EncodableValue(static_cast<int32_t>(callId));
    argsMap[flutter::EncodableValue(kArgStatusCode)] = flutter::EncodableValue(static_cast<int32_t>(statusCode));

    channel_->InvokeMethod(kOnCallTerminated,
        std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}

void SiprixVoipSdkPlugin::OnCallConnected(Siprix::CallId callId, const char* hdrFrom, const char* hdrTo, bool withVideo)
{
    flutter::EncodableMap argsMap;
    argsMap[flutter::EncodableValue(kArgCallId)]   = flutter::EncodableValue(static_cast<int32_t>(callId));
    argsMap[flutter::EncodableValue(kFrom)]        = flutter::EncodableValue(hdrFrom);
    argsMap[flutter::EncodableValue(kTo)]          = flutter::EncodableValue(hdrTo);
    argsMap[flutter::EncodableValue(kArgWithVideo)]= flutter::EncodableValue(withVideo);

    channel_->InvokeMethod(kOnCallConnected,
        std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}

void SiprixVoipSdkPlugin::OnCallIncoming(Siprix::CallId callId, Siprix::AccountId accId, bool withVideo, const char* hdrFrom, const char* hdrTo)
{
    flutter::EncodableMap argsMap;    
    argsMap[flutter::EncodableValue(kArgCallId)]    = flutter::EncodableValue(static_cast<int32_t>(callId));
    argsMap[flutter::EncodableValue(kArgAccId)]     = flutter::EncodableValue(static_cast<int32_t>(accId));
    argsMap[flutter::EncodableValue(kArgWithVideo)] = flutter::EncodableValue(withVideo);
    argsMap[flutter::EncodableValue(kFrom)]         = flutter::EncodableValue(hdrFrom);
    argsMap[flutter::EncodableValue(kTo)]           = flutter::EncodableValue(hdrTo);
    
    channel_->InvokeMethod(kOnCallIncoming,
        std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}

void SiprixVoipSdkPlugin::OnCallDtmfReceived(Siprix::CallId callId, uint16_t tone)
{
    flutter::EncodableMap argsMap;
    argsMap[flutter::EncodableValue(kArgCallId)] = flutter::EncodableValue(static_cast<int32_t>(callId));
    argsMap[flutter::EncodableValue(kArgTone)]   = flutter::EncodableValue(static_cast<int32_t>(tone));

    channel_->InvokeMethod(kOnCallDtmfReceived,
        std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}

void SiprixVoipSdkPlugin::OnCallTransferred(Siprix::CallId callId, uint32_t statusCode)
{
    flutter::EncodableMap argsMap;
    argsMap[flutter::EncodableValue(kArgCallId)] = flutter::EncodableValue(static_cast<int32_t>(callId));
    argsMap[flutter::EncodableValue(kArgStatusCode)] = flutter::EncodableValue(static_cast<int32_t>(statusCode));  

    channel_->InvokeMethod(kOnCallTransferred,
        std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}

void SiprixVoipSdkPlugin::OnCallRedirected(Siprix::CallId fromCallId, Siprix::CallId toCallId, const char* referTo)
{
    flutter::EncodableMap argsMap;
    argsMap[flutter::EncodableValue(kArgFromCallId)] = flutter::EncodableValue(static_cast<int32_t>(fromCallId));
    argsMap[flutter::EncodableValue(kArgToCallId)] = flutter::EncodableValue(static_cast<int32_t>(toCallId));  
    argsMap[flutter::EncodableValue(kArgToExt)] = flutter::EncodableValue(referTo);  

    channel_->InvokeMethod(kOnCallRedirected,
        std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}

void SiprixVoipSdkPlugin::OnCallSwitched(Siprix::CallId callId)
{
    flutter::EncodableMap argsMap;
    argsMap[flutter::EncodableValue(kArgCallId)] = flutter::EncodableValue(static_cast<int32_t>(callId));  

    channel_->InvokeMethod(kOnCallSwitched,
        std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}

void SiprixVoipSdkPlugin::OnCallHeld(Siprix::CallId callId, Siprix::HoldState state)
{
    flutter::EncodableMap argsMap;
    argsMap[flutter::EncodableValue(kArgCallId)] = flutter::EncodableValue(static_cast<int32_t>(callId));  
    argsMap[flutter::EncodableValue(kHoldState)] = flutter::EncodableValue(static_cast<int32_t>(state));

    channel_->InvokeMethod(kOnCallHeld,
        std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}

void SiprixVoipSdkPlugin::OnMessageSentState(Siprix::MessageId messageId, bool success, const char* response)
{
    flutter::EncodableMap argsMap;
    argsMap[flutter::EncodableValue(kArgMsgId)] = flutter::EncodableValue(static_cast<int32_t>(messageId));  
    argsMap[flutter::EncodableValue(kSuccess)]  = flutter::EncodableValue(success);
    argsMap[flutter::EncodableValue(kResponse)] = flutter::EncodableValue(response);

    channel_->InvokeMethod(kOnMessageSentState,
        std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}

void SiprixVoipSdkPlugin::OnMessageIncoming(Siprix::MessageId messageId, Siprix::AccountId accId, const char* hdrFrom, const char* body)
{
    flutter::EncodableMap argsMap;
    argsMap[flutter::EncodableValue(kArgAccId)] = flutter::EncodableValue(static_cast<int32_t>(accId));  
    argsMap[flutter::EncodableValue(kArgMsgId)] = flutter::EncodableValue(static_cast<int32_t>(messageId));
    argsMap[flutter::EncodableValue(kFrom)] = flutter::EncodableValue(hdrFrom);
    argsMap[flutter::EncodableValue(kBody)] = flutter::EncodableValue(body);

    channel_->InvokeMethod(kOnMessageIncoming,
        std::make_unique<flutter::EncodableValue>(std::move(argsMap)));
}


////////////////////////////////////////////////////////////////////////////////////////
//FlutterVideoRenderer

FlutterVideoRenderer::FlutterVideoRenderer(flutter::TextureRegistrar* registrar) :
    textureRegistrar_(registrar)
{
}

FlutterVideoRenderer::~FlutterVideoRenderer()
{
    //textureRegistrar_->UnregisterTexture(texture_id_);
}

int64_t FlutterVideoRenderer::registerTextureAndCreateChannel(flutter::BinaryMessenger* messenger)
{
    texture_ =
        std::make_unique<flutter::TextureVariant>(flutter::PixelBufferTexture(
            [renderer_pointer = this](size_t width, size_t height) -> const FlutterDesktopPixelBuffer* {
                return renderer_pointer->CopyPixelBuffer(width, height);
            }));

    texture_id_ = textureRegistrar_->RegisterTexture(texture_.get());
    createEventChannel(messenger);

    first_.pixel_buffer_.reset(new FlutterDesktopPixelBuffer());
    first_.pixel_buffer_->width  = 0;
    first_.pixel_buffer_->height = 0;
    first_.pixel_buffer_->buffer = nullptr;

    second_.pixel_buffer_.reset(new FlutterDesktopPixelBuffer());
    second_.pixel_buffer_->width  = 0;
    second_.pixel_buffer_->height = 0;
    second_.pixel_buffer_->buffer = nullptr;

    return texture_id_;
}


void FlutterVideoRenderer::createEventChannel(flutter::BinaryMessenger* messenger)
{
    std::string channel_name = "Siprix/Texture" + std::to_string(texture_id_);
    
    event_channel_ = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
        messenger, channel_name, &flutter::StandardMethodCodec::GetInstance());
    
    auto handler = std::make_unique<
        flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
            [&](const flutter::EncodableValue* arguments,
                std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
            -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
                sink_ = std::move(events);
                for (auto& event : event_queue_) {
                    sink_->Success(event);
                }
                event_queue_.clear();
                on_listen_called_ = true;
                return nullptr;
            },
            [&](const flutter::EncodableValue* arguments)
            -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
                on_listen_called_ = false;
                return nullptr;
            });
    
    event_channel_->SetStreamHandler(std::move(handler));
}


const FlutterDesktopPixelBuffer* FlutterVideoRenderer::CopyPixelBuffer(
    size_t width, size_t height)
{
    std::scoped_lock lock(mutex_);
    if (second_.fresh_) std::swap(second_, first_);    
    return first_.pixel_buffer_.get();
}

void FlutterVideoRenderer::convertToRgb(Siprix::IVideoFrame* frame)
{
    std::scoped_lock lock(mutex_);
    if(second_.fresh_) return;

    if (second_.pixel_buffer_.get() && frame) {
        const size_t w = frame->width();
        const size_t h = frame->height();
        if (second_.pixel_buffer_->width  != w || second_.pixel_buffer_->height != h) {
            size_t buffer_size = (w * h * 4);
            second_.rgb_buffer_.reset(new uint8_t[buffer_size]);
            second_.pixel_buffer_->width  = w;
            second_.pixel_buffer_->height = h;
        }

        frame->ConvertToARGB(Siprix::IVideoFrame::RGBType::kABGR, second_.rgb_buffer_.get(), 
                             frame->width(), frame->height(), 0);

        second_.pixel_buffer_->buffer = second_.rgb_buffer_.get();
        second_.fresh_ = true;
        first_.fresh_ = false;
    }
}

void FlutterVideoRenderer::OnFrame(Siprix::IVideoFrame* frame)
{
    sendEvent(frame);
    convertToRgb(frame);
    textureRegistrar_->MarkTextureFrameAvailable(texture_id_);
}

void FlutterVideoRenderer::sendEvent(Siprix::IVideoFrame* frame)
{
    if (event_data_.rotation_ != frame->rotation()) {
        event_data_.rotation_ = frame->rotation();

        flutter::EncodableMap params;
        params[flutter::EncodableValue("event")]    = "didTextureChangeRotation";
        params[flutter::EncodableValue("id")]       = flutter::EncodableValue(texture_id_);
        params[flutter::EncodableValue("rotation")] = flutter::EncodableValue((int32_t)event_data_.rotation_);
        eventChannelSend(flutter::EncodableValue(params));
    }

    if (event_data_.width != frame->width() || event_data_.height != frame->height()) {
        event_data_.width = frame->width();
        event_data_.height = frame->height();

        flutter::EncodableMap params;
        params[flutter::EncodableValue("event")] = "didTextureChangeVideoSize";
        params[flutter::EncodableValue("id")]    = flutter::EncodableValue(texture_id_);
        params[flutter::EncodableValue("width")] = flutter::EncodableValue((int32_t)event_data_.width);
        params[flutter::EncodableValue("height")]= flutter::EncodableValue((int32_t)event_data_.height);
        eventChannelSend(flutter::EncodableValue(params));
    }
}

void FlutterVideoRenderer::eventChannelSend(const flutter::EncodableValue& event, bool cache_event)
{
    if (on_listen_called_)  sink_->Success(event); else 
    if (cache_event)        event_queue_.push_back(event);
}




}  // namespace siprix_voip_sdk
