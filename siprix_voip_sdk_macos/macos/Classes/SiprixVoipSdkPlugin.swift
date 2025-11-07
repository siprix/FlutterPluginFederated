import Cocoa
import FlutterMacOS
import siprix

////////////////////////////////////////////////////////////////////////////////////////
//Method and argument names constants

private let kBadArgumentsError          = "Bad argument. Map with fields expected"
private let kModuleNotInitializedError  = "Siprix module has not initialized yet"

private let kChannelName                = "siprix_voip_sdk"

private let kMethodModuleInitialize     = "Module_Initialize"
private let kMethodModuleUnInitialize   = "Module_UnInitialize"
private let kMethodModuleHomeFolder     = "Module_HomeFolder"
private let kMethodModuleVersionCode    = "Module_VersionCode"
private let kMethodModuleVersion        = "Module_Version"

private let kMethodAccountAdd           = "Account_Add"
private let kMethodAccountUpdate        = "Account_Update"
private let kMethodAccountRegister      = "Account_Register"
private let kMethodAccountUnregister    = "Account_Unregister"
private let kMethodAccountDelete        = "Account_Delete"
private let kMethodAccountGenInstId     = "Account_GenInstId"

private let kMethodCallInvite           = "Call_Invite"
private let kMethodCallReject           = "Call_Reject"
private let kMethodCallAccept           = "Call_Accept"
private let kMethodCallHold             = "Call_Hold"
private let kMethodCallGetHoldState     = "Call_GetHoldState"
private let kMethodCallGetSipHeader     = "Call_GetSipHeader";
private let kMethodCallGetStats         = "Call_GetStats";
private let kMethodCallMuteMic          = "Call_MuteMic"
private let kMethodCallMuteCam          = "Call_MuteCam"
private let kMethodCallSendDtmf         = "Call_SendDtmf"
private let kMethodCallPlayFile         = "Call_PlayFile"
private let kMethodCallStopPlayFile     = "Call_StopPlayFile"
private let kMethodCallRecordFile       = "Call_RecordFile"
private let kMethodCallStopRecordFile   = "Call_StopRecordFile"
private let kMethodCallTransferBlind    = "Call_TransferBlind"
private let kMethodCallTransferAttended = "Call_TransferAttended"
private let kMethodCallUpgradeToVideo   = "Call_UpgradeToVideo"
private let kMethodCallStopRingtone     = "Call_StopRingtone"
private let kMethodCallBye              = "Call_Bye"

private let kMethodMixerSwitchToCall   = "Mixer_SwitchToCall"
private let kMethodMixerMakeConference = "Mixer_MakeConference"

private let kMethodMessageSend         = "Message_Send"

private let kMethodSubscriptionAdd     = "Subscription_Add"
private let kMethodSubscriptionDelete  = "Subscription_Delete"

private let kMethodDvcGetPlayoutNumber = "Dvc_GetPlayoutDevices"
private let kMethodDvcGetRecordNumber  = "Dvc_GetRecordingDevices"
private let kMethodDvcGetVideoNumber   = "Dvc_GetVideoDevices"
private let kMethodDvcGetPlayout       = "Dvc_GetPlayoutDevice"
private let kMethodDvcGetRecording     = "Dvc_GetRecordingDevice"
private let kMethodDvcGetVideo         = "Dvc_GetVideoDevice"
private let kMethodDvcSetPlayout       = "Dvc_SetPlayoutDevice"
private let kMethodDvcSetRecording     = "Dvc_SetRecordingDevice"
private let kMethodDvcSetVideo         = "Dvc_SetVideoDevice"
private let kMethodDvcSetVideoParams   = "Dvc_SetVideoParams"

private let kMethodVideoRendererCreate  = "Video_RendererCreate"
private let kMethodVideoRendererSetSrc  = "Video_RendererSetSrc"
private let kMethodVideoRendererDispose = "Video_RendererDispose"

private let kOnTrialModeNotif   = "OnTrialModeNotif"
private let kOnDevicesChanged   = "OnDevicesChanged"
private let kOnAccountRegState  = "OnAccountRegState"
private let kOnSubscriptionState = "OnSubscriptionState"
private let kOnNetworkState     = "OnNetworkState"
private let kOnPlayerState      = "OnPlayerState"
private let kOnRingerState      = "OnRingerState"
private let kOnCallProceeding   = "OnCallProceeding"
private let kOnCallTerminated   = "OnCallTerminated"
private let kOnCallConnected    = "OnCallConnected"
private let kOnCallIncoming     = "OnCallIncoming"
private let kOnCallDtmfReceived = "OnCallDtmfReceived"
private let kOnCallTransferred  = "OnCallTransferred"
private let kOnCallRedirected   = "OnCallRedirected"
private let kOnCallVideoUpgraded = "OnCallVideoUpgraded";
private let kOnCallSwitched     = "OnCallSwitched"
private let kOnCallHeld         = "OnCallHeld"

private let kOnMessageSentState = "OnMessageSentState"
private let kOnMessageIncoming  = "OnMessageIncoming"

private let kOnSipNotify        = "OnSipNotify";
private let kOnVuMeterLevel     = "OnVuMeterLevel";

private let kArgVideoTextureId  = "videoTextureId"

private let kArgStatusCode = "statusCode"
private let kArgExpireTime = "expireTime"
private let kArgWithVideo  = "withVideo"

private let kArgDvcIndex = "dvcIndex"
private let kArgDvcName  = "dvcName"
private let kArgDvcGuid  = "dvcGuid"

private let kArgCallId     = "callId"
private let kArgFromCallId = "fromCallId"
private let kArgToCallId   = "toCallId"
private let kArgToExt      = "toExt"

private let kArgAccId    = "accId"
private let kArgPlayerId = "playerId"
private let kArgSubscrId = "subscrId"
private let kArgMsgId    = "msgId"
private let kRegState    = "regState"
private let kHoldState   = "holdState"
private let kPlayerState = "playerState"
private let kSubscrState = "subscrState"
private let kNetState    = "netState"
private let kResponse    = "response"
private let kSuccess     = "success"

