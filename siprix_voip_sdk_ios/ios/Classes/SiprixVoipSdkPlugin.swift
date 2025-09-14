import Flutter
import UIKit
import CallKit
import PushKit
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
private let kMethodCallMuteMic          = "Call_MuteMic"
private let kMethodCallMuteCam          = "Call_MuteCam"
private let kMethodCallSendDtmf         = "Call_SendDtmf"
private let kMethodCallPlayFile         = "Call_PlayFile"
private let kMethodCallStopPlayFile     = "Call_StopPlayFile"
private let kMethodCallRecordFile       = "Call_RecordFile"
private let kMethodCallStopRecordFile   = "Call_StopRecordFile"
private let kMethodCallTransferBlind    = "Call_TransferBlind"
private let kMethodCallTransferAttended = "Call_TransferAttended"
private let kMethodCallStopRingtone     = "Call_StopRingtone"
private let kMethodCallBye              = "Call_Bye"

private let kMethodMixerSwitchToCall   = "Mixer_SwitchToCall"
private let kMethodMixerMakeConference = "Mixer_MakeConference"

private let kMethodMessageSend         = "Message_Send"

private let kMethodSubscriptionAdd     = "Subscription_Add"
private let kMethodSubscriptionDelete  = "Subscription_Delete"

private let kMethodDvcGetPushKitToken  = "Dvc_GetPushKitToken"
private let kMethodDvcUpdCallKitDetails = "Dvc_UpdCallKitDetails"
private let kMethodDvcGetCallKitUUID   = "Dvc_GetCallKitUUID"

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

private let kMethodVideoRendererCreate = "Video_RendererCreate"
private let kMethodVideoRendererSetSrc = "Video_RendererSetSrc"
private let kMethodVideoRendererDispose = "Video_RendererDispose"

private let kOnPushIncoming     = "OnPushIncoming"
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
private let kOnCallSwitched     = "OnCallSwitched"
private let kOnCallHeld         = "OnCallHeld"

private let kOnMessageSentState = "OnMessageSentState"
private let kOnMessageIncoming  = "OnMessageIncoming"

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

private let kArgCallKitUuid = "callKitUuid"
private let kArgPushPayload = "pushPayload"
private let kArgPushName   = "pushName"
private let kArgPushHandle = "pushHandle"

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

private let kArgName   = "name"
private let kArgTone   = "tone"
private let kFrom      = "from"
private let kTo        = "to"
private let kBody      = "body"


////////////////////////////////////////////////////////////////////////////////////////
//SiprixEventHandler
class SiprixEventHandler : NSObject, SiprixEventDelegate {
    
    private var _channel : FlutterMethodChannel
    private var _callKitProvider : SiprixCxProvider?
    private var _pushKitDisabled : Bool = true
    private var _ringer : Ringer?

    init(withChannel channel:FlutterMethodChannel) {
        self._channel      = channel
    }
    
    public func setRingTonePath(_ path : String) {
        DispatchQueue.main.async {
            self._ringer?.setRingTonePath(path)
        }
    }
    
    public func setCallKitProvider(_ callKitProvider : SiprixCxProvider?, pushKitProvider : SiprixPushRegistry?) {
        _callKitProvider = callKitProvider
        _pushKitDisabled = (pushKitProvider==nil)
        _ringer = (callKitProvider == nil) ? Ringer() : nil // Create ringer when CallKit disabled
    }
    
    public func didReceiveIncomingPush(_ dictionaryPayload : [AnyHashable : Any]) {
        let callKit_callUUID = _callKitProvider?.onPushIncoming()
        if(callKit_callUUID != nil) {
            var argsMap = [String:Any]()
            argsMap[kArgCallKitUuid] = callKit_callUUID
            argsMap[kArgPushPayload] = dictionaryPayload
            _channel.invokeMethod(kOnPushIncoming, arguments: argsMap)
        }
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
        DispatchQueue.main.async {
            if(started) { self._ringer?.play() }
            else        { self._ringer?.stop() }
        }
    }

