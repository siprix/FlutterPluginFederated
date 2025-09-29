#include "include/siprix_voip_sdk_linux/siprix_voip_sdk_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>
#include <list>
#include <mutex>
#include <variant>

#include "flutter/binary_messenger_impl.h"
#include "flutter/texture_registrar_impl.h"
#include "flutter/include/encodable_value.h"
#include "flutter/include/event_channel.h"
#include "flutter/include/standard_method_codec.h"
#include "flutter/include/event_stream_handler_functions.h"

#include "siprix_voip_sdk_plugin_private.h"
#include "siprix.framework/include/Siprix.h"


////////////////////////////////////////////////////////////////////////////

const char kBadArgumentsError[]         = "Name/type of fields doesn't match expected";
const char kModuleNotInitializedError[] = "Siprix module has not initialized yet";
const char kTextureNoFoundError[]       = "Texture not found!";

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
const char kMethodCallUpgradeToVideo[]  = "Call_UpgradeToVideo";
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

const char kArgStarted[]    = "started";
const char kArgStatusCode[] = "statusCode";
const char kArgExpireTime[] = "expireTime";
const char kArgWithVideo[]  = "withVideo";

const char kArgDvcIndex[] = "dvcIndex";
const char kArgDvcName[]  = "dvcName";
const char kArgDvcGuid[]  = "dvcGuid";

const char kArgCallId[]= "callId";
const char kArgFromCallId[] = "fromCallId";
const char kArgToCallId[]   = "toCallId";
const char kArgToExt[]      = "toExt";

const char kArgAccId[] = "accId";
const char kArgPlayerId[] = "playerId";
const char kArgSubscrId[] = "subscrId";
const char kArgMsgId[]    = "msgId";
const char kRegState[] = "regState";
const char kHoldState[]= "holdState";
const char kPlayerState[] = "playerState";
const char kSubscrState[] = "subscrState";

const char kNetState[]    = "netState";
const char kResponse[] = "response";
const char kSuccess[]  = "success";
const char kArgName[]  = "name";
const char kArgTone[]  = "tone";
const char kFrom[]     = "from";
const char kTo[]       = "to";
const char kBody[]     = "body";


class EventHandler : public Siprix::ISiprixEventHandler {
 public:
  virtual ~EventHandler() {}
  void OnTrialModeNotified() override;
  void OnDevicesAudioChanged() override;

  void OnAccountRegState(Siprix::AccountId accId, Siprix::RegState state, const char* response) override;
  void OnSubscriptionState(Siprix::SubscriptionId subscrId, Siprix::SubscriptionState state, const char* response) override;
  void OnNetworkState(const char* name, Siprix::NetworkState state) override;
  void OnPlayerState(Siprix::PlayerId playerId, Siprix::PlayerState state) override;
  void OnRingerState(bool start) override;

  void OnCallProceeding(Siprix::CallId callId, const char* response) override;
  void OnCallTerminated(Siprix::CallId callId, uint32_t statusCode) override;
  void OnCallConnected(Siprix::CallId callId, const char* hdrFrom, const char* hdrTo, bool withVideo) override;
  void OnCallIncoming(Siprix::CallId callId, Siprix::AccountId accId, bool withVideo, const char* hdrFrom, const char* hdrTo) override;
  void OnCallDtmfReceived(Siprix::CallId callId, uint16_t tone) override;
  void OnCallTransferred(Siprix::CallId callId, uint32_t statusCode) override;
  void OnCallRedirected(Siprix::CallId origCallId, Siprix::CallId relatedCallId, const char* referTo)override;
  void OnCallHeld(Siprix::CallId callId, Siprix::HoldState state) override;
  void OnCallSwitched(Siprix::CallId callId) override;

  void OnMessageSentState(Siprix::MessageId messageId, bool success, const char* response) override;
  void OnMessageIncoming(Siprix::MessageId messageId, Siprix::AccountId accId, 
                         const char* hdrFrom, const char* body) override;

  FlMethodChannel* channel_;
};



////////////////////////////////////////////////////////////////////////////////////////
//FlutterVideoRenderer

class FlutterVideoRenderer : public Siprix::IVideoRenderer
{
public:
    FlutterVideoRenderer(flutter::TextureRegistrar* registrar);
    virtual ~FlutterVideoRenderer();

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

    Siprix::CallId srcCallId_=0;
    bool isRemote_ = false;
};



////////////////////////////////////////////////////////////////////////////



#define SIPRIX_VOIP_SDK_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), siprix_voip_sdk_plugin_get_type(), \
                              SiprixVoipSdkPlugin))

struct _SiprixVoipSdkPlugin {
  GObject parent_instance;

  EventHandler* event_handler;
  Siprix::ISiprixModule* module_;

  std::unique_ptr<flutter::BinaryMessenger> messenger_;
  std::unique_ptr<flutter::TextureRegistrar> texture_registrar_;
  std::unique_ptr<std::map<int64_t, std::shared_ptr<FlutterVideoRenderer>>> renderers_;
};

G_DEFINE_TYPE(SiprixVoipSdkPlugin, siprix_voip_sdk_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void siprix_voip_sdk_plugin_handle_method_call(
    SiprixVoipSdkPlugin* self, FlMethodCall* method_call);

static void siprix_voip_sdk_plugin_dispose(GObject* object) {
  SiprixVoipSdkPlugin* self = SIPRIX_VOIP_SDK_PLUGIN(object);
  g_clear_object(&self->event_handler->channel_);
  delete self->event_handler;

  G_OBJECT_CLASS(siprix_voip_sdk_plugin_parent_class)->dispose(object);
}

static void siprix_voip_sdk_plugin_class_init(SiprixVoipSdkPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = siprix_voip_sdk_plugin_dispose;
}

static void siprix_voip_sdk_plugin_init(SiprixVoipSdkPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  SiprixVoipSdkPlugin* plugin = SIPRIX_VOIP_SDK_PLUGIN(user_data);
  siprix_voip_sdk_plugin_handle_method_call(plugin, method_call);
}

void siprix_voip_sdk_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  SiprixVoipSdkPlugin* plugin = SIPRIX_VOIP_SDK_PLUGIN(
      g_object_new(siprix_voip_sdk_plugin_get_type(), nullptr));

  plugin->event_handler = new EventHandler();

  auto core_messenger = fl_plugin_registrar_get_messenger(registrar);
  plugin->messenger_ = std::make_unique<flutter::BinaryMessengerImpl>(core_messenger);

  auto texture_registrar = fl_plugin_registrar_get_texture_registrar(registrar);
  plugin->texture_registrar_ = std::make_unique<flutter::TextureRegistrarImpl>(texture_registrar);

  plugin->renderers_ = std::make_unique<std::map<int64_t, std::shared_ptr<FlutterVideoRenderer>>>();

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->event_handler->channel_ =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            kChannelName,
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(plugin->event_handler->channel_, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  plugin->module_ = nullptr;
  g_object_unref(plugin);
}





////////////////////////////////////////////////////////////////////////////////////////
//Helpers methods

FlMethodResponse* sendResult(Siprix::ErrorCode err)
{
    if (err == Siprix::EOK) {
      FlValue* res = fl_value_new_string("Success");
      return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
    }
    else {
        return FL_METHOD_RESPONSE(fl_method_error_response_new(
            g_strdup_printf("%d", err), Siprix::GetErrorText(err), nullptr));
    }
}

FlMethodResponse* badArgsResponse()
{
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "-", kBadArgumentsError, nullptr));
}