private let kArgName  = "name"
private let kArgTone  = "tone"
private let kFrom     = "from"
private let kTo       = "to"
private let kBody     = "body"
private let kEvent    = "event";
private let kMicLevel = "mic";
private let kSpkLevel = "spk";


////////////////////////////////////////////////////////////////////////////////////////
//SiprixEventHandler
class SiprixEventHandler : NSObject, SiprixEventDelegate {
    
    var _channel : FlutterMethodChannel
    init(withChannel channel:FlutterMethodChannel) {
        self._channel = channel
    }
    
    //////////////////////////////////////////////////////////////////////////
    //Event handlers
    
    public func onTrialModeNotified() {
        DispatchQueue.main.async {
            let argsMap = [String:Any]()
            self._channel.invokeMethod(kOnTrialModeNotif, arguments: argsMap)
        }
    }

    public func onDevicesAudioChanged() {
        DispatchQueue.main.async {
            let argsMap = [String:Any]()
            self._channel.invokeMethod(kOnDevicesChanged, arguments: argsMap)
        }
    }
    
    public func onAccountRegState(_ accId: Int, regState: RegState, response: String) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgAccId] = accId
            argsMap[kRegState] = regState.rawValue
            argsMap[kResponse] = response
            self._channel.invokeMethod(kOnAccountRegState, arguments: argsMap)
        }
    }
    
    public func onSubscriptionState(_ subscrId: Int, subscrState: SubscrState, response: String) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgSubscrId] = subscrId
            argsMap[kSubscrState] = subscrState.rawValue
            argsMap[kResponse] = response
            self._channel.invokeMethod(kOnSubscriptionState, arguments: argsMap)
        }
    }
    
    public func onNetworkState(_ name: String, netState: NetworkState) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgName] = name
            argsMap[kNetState] = netState.rawValue
            self._channel.invokeMethod(kOnNetworkState, arguments: argsMap)
        }
    }

    public func onPlayerState(_ playerId: Int, playerState: PlayerState) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgPlayerId] = playerId
            argsMap[kPlayerState] = playerState.rawValue
            self._channel.invokeMethod(kOnPlayerState, arguments: argsMap)
        }
    }
    
    public func onRingerState(_ started: Bool) {    
    }

    public func onCallProceeding(_ callId: Int, response:String){
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgCallId] = callId
            argsMap[kResponse] = response
            self._channel.invokeMethod(kOnCallProceeding, arguments: argsMap)
        }
    }

    public func onCallTerminated(_ callId: Int, statusCode:Int) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgCallId] = callId
            argsMap[kArgStatusCode] = statusCode
            self._channel.invokeMethod(kOnCallTerminated, arguments: argsMap)
        }
    }

    public func onCallConnected(_ callId: Int, hdrFrom:String, hdrTo:String, withVideo:Bool) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgWithVideo] = withVideo
            argsMap[kArgCallId] = callId
            argsMap[kFrom] = hdrFrom
            argsMap[kTo] = hdrTo
            self._channel.invokeMethod(kOnCallConnected, arguments: argsMap)
        }
    }

    public func onCallIncoming(_ callId:Int, accId:Int, withVideo:Bool, hdrFrom:String, hdrTo:String) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgWithVideo] = withVideo
            argsMap[kArgCallId] = callId
            argsMap[kArgAccId] = accId
            argsMap[kFrom] = hdrFrom
            argsMap[kTo] = hdrTo
            self._channel.invokeMethod(kOnCallIncoming, arguments: argsMap)
        }
    }

    public func onCallDtmfReceived(_ callId:Int, tone:Int) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgCallId] = callId
            argsMap[kArgTone] = tone
            self._channel.invokeMethod(kOnCallDtmfReceived, arguments: argsMap)
        }
    }

    public func onCallSwitched(_ callId: Int) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgCallId] = callId
            self._channel.invokeMethod(kOnCallSwitched, arguments: argsMap)
        }
    }
    
    public func onCallTransferred(_ callId: Int, statusCode: Int) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgCallId] = callId
            argsMap[kArgStatusCode] = statusCode
            self._channel.invokeMethod(kOnCallTransferred, arguments: argsMap)
        }
    }
    
    public func onCallRedirected(_ origCallId: Int, relatedCallId: Int, referTo: String) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgFromCallId] = origCallId
            argsMap[kArgToCallId] = relatedCallId
            argsMap[kArgToExt] = referTo
            self._channel.invokeMethod(kOnCallRedirected, arguments: argsMap)
        }
    }

    public func onCallVideoUpgraded(_ callId: Int, withVideo:Bool) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgCallId] = callId
            argsMap[kArgWithVideo] = withVideo
            self._channel.invokeMethod(kOnCallVideoUpgraded, arguments: argsMap)
        }
    }

    public func onCallHeld(_ callId: Int, holdState: HoldState) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgCallId] = callId
            argsMap[kHoldState] = holdState.rawValue
            self._channel.invokeMethod(kOnCallHeld, arguments: argsMap)
        }
    }

    public func onMessageSentState(_ messageId:Int, success:Bool, response:String) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgMsgId] = messageId
            argsMap[kSuccess] = success
            argsMap[kResponse] = response
            self._channel.invokeMethod(kOnMessageSentState, arguments: argsMap)
        }
    }

    public func onMessageIncoming(_ messageId:Int, accId:Int, hdrFrom:String, body:String) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgMsgId] = messageId
            argsMap[kArgAccId] = accId
            argsMap[kFrom] = hdrFrom
            argsMap[kBody] = body
            self._channel.invokeMethod(kOnMessageIncoming, arguments: argsMap)
        }
    }

    public func onSipNotify(_ accId:Int, hdrEvent:String, body:String) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgAccId] = accId
            argsMap[kEvent] = hdrEvent
            argsMap[kBody] = body
            self._channel.invokeMethod(kOnSipNotify, arguments: argsMap)
        }
    }

    public func onVuMeterLevel(_ micLevel:Int, spkLevel:Int) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kMicLevel] = micLevel
            argsMap[kSpkLevel] = spkLevel
            self._channel.invokeMethod(kOnVuMeterLevel, arguments: argsMap)
        }
    }
}