    public func onCallProceeding(_ callId: Int, response:String){
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgCallId] = callId
            argsMap[kResponse] = response
            self._channel.invokeMethod(kOnCallProceeding, arguments: argsMap)
            self._callKitProvider?.onSipProceeding(callId)
        }
    }

    public func onCallTerminated(_ callId: Int, statusCode:Int) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgCallId] = callId
            argsMap[kArgStatusCode] = statusCode
            self._channel.invokeMethod(kOnCallTerminated, arguments: argsMap)
            self._callKitProvider?.onSipTerminated(callId)
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
            self._callKitProvider?.onSipConnected(callId, withVideo:withVideo)
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
            
            if(self._pushKitDisabled) {
                self._callKitProvider?.onSipIncoming(callId, withVideo:withVideo, hdrFrom:hdrFrom, hdrTo:hdrTo)
            }
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

    public func onCallSwitched(_ callId:Int) {
        DispatchQueue.main.async {
            var argsMap = [String:Any]()
            argsMap[kArgCallId] = callId
            self._channel.invokeMethod(kOnCallSwitched, arguments: argsMap)
        }
    }
    
    public func onCallTransferred(_ callId:Int, statusCode:Int) {
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
            self._callKitProvider?.onSipRedirected(origCallId:origCallId, relatedCallId:relatedCallId, referTo:referTo)
        }
    }

    public func onCallHeld(_ callId:Int, holdState:HoldState) {
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
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///Ringer

class Ringer {
    private var player: AVAudioPlayer?
    private var ringtonePath: String = ""
    
    public func setRingTonePath(_ path : String) {
        ringtonePath = path
    }

    func unInit() {
        if (player != nil)&&(player!.isPlaying) {
            player!.stop()
        }
    }

    private func enableSpeaker(_ enabled: Bool) {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        var options = session.categoryOptions

        if enabled {
            options.insert(AVAudioSession.CategoryOptions.defaultToSpeaker)
        } else {
            options.remove(AVAudioSession.CategoryOptions.defaultToSpeaker)
        }
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord, options: options)
        } catch {
            print("siprix: Ringer: Can't start ringer: error \(error)")
        }
        #endif
    }

    @discardableResult
    func play() -> Bool {
        if player == nil {
            let url = URL(fileURLWithPath:ringtonePath)
            player = try? AVAudioPlayer(contentsOf: url)
        }
        if player != nil {
            player?.numberOfLoops = -1
            enableSpeaker(true)
            player?.play()
            return true
        }
        return false
    }

    @discardableResult
    func stop() -> Bool {
        if (player != nil) && player!.isPlaying {
            player?.stop()
            enableSpeaker(false)
        }
        return true
    }
    
}//Ringer

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
    
    static let kInvalidCallCallId : Int32 = -1
    public var srcCallId : Int32 = kInvalidCallCallId
            
    init(textureRegistry:FlutterTextureRegistry) {
        self._textureRegistry = textureRegistry
    }
    
    deinit {
       // _textureRegistry.unregisterTexture(_textureId)
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
    var _callKitProvider : SiprixCxProvider?
    var _pushKitProvider : SiprixPushRegistry?
    var _textureRegistry : FlutterTextureRegistry
    var _binMessenger : FlutterBinaryMessenger
    var _renderers = [Int64 : FlutterVideoRenderer]()
    var _initialized = false

    init(withChannel channel:FlutterMethodChannel, registrar: FlutterPluginRegistrar) {
        self._siprixModule = SiprixModule()
        self._eventHandler = SiprixEventHandler(withChannel:channel)
        self._textureRegistry = registrar.textures()
        self._binMessenger = registrar.messenger()
    }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: kChannelName, binaryMessenger: registrar.messenger())
        
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
        case kMethodCallMuteMic       :   handleCallMuteMic(argsMap!, result:result)
        case kMethodCallMuteCam       :   handleCallMuteCam(argsMap!, result:result)
        case kMethodCallSendDtmf      :   handleCallSendDtmf(argsMap!, result:result)
        case kMethodCallPlayFile      :   handleCallPlayFile(argsMap!, result:result)
        case kMethodCallStopPlayFile  :   handleCallStopPlayFile(argsMap!, result:result)
        case kMethodCallRecordFile     :  handleCallRecordFile(argsMap!, result:result)
        case kMethodCallStopRecordFile :  handleCallStopRecordFile(argsMap!, result:result)
        case kMethodCallTransferBlind  :  handleCallTransferBlind(argsMap!, result:result)
        case kMethodCallTransferAttended : handleCallTransferAttended(argsMap!, result:result)
        case kMethodCallStopRingtone  :   handleCallStopRingtone(argsMap!, result:result)
        case kMethodCallBye :             handleCallBye(argsMap!, result:result)

        case kMethodMixerSwitchToCall   : handleMixerSwitchToCall(argsMap!, result:result)
        case kMethodMixerMakeConference : handleMixerMakeConference(argsMap!, result:result)

        case kMethodMessageSend :          handleMessageSend(argsMap!, result:result)

        case kMethodSubscriptionAdd     : handleSubscriptionAdd(argsMap!, result:result)
        case kMethodSubscriptionDelete  : handleSubscriptionDelete(argsMap!, result:result)

        case kMethodDvcGetPushKitToken  : handleDvcGetPushkitToken(argsMap!, result:result)
        case kMethodDvcUpdCallKitDetails : handleDvcUpdCallKitDetails(argsMap!, result:result)
        case kMethodDvcGetCallKitUUID  :   handleDvcGetCallKitUUID(argsMap!, result:result)
          
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

        default:      result(FlutterMethodNotImplemented)
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
        //Check already created
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
      
        let enablePushKit = args["enablePushKit"] as? Bool
        let enableCallKit = args["enableCallKit"] as? Bool
        let enableCallKitRecents = args["enableCallKitRecents"] as? Bool
      
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        iniData.homeFolder = documentsURL.path + "/"

        let err = _siprixModule.initialize(_eventHandler, iniData:iniData)
        _initialized = (err == kErrorCodeEOK)
        
        #if os(iOS) && !targetEnvironment(simulator)
        if((err == kErrorCodeEOK) && (enableCallKit != nil) && enableCallKit!) {
            let singleCall = (singleCallMode != nil) && singleCallMode!
            let includeInRecents = (enableCallKitRecents != nil) && enableCallKitRecents!
            _callKitProvider = SiprixCxProvider(_siprixModule, singleCallMode:singleCall, includeInRecents:includeInRecents)
        }
      
        if((err == kErrorCodeEOK) && (_callKitProvider != nil) && (enablePushKit != nil) && enablePushKit!) {
            _pushKitProvider = SiprixPushRegistry(_siprixModule, eventHandler:_eventHandler)
        }
        #endif
      
        _siprixModule.enableCallKit(_callKitProvider != nil)
        _eventHandler.setCallKitProvider(_callKitProvider, pushKitProvider:_pushKitProvider)
        
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
        setRingtonePath(err, assetPath:accData.ringTonePath)
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
            setRingtonePath(err, assetPath:accData.ringTonePath)
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
            _callKitProvider?.cxActionNewOutgoingCall(destData)
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

        if((callId == nil)||(withVideo == nil)) {
            sendBadArguments(result:result)
            return
        }

        if(_callKitProvider == nil || !_callKitProvider!.containsCall(callId!)) {
            let err = _siprixModule.callAccept(Int32(callId!), withVideo:withVideo!)
            sendResult(err, result:result)
        }else{
            let err = _callKitProvider!.cxActionAnswer(callId!, withVideo:withVideo!)
            sendResult(err, result:result)
        }
    }

    func handleCallHold(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int

        if(callId == nil) {
            sendBadArguments(result:result)
            return;
        }

        if(_callKitProvider == nil || !_callKitProvider!.containsCall(callId!)) {
            let err = _siprixModule.callHold(Int32(callId!))
            sendResult(err, result:result)
        }else{
            let err = _callKitProvider!.cxActionSetHeld(callId!)
            sendResult(err, result:result)
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

    func handleCallMuteMic(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int
        let mute   = args["mute"] as? Bool

        if((callId == nil)||(mute==nil)) {
            sendBadArguments(result:result)
            return
        }
        
        if(_callKitProvider == nil || !_callKitProvider!.containsCall(callId!)) {
            let err = _siprixModule.callMuteMic(Int32(callId!), mute:mute!)
            sendResult(err, result:result)
        }else{
            let err = _callKitProvider!.cxActionSetMuted(callId!, muted:mute!);
            sendResult(err, result:result)
        }
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

        if(_callKitProvider == nil || !_callKitProvider!.containsCall(callId!)) {
           let m = (method! == DtmfMethod.rtp.rawValue) ? DtmfMethod.rtp : DtmfMethod.info
        
           let err = _siprixModule.callSendDtmf(Int32(callId!), dtmfs:dtmfs!,
                                    durationMs:Int32(durationMs!),
                                    intertoneGapMs:Int32(intertoneGapMs!),
                                    method:m)
            sendResult(err, result:result)
        }else {
            let err = _callKitProvider!.cxActionPlayDtmf(callId!, digits:dtmfs!);
            sendResult(err, result:result)
        }
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

    func handleCallBye(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int

        if(callId == nil) {
            sendBadArguments(result:result)
            return
        }

        if(_callKitProvider == nil || !_callKitProvider!.containsCall(callId!)) {
            let err = _siprixModule.callBye(Int32(callId!))
            sendResult(err, result:result)
        }else{
            let err = _callKitProvider!.cxActionEndCall(callId!)
            sendResult(err, result:result)
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
        if(_callKitProvider == nil || !_callKitProvider!.contains2Calls()) {
            let err = _siprixModule.mixerMakeConference()
            sendResult(err, result:result)
        }else{
            let err = _callKitProvider!.cxActionGroupCall()
            sendResult(err, result:result)
        }
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
    //Siprix PushKit implementation
    
    func handleDvcGetPushkitToken(_ args : ArgsMap, result: @escaping FlutterResult) {
        result(_pushKitProvider?.getToken())
    }
    
    func handleDvcUpdCallKitDetails(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callKit_callUUID = args[kArgCallKitUuid] as? String
        let localizedName = args[kArgPushName] as? String
        let genericHandle = args[kArgPushHandle] as? String
        let withVideo = args[kArgWithVideo] as? Bool
        let callId   = args[kArgCallId] as? Int
        
        //Check argument
        let uuid = (callKit_callUUID != nil) ? UUID(uuidString: callKit_callUUID!) : nil
        if(uuid==nil) {
            sendBadArguments(result:result)
        }
        else {
            //Call exist update details
            _callKitProvider?.sipAppUpdateCallDetails(uuid!, callId:callId,
                            localizedName:localizedName, genericHandle:genericHandle, withVideo:withVideo)
        }
    }

    func handleDvcGetCallKitUUID(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId   = args[kArgCallId] as? Int

        if(callId != nil) {
            result(_callKitProvider?.getCallKitUUID(callId!))
        } else {
            sendBadArguments(result:result)
        }
    }
    

    ////////////////////////////////////////////////////////////////////////////////////////
    //Siprix Devices methods implementation
    
    func handleDvcGetPlayoutNumber(_ args : ArgsMap, result: @escaping FlutterResult) {
        //let data = SiprixDevicesNumbData()
        //_siprixModule.dvcGetPlayoutDevices(data)
        result(4)//result(data.number)
    }

    func handleDvcGetRecordNumber(_ args : ArgsMap, result: @escaping FlutterResult) {
        //let data = SiprixDevicesNumbData()
        //_siprixModule.dvcGetRecordingDevices(data)
        result(0)//result(data.number)
    }

    func handleDvcGetVideoNumber(_ args : ArgsMap, result: @escaping FlutterResult) {
        //let data = SiprixDevicesNumbData()
        //_siprixModule.dvcGetVideoDevices(data)
        result(0)//result(data.number)
    }

    //enum DvcType { case Playout; case Recording; case Video}
    //func doGetDevice(_ dvcType:DvcType, args:ArgsMap, result:@escaping FlutterResult) {
    //    let dvcIndex = args[kArgDvcIndex] as? Int
    //
    //    if(dvcIndex == nil) {
    //        sendBadArguments(result:result)
    //        return
    //    }
    //
    //    let err : Int32
    //    let data = SiprixDeviceData()
    //    switch (dvcType) {
    //        case .Playout   :  err = _siprixModule.dvcGetPlayoutDevice(Int32(dvcIndex!), device:data)
    //        case .Recording :  err = _siprixModule.dvcGetRecordingDevice(Int32(dvcIndex!), device:data)
    //        case .Video     :  err = _siprixModule.dvcGetVideoDevice(Int32(dvcIndex!), device:data)
    //    }
    //    if(err == kErrorCodeEOK) {
    //        var argsMap = [String:Any]()
    //        argsMap[kArgDvcName] = data.name
    //        argsMap[kArgDvcGuid] = data.guid
    //        result(argsMap);
    //    }else{
    //        result(FlutterError(code: String(err), message: _siprixModule.getErrorText(err), details: nil));
    //    }
    //}

    enum iOSDevices : Int { case kOutSpeaker=0; case kOutEarPiece=1; case kRouteBluetoth=2; case kRouteBuildIn=3}
    func handleDvcGetPlayout(_ args : ArgsMap, result: @escaping FlutterResult) {
        //doGetDevice(DvcType.Playout, args:args, result:result)
        
        let dvcIndex = args[kArgDvcIndex] as? Int
        if(dvcIndex == nil) {
            sendBadArguments(result:result)
            return
        }
        
        var argsMap = [String:Any]()
        switch(dvcIndex!) {
            case iOSDevices.kOutSpeaker.rawValue:    argsMap[kArgDvcName] = "Speaker"
            case iOSDevices.kOutEarPiece.rawValue:   argsMap[kArgDvcName] = "Earpiece"
            case iOSDevices.kRouteBluetoth.rawValue: argsMap[kArgDvcName] = "Bluetooth"
            case iOSDevices.kRouteBuildIn.rawValue:  argsMap[kArgDvcName] = "BuiltIn"
            default:                                 argsMap[kArgDvcName] = "---"
        }
        argsMap[kArgDvcGuid] = String(dvcIndex!)
        result(argsMap);
    }

    func handleDvcGetRecording(_ args : ArgsMap, result: @escaping FlutterResult) {
        //doGetDevice(DvcType.Recording, args:args, result:result)
    }

    func handleDvcGetVideo(_ args : ArgsMap, result: @escaping FlutterResult) {
        //doGetDevice(DvcType.Video, args:args, result:result)
    }


    //func doSetDevice(dvcType:DvcType, args : ArgsMap, result: @escaping FlutterResult) {
    //    let dvcIndex = args[kArgDvcIndex] as? Int;
    //
    //    if(dvcIndex == nil) {
    //        sendBadArguments(result:result);
    //        return;
    //    }
    //
    //    let err : Int32;
    //    switch (dvcType) {
    //        case .Playout   : err = _siprixModule.dvcSetPlayoutDevice(Int32(dvcIndex!));
    //        case .Recording : err = _siprixModule.dvcSetRecordingDevice(Int32(dvcIndex!));
    //        case .Video     : err = _siprixModule.dvcSetVideoDevice(Int32(dvcIndex!));
    //    }
    //    sendResult(err, result:result);
    //}

    func handleDvcSetPlayout(_ args : ArgsMap, result: @escaping FlutterResult) {
        //doGetDevice(.Playout, args:args, result:result)
        
        let dvcIndex = args[kArgDvcIndex] as? Int
        if(dvcIndex == nil) {
            sendBadArguments(result:result)
            return
        }
        
        let ret : Bool;
        switch(dvcIndex) {
            case iOSDevices.kOutSpeaker.rawValue:    ret = _siprixModule.overrideAudioOutput(toSpeaker: true)
            case iOSDevices.kOutEarPiece.rawValue:   ret = _siprixModule.overrideAudioOutput(toSpeaker: false)
            case iOSDevices.kRouteBluetoth.rawValue: ret = _siprixModule.routeAudioToBluetoth()
            case iOSDevices.kRouteBuildIn.rawValue:  ret = _siprixModule.routeAudioToBuiltIn()
            default:                                 ret = false;
        }

        if (ret) { result("Success") }
        else     { result(FlutterError(code: "-", message: "Can't overrideAudioOutput/set route", details: nil)) }
    }

    func handleDvcSetRecording(_ args : ArgsMap, result: @escaping FlutterResult) {
        //doGetDevice(.Recording, args:args, result:result)
    }

    func handleDvcSetVideo(_ args : ArgsMap, result: @escaping FlutterResult) {
        let err = _siprixModule.switchCamera();
        sendResult(err, result:result);
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
        if(renderer == nil) {
            result(FlutterError(code: "-", message: "Renderer for specified texture doesn't exist", details: nil))
            return
        }
        
        //Unsubscribe from previous call
        if(renderer!.srcCallId != FlutterVideoRenderer.kInvalidCallCallId) {
            _siprixModule.callSetVideoRenderer(renderer!.srcCallId, renderer: nil)
        }
        
        //Set new call
        renderer!.srcCallId = Int32(callId!)
        let err = _siprixModule.callSetVideoRenderer(renderer!.srcCallId, renderer: renderer)
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
    
    func setRingtonePath(_ err : Int32, assetPath: String?) {
        if (err != kErrorCodeEOK) || (assetPath == nil) {
            return;
        }

        let exists = (FileManager.default.fileExists(atPath:assetPath!))
        if(exists) {
            _siprixModule.writeLog("Ringtone path: '\(assetPath!)' - exists")
            _eventHandler.setRingTonePath(assetPath!)
            return;
        }

        let index = assetPath!.lastIndex(of: "/")
        if(index != nil) {
            let updatedPath = _siprixModule.homeFolder() + assetPath!.suffix(from: index!).dropFirst()
            _siprixModule.writeLog("Ringtone path updated: '\(updatedPath)'")
            _eventHandler.setRingTonePath(updatedPath)
        }
    }
    
}//SiprixVoipSdkPlugin


///////////////////////////////////////////////////////////////////////////////////////////////////
///SiprixPushRegistry

class SiprixPushRegistry : NSObject, PKPushRegistryDelegate {
    private let _siprixModule : SiprixModule
    private var _eventHandler : SiprixEventHandler
    private let _registry: PKPushRegistry
    private var _token: String?
    
    init(_  module: SiprixModule, eventHandler : SiprixEventHandler) {
        _siprixModule = module
        _eventHandler = eventHandler
        _registry = PKPushRegistry(queue: .main)
        super.init()
        
        _registry.delegate = self
        _registry.desiredPushTypes = [.voIP]
        _siprixModule.writeLog("SiprixPushRegistry: created")
    }
    
    public func getToken() -> String? {
        if(_token == nil) {
            let data = _registry.pushToken(for: .voIP)
            _token = (data != nil) ? format(data!) : nil
        }
        return _token
    }
    
    func format(_ token: Data) -> String? {
        return token.map { String(format: "%02x", $0) }.joined()
    }
    
    public func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if(type == .voIP) {
            _token = format(pushCredentials.token)
        }
    }

    public func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        if(type == .voIP) {
            _token = nil
        }
    }
           
    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload:
                                PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        _siprixModule.writeLog("PushRegistry: didReceiveIncomingPushWith \(type)")
        if(type == .voIP) {
            _eventHandler.didReceiveIncomingPush(payload.dictionaryPayload)
        }
        completion()
    }

}//SiprixPushRegistry

///////////////////////////////////////////////////////////////////////////////////////////////////
///SiprixCxProvider

class SiprixCxProvider : NSObject, CXProviderDelegate {
    private let _siprixModule : SiprixModule
    private var _cxProvider: CXProvider!
    private var _cxCallCtrl: CXCallController
    private var _callsList: [CallModel] = []
      
    static let kECallNotFound: Int32       = -1040
    static let kEConfRequires2Calls: Int32 = -1055
    
    init(_ module: SiprixModule, singleCallMode:Bool, includeInRecents:Bool) {
        _siprixModule = module
        _cxCallCtrl = CXCallController()
        super.init()
        createCxProvider(singleCallMode, includeInRecents:includeInRecents)
        _siprixModule.writeLog("CxProvider: created")
    }
        
    //--------------------------------------------------------
    //Event handlers
    
    func containsCall(_ callId: Int) -> Bool {
        return _callsList.contains(where: {$0.id == callId})
    }
        
    func contains2Calls() ->Bool {
        return (_callsList.count > 1)
    }
        
    func onSipProceeding(_ callId: Int) {
        let call = _callsList.first(where: {$0.id == callId})
        if(call != nil) {
            _cxProvider.reportOutgoingCall(with:call!.uuid, startedConnectingAt: nil) //now
        }
    }
    
    func onSipTerminated(_ callId: Int) {
        let callIdx = _callsList.firstIndex(where: {$0.id == callId})
        if(callIdx == nil) { return }
            
        let call = self._callsList[callIdx!]
            
        call.cxEndAction?.fulfill()
        call.cxEndAction = nil

        if(!call.endedByLocalSide) {
            var reason : CXCallEndedReason = .failed
            if(call.connectedSuccessfully || call.isIncoming) {  reason = .remoteEnded } else
            if(!call.isIncoming) { reason = .unanswered }
            
            self._cxProvider.reportCall(with:call.uuid, endedAt: nil, reason: reason)
        }
        //Remove call item from collection
        _callsList.remove(at:callIdx!)
        _siprixModule.writeLog("CxProvider: onSipTerminated remove callId:\(call.id) <=> \(call.uuid)")
    }
    
    func onSipConnected(_ callId: Int, withVideo:Bool) {
        _siprixModule.activate( AVAudioSession.sharedInstance())

        let call = self._callsList.first(where: {$0.id == callId})
        if(call == nil) { return }

        call!.connectedSuccessfully = true
        //call!.cxAnswerAction?.fulfill()
            
        //Set 'connected' time of the outgoing call
        if(!call!.isIncoming) {
            _cxProvider.reportOutgoingCall(with:call!.uuid, connectedAt: nil)
        }
            
        //Update 'withVideo' flag
        //if(call!.withVideo != withVideo) {
            call!.withVideo = withVideo

            let update = CXCallUpdate()
            update.hasVideo = withVideo
            update.supportsHolding = true
            update.supportsDTMF = true
            update.supportsGrouping = true
            update.supportsUngrouping = true
            _cxProvider.reportCall(with: call!.uuid, updated: update)
        //}
    }
    
    func onSipIncoming(_ callId:Int, withVideo:Bool, hdrFrom:String, hdrTo:String) {
        let call = CallModel(callId:callId, withVideo:withVideo, from:hdrFrom)
        _callsList.append(call)
        
        reportNewIncomingCall(call)
        _siprixModule.writeLog("CxProvider: onSipIncoming - added new call with uuid:\(call.uuid)")
    }
    
    public func onPushIncoming() -> String {
        let call = CallModel(callId:kInvalidId, withVideo:true, from:"SiprixPushKit")
        _callsList.append(call)
        
        reportNewIncomingCall(call)
        
        _siprixModule.writeLog("CxProvider: onPushIncoming - added new call with uuid:\(call.uuid)")
        return call.uuid.uuidString
    }
        
    func reportNewIncomingCall(_ call : CallModel) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: call.fromTo)
        update.hasVideo = call.withVideo
        update.supportsUngrouping = true
        update.supportsGrouping = true
        update.supportsHolding = true
        update.supportsDTMF = true
        
        _cxProvider.reportNewIncomingCall(with: call.uuid, update: update,
                                 completion: { error in self.printResult("CXCallUpdate", err:error)
        })
    }
    
    func proceedCxAnswerAction(_ call: CallModel) {
        let err = _siprixModule.callAccept(Int32(call.id), withVideo:call.withVideo)
        if (err == kErrorCodeEOK) { call.cxAnswerAction?.fulfill() }
        else                      { call.cxAnswerAction?.fail()    }
        _siprixModule.writeLog("CxProvider: proceedCxAnswerAction err:\(err) sipCallId:\(call.id) uuid:\(call.uuid))")
    }
    
    func proceedCxEndAction(_ call: CallModel) {
        var err = kErrorCodeEOK
        if(call.isIncoming && !call.connectedSuccessfully) {
            err = _siprixModule.callReject(Int32(call.id), statusCode:486) }
        else {
            call.endedByLocalSide = true
            err = _siprixModule.callBye(Int32(call.id))
        }
                    
        if (err != kErrorCodeEOK) {
            call.cxEndAction?.fail()
        }
        _siprixModule.writeLog("CxProvider: proceedCxEndAction err:\(err) sipCallId:\(call.id) uuid:\(call.uuid))")
    }

    public func getCallKitUUID(_ callId:Int) -> String? {
        let call = _callsList.first(where: {$0.id == callId})
        return call?.uuid.uuidString;
    }

    public func sipAppUpdateCallDetails(_ callKit_callUUID:UUID, callId:Int?,
                                       localizedName:String?, genericHandle:String?, withVideo:Bool?) {
        DispatchQueue.main.async {
            let call = self.getCallByUUID(callKit_callUUID)
            if(call == nil) {
                self._siprixModule.writeLog("CxProvider: sipAppUpdateCallDetails uuid:\(callKit_callUUID) call not found")
                return
            }
        
            if(callId != nil) {
                //INVITE received - update SIP callId
                self._siprixModule.writeLog("CxProvider: sipAppUpdateCallDetails uuid:\(callKit_callUUID)) set sipCallId:\(callId!)")
                call!.setSipCallId(callId: callId!, withVideo: withVideo)
                
                if(call!.rejectedByCallKit) {
                    self.proceedCxEndAction(call!)
                }
                else if(call!.answeredByCallKit) {
                    self.proceedCxAnswerAction(call!)
                }
            }

            if((genericHandle != nil)||(localizedName != nil)||(withVideo != nil)) {
                self._siprixModule.writeLog("CxProvider: sipAppUpdateCallDetails uuid:\(callKit_callUUID) genericHandle:\(String(describing: genericHandle)) localizedName:\(String(describing: localizedName)) withVideo:\(String(describing: withVideo))")
                
                let update = CXCallUpdate()
                if(genericHandle != nil) { update.remoteHandle = CXHandle(type: .generic, value: genericHandle!) }
                if(localizedName != nil) { update.localizedCallerName = localizedName! }
                if(withVideo != nil)     { update.hasVideo = withVideo! }
                    
                update.supportsUngrouping = true
                update.supportsGrouping = true
                update.supportsHolding = true
                update.supportsDTMF = true
                
                self._cxProvider.reportCall(with: call!.uuid, updated: update)
            }
        }
    }

    public func onSipRedirected(origCallId: Int, relatedCallId: Int, referTo: String) {
        let origCall = _callsList.first(where: {$0.id == origCallId})//Find 'origCallId'
        if(origCall != nil) {
            //Clone 'origCall' and add to collection of calls as related one
            _callsList.append(CallModel(callId:relatedCallId, withVideo:origCall!.withVideo, from:origCall!.fromTo))
        }
    }
    
    //--------------------------------------------------------
    //Actions

    private func createCxProvider(_ singleCallMode : Bool, includeInRecents : Bool) {
        let providerConfiguration : CXProviderConfiguration
        if #available(iOS 14.0, *) {
            providerConfiguration = CXProviderConfiguration()
        } else {
            providerConfiguration = CXProviderConfiguration(localizedName: "AppName")
        }
        
        providerConfiguration.supportsVideo = true
        providerConfiguration.includesCallsInRecents = includeInRecents
        providerConfiguration.maximumCallGroups = singleCallMode ? 1 : 5
        providerConfiguration.maximumCallsPerCallGroup = singleCallMode ? 1 : 5
        providerConfiguration.supportedHandleTypes = [.phoneNumber, .generic]
        
        if let iconMaskImage = UIImage(named: "CallKitIcon") {
            providerConfiguration.iconTemplateImageData = iconMaskImage.pngData()
        }

        _cxProvider = CXProvider(configuration: providerConfiguration)
        _cxProvider.setDelegate(self, queue: DispatchQueue.main)
    }
    
            
    func cxActionNewOutgoingCall(_ destData : SiprixDestData) {
        let call = CallModel(destData)
        _callsList.append(call)
        
        let handle = CXHandle(type: .generic, value: destData.toExt)
        let action = CXStartCallAction(call: call.uuid, handle: handle)
        action.isVideo = call.withVideo
        
        let transaction = CXTransaction(action: action)
        _cxCallCtrl.request(transaction) { error in self.printResult("CXStart", err:error) }
    }

    func cxActionPlayDtmf(_ callId:Int, digits: String) -> Int32 {
        let call = _callsList.first(where: {$0.id == callId})
        if(call != nil) {
            let action = CXPlayDTMFCallAction(call: call!.uuid, digits: digits, type: .singleTone)
            let transaction = CXTransaction(action: action)
        
            _cxCallCtrl.request(transaction) { error in self.printResult("CXPlayDTMF", err:error) }
            return kErrorCodeEOK;
        }
        return SiprixCxProvider.kECallNotFound
    }

    func cxActionSetHeld(_ callId:Int) -> Int32 {
        let call = _callsList.first(where: {$0.id == callId})
        if(call != nil) {
            let action = CXSetHeldCallAction(call: call!.uuid, onHold: !call!.isHeld)
            let transaction = CXTransaction(action: action)
        
            _cxCallCtrl.request(transaction) { error in self.printResult("CXSetHeld", err:error) }
            return kErrorCodeEOK;
        }
        return SiprixCxProvider.kECallNotFound
    }

    func cxActionSetMuted(_ callId:Int, muted: Bool) -> Int32 {
        let call = _callsList.first(where: {$0.id == callId})
        if(call != nil) {
            let action = CXSetMutedCallAction(call: call!.uuid, muted: muted)
            let transaction = CXTransaction(action: action)
        
            _cxCallCtrl.request(transaction) { error in self.printResult("CXSetMuted", err:error) }
            return kErrorCodeEOK;
        }
        return SiprixCxProvider.kECallNotFound
    }
    
    func cxActionEndCall(_ callId:Int) -> Int32 {
        let call = _callsList.first(where: {$0.id == callId})
        if(call != nil) {
            let action = CXEndCallAction(call: call!.uuid)
            let transaction = CXTransaction(action: action)
        
            _cxCallCtrl.request(transaction) { error in self.printResult("CXEndCall", err:error) }
            return kErrorCodeEOK;
        }
        return SiprixCxProvider.kECallNotFound;
    }

    func cxActionGroupCall() -> Int32 {
        if(_callsList.count >= 2) {
            let action = CXSetGroupCallAction(call: _callsList[0].uuid, callUUIDToGroupWith: _callsList[1].uuid)
            let transaction = CXTransaction(action: action)
        
            _cxCallCtrl.request(transaction) { error in self.printResult("CXSetGroupCallAction", err:error) }
            return kErrorCodeEOK;
        }
        return SiprixCxProvider.kEConfRequires2Calls
    }

    func cxActionAnswer(_ callId:Int, withVideo:Bool) -> Int32 {
        let call = _callsList.first(where: {$0.id == callId})
        if(call != nil) {
            call!.withVideo = withVideo
            let action = CXAnswerCallAction(call: call!.uuid)
            let transaction = CXTransaction(action: action)
        
            _cxCallCtrl.request(transaction) { error in self.printResult("CXAnswer", err:error) }
            return kErrorCodeEOK;
        }
        return SiprixCxProvider.kECallNotFound
    }
    
    func printResult(_ name: String, err: Error?) {
        let strErr = (err != nil) ? ("Error requesting <\(name)> :\(err!)") : ("<\(name)> requested successfully")
        _siprixModule.writeLog("CxProvider: completion: '\(strErr)'")
    }

    ///------------------------------------------------------------------------------
    ///CXProviderDelegate
    ///
    func providerDidReset(_ provider: CXProvider) {
        _siprixModule.writeLog("CxProvider: providerDidReset")
    }
    
    func provider(_: CXProvider, perform action: CXStartCallAction) {
        _siprixModule.writeLog("CxProvider: CXStartCall uuid:\(action.callUUID)")
        //TODO Case starting call from NativeUI
        
        let call = getCallByUUID(action.callUUID)
        if(call != nil) {
           //if(callsListModel.inviteWithUUID(callee: action.handle.value,
            //      displayName: action.handle.value, videoCall: action.isVideo, uuid: action.callUUID))  {
            action.fulfill()
        } else {
            action.fail()
        }
    }
    
    func provider(_: CXProvider, perform action: CXEndCallAction) {
        let call = getCallByUUID(action.callUUID)
        if(call == nil) {
            _siprixModule.writeLog("CxProvider: CXEndCall uuid:\(action.callUUID) not found")
            action.fail()
            return
        }
        
        call!.cxEndAction = action

        if(call!.id == kInvalidId) {
            call!.rejectedByCallKit = true
            _siprixModule.writeLog("CxProvider: CXEndCall uuid:\(action.callUUID) SIP hasn't received yet")
        }
        else {
            _siprixModule.writeLog("CxProvider: CXEndCall uuid:\(action.callUUID) callId:\(call!.id)")
            proceedCxEndAction(call!)
        }
    }
    
    func provider(_: CXProvider, perform action: CXAnswerCallAction) {
        let call = getCallByUUID(action.callUUID)
        if(call == nil) {
            _siprixModule.writeLog("CxProvider: CXAnswer uuid:\(action.callUUID) not found")
            action.fail()
            return
        }
       
        call!.cxAnswerAction = action
        
        if (call!.id == kInvalidId) {
            call!.answeredByCallKit = true
            _siprixModule.writeLog("CxProvider: CXAnswer uuid:\(action.callUUID) SIP hasn't received yet")
        }else{
            _siprixModule.writeLog("CxProvider: CXAnswer uuid:\(action.callUUID) callId:\(call!.id)")
            proceedCxAnswerAction(call!)
        }
    }
    
    func provider(_: CXProvider, perform action: CXPlayDTMFCallAction) {
        _siprixModule.writeLog("CxProvider: CXPlayDTMF uuid:\(action.callUUID) dtmf:\(action.digits)")
       
        let call = getCallByUUID(action.callUUID)
        if((call != nil) && (_siprixModule.callSendDtmf(Int32(call!.id), dtmfs:action.digits) == kErrorCodeEOK)) {
            action.fulfill()
        }
        else {
            action.fail()
        }
    }

    func provider(_: CXProvider, perform action: CXSetHeldCallAction) {
        _siprixModule.writeLog("CxProvider: CXSetHeld uuid:\(action.callUUID) isOnHold:\(action.isOnHold)")
       
        let call = getCallByUUID(action.callUUID)
        if((call != nil) && (_siprixModule.callHold(Int32(call!.id)) == kErrorCodeEOK)) {
            call!.isHeld = action.isOnHold//TODO check, may be fullfil only when event received
            action.fulfill()
        }
        else {
            action.fail()
        }
    }
    
    func provider(_: CXProvider, perform action: CXSetMutedCallAction) {
        _siprixModule.writeLog("CxProvider: CXSetMuted uuid:\(action.callUUID) muted:\(action.isMuted)")
        //TODO fix case when callKit muted call, but flutter can't see that
       
        let call = getCallByUUID(action.callUUID)
        if((call != nil) && (_siprixModule.callMuteMic(Int32(call!.id), mute:action.isMuted)) == kErrorCodeEOK) {
            action.fulfill()
        }
        else {
            action.fail()
        }
    }
        
    func provider(_: CXProvider, timedOutPerforming action: CXAction) {
        _siprixModule.writeLog("CxProvider: CXAction timedOutPerforming uuid:\(action.uuid)")
    }
    
    func provider(_: CXProvider, perform action: CXSetGroupCallAction) {
        let call = getCallByUUID(action.callUUID)
        if(call == nil) {
            _siprixModule.writeLog("CxProvider: CXSetGroup not found uuid:\(action.callUUID)")
            action.fail()
            return
        }
        
        if (action.callUUIDToGroupWith != nil) {
            let err = _siprixModule.mixerMakeConference()//TODO fix case when callKit started conf, but flutter can't see that
            _siprixModule.writeLog("CxProvider: CXSetGroup group uuid:\(action.callUUID) with:\(action.callUUIDToGroupWith!) err:\(err)")
            //_siprixModule._eventHandler.onCallConfStarted()
        } else {
            _siprixModule.writeLog("CxProvider: CXSetGroup ungroup uuid:\(action.callUUID)")
            _siprixModule.mixerSwitchCall(Int32(call!.id))
        }
        action.fulfill()
    }
   
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        _siprixModule.writeLog("CxProvider: didActivate")
        _siprixModule.activate(audioSession)
    }

    func provider(_: CXProvider, didDeactivate audioSession: AVAudioSession) {
        _siprixModule.writeLog("CxProvider: didDeactivate")
        _siprixModule.deactivate(audioSession)
    }

    public func  getCallByUUID(_ uuid: UUID) -> CallModel? {
        return _callsList.first(where: {$0.uuid == uuid})
    }

    class CallModel : Identifiable, Equatable {
        private(set) var uuid = UUID()
        private(set) var mySipCallId : Int  //Assigned by Siprix module.
        //When this instance created by push - 'myCallId' will set to 'kInvalidId
        //  and proper value assigned only when received SIP INVITE
        //App has to match call by comparing data from push and SIP.
        
        public var withVideo = false
        public let isIncoming : Bool
        public var isHeld : Bool = false
        public var connectedSuccessfully = false
        public var answeredByCallKit = false
        public var rejectedByCallKit = false
        public var endedByLocalSide = false
        public var fromTo : String
        
        public var cxAnswerAction : CXAnswerCallAction?
        public var cxEndAction : CXEndCallAction?
                  
        init(_ destData:SiprixDestData) {
            self.mySipCallId = Int(destData.myCallId)
            self.isIncoming = false

            self.withVideo = (destData.withVideo != nil) ? destData.withVideo!.boolValue : false
            self.fromTo = destData.toExt
        }

        init(callId:Int, withVideo:Bool, from:String) {
            self.mySipCallId = callId
            self.isIncoming = true
            self.withVideo = withVideo
            self.fromTo = from
        }

        public func setSipCallId(callId:Int, withVideo:Bool?) {
            self.mySipCallId = callId
            if(withVideo != nil) { self.withVideo = withVideo! }
        }
    
        var id : Int { get { return mySipCallId } }
        
        static func ==(lhs: CallModel, rhs: CallModel) -> Bool {
            return lhs.uuid == rhs.uuid
        }
    }
    
}//SiprixCxProvider