////////////////////////////////////////////////////////////////////////////////////////
//Siprix module methods implementation

static FlMethodResponse* handleModuleInitialize(FlValue* args, SiprixVoipSdkPlugin* self)
{
    //Check alredy created
    if (self->module_) {
        FlValue* res = fl_value_new_string("Already created");
        return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
    }

    //Create
    self->module_ = Siprix::Module_Create();
    if (!self->module_) {
      return FL_METHOD_RESPONSE(fl_method_error_response_new(
           "-", "Can't create module instance", nullptr));
    }

    //Get params
    Siprix::IniData* iniData = Siprix::Ini_GetDefault();

    FlValue* val = fl_value_lookup_string(args, "license");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
      Siprix::Ini_SetLicense(iniData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "brandName");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
      Siprix::Ini_SetBrandName(iniData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "logLevelFile");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
      Siprix::Ini_SetLogLevelFile(iniData, static_cast<uint8_t>(fl_value_get_int(val)));

    val = fl_value_lookup_string(args, "logLevelIde");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
      Siprix::Ini_SetLogLevelIde(iniData, static_cast<uint8_t>(fl_value_get_int(val)));

    val = fl_value_lookup_string(args, "rtpStartPort");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
      Siprix::Ini_SetRtpStartPort(iniData, static_cast<uint16_t>(fl_value_get_int(val)));

    val = fl_value_lookup_string(args, "tlsVerifyServer");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL)
      Siprix::Ini_SetTlsVerifyServer(iniData, fl_value_get_bool(val));

    val = fl_value_lookup_string(args, "singleCallMode");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL)
      Siprix::Ini_SetSingleCallMode(iniData, fl_value_get_bool(val));

    val = fl_value_lookup_string(args, "shareUdpTransport");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL)
      Siprix::Ini_SetShareUdpTransport(iniData, fl_value_get_bool(val));

    val = fl_value_lookup_string(args, "unregOnDestroy");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL)
      Siprix::Ini_SetUnregOnDestroy(iniData, fl_value_get_bool(val));

    val = fl_value_lookup_string(args, "useDnsSrv");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL)
      Siprix::Ini_SetUseDnsSrv(iniData, fl_value_get_bool(val));

    val = fl_value_lookup_string(args, "recordStereo");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL)
      Siprix::Ini_SetRecordStereo(iniData, fl_value_get_bool(val));

    val = fl_value_lookup_string(args, "enableVideoCall");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL)
      Siprix::Ini_SetVideoCallEnabled(iniData, fl_value_get_bool(val));

    val = fl_value_lookup_string(args, "transpForceIPv4");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL)
      Siprix::Ini_SetTranspForceIPv4(iniData, fl_value_get_bool(val));

    //Initialize
    const Siprix::ErrorCode err = Siprix::Module_Initialize(self->module_, iniData);

    //Set event handler
    if (err == Siprix::EOK)
      Siprix::Callback_SetEventHandler(self->module_, self->event_handler);

    //Send result
    return sendResult(err);

}//handleModuleInitialize


FlMethodResponse* handleModuleUnInitialize(FlValue* args, SiprixVoipSdkPlugin* self)
{
    const Siprix::ErrorCode err = Siprix::Module_UnInitialize(self->module_);
    self->module_ = nullptr;
    return sendResult(err);
}

FlMethodResponse* handleModuleHomeFolder(FlValue* args, SiprixVoipSdkPlugin* self)
{
    const gchar* path = Siprix::Module_HomeFolder(self->module_);
    g_autoptr(FlValue) res = fl_value_new_string(path);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
}

FlMethodResponse* handleModuleVersionCode(FlValue* args, SiprixVoipSdkPlugin* self)
{
    const int32_t versionCode = Siprix::Module_VersionCode(self->module_);
    g_autoptr(FlValue) res = fl_value_new_int(versionCode);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
}

FlMethodResponse* handleModuleVersion(FlValue* args, SiprixVoipSdkPlugin* self)
{
    const gchar* version = Siprix::Module_Version(self->module_);
    g_autoptr(FlValue) res = fl_value_new_string(version);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
}

////////////////////////////////////////////////////////////////////////////////////////
//Siprix Account methods implementation