///////////////////////////////////////////////////////////////////////////////////////
//FlutterVideoRenderer
class FlutterVideoRenderer : NSObject, SiprixVideoRendererDelegate, FlutterTexture, FlutterStreamHandler {
    struct EventData {
        var width: Int32 = 0
        var height: Int32 = 0
        var rotation: VideoFrameRotation = .rotation_0
    }
    var _eventData = EventData()
    var _textureRegistry : FlutterTextureRegistry
    var _eventChannel : FlutterEventChannel?
    var _eventSink : FlutterEventSink?
    var _pixelBuffer : CVPixelBuffer? = nil
    var _pixelBufferWidth = 0
    var _pixelBufferHeight = 0
    var _textureId : Int64 = 0
    public var srcCallId : Int32 = 0
            
    init(textureRegistry:FlutterTextureRegistry) {
        self._textureRegistry = textureRegistry
    }
    
    deinit {
        _textureRegistry.unregisterTexture(_textureId)
    }
    
    public func registerTextureAndCreateChannel(binMessenger : FlutterBinaryMessenger) -> Int64 {
        _textureId = _textureRegistry.register(self)
        
        _eventChannel = FlutterEventChannel(name:"Siprix/Texture\(_textureId)", binaryMessenger:binMessenger)
        _eventChannel?.setStreamHandler(self)
        return _textureId
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self._eventSink = events
        return nil
    }
       
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self._eventSink = nil
        return nil
    }
    
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
      if (_pixelBuffer != nil) {
        return Unmanaged<CVPixelBuffer>.passRetained(_pixelBuffer!)
      }
      return nil
    }
    
    func copyFrameToCVPixelBuffer(frame : SiprixVideoFrame) {
        if (_pixelBufferWidth != frame.width() || _pixelBufferHeight != frame.height()) {
            _pixelBufferWidth  = Int(frame.width())
            _pixelBufferHeight = Int(frame.height())
            print("siprix: Got new video frame \(_pixelBufferWidth)x\(_pixelBufferHeight) \(frame.rotation()) textureId:\(_textureId)")
            
            let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                         kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
                         kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue] as CFDictionary
            
            CVPixelBufferCreate(nil, _pixelBufferWidth, _pixelBufferHeight,
                                kCVPixelFormatType_32BGRA, attrs, &_pixelBuffer)
        }
        
        CVPixelBufferLockBaseAddress(_pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let bytesPerRow = CVPixelBufferGetBytesPerRow(_pixelBuffer!)
        if let baseAddress = CVPixelBufferGetBaseAddress(_pixelBuffer!) {
            let buf = baseAddress.assumingMemoryBound(to: UInt8.self)
            frame.convert(toARGB: .ARGB, dstBuffer: buf, 
                          dstWidth: frame.width(), dstHeight: frame.height(),
                          dstStride: Int32(bytesPerRow))
        }
        CVPixelBufferUnlockBaseAddress(_pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    }
        
    public func onFrame(_ videoFrame : SiprixVideoFrame) {
        copyFrameToCVPixelBuffer(frame:videoFrame)
        sendEvent(frame:videoFrame)
        DispatchQueue.main.async {
            self._textureRegistry.textureFrameAvailable(self._textureId)
        }
    }
    
    func degrees(_ rotation : VideoFrameRotation) -> Int32 {
        switch(rotation) {
            case VideoFrameRotation.rotation_90: return 90
            case VideoFrameRotation.rotation_180: return 180
            case VideoFrameRotation.rotation_270: return 270
            default: return 0
        }
    }

    func sendEvent(frame : SiprixVideoFrame) {
        if(_eventData.rotation != frame.rotation()) {
            _eventData.rotation = frame.rotation()
            if(_eventSink != nil) {
                var argsMap = [String:Any]()
                argsMap["event"]  = "didTextureChangeRotation"
                argsMap["id"]     = _textureId
                argsMap["rotation"]  = degrees(_eventData.rotation)
                DispatchQueue.main.async {
                    self._eventSink!(argsMap)
                }
            }
        }
        
        if(_eventData.width != frame.width() || _eventData.height != frame.height()) {
            _eventData.width = frame.width()
            _eventData.height = frame.height()
            if(_eventSink != nil) {
                var argsMap = [String:Any]()
                argsMap["event"]  = "didTextureChangeVideoSize"
                argsMap["id"]     = _textureId
                argsMap["width"]  = _eventData.width
                argsMap["height"] = _eventData.height
                DispatchQueue.main.async {
                    self._eventSink!(argsMap)
                }
            }
        }
    }//sendEvent
    
}//FlutterVideoRenderer


////////////////////////////////////////////////////////////////////////////////////////
//SiprixVoipSdkPlugin
public class SiprixVoipSdkPlugin: NSObject, FlutterPlugin {
    typealias ArgsMap = Dictionary<AnyHashable,Any>
    
    var _siprixModule : SiprixModule
    var _eventHandler : SiprixEventHandler
    var _textureRegistry : FlutterTextureRegistry
    var _binMessenger : FlutterBinaryMessenger
    var _renderers = [Int64 : FlutterVideoRenderer]()
    var _initialized = false
    
    init(withChannel channel:FlutterMethodChannel, registrar: FlutterPluginRegistrar) {
        self._siprixModule = SiprixModule()
        self._eventHandler = SiprixEventHandler(withChannel:channel)
        self._textureRegistry = registrar.textures
        self._binMessenger = registrar.messenger
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
      let channel = FlutterMethodChannel(name: kChannelName, binaryMessenger: registrar.messenger)
        
      let instance = SiprixVoipSdkPlugin(withChannel:channel, registrar:registrar)
      registrar.addMethodCallDelegate(instance, channel: channel)
    }
        
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let argsMap = call.arguments as? ArgsMap
        if (argsMap==nil) {
            result(FlutterError(code: "-", message: kBadArgumentsError, details: nil))
            return
        }
        