Siprix::AccData* parseAccData(FlValue* args)
{
    Siprix::AccData* accData = Siprix::Acc_GetDefault();

    FlValue* val = fl_value_lookup_string(args, "sipServer");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
        Acc_SetSipServer(accData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "sipExtension");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
        Acc_SetSipExtension(accData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "sipPassword");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
        Acc_SetSipPassword(accData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "sipAuthId");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
        Acc_SetSipAuthId(accData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "sipProxy");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
        Acc_SetSipProxyServer(accData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "displName");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
        Acc_SetDisplayName(accData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "userAgent");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
        Acc_SetUserAgent(accData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "expireTime");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
        Acc_SetExpireTime(accData, fl_value_get_int(val));

    val = fl_value_lookup_string(args, "transport");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
        Acc_SetTranspProtocol(accData, static_cast<Siprix::SipTransport>(fl_value_get_int(val)));

    val = fl_value_lookup_string(args, "port");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
        Acc_SetTranspPort(accData, static_cast<uint16_t>(fl_value_get_int(val)));

    val = fl_value_lookup_string(args, "tlsCaCertPath");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
        Acc_SetTranspTlsCaCert(accData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "tlsUseSipScheme");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL)
        Acc_SetUseSipSchemeForTls(accData, fl_value_get_bool(val));

    val = fl_value_lookup_string(args, "rtcpMuxEnabled");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL)
        Acc_SetRtcpMuxEnabled(accData, fl_value_get_bool(val));

    val = fl_value_lookup_string(args, "iceEnabled");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL)
        Acc_SetIceEnabled(accData, fl_value_get_bool(val));

    val = fl_value_lookup_string(args, "instanceId");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
        Acc_SetInstanceId(accData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "ringTonePath");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
        Acc_SetRingToneFile(accData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "keepAliveTime");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
        Acc_SetKeepAliveTime(accData, static_cast<uint32_t>(fl_value_get_int(val)));

    val = fl_value_lookup_string(args, "rewriteContactIp");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL)
        Acc_SetRewriteContactIp(accData, fl_value_get_bool(val));

    val = fl_value_lookup_string(args, "verifyIncomingCall");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL)
        Acc_SetVerifyIncomingCall(accData, fl_value_get_bool(val));

    val = fl_value_lookup_string(args, "forceSipProxy");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL)
        Acc_SetForceSipProxy(accData, fl_value_get_bool(val));

    val = fl_value_lookup_string(args, "secureMedia");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
        Acc_SetSecureMediaMode(accData, static_cast<Siprix::SecureMedia>(fl_value_get_int(val)));

    val = fl_value_lookup_string(args, "stunServer");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
        Acc_SetStunServer(accData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "turnServer");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
        Acc_SetTurnServer(accData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "turnUser");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
        Acc_SetTurnUser(accData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "turnPassword");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
        Acc_SetTurnPassword(accData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "xheaders");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_MAP) {
        for (size_t i = 0; i < fl_value_get_length(val); ++i) {
            FlValue* xHdrName = fl_value_get_map_key(val, i);
            FlValue* xHdrValue = fl_value_get_map_value(val, i);

            if((fl_value_get_type(xHdrName) == FL_VALUE_TYPE_STRING)&&
                (fl_value_get_type(xHdrValue) == FL_VALUE_TYPE_STRING)) {
                Siprix::Acc_AddXHeader(accData, fl_value_get_string(xHdrName), fl_value_get_string(xHdrValue));
            }
        }
    }

    val = fl_value_lookup_string(args, "xContactUriParams");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_MAP) {
        for (size_t i = 0; i < fl_value_get_length(val); ++i) {
            FlValue* xParamName = fl_value_get_map_key(val, i);
            FlValue* xParamValue = fl_value_get_map_value(val, i);

            if((fl_value_get_type(xParamName) == FL_VALUE_TYPE_STRING)&&
                (fl_value_get_type(xParamValue) == FL_VALUE_TYPE_STRING)) {
                Siprix::Acc_AddXContactUriParam(accData, fl_value_get_string(xParamName), fl_value_get_string(xParamValue));
            }
        }
    }

    val = fl_value_lookup_string(args, "aCodecs");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_LIST) {
        Siprix::Acc_ResetAudioCodecs(accData);
        for (size_t i = 0; i < fl_value_get_length(val); ++i) {
            FlValue* codec = fl_value_get_list_value(val, i);
            if(fl_value_get_type(codec) == FL_VALUE_TYPE_INT)
                Siprix::Acc_AddAudioCodec(accData, static_cast<Siprix::AudioCodec>(fl_value_get_int(codec)));
        }
    }

    val = fl_value_lookup_string(args, "vCodecs");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_LIST) {
        Siprix::Acc_ResetVideoCodecs(accData);
        for (size_t i = 0; i < fl_value_get_length(val); ++i) {
            FlValue* codec = fl_value_get_list_value(val, i);
            if(fl_value_get_type(codec) == FL_VALUE_TYPE_INT)
                Siprix::Acc_AddVideoCodec(accData, static_cast<Siprix::VideoCodec>(fl_value_get_int(codec)));
        }
    }

    return accData;
}

FlMethodResponse* handleAccountAdd(FlValue* args, SiprixVoipSdkPlugin* self)
{
  Siprix::AccountId accId  = 0;
  Siprix::AccData* accData = parseAccData(args);
  const Siprix::ErrorCode err = Siprix::Account_Add(self->module_, accData, &accId);
  g_autoptr(FlValue) res = fl_value_new_int(accId);
  if(err == Siprix::EOK){
    return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
  }
  else {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
            g_strdup_printf("%d", err), Siprix::GetErrorText(err), res));
  }
}

FlMethodResponse* handleAccountUpdate(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgAccId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::AccountId accId = fl_value_get_int(val);

    Siprix::AccData* accData = parseAccData(args);

    const Siprix::ErrorCode err = Siprix::Account_Update(self->module_, accData, accId);
    return sendResult(err);
}

FlMethodResponse* handleAccountRegister(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgAccId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::AccountId accId = fl_value_get_int(val);

    val = fl_value_lookup_string(args, kArgExpireTime);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const int32_t expireTime = fl_value_get_int(val);

    const Siprix::ErrorCode err = Siprix::Account_Register(self->module_, accId, expireTime);
    return sendResult(err);
}

FlMethodResponse* handleAccountUnregister(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgAccId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::AccountId accId = fl_value_get_int(val);

    const Siprix::ErrorCode err = Siprix::Account_Unregister(self->module_, accId);
    return sendResult(err);
}

FlMethodResponse* handleAccountDelete(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgAccId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::AccountId accId = fl_value_get_int(val);

    const Siprix::ErrorCode err = Siprix::Account_Delete(self->module_, accId);
    return sendResult(err);
}

FlMethodResponse* handleAccountGenInstId(FlValue* args, SiprixVoipSdkPlugin* self)
{
    const gchar* instId = Siprix::Acc_GenerateInstanceId();
    g_autoptr(FlValue) res = fl_value_new_string(instId);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
}


////////////////////////////////////////////////////////////////////////////////////////
//Siprix Calls methods implementation

FlMethodResponse* handleCallInvite(FlValue* args, SiprixVoipSdkPlugin* self)
{
  Siprix::DestData* destData = Siprix::Dest_GetDefault();

  FlValue* val = fl_value_lookup_string(args, "extension");
  if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
      Dest_SetExtension(destData, fl_value_get_string(val));

  val = fl_value_lookup_string(args, kArgAccId);
  if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
      Siprix::Dest_SetAccountId(destData, fl_value_get_int(val));

  val = fl_value_lookup_string(args, "inviteTimeout");
  if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
      Siprix::Dest_SetInviteTimeout(destData, fl_value_get_int(val));

  val = fl_value_lookup_string(args, kArgWithVideo);
  if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL)
      Siprix::Dest_SetVideoCall(destData, fl_value_get_bool(val));

  val = fl_value_lookup_string(args, "displName");
  if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
      Dest_SetDisplayName(destData, fl_value_get_string(val));

  val = fl_value_lookup_string(args, "xheaders");
  if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_MAP) {
      for (size_t i = 0; i < fl_value_get_length(val); ++i) {
          FlValue* xHdrName = fl_value_get_map_key(val, i);
          FlValue* xHdrValue = fl_value_get_map_value(val, i);

          if ((fl_value_get_type(xHdrName) == FL_VALUE_TYPE_STRING) &&
              (fl_value_get_type(xHdrValue) == FL_VALUE_TYPE_STRING)) {
                  Siprix::Dest_AddXHeader(destData, fl_value_get_string(xHdrName), fl_value_get_string(xHdrValue));
         }
      }
  }

  Siprix::CallId callId=0;
  const Siprix::ErrorCode err = Siprix::Call_Invite(self->module_, destData, &callId);
  if(err == Siprix::EOK){
    g_autoptr(FlValue) res = fl_value_new_int(callId);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
  }

  return sendResult(err);
}

FlMethodResponse* handleCallReject(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    val = fl_value_lookup_string(args, kArgStatusCode);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const uint16_t statusCode = static_cast<uint16_t>(fl_value_get_int(val));

    const Siprix::ErrorCode err = Siprix::Call_Reject(self->module_, callId, statusCode);
    return sendResult(err);
}

FlMethodResponse* handleCallAccept(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    val = fl_value_lookup_string(args, kArgWithVideo);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_BOOL) return badArgsResponse();
    bool withVideo = fl_value_get_bool(val);

    const Siprix::ErrorCode err = Siprix::Call_Accept(self->module_, callId, withVideo);
    return sendResult(err);
}

FlMethodResponse* handleCallHold(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    const Siprix::ErrorCode err = Siprix::Call_Hold(self->module_, callId);
    return sendResult(err);
}

FlMethodResponse* handleCallGetSipHeader(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    val = fl_value_lookup_string(args, "hdrName");
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_STRING) return badArgsResponse();
    const gchar* hdrName = fl_value_get_string(val);

    std::string headerVal;
    uint32_t headerValLen = 0;
    Siprix::Call_GetSipHeader(self->module_, callId, hdrName, nullptr, &headerValLen);

    if (headerValLen > 0) {
        headerVal.resize(headerValLen);
        Siprix::Call_GetSipHeader(self->module_, callId, hdrName, &headerVal[0], &headerValLen);
    }

    g_autoptr(FlValue) res = fl_value_new_string(headerVal.c_str());
    return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
}

FlMethodResponse* handleCallGetHoldState(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    Siprix::HoldState state;
    const Siprix::ErrorCode err = Siprix::Call_GetHoldState(self->module_, callId, &state);

    if (err == Siprix::EOK) {
        g_autoptr(FlValue) res = fl_value_new_int(state);
        return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
    }

    return sendResult(err);
}

FlMethodResponse* handleCallMuteMic(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    val = fl_value_lookup_string(args, "mute");
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_BOOL) return badArgsResponse();
    bool muteFlag = fl_value_get_bool(val);

    const Siprix::ErrorCode err = Siprix::Call_MuteMic(self->module_, callId, muteFlag);
    return sendResult(err);
}

FlMethodResponse* handleCallMuteCam(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    val = fl_value_lookup_string(args, "mute");
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_BOOL) return badArgsResponse();
    bool muteFlag = fl_value_get_bool(val);

    const Siprix::ErrorCode err = Siprix::Call_MuteCam(self->module_, callId, muteFlag);
    return sendResult(err);
}


FlMethodResponse* handleCallSendDtmf(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    val = fl_value_lookup_string(args, "durationMs");
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const int64_t durationMs = fl_value_get_int(val);

    val = fl_value_lookup_string(args, "intertoneGapMs");
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const int64_t intertoneGapMs = fl_value_get_int(val);

    val = fl_value_lookup_string(args, "method");
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const int64_t method = fl_value_get_int(val);

    val = fl_value_lookup_string(args, "dtmfs");
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_STRING) return badArgsResponse();
    const gchar* dtmfs = fl_value_get_string(val);

    const Siprix::ErrorCode err = Siprix::Call_SendDtmf(self->module_, callId, dtmfs, 
        static_cast<uint16_t>(durationMs), static_cast<uint16_t>(intertoneGapMs), 
        static_cast<Siprix::DtmfMethod>(method));
    return sendResult(err);
}

FlMethodResponse* handleCallRecordFile(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    val = fl_value_lookup_string(args, "pathToMp3File");
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_STRING) return badArgsResponse();
    const gchar* pathToMp3File = fl_value_get_string(val);

    const Siprix::ErrorCode err = Siprix::Call_RecordFile(self->module_, callId, pathToMp3File);
    return sendResult(err);
}

FlMethodResponse* handleCallStopRecordFile(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    const Siprix::ErrorCode err = Siprix::Call_StopRecordFile(self->module_, callId);
    return sendResult(err);
}

FlMethodResponse* handleCallPlayFile(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    val = fl_value_lookup_string(args, "pathToMp3File");
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_STRING) return badArgsResponse();
    const gchar* pathToMp3File = fl_value_get_string(val);

    val = fl_value_lookup_string(args, "loop");
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_BOOL) return badArgsResponse();
    bool loopFlag = fl_value_get_bool(val);

    Siprix::PlayerId playerId = 0;
    const Siprix::ErrorCode err = Siprix::Call_PlayFile(self->module_, callId, pathToMp3File, loopFlag, &playerId);

    if (err == Siprix::EOK) {
        g_autoptr(FlValue) res = fl_value_new_int(playerId);
        return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
    }

    return sendResult(err);
}


FlMethodResponse* handleCallStopPlayFile(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgPlayerId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::PlayerId playerId = fl_value_get_int(val);

    const Siprix::ErrorCode err = Siprix::Call_StopPlayFile(self->module_, playerId);
    return sendResult(err);
}