        if(_initialized) {
            switch call.method {
                case kMethodModuleInitialize   :  handleModuleInitialize(argsMap!, result:result)
                case kMethodModuleUnInitialize :  handleModuleUnInitialize(argsMap!, result:result)
                case kMethodModuleHomeFolder   :  handleModuleHomeFolder(argsMap!, result:result)
                case kMethodModuleVersionCode  :  handleModuleVersionCode(argsMap!, result:result)
                case kMethodModuleVersion      :  handleModuleVersion(argsMap!, result:result)
                
                case kMethodAccountAdd         :  handleAccountAdd(argsMap!, result:result)
                case kMethodAccountUpdate      :  handleAccountUpdate(argsMap!, result:result)
                case kMethodAccountRegister    :  handleAccountRegister(argsMap!, result:result)
                case kMethodAccountUnregister  :  handleAccountUnregister(argsMap!, result:result)
                case kMethodAccountDelete      :  handleAccountDelete(argsMap!, result:result)
                case kMethodAccountGenInstId   :  handleAccountGenInstId(argsMap!, result:result)
                
                case kMethodCallInvite        :   handleCallInvite(argsMap!, result:result)
                case kMethodCallReject        :   handleCallReject(argsMap!, result:result)
                case kMethodCallAccept        :   handleCallAccept(argsMap!, result:result)
                case kMethodCallHold          :   handleCallHold(argsMap!, result:result)
                case kMethodCallGetHoldState  :   handleCallGetHoldState(argsMap!, result:result)
                case kMethodCallGetSipHeader  :   handleCallGetSipHeader(argsMap!, result:result)
                case kMethodCallGetStats      :   handleCallGetStats(argsMap!, result:result)
                case kMethodCallMuteMic       :   handleCallMuteMic(argsMap!, result:result)
                case kMethodCallMuteCam       :   handleCallMuteCam(argsMap!, result:result)
                case kMethodCallSendDtmf      :   handleCallSendDtmf(argsMap!, result:result)
                case kMethodCallPlayFile      :   handleCallPlayFile(argsMap!, result:result)
                case kMethodCallStopPlayFile  :   handleCallStopPlayFile(argsMap!, result:result)
                case kMethodCallRecordFile    :   handleCallRecordFile(argsMap!, result:result)
                case kMethodCallStopRecordFile:   handleCallStopRecordFile(argsMap!, result:result)
                case kMethodCallTransferBlind :   handleCallTransferBlind(argsMap!, result:result)
                case kMethodCallTransferAttended : handleCallTransferAttended(argsMap!, result:result)
                case kMethodCallUpgradeToVideo:   handleCallUpgradeToVideo(argsMap!, result:result)
                case kMethodCallStopRingtone  :   handleCallStopRingtone(argsMap!, result:result)
                case kMethodCallBye           :   handleCallBye(argsMap!, result:result)

                case kMethodMixerSwitchToCall :   handleMixerSwitchToCall(argsMap!, result:result)
                case kMethodMixerMakeConference : handleMixerMakeConference(argsMap!, result:result)

                case kMethodMessageSend :          handleMessageSend(argsMap!, result:result)

                case kMethodSubscriptionAdd    :   handleSubscriptionAdd(argsMap!, result:result)
                case kMethodSubscriptionDelete :   handleSubscriptionDelete(argsMap!, result:result)

                case kMethodDvcGetPlayoutNumber:   handleDvcGetPlayoutNumber(argsMap!, result:result)
                case kMethodDvcGetRecordNumber :   handleDvcGetRecordNumber(argsMap!, result:result)
                case kMethodDvcGetVideoNumber  :   handleDvcGetVideoNumber(argsMap!, result:result)
                case kMethodDvcGetPlayout      :   handleDvcGetPlayout(argsMap!, result:result)
                case kMethodDvcGetRecording    :   handleDvcGetRecording(argsMap!, result:result)
                case kMethodDvcGetVideo        :   handleDvcGetVideo(argsMap!, result:result)
                case kMethodDvcSetPlayout      :   handleDvcSetPlayout(argsMap!, result:result)
                case kMethodDvcSetRecording    :   handleDvcSetRecording(argsMap!, result:result)
                case kMethodDvcSetVideo        :   handleDvcSetVideo(argsMap!, result:result)
                case kMethodDvcSetVideoParams  :   handleDvcSetVideoParams(argsMap!, result:result)
                
                case kMethodVideoRendererCreate :  handleVideoRendererCreate(argsMap!, result:result)
                case kMethodVideoRendererSetSrc :  handleVideoRendererSetSrc(argsMap!, result:result)
                case kMethodVideoRendererDispose:  handleVideoRendererDispose(argsMap!, result:result)

                default:       result(FlutterMethodNotImplemented)
            }//switch
        }else{
            if(call.method==kMethodModuleInitialize) { handleModuleInitialize(argsMap!, result:result) }
            else { result(FlutterError(code: "UNAVAILABLE", message:kModuleNotInitializedError, details: nil)) }
        }
    }//handle
        
    deinit {
         _siprixModule.unInitialize()
    }
    
    func handleModuleInitialize(_ args : ArgsMap, result: @escaping FlutterResult) {
        //Check already initialized
        if (_siprixModule.isInitialized()) {
            _initialized = true
            result("Already initialized")
            return
        }
        
        //Get arguments from map
        let iniData = SiprixIniData()
        
        let license = args["license"] as? String
        if(license != nil) { iniData.license = license }
 
        let brandName = args["brandName"] as? String
        if(brandName != nil) { iniData.brandName = brandName }
        
        let logLevelFile = args["logLevelFile"] as? Int
        if(logLevelFile != nil) { iniData.logLevelFile = NSNumber(value: logLevelFile!) }
        
        let logLevelIde = args["logLevelIde"] as? Int
        if(logLevelIde != nil) { iniData.logLevelIde = NSNumber(value: logLevelIde!) }
        
        let rtpStartPort = args["rtpStartPort"] as? Int
        if(rtpStartPort != nil) { iniData.rtpStartPort = NSNumber(value: rtpStartPort!) }
        
        let tlsVerifyServer = args["tlsVerifyServer"] as? Bool
        if(tlsVerifyServer != nil) { iniData.tlsVerifyServer = NSNumber(value: tlsVerifyServer!) }
        
        let singleCallMode = args["singleCallMode"] as? Bool
        if(singleCallMode != nil) { iniData.singleCallMode = NSNumber(value: singleCallMode!) }
        
        let shareUdpTransport = args["shareUdpTransport"] as? Bool
        if(shareUdpTransport != nil) { iniData.shareUdpTransport = NSNumber(value: shareUdpTransport!) }

        let unregOnDestroy = args["unregOnDestroy"] as? Bool
        if(unregOnDestroy != nil) { iniData.unregOnDestroy = NSNumber(value: unregOnDestroy!) }

        let useDnsSrv = args["useDnsSrv"] as? Bool
        if(useDnsSrv != nil) { iniData.useDnsSrv = NSNumber(value: useDnsSrv!) }

        let recordStereo = args["recordStereo"] as? Bool
        if(recordStereo != nil) { iniData.recordStereo = NSNumber(value: recordStereo!) }

        let enableVideoCall = args["enableVideoCall"] as? Bool
        if(enableVideoCall != nil) { iniData.enableVideoCall = NSNumber(value: enableVideoCall!) }

        let transpForceIPv4 = args["transpForceIPv4"] as? Bool
        if(transpForceIPv4 != nil) { iniData.transpForceIPv4 = NSNumber(value: transpForceIPv4!) }

        let enableAes128Sha32 = args["enableAes128Sha32"] as? Bool
        if(enableAes128Sha32 != nil) { iniData.enableAes128Sha32 = NSNumber(value: enableAes128Sha32!) }

        let enableVUmeter = args["enableVUmeter"] as? Bool
        if(enableVUmeter != nil) { iniData.enableVUmeter = NSNumber(value: enableVUmeter!) }

        let err = _siprixModule.initialize(_eventHandler, iniData:iniData)
        _initialized = (err == kErrorCodeEOK)
        sendResult(err, result:result)
    }
        
    func handleModuleUnInitialize(_ args : ArgsMap, result: @escaping FlutterResult) {
        let err = _siprixModule.unInitialize()
        _initialized = false
        sendResult(err, result:result)
    }

    func handleModuleHomeFolder(_ args : ArgsMap, result: @escaping FlutterResult) {
        let path = _siprixModule.homeFolder()
        result(path)
    }

    func handleModuleVersionCode(_ args : ArgsMap, result: @escaping FlutterResult) {
        let versionCode = _siprixModule.versionCode()
        result(versionCode)
    }

    func handleModuleVersion(_ args : ArgsMap, result: @escaping FlutterResult) {
        let version = _siprixModule.version()
        result(version)
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    //Siprix Account methods implementation

    func parseAccData(_ args : ArgsMap) -> SiprixAccData {
        //Get arguments from map
        let accData = SiprixAccData()
        
        let sipServer = args["sipServer"] as? String
        if(sipServer != nil) { accData.sipServer = sipServer! }
        
        let sipExtension = args["sipExtension"] as? String
        if(sipExtension != nil) { accData.sipExtension = sipExtension! }
        
        let sipPassword = args["sipPassword"] as? String
        if(sipPassword != nil) { accData.sipPassword = sipPassword! }
        
        let sipAuthId = args["sipAuthId"] as? String
        if(sipAuthId != nil) { accData.sipAuthId = sipAuthId! }
        
        let sipProxy = args["sipProxy"] as? String
        if(sipProxy != nil) { accData.sipProxy = sipProxy! }
        
        let displName = args["displName"] as? String
        if(displName != nil) { accData.displName = displName! }

        let userAgent = args["userAgent"] as? String
        if(userAgent != nil) { accData.userAgent = userAgent! }
        
        let expireTime = args["expireTime"] as? Int
        if(expireTime != nil) { accData.expireTime = NSNumber(value:expireTime!) }
      
        let transport = args["transport"] as? Int
        if(transport != nil) { accData.transport = SipTransport(rawValue: transport!)! }

        let port = args["port"] as? Int
        if(port != nil) { accData.port = NSNumber(value:port!) }

        let tlsCaCertPath = args["userAgent"] as? String
        if(tlsCaCertPath != nil) { accData.tlsCaCertPath = tlsCaCertPath! }

        let tlsUseSipScheme = args["tlsUseSipScheme"] as? Bool
        if(tlsUseSipScheme != nil) { accData.tlsUseSipScheme = NSNumber(value:tlsUseSipScheme!) }

        let rtcpMuxEnabled = args["rtcpMuxEnabled"] as? Bool
        if(rtcpMuxEnabled != nil) { accData.rtcpMuxEnabled = NSNumber(value:rtcpMuxEnabled!) }

        let iceEnabled = args["iceEnabled"] as? Bool
        if(iceEnabled != nil) { accData.iceEnabled = NSNumber(value:iceEnabled!) }

        let instanceId = args["instanceId"] as? String
        if(instanceId != nil) { accData.instanceId = instanceId! }
        
        let ringTonePath = args["ringTonePath"] as? String
        if(ringTonePath != nil) { accData.ringTonePath = ringTonePath! }

        let keepAliveTime = args["keepAliveTime"] as? Int
        if(keepAliveTime != nil) { accData.keepAliveTime = NSNumber(value:keepAliveTime!) }

        let rewriteContactIp = args["rewriteContactIp"] as? Bool
        if(rewriteContactIp != nil) { accData.rewriteContactIp = NSNumber(value: rewriteContactIp!) }
        
        let verifyIncomingCall = args["verifyIncomingCall"] as? Bool
        if(verifyIncomingCall != nil) { accData.verifyIncomingCall = NSNumber(value: verifyIncomingCall!) }
        
        let forceSipProxy = args["forceSipProxy"] as? Bool
        if(forceSipProxy != nil) { accData.forceSipProxy = NSNumber(value: forceSipProxy!) }
        
        let secureMedia = args["secureMedia"] as? Int
        if(secureMedia != nil) { accData.secureMedia = NSNumber(value:secureMedia!) }

        let upgradeToVideo = args["upgradeToVideo"] as? Int
        if(upgradeToVideo != nil) { accData.upgradeToVideo = NSNumber(value:upgradeToVideo!) }
         
        let xheaders = args["xheaders"] as? Dictionary<AnyHashable,Any>
        if(xheaders != nil) { accData.xheaders = xheaders }

        let stunServer = args["stunServer"] as? String
        if(stunServer != nil) { accData.stunServer = stunServer! }

        let turnServer = args["turnServer"] as? String
        if(turnServer != nil) { accData.turnServer = turnServer! }

        let turnUser = args["turnUser"] as? String
        if(turnUser != nil) { accData.turnUser = turnUser! }

        let turnPassword = args["turnPassword"] as? String
        if(turnPassword != nil) { accData.turnPassword = turnPassword! }
        
        let xContactUriParams = args["xContactUriParams"] as? Dictionary<AnyHashable,Any>
        if(xContactUriParams != nil) { accData.xContactUriParams = xContactUriParams }
        
        let aCodecs = args["aCodecs"] as? [Int]
        if(aCodecs != nil) { accData.aCodecs = aCodecs }
        
        let vCodecs = args["vCodecs"] as? [Int]
        if(vCodecs != nil) { accData.vCodecs = vCodecs }
        
        return accData
    }
    
    func handleAccountAdd(_ args : ArgsMap, result: @escaping FlutterResult) {
        let accData = parseAccData(args)
        let err = _siprixModule.accountAdd(accData)
        if(err == kErrorCodeEOK){
            result(accData.myAccId)
        }else{
            result(FlutterError(code: String(err), message: _siprixModule.getErrorText(err), details: accData.myAccId))
        }
    }
    
    func handleAccountUpdate(_ args : ArgsMap, result: @escaping FlutterResult) {
        let accData = parseAccData(args)
        let accId   = args[kArgAccId] as? Int

        if(accId != nil) {
            let err = _siprixModule.accountUpdate(accData, accId:Int32(accId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleAccountRegister(_ args : ArgsMap, result: @escaping FlutterResult) {
        let accId      = args[kArgAccId] as? Int
        let expireTime = args[kArgExpireTime] as? Int

        if((accId != nil) && ( expireTime != nil)) {
            let err = _siprixModule.accountRegister(Int32(accId!), expireTime:Int32(expireTime!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleAccountUnregister(_ args : ArgsMap, result: @escaping FlutterResult) {
        let accId = args[kArgAccId] as? Int

        if(accId != nil) {
            let err = _siprixModule.accountUnRegister(Int32(accId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleAccountDelete(_ args : ArgsMap, result: @escaping FlutterResult) {
        let accId = args[kArgAccId] as? Int

        if(accId != nil) {
            let err = _siprixModule.accountDelete(Int32(accId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

     func handleAccountGenInstId(_ args : ArgsMap, result: @escaping FlutterResult) {
        let instId = _siprixModule.accountGenInstId()
        result(instId)
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    //Siprix Calls methods implementation

    func handleCallInvite(_ args : ArgsMap, result: @escaping FlutterResult) {
        //Get arguments from map
        let destData = SiprixDestData()
        
        let toExt = args["extension"] as? String
        if(toExt != nil) { destData.toExt = toExt! }
        
        let fromAccId = args[kArgAccId] as? Int
        if(fromAccId != nil) { destData.fromAccId = Int32(fromAccId!) }

        let inviteTimeout = args["inviteTimeout"] as? Int
        if(inviteTimeout != nil) { destData.inviteTimeoutSec = NSNumber(value:inviteTimeout!) }
        
        let withVideo = args[kArgWithVideo] as? Bool
        if(withVideo != nil) { destData.withVideo = NSNumber(value: withVideo!) }
        
        let xheaders = args["xheaders"] as? Dictionary<AnyHashable,Any>
        if(xheaders != nil) { destData.xheaders = xheaders }
     
        let displName = args["displName"] as? String
        if(displName != nil) { destData.displName = displName! }
     
        let err = _siprixModule.callInvite(destData)
        if(err == kErrorCodeEOK){
            result(destData.myCallId)
        }else{
            result(FlutterError(code: String(err), message: _siprixModule.getErrorText(err), details: nil))
        }
    }

    func handleCallReject(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId     = args[kArgCallId] as? Int
        let statusCode = args[kArgStatusCode] as? Int

        if((callId != nil) && ( statusCode != nil)) {
            let err = _siprixModule.callReject(Int32(callId!), statusCode:Int32(statusCode!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleCallAccept(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int
        let withVideo = args[kArgWithVideo] as? Bool

        if((callId != nil)&&(withVideo != nil)) {
            let err = _siprixModule.callAccept(Int32(callId!), withVideo:withVideo!)
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleCallHold(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int

        if(callId != nil) {
            let err = _siprixModule.callHold(Int32(callId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleCallGetHoldState(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int

        if(callId == nil) {
            sendBadArguments(result:result)
            return
        }
        
        let data = SiprixHoldData()
        let err = _siprixModule.callGetHoldState(Int32(callId!), holdState:data)
        if(err == kErrorCodeEOK){
            result(data.holdState.rawValue)
        }else{
            result(FlutterError(code: String(err), message: _siprixModule.getErrorText(err), details: nil))
        }
    }

    func handleCallGetSipHeader(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int
        let hdrName = args["hdrName"] as? String

        if((callId == nil)||(hdrName == nil)) {
            sendBadArguments(result:result)
            return
        }
        
        let hdrVal = _siprixModule.callGetSipHeader(Int32(callId!), hdrName:hdrName!)
        result(hdrVal)
    }

    func handleCallGetStats(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int

        if(callId == nil) {
            sendBadArguments(result:result)
            return
        }
        
        let statsVal = _siprixModule.callGetStats(Int32(callId!))
        result(statsVal)
    }

    func handleCallMuteMic(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int
        let mute   = args["mute"] as? Bool

        if((callId == nil)||(mute==nil)) {
            sendBadArguments(result:result)
            return
        }
        let err = _siprixModule.callMuteMic(Int32(callId!), mute:mute!)
        sendResult(err, result:result)
    }

    func handleCallMuteCam(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int
        let mute   = args["mute"] as? Bool

        if((callId == nil)||(mute==nil)) {
            sendBadArguments(result:result)
            return
        }
        let err = _siprixModule.callMuteCam(Int32(callId!), mute:mute!)
        sendResult(err, result:result)
    }

    func handleCallSendDtmf(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId         = args[kArgCallId] as? Int
        let durationMs     = args["durationMs"] as? Int
        let intertoneGapMs = args["intertoneGapMs"] as? Int
        let method         = args["method"] as? Int
        let dtmfs          = args["dtmfs"] as? String
        
        if((callId == nil)||(durationMs==nil)||(intertoneGapMs==nil)||(dtmfs==nil)||(method==nil)) {
            sendBadArguments(result:result)
            return
        }
        let m = (method! == DtmfMethod.rtp.rawValue) ? DtmfMethod.rtp : DtmfMethod.info
        
        let err = _siprixModule.callSendDtmf(Int32(callId!), dtmfs:dtmfs!,
                                    durationMs:Int32(durationMs!),
                                    intertoneGapMs:Int32(intertoneGapMs!),
                                    method:m)
        sendResult(err, result:result)
    }

    func handleCallPlayFile(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId        = args[kArgCallId] as? Int
        let pathToMp3File = args["pathToMp3File"] as? String
        let loop          = args["loop"] as? Bool
        
        if((callId == nil)||(pathToMp3File==nil)||(loop==nil)) {
            sendBadArguments(result:result)
            return
        }
        
        let data = SiprixPlayerData()
        let err = _siprixModule.callPlayFile(Int32(callId!), pathToMp3File:pathToMp3File!, 
                                              loop:loop!, playerData:data)
        if(err == kErrorCodeEOK){
            result(data.playerId)
        }else{
            result(FlutterError(code: String(err), message: _siprixModule.getErrorText(err), details: nil))
        }
    }
    
    func handleCallStopPlayFile(_ args : ArgsMap, result: @escaping FlutterResult) {
        let playerId = args[kArgPlayerId] as? Int
        
        if(playerId != nil) {
            let err = _siprixModule.callStopPlayFile(Int32(playerId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

 func handleCallRecordFile(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId        = args[kArgCallId] as? Int
        let pathToMp3File = args["pathToMp3File"] as? String
        
        if((callId != nil)||(pathToMp3File != nil)) {
            let err = _siprixModule.callRecordFile(Int32(callId!), pathToMp3File:pathToMp3File!)
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }
    
    func handleCallStopRecordFile(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int
        
        if(callId != nil) {
            let err = _siprixModule.callStopRecordFile(Int32(callId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleCallTransferBlind(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int
        let toExt  = args[kArgToExt] as? String
        
        if((callId != nil) && ( toExt != nil)) {
            let err = _siprixModule.callTransferBlind(Int32(callId!), toExt:toExt!)
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleCallTransferAttended(_ args : ArgsMap, result: @escaping FlutterResult) {
        let fromCallId = args[kArgFromCallId] as? Int
        let toCallId   = args[kArgToCallId] as? Int
        
        if((fromCallId != nil) && ( toCallId != nil)) {
            let err = _siprixModule.callTransferAttended(Int32(fromCallId!), toCallId:Int32(toCallId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleCallUpgradeToVideo(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int
        
        if(callId != nil) {
            let err = _siprixModule.callUpgrade(toVideo:Int32(callId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleCallBye(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int

        if(callId != nil) {
            let err = _siprixModule.callBye(Int32(callId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleCallStopRingtone(_ args : ArgsMap, result: @escaping FlutterResult) {
        _siprixModule.callStopRingtone()
        result(kErrorCodeEOK)
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    //Siprix Mixer methods implementation

    func handleMixerSwitchToCall(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int

        if(callId != nil) {
            let err = _siprixModule.mixerSwitchCall(Int32(callId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleMixerMakeConference(_ args : ArgsMap, result: @escaping FlutterResult) {
        let err = _siprixModule.mixerMakeConference()
        sendResult(err, result:result)
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    //Siprix messages

    func handleMessageSend(_ args : ArgsMap, result: @escaping FlutterResult) {
        //Get arguments from map
        let msgData = SiprixMsgData()
        
        let toExt = args["extension"] as? String
        if(toExt != nil) { msgData.toExt = toExt! }
        
        let fromAccId = args[kArgAccId] as? Int
        if(fromAccId != nil) { msgData.fromAccId = Int32(fromAccId!) }
       
        let body = args[kBody] as? String
        if(body != nil) { msgData.body = body! }

        let err = _siprixModule.messageSend(msgData)
        if(err == kErrorCodeEOK){
            result(msgData.myMessageId)
        }else{
            result(FlutterError(code: String(err), message: _siprixModule.getErrorText(err), details: nil))
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    //Siprix subscriptions

    func handleSubscriptionAdd(_ args : ArgsMap, result: @escaping FlutterResult) {
        //Get arguments from map
        let subscrData = SiprixSubscrData()
        
        let toExt = args["extension"] as? String
        if(toExt != nil) { subscrData.toExt = toExt! }
        
        let fromAccId = args[kArgAccId] as? Int
        if(fromAccId != nil) { subscrData.fromAccId = Int32(fromAccId!) }

        let expireTime = args["expireTime"] as? Int
        if(expireTime != nil) { subscrData.expireTime = NSNumber(value:expireTime!) }
        
        let mimeSubType = args["mimeSubType"] as? String
        if(mimeSubType != nil) { subscrData.mimeSubtype = mimeSubType! }

        let eventType = args["eventType"] as? String
        if(eventType != nil) { subscrData.eventType = eventType! }
     
        let err = _siprixModule.subscrCreate(subscrData)
        if(err == kErrorCodeEOK){
            result(subscrData.mySubscrId)
        }else{
            result(FlutterError(code: String(err), message: _siprixModule.getErrorText(err), details: subscrData.mySubscrId))
        }
    }

    func handleSubscriptionDelete(_ args : ArgsMap, result: @escaping FlutterResult) {
        let subscrId = args[kArgSubscrId] as? Int

        if(subscrId != nil) {
            let err = _siprixModule.subscrDestroy(Int32(subscrId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    //Siprix Devices methods implementation

    func handleDvcGetPlayoutNumber(_ args : ArgsMap, result: @escaping FlutterResult) {
        let data = SiprixDevicesNumbData()
        _siprixModule.dvcGetPlayoutDevices(data)
        result(data.number)
    }

    func handleDvcGetRecordNumber(_ args : ArgsMap, result: @escaping FlutterResult) {
        let data = SiprixDevicesNumbData()
        _siprixModule.dvcGetRecordingDevices(data)
        result(data.number)
    }

    func handleDvcGetVideoNumber(_ args : ArgsMap, result: @escaping FlutterResult) {
        let data = SiprixDevicesNumbData()
        _siprixModule.dvcGetVideoDevices(data)
        result(data.number)
    }

    enum DvcType { case Playout; case Recording; case Video}
    func doGetDevice(_ dvcType:DvcType, args:ArgsMap, result:@escaping FlutterResult) {
        let dvcIndex = args[kArgDvcIndex] as? Int

        if(dvcIndex == nil) {
            sendBadArguments(result:result)
            return
        }
        
        let err : Int32
        let data = SiprixDeviceData()
        switch (dvcType) {
            case .Playout   :  err = _siprixModule.dvcGetPlayoutDevice(Int32(dvcIndex!), device:data);
            case .Recording :  err = _siprixModule.dvcGetRecordingDevice(Int32(dvcIndex!), device:data);
            case .Video     :  err = _siprixModule.dvcGetVideoDevice(Int32(dvcIndex!), device:data);
        }
        if(err == kErrorCodeEOK) {
            var argsMap = [String:Any]()
            argsMap[kArgDvcName] = data.name
            argsMap[kArgDvcGuid] = data.guid
            result(argsMap)
        }else{
            result(FlutterError(code: String(err), message: _siprixModule.getErrorText(err), details: nil))
        }
    }

    func handleDvcGetPlayout(_ args : ArgsMap, result: @escaping FlutterResult) {
        doGetDevice(DvcType.Playout, args:args, result:result)
    }

    func handleDvcGetRecording(_ args : ArgsMap, result: @escaping FlutterResult) {
        doGetDevice(DvcType.Recording, args:args, result:result)
    }

    func handleDvcGetVideo(_ args : ArgsMap, result: @escaping FlutterResult) {
        doGetDevice(DvcType.Video, args:args, result:result)
    }


    func doSetDevice(dvcType:DvcType, args : ArgsMap, result: @escaping FlutterResult) {
        let dvcIndex = args[kArgDvcIndex] as? Int

        if(dvcIndex == nil) {
            sendBadArguments(result:result)
            return
        }

        let err : Int32
        switch (dvcType) {
            case .Playout   : err = _siprixModule.dvcSetPlayoutDevice(Int32(dvcIndex!));
            case .Recording : err = _siprixModule.dvcSetRecordingDevice(Int32(dvcIndex!));
            case .Video     : err = _siprixModule.dvcSetVideoDevice(Int32(dvcIndex!));
        }
        sendResult(err, result:result)
    }

    func handleDvcSetPlayout(_ args : ArgsMap, result: @escaping FlutterResult) {
        doSetDevice(dvcType:.Playout, args:args, result:result)
    }

    func handleDvcSetRecording(_ args : ArgsMap, result: @escaping FlutterResult) {
        doSetDevice(dvcType:.Recording, args:args, result:result)
    }

    func handleDvcSetVideo(_ args : ArgsMap, result: @escaping FlutterResult) {
        doSetDevice(dvcType:.Video, args:args, result:result)
    }

    func handleDvcSetVideoParams(_ args : ArgsMap, result: @escaping FlutterResult) {
        let vdoData = SiprixVideoData()
        
        let noCameraImgPath = args["noCameraImgPath"] as? String
        if(noCameraImgPath != nil) { vdoData.noCameraImgPath = noCameraImgPath }
        
        let framerateFps = args["framerateFps"] as? Int
        if(framerateFps != nil) { vdoData.framerateFps = NSNumber(value: framerateFps!) }
        
        let bitrateKbps = args["bitrateKbps"] as? Int
        if(bitrateKbps != nil) { vdoData.bitrateKbps = NSNumber(value: bitrateKbps!) }
        
        let height = args["height"] as? Int
        if(height != nil) { vdoData.height = NSNumber(value: height!) }
        
        let width = args["width"] as? Int
        if(width != nil) { vdoData.width = NSNumber(value: width!) }
        
        let err = _siprixModule.dvcSetVideoParams(vdoData)
        sendResult(err, result:result)
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    //Video methods
       
    func handleVideoRendererCreate(_ args : ArgsMap, result: @escaping FlutterResult) {
        let renderer = FlutterVideoRenderer(textureRegistry:_textureRegistry)
        let textureId = renderer.registerTextureAndCreateChannel(binMessenger:_binMessenger)
        _renderers[textureId] = renderer
        result(textureId)
    }
       
    func handleVideoRendererSetSrc(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId   = args[kArgCallId] as? Int
        let textureId = args[kArgVideoTextureId] as? Int64

        if((callId == nil)||(textureId == nil)) {
            sendBadArguments(result:result)
            return
        }
        
        let renderer = _renderers[textureId!]
        let err = _siprixModule.callSetVideoRenderer(Int32(callId!), renderer: renderer)
        renderer?.srcCallId = Int32(callId!)
        sendResult(err, result:result)
    }
       
    func handleVideoRendererDispose(_ args : ArgsMap, result: @escaping FlutterResult) {
        let textureId = args[kArgVideoTextureId] as? Int64
        if(textureId == nil) {
            sendBadArguments(result:result)
            return
        }
        
        let renderer = _renderers[textureId!]
        if(renderer != nil) {
            _siprixModule.callSetVideoRenderer(renderer!.srcCallId, renderer: nil)
            _renderers.removeValue(forKey: textureId!)
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    //Helpers methods
    
    func sendResult(_ err : Int32, result: @escaping FlutterResult) {
        if (err == kErrorCodeEOK) {
            result("Success")
        } else {
            result(FlutterError(code: String(err), message: _siprixModule.getErrorText(err), details: nil))
        }
    }
    
    func sendBadArguments(result: @escaping FlutterResult){
        result(FlutterError(code: "-", message: kBadArgumentsError, details: nil))
    }
    
}//SiprixVoipSdkPlugin