FlMethodResponse* handleCallTransferBlind(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    val = fl_value_lookup_string(args, kArgToExt);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_STRING) return badArgsResponse();
    const gchar* toExt = fl_value_get_string(val);

    const Siprix::ErrorCode err = Siprix::Call_TransferBlind(self->module_, callId, toExt);
    return sendResult(err);
}

FlMethodResponse* handleCallTransferAttended(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgFromCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId fromCallId = fl_value_get_int(val);

    val = fl_value_lookup_string(args, kArgToCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId toCallId = fl_value_get_int(val);

    const Siprix::ErrorCode err = Siprix::Call_TransferAttended(self->module_, fromCallId, toCallId);
    return sendResult(err);
}

FlMethodResponse* handleCallUpgradeToVideo(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    const Siprix::ErrorCode err = Siprix::Call_UpgradeToVideo(self->module_, callId);
    return sendResult(err);
}

FlMethodResponse* handleCallStopRingtone(FlValue* args, SiprixVoipSdkPlugin* self)
{
    const Siprix::ErrorCode err = Siprix::Call_StopRingtone(self->module_);
    return sendResult(err);
}

FlMethodResponse* handleCallBye(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    const Siprix::ErrorCode err = Siprix::Call_Bye(self->module_, callId);
    return sendResult(err);
}

////////////////////////////////////////////////////////////////////////////////////////
//Siprix Mixer methods implementation

FlMethodResponse* handleMixerSwitchToCall(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    const Siprix::ErrorCode err = Siprix::Mixer_SwitchToCall(self->module_, callId);
    return sendResult(err);
}

FlMethodResponse* handleMixerMakeConference(FlValue* args, SiprixVoipSdkPlugin* self)
{
    const Siprix::ErrorCode err = Siprix::Mixer_MakeConference(self->module_);
    return sendResult(err);
}

////////////////////////////////////////////////////////////////////////////////////////
//Siprix messages

FlMethodResponse* handleMessageSend(FlValue* args, SiprixVoipSdkPlugin* self)
{
  Siprix::MsgData* msgData = Siprix::Msg_GetDefault();

  FlValue* val = fl_value_lookup_string(args, "extension");
  if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
      Siprix::Msg_SetExtension(msgData, fl_value_get_string(val));

  val = fl_value_lookup_string(args, kArgAccId);
  if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
      Siprix::Msg_SetAccountId(msgData, fl_value_get_int(val));

  val = fl_value_lookup_string(args, kBody);
  if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
      Msg_SetBody(msgData, fl_value_get_string(val));

  Siprix::MessageId msgId = 0;
  const Siprix::ErrorCode err = Siprix::Message_Send(self->module_, msgData, &msgId);
  g_autoptr(FlValue) res = fl_value_new_int(msgId);

  if(err == Siprix::EOK) {
    return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
  }
  else {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
            g_strdup_printf("%d", err), Siprix::GetErrorText(err), res));
  }
}


////////////////////////////////////////////////////////////////////////////////////////
//Siprix subscriptions

FlMethodResponse* handleSubscriptionAdd(FlValue* args, SiprixVoipSdkPlugin* self)
{
  Siprix::SubscrData* subscrData = Siprix::Subscr_GetDefault();

  FlValue* val = fl_value_lookup_string(args, "extension");
  if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
      Siprix::Subscr_SetExtension(subscrData, fl_value_get_string(val));

  val = fl_value_lookup_string(args, kArgAccId);
  if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
      Siprix::Subscr_SetAccountId(subscrData, fl_value_get_int(val));

  val = fl_value_lookup_string(args, "expireTime");
  if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
      Siprix::Subscr_SetExpireTime(subscrData, fl_value_get_int(val));

  val = fl_value_lookup_string(args, "mimeSubType");
  if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
      Subscr_SetMimeSubtype(subscrData, fl_value_get_string(val));

  val = fl_value_lookup_string(args, "eventType");
  if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
      Subscr_SetEventType(subscrData, fl_value_get_string(val));

  Siprix::SubscriptionId subscrId=0;
  const Siprix::ErrorCode err = Siprix::Subscription_Create(self->module_, subscrData, &subscrId);
  g_autoptr(FlValue) res = fl_value_new_int(subscrId);

  if(err == Siprix::EOK){
    return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
  }
  else {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
            g_strdup_printf("%d", err), Siprix::GetErrorText(err), res));
  }
}

FlMethodResponse* handleSubscriptionDelete(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgSubscrId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::SubscriptionId subscrId = fl_value_get_int(val);

    const Siprix::ErrorCode err = Siprix::Subscription_Destroy(self->module_, subscrId);
    return sendResult(err);
}

////////////////////////////////////////////////////////////////////////////////////////
//Siprix Devices methods implementation

FlMethodResponse* handleDvcGetPlayoutNumber(FlValue* args, SiprixVoipSdkPlugin* self)
{
    uint32_t numberOfDevices = 0;
    Siprix::Dvc_GetPlayoutDevices(self->module_, &numberOfDevices);

    g_autoptr(FlValue) res = fl_value_new_int(numberOfDevices);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
}

FlMethodResponse* handleDvcGetRecordNumber(FlValue* args, SiprixVoipSdkPlugin* self)
{
    uint32_t numberOfDevices = 0;
    Siprix::Dvc_GetRecordingDevices(self->module_, &numberOfDevices);

    g_autoptr(FlValue) res = fl_value_new_int(numberOfDevices);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
}

FlMethodResponse* handleDvcGetVideoNumber(FlValue* args, SiprixVoipSdkPlugin* self)
{
    uint32_t numberOfDevices = 0;
    Siprix::Dvc_GetVideoDevices(self->module_, &numberOfDevices);

    g_autoptr(FlValue) res = fl_value_new_int(numberOfDevices);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
}


template <typename F>
FlMethodResponse* doGetDevice(F getDeviceF, FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgDvcIndex);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const int32_t dvcIndex = fl_value_get_int(val);

    char name[128] = "";
    char guid[128] = "";
    const Siprix::ErrorCode err = getDeviceF(self->module_, static_cast<uint16_t>(dvcIndex),
        name, sizeof(name), guid, sizeof(guid));

    if (err == Siprix::EOK) {
        g_autoptr(FlValue) res = fl_value_new_map();
        fl_value_set_string_take(res, kArgDvcName, fl_value_new_string(name));
        fl_value_set_string_take(res, kArgDvcGuid, fl_value_new_string(guid));
        return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
    }
    else {
        return sendResult(err);
    }
}

FlMethodResponse* handleDvcGetPlayout(FlValue* args, SiprixVoipSdkPlugin* self)
{
    return doGetDevice(Siprix::Dvc_GetPlayoutDevice, args, self);
}

FlMethodResponse* handleDvcGetRecording(FlValue* args, SiprixVoipSdkPlugin* self)
{
    return doGetDevice(Siprix::Dvc_GetRecordingDevice, args, self);
}

FlMethodResponse* handleDvcGetVideo(FlValue* args, SiprixVoipSdkPlugin* self)
{
    return doGetDevice(Siprix::Dvc_GetVideoDevice, args, self);
}


FlMethodResponse* handleDvcSetPlayout(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgDvcIndex);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const int32_t dvcIndex = fl_value_get_int(val);

    const Siprix::ErrorCode err = Siprix::Dvc_SetPlayoutDevice(self->module_, static_cast<uint16_t>(dvcIndex));
    return sendResult(err);
}

FlMethodResponse* handleDvcSetRecording(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgDvcIndex);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const int32_t dvcIndex = fl_value_get_int(val);

    const Siprix::ErrorCode err = Siprix::Dvc_SetRecordingDevice(self->module_, static_cast<uint16_t>(dvcIndex));
    return sendResult(err);
}

FlMethodResponse* handleDvcSetVideo(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgDvcIndex);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const int32_t dvcIndex = fl_value_get_int(val);

    const Siprix::ErrorCode err = Siprix::Dvc_SetVideoDevice(self->module_, static_cast<uint16_t>(dvcIndex));
    return sendResult(err);
}

FlMethodResponse* handleDvcSetVideoParams(FlValue* args, SiprixVoipSdkPlugin* self)
{
    Siprix::VideoData* vdoData = Siprix::Vdo_GetDefault();

    FlValue* val = fl_value_lookup_string(args, "noCameraImgPath");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING)
      Siprix::Vdo_SetNoCameraImgPath(vdoData, fl_value_get_string(val));

    val = fl_value_lookup_string(args, "framerateFps");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
      Siprix::Vdo_SetFramerate(vdoData, fl_value_get_int(val));

    val = fl_value_lookup_string(args, "bitrateKbps");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
      Siprix::Vdo_SetBitrate(vdoData, fl_value_get_int(val));

    val = fl_value_lookup_string(args, "height");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
      Siprix::Vdo_SetHeight(vdoData, fl_value_get_int(val));

    val = fl_value_lookup_string(args, "width");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT)
      Siprix::Vdo_SetWidth(vdoData, fl_value_get_int(val));

    const Siprix::ErrorCode err = Siprix::Dvc_SetVideoParams(self->module_, vdoData);
    return sendResult(err);

}//handleModuleInitialize

////////////////////////////////////////////////////////////////////////////////////////
//Siprix video renderers

FlMethodResponse* handleVideoRendererCreate(FlValue* args, SiprixVoipSdkPlugin* self)
{
    auto renderer = std::make_shared<FlutterVideoRenderer>(self->texture_registrar_.get());
    auto texture_id = renderer->registerTextureAndCreateChannel(self->messenger_.get());

    (*self->renderers_)[texture_id] = renderer;
    //self->renderers_.insert(std::pair<int64_t, std::shared_ptr<FlutterVideoRenderer>>(texture_id, renderer));
    //std::map<int64_t, std::shared_ptr<FlutterVideoRenderer>> renderers_;

    g_autoptr(FlValue) res = fl_value_new_int(texture_id);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
}

FlMethodResponse* handleVideoRendererSetSrc(FlValue* args, SiprixVoipSdkPlugin* self)
{
    FlValue* val = fl_value_lookup_string(args, kArgCallId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const Siprix::CallId callId = fl_value_get_int(val);

    val = fl_value_lookup_string(args, kArgVideoTextureId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const int64_t textureId = fl_value_get_int(val);

    auto it = (*self->renderers_).find(textureId);
    if(it != (*self->renderers_).end()){
        FlutterVideoRenderer* renderer = it->second.get();

        const Siprix::ErrorCode err = Siprix::Call_SetVideoRenderer(self->module_, callId, renderer);
        renderer->setSrcCallId(callId);
        return sendResult(err);
    }
    else{
        return sendResult(Siprix::EOK);
    }
}

FlMethodResponse* handleVideoRendererDispose(FlValue* args, SiprixVoipSdkPlugin* self)
{
    //Parse argument
    FlValue* val = fl_value_lookup_string(args, kArgVideoTextureId);
    if (val == nullptr || fl_value_get_type(val) != FL_VALUE_TYPE_INT) return badArgsResponse();
    const int64_t textureId = fl_value_get_int(val);

    auto it = (*self->renderers_).find(textureId);
    if (it == (*self->renderers_).end()) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new(
            "-", kTextureNoFoundError, nullptr));
    }

    FlutterVideoRenderer* renderer = it->second.get();
    Siprix::Call_SetVideoRenderer(self->module_, renderer->getSrcCallId(), nullptr);

    self->texture_registrar_->UnregisterTexture(textureId);
    (*self->renderers_).erase(it);

    return sendResult(Siprix::EOK);
}

// Called when a method call is received from Flutter.
static void siprix_voip_sdk_plugin_handle_method_call(
    SiprixVoipSdkPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  FlValue* args = fl_method_call_get_args(method_call);
  if(fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    fl_method_call_respond(method_call, badArgsResponse(), nullptr);
    return;
  }
  const gchar* method = fl_method_call_get_name(method_call);

  if(self->module_) {
    if(strcmp(method, kMethodModuleInitialize)  == 0)    response = handleModuleInitialize(args, self);else
    if(strcmp(method, kMethodModuleUnInitialize)== 0)    response = handleModuleUnInitialize(args, self); else
    if(strcmp(method, kMethodModuleHomeFolder)  == 0)    response = handleModuleHomeFolder(args, self); else
    if(strcmp(method, kMethodModuleVersionCode) == 0)    response = handleModuleVersionCode(args, self); else
    if(strcmp(method, kMethodModuleVersion)     == 0)    response = handleModuleVersion(args, self); else

    if(strcmp(method, kMethodAccountAdd)       == 0)     response = handleAccountAdd(args, self); else
    if(strcmp(method, kMethodAccountUpdate)    == 0)     response = handleAccountUpdate(args, self); else
    if(strcmp(method, kMethodAccountRegister)  == 0)     response = handleAccountRegister(args, self); else
    if(strcmp(method, kMethodAccountUnregister)== 0)     response = handleAccountUnregister(args, self); else
    if(strcmp(method, kMethodAccountDelete) == 0)        response = handleAccountDelete(args, self); else
    if(strcmp(method, kMethodAccountGenInstId) == 0)     response = handleAccountGenInstId(args, self); else

    if(strcmp(method, kMethodCallInvite)  == 0)          response = handleCallInvite(args, self); else
    if(strcmp(method, kMethodCallReject)  == 0)          response = handleCallReject(args, self); else
    if(strcmp(method, kMethodCallAccept)  == 0)          response = handleCallAccept(args, self); else
    if(strcmp(method, kMethodCallHold)    == 0)          response = handleCallHold(args, self); else
    if(strcmp(method, kMethodCallGetHoldState)  == 0)    response = handleCallGetHoldState(args, self); else
    if(strcmp(method, kMethodCallGetSipHeader)  == 0)    response = handleCallGetSipHeader(args, self); else
    if(strcmp(method, kMethodCallMuteMic) == 0)          response = handleCallMuteMic(args, self); else
    if(strcmp(method, kMethodCallMuteCam) == 0)          response = handleCallMuteCam(args, self); else
    if(strcmp(method, kMethodCallSendDtmf)== 0)          response = handleCallSendDtmf(args, self); else
    if(strcmp(method, kMethodCallPlayFile) == 0)         response = handleCallPlayFile(args, self); else
    if(strcmp(method, kMethodCallStopPlayFile) == 0)     response = handleCallStopPlayFile(args, self); else
    if(strcmp(method, kMethodCallRecordFile) == 0)       response = handleCallRecordFile(args, self); else
    if(strcmp(method, kMethodCallStopRecordFile) == 0)   response = handleCallStopRecordFile(args, self); else
    if(strcmp(method, kMethodCallTransferBlind) == 0)    response = handleCallTransferBlind(args, self); else
    if(strcmp(method, kMethodCallTransferAttended) == 0) response = handleCallTransferAttended(args, self); else
    if(strcmp(method, kMethodCallUpgradeToVideo) == 0)   response = handleCallUpgradeToVideo(args, self); else
    if(strcmp(method, kMethodCallStopRingtone) == 0)     response = handleCallStopRingtone(args, self); else
    if(strcmp(method, kMethodCallBye) == 0)              response = handleCallBye(args, self);    else

    if(strcmp(method, kMethodMixerSwitchToCall) == 0)    response = handleMixerSwitchToCall(args, self); else
    if(strcmp(method, kMethodMixerMakeConference) == 0)  response = handleMixerMakeConference(args, self);else

    if(strcmp(method, kMethodMessageSend) == 0)          response = handleMessageSend(args, self); else

    if(strcmp(method, kMethodSubscriptionAdd) == 0)      response = handleSubscriptionAdd(args, self); else
    if(strcmp(method, kMethodSubscriptionDelete) == 0)   response = handleSubscriptionDelete(args, self);else

    if(strcmp(method, kMethodDvcGetPlayoutNumber)== 0)   response = handleDvcGetPlayoutNumber(args, self); else
    if(strcmp(method, kMethodDvcGetRecordNumber) == 0)   response = handleDvcGetRecordNumber(args, self); else
    if(strcmp(method, kMethodDvcGetVideoNumber)  == 0)   response = handleDvcGetVideoNumber(args, self); else
    if(strcmp(method, kMethodDvcGetPlayout)      == 0)   response = handleDvcGetPlayout(args, self); else
    if(strcmp(method, kMethodDvcGetRecording)    == 0)   response = handleDvcGetRecording(args, self); else
    if(strcmp(method, kMethodDvcGetVideo)        == 0)   response = handleDvcGetVideo(args, self); else
    if(strcmp(method, kMethodDvcSetPlayout)      == 0)   response = handleDvcSetPlayout(args, self); else
    if(strcmp(method, kMethodDvcSetRecording)    == 0)   response = handleDvcSetRecording(args, self); else
    if(strcmp(method, kMethodDvcSetVideo)        == 0)   response = handleDvcSetVideo(args, self); else
    if(strcmp(method, kMethodDvcSetVideoParams)  == 0)   response = handleDvcSetVideoParams(args, self); else

    if(strcmp(method, kMethodVideoRendererCreate) == 0)  response = handleVideoRendererCreate(args, self); else
    if(strcmp(method, kMethodVideoRendererSetSrc) == 0)  response = handleVideoRendererSetSrc(args, self); else
    if(strcmp(method, kMethodVideoRendererDispose)== 0)  response = handleVideoRendererDispose(args, self);

    else response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  else{
    if(strcmp(method, kMethodModuleInitialize)  == 0)  response = handleModuleInitialize(args, self);
    else response = FL_METHOD_RESPONSE(fl_method_error_response_new(
           "UNAVAILABLE", kModuleNotInitializedError, nullptr));
  }

  fl_method_call_respond(method_call, response, nullptr);
}




FlMethodResponse* get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) res = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(res));
}



//////////////////////////////////////////////////////////////////////////
//Event handlers

void EventHandler::OnTrialModeNotified()
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_method_channel_invoke_method(channel_, kOnTrialModeNotif, args,
        nullptr, nullptr, nullptr);
}


void EventHandler::OnDevicesAudioChanged()
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_method_channel_invoke_method(channel_, kOnDevicesChanged, args,
        nullptr, nullptr, nullptr);
}

void EventHandler::OnNetworkState(const char* name, Siprix::NetworkState state)
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string_take(args, kArgName, fl_value_new_string(name));
    fl_value_set_string_take(args, kNetState, fl_value_new_int(state));

    fl_method_channel_invoke_method(channel_, kOnNetworkState, args,
        nullptr, nullptr, nullptr);
}


void EventHandler::OnAccountRegState(Siprix::AccountId accId, Siprix::RegState state, const char* response)
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string_take(args, kArgAccId, fl_value_new_int(accId));
    fl_value_set_string_take(args, kRegState, fl_value_new_int(state));
    fl_value_set_string_take(args, kResponse, fl_value_new_string(response));

    fl_method_channel_invoke_method(channel_, kOnAccountRegState, args,
        nullptr, nullptr, nullptr);
}

void EventHandler::OnSubscriptionState(Siprix::SubscriptionId subscrId, Siprix::SubscriptionState state, const char* response)
{
    g_autoptr(FlValue) args = fl_value_new_map();    
    fl_value_set_string_take(args, kArgSubscrId, fl_value_new_int(subscrId));
    fl_value_set_string_take(args, kSubscrState, fl_value_new_int(state));
    fl_value_set_string_take(args, kResponse, fl_value_new_string(response));

    fl_method_channel_invoke_method(channel_, kOnSubscriptionState, args,
        nullptr, nullptr, nullptr);
}

void EventHandler::OnRingerState(bool start)
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string_take(args, kArgStarted, fl_value_new_bool(start));

    fl_method_channel_invoke_method(channel_, kOnRingerState, args,
        nullptr, nullptr, nullptr);
}

void EventHandler::OnPlayerState(Siprix::PlayerId playerId, Siprix::PlayerState state)
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string_take(args, kArgPlayerId, fl_value_new_int(playerId));
    fl_value_set_string_take(args, kPlayerState, fl_value_new_int(state));

    fl_method_channel_invoke_method(channel_, kOnPlayerState, args,
        nullptr, nullptr, nullptr);
}

void EventHandler::OnCallProceeding(Siprix::CallId callId, const char* response)
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string_take(args, kArgCallId, fl_value_new_int(callId));
    fl_value_set_string_take(args, kResponse,  fl_value_new_string(response));

    fl_method_channel_invoke_method(channel_, kOnCallProceeding, args,
        nullptr, nullptr, nullptr);
}

void EventHandler::OnCallTerminated(Siprix::CallId callId, uint32_t statusCode)
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string_take(args, kArgCallId,     fl_value_new_int(callId));
    fl_value_set_string_take(args, kArgStatusCode, fl_value_new_int(statusCode));

    fl_method_channel_invoke_method(channel_, kOnCallTerminated, args,
        nullptr, nullptr, nullptr);
}

void EventHandler::OnCallConnected(Siprix::CallId callId, const char* hdrFrom, const char* hdrTo, bool withVideo)
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string_take(args, kArgWithVideo, fl_value_new_bool(withVideo));
    fl_value_set_string_take(args, kArgCallId, fl_value_new_int(callId));
    fl_value_set_string_take(args, kFrom,      fl_value_new_string(hdrFrom));
    fl_value_set_string_take(args, kTo,        fl_value_new_string(hdrTo));

    fl_method_channel_invoke_method(channel_, kOnCallConnected, args,
        nullptr, nullptr, nullptr);
}

void EventHandler::OnCallIncoming(Siprix::CallId callId, Siprix::AccountId accId, bool withVideo, const char* hdrFrom, const char* hdrTo)
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string_take(args, kArgCallId,    fl_value_new_int(callId));
    fl_value_set_string_take(args, kArgAccId,     fl_value_new_int(accId));
    fl_value_set_string_take(args, kArgWithVideo, fl_value_new_bool(withVideo));
    fl_value_set_string_take(args, kFrom,         fl_value_new_string(hdrFrom));
    fl_value_set_string_take(args, kTo,           fl_value_new_string(hdrTo));

    fl_method_channel_invoke_method(channel_, kOnCallIncoming, args,
        nullptr, nullptr, nullptr);
}

void EventHandler::OnCallDtmfReceived(Siprix::CallId callId, uint16_t tone)
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string_take(args, kArgCallId, fl_value_new_int(callId));
    fl_value_set_string_take(args, kArgTone,   fl_value_new_int(tone));

    fl_method_channel_invoke_method(channel_, kOnCallDtmfReceived, args,
        nullptr, nullptr, nullptr);
}

void EventHandler::OnCallTransferred(Siprix::CallId callId, uint32_t statusCode)
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string_take(args, kArgCallId, fl_value_new_int(callId));
    fl_value_set_string_take(args, kArgStatusCode, fl_value_new_int(statusCode));

    fl_method_channel_invoke_method(channel_, kOnCallTransferred, args,
        nullptr, nullptr, nullptr);
}

void EventHandler::OnCallRedirected(Siprix::CallId origCallId, Siprix::CallId relatedCallId, const char* referTo)
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string_take(args, kArgFromCallId, fl_value_new_int(origCallId));
    fl_value_set_string_take(args, kArgToCallId, fl_value_new_int(relatedCallId));
    fl_value_set_string_take(args, kArgToExt, fl_value_new_string(referTo));

    fl_method_channel_invoke_method(channel_, kOnCallRedirected, args,
        nullptr, nullptr, nullptr);
}


void EventHandler::OnCallSwitched(Siprix::CallId callId)
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string_take(args, kArgCallId, fl_value_new_int(callId));

    fl_method_channel_invoke_method(channel_, kOnCallSwitched, args,
        nullptr, nullptr, nullptr);
}

void EventHandler::OnCallHeld(Siprix::CallId callId, Siprix::HoldState state)
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string_take(args, kArgCallId, fl_value_new_int(callId));
    fl_value_set_string_take(args, kHoldState, fl_value_new_int(state));

    fl_method_channel_invoke_method(channel_, kOnCallHeld, args,
        nullptr, nullptr, nullptr);
}

void EventHandler::OnMessageSentState(Siprix::MessageId messageId, bool success, const char* response)
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string_take(args, kArgMsgId, fl_value_new_int(messageId));
    fl_value_set_string_take(args, kSuccess,  fl_value_new_bool(success));
    fl_value_set_string_take(args, kResponse, fl_value_new_string(response));

    fl_method_channel_invoke_method(channel_, kOnMessageSentState, args,
        nullptr, nullptr, nullptr);
}

void EventHandler::OnMessageIncoming(Siprix::MessageId messageId, Siprix::AccountId accId, 
                                     const char* hdrFrom, const char* body)
{
    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string_take(args, kArgAccId, fl_value_new_int(accId));
    fl_value_set_string_take(args, kArgMsgId, fl_value_new_int(messageId));
    fl_value_set_string_take(args, kFrom,     fl_value_new_string(hdrFrom));
    fl_value_set_string_take(args, kBody,     fl_value_new_string(body));

    fl_method_channel_invoke_method(channel_, kOnMessageIncoming, args,
        nullptr, nullptr, nullptr);
}


////////////////////////////////////////////////////////////////////////////////////////
//FlutterVideoRenderer

FlutterVideoRenderer::FlutterVideoRenderer(flutter::TextureRegistrar* registrar) :
    textureRegistrar_(registrar)
{
}

FlutterVideoRenderer::~FlutterVideoRenderer()
{
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

