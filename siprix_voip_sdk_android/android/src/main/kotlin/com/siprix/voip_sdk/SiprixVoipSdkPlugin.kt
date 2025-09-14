@file:Suppress("SpellCheckingInspection", "UNUSED_PARAMETER", "UNCHECKED_CAST", "DEPRECATION")
package com.siprix.voip_sdk

//import io.flutter.embedding.android.FlutterActivity

import android.Manifest
import android.app.Activity
import android.app.AlertDialog
import android.content.ComponentName
import android.content.Context
import android.content.DialogInterface
import android.content.Intent
import android.content.ServiceConnection
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.graphics.SurfaceTexture
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.siprix.AccData
import com.siprix.DestData
import com.siprix.ISiprixModelListener
import com.siprix.IniData
import com.siprix.MsgData
import com.siprix.SiprixCore
import com.siprix.SiprixEglBase
import com.siprix.SubscrData
import com.siprix.VideoData
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.TextureRegistry
import io.flutter.view.TextureRegistry.SurfaceTextureEntry
import org.webrtc.EglBase
import org.webrtc.EglRenderer
import org.webrtc.GlRectDrawer
import org.webrtc.RendererCommon
import org.webrtc.ThreadUtils
import java.util.concurrent.CountDownLatch


////////////////////////////////////////////////////////////////////////////////////////
//Method and argument names constants

const val kBadArgumentsError          = "Bad argument. Map with fields expected"
const val kModuleNotInitializedError  = "Siprix module has not initialized yet"

const val kChannelName                = "siprix_voip_sdk"

const val kMethodModuleInitialize     = "Module_Initialize"
const val kMethodModuleUnInitialize   = "Module_UnInitialize"
const val kMethodModuleHomeFolder     = "Module_HomeFolder"
const val kMethodModuleVersionCode    = "Module_VersionCode"
const val kMethodModuleVersion        = "Module_Version"

const val kMethodAccountAdd           = "Account_Add"
const val kMethodAccountUpdate        = "Account_Update"
const val kMethodAccountRegister      = "Account_Register"
const val kMethodAccountUnregister    = "Account_Unregister"
const val kMethodAccountDelete        = "Account_Delete"
const val kMethodAccountGenInstId     = "Account_GenInstId"

const val kMethodCallInvite           = "Call_Invite"
const val kMethodCallReject           = "Call_Reject"
const val kMethodCallAccept           = "Call_Accept"
const val kMethodCallHold             = "Call_Hold"
const val kMethodCallGetHoldState     = "Call_GetHoldState"
const val kMethodCallGetSipHeader     = "Call_GetSipHeader"
const val kMethodCallMuteMic          = "Call_MuteMic"
const val kMethodCallMuteCam          = "Call_MuteCam"
const val kMethodCallSendDtmf         = "Call_SendDtmf"
const val kMethodCallPlayFile         = "Call_PlayFile"
const val kMethodCallStopPlayFile     = "Call_StopPlayFile"
const val kMethodCallRecordFile       = "Call_RecordFile"
const val kMethodCallStopRecordFile   = "Call_StopRecordFile"
const val kMethodCallTransferBlind    = "Call_TransferBlind"
const val kMethodCallTransferAttended = "Call_TransferAttended"
const val kMethodCallStopRingtone     = "Call_StopRingtone"
const val kMethodCallBye              = "Call_Bye"

const val kMethodMixerSwitchToCall   = "Mixer_SwitchToCall"
const val kMethodMixerMakeConference = "Mixer_MakeConference"

const val kMethodMessageSend         = "Message_Send"

const val kMethodSubscriptionAdd     = "Subscription_Add"
const val kMethodSubscriptionDelete  = "Subscription_Delete"

const val kMethodDvcSetForegroundMode= "Dvc_SetForegroundMode"
const val kMethodDvcIsForegroundMode = "Dvc_IsForegroundMode"

const val kMethodDvcGetPlayoutNumber = "Dvc_GetPlayoutDevices"
const val kMethodDvcGetRecordNumber  = "Dvc_GetRecordingDevices"
const val kMethodDvcGetVideoNumber   = "Dvc_GetVideoDevices"
const val kMethodDvcGetPlayout       = "Dvc_GetPlayoutDevice"
const val kMethodDvcGetRecording     = "Dvc_GetRecordingDevice"
const val kMethodDvcGetVideo         = "Dvc_GetVideoDevice"
const val kMethodDvcSetPlayout       = "Dvc_SetPlayoutDevice"
const val kMethodDvcSetRecording     = "Dvc_SetRecordingDevice"
const val kMethodDvcSetVideo         = "Dvc_SetVideoDevice"
const val kMethodDvcSetVideoParams   = "Dvc_SetVideoParams"

const val kMethodVideoRendererCreate = "Video_RendererCreate"
const val kMethodVideoRendererSetSrc = "Video_RendererSetSrc"
const val kMethodVideoRendererDispose= "Video_RendererDispose"

const val kOnTrialModeNotif   = "OnTrialModeNotif"
const val kOnDevicesChanged   = "OnDevicesChanged"
const val kOnAccountRegState  = "OnAccountRegState"
const val kOnSubscriptionState= "OnSubscriptionState"
const val kOnNetworkState     = "OnNetworkState"
const val kOnPlayerState      = "OnPlayerState"
const val kOnCallProceeding   = "OnCallProceeding"
const val kOnCallTerminated   = "OnCallTerminated"
const val kOnCallConnected    = "OnCallConnected"
const val kOnCallIncoming     = "OnCallIncoming"
const val kOnCallAcceptNotif  = "OnCallAcceptNotif"
const val kOnCallDtmfReceived = "OnCallDtmfReceived"
const val kOnCallTransferred  = "OnCallTransferred"
const val kOnCallRedirected   = "OnCallRedirected"
const val kOnCallSwitched     = "OnCallSwitched"
const val kOnCallHeld         = "OnCallHeld"

const val kOnMessageSentState = "OnMessageSentState"
const val kOnMessageIncoming  = "OnMessageIncoming"

const val kArgVideoTextureId  = "videoTextureId"

const val kArgForeground = "foreground"
const val kArgStatusCode = "statusCode"
const val kArgExpireTime = "expireTime"
const val kArgWithVideo  = "withVideo"

const val kArgDvcIndex = "dvcIndex"
const val kArgDvcName  = "dvcName"
const val kArgDvcGuid  = "dvcGuid"

const val kArgCallId     = "callId"
const val kArgFromCallId = "fromCallId"
const val kArgToCallId   = "toCallId"
const val kArgToExt      = "toExt"
const val kArgAccId      = "accId"
const val kArgPlayerId   = "playerId"
const val kArgSubscrId   = "subscrId"
const val kArgMsgId    = "msgId"
const val kRegState    = "regState"
const val kHoldState   = "holdState"
const val kPlayerState = "playerState"
const val kSubscrState = "subscrState"
const val kNetState    = "netState"
const val kResponse    = "response"
const val kSuccess   = "success"
const val kArgName   = "name"
const val kArgTone   = "tone"
const val kFrom      = "from"
const val kTo        = "to"
const val kBody      = "body"

const val kErrorCodeEOK = 0
const val kErrorDuplicateAccount = -1021

////////////////////////////////////////////////////////////////////////////////////////
//EventListener

class EventListener: ISiprixModelListener {
  private var channel: MethodChannel? = null

  fun setMethodChannel(c : MethodChannel?) {
    channel = c
  }

  override fun onTrialModeNotified() {
    val argsMap = HashMap<String, Any> ()
    channel?.invokeMethod(kOnTrialModeNotif, argsMap)
  }

  override fun onDevicesAudioChanged() {
    val argsMap = HashMap<String, Any> ()
    channel?.invokeMethod(kOnDevicesChanged, argsMap)
  }

  override fun onAccountRegState(accId: Int, regState: AccData.RegState, response: String?) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgAccId] = accId
    argsMap[kRegState] = regState.value
    argsMap[kResponse] = response
    channel?.invokeMethod(kOnAccountRegState, argsMap)
  }

  override fun onSubscriptionState(subscrId: Int, state: SubscrData.SubscrState, response: String?) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgSubscrId] = subscrId
    argsMap[kSubscrState] = state.value
    argsMap[kResponse] = response
    channel?.invokeMethod(kOnSubscriptionState, argsMap)
  }

  override fun onNetworkState(name: String?, state: SiprixCore.NetworkState?) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgName] = name
    argsMap[kNetState] = state?.value
    channel?.invokeMethod(kOnNetworkState, argsMap)
  }

  override fun onPlayerState(playerId: Int, state: SiprixCore.PlayerState?) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgPlayerId] = playerId
    argsMap[kPlayerState] = state?.value
    channel?.invokeMethod(kOnPlayerState, argsMap)
  }

  override fun onCallProceeding(callId: Int, response: String?) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgCallId] = callId
    argsMap[kResponse] = response
    channel?.invokeMethod(kOnCallProceeding, argsMap)
  }

  override fun onCallTerminated(callId: Int, statusCode: Int) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgCallId] = callId
    argsMap[kArgStatusCode] = statusCode
    channel?.invokeMethod(kOnCallTerminated, argsMap)
  }

  override fun onCallConnected(callId: Int, hdrFrom: String?, hdrTo: String?, withVideo:Boolean) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgWithVideo] = withVideo
    argsMap[kArgCallId] = callId
    argsMap[kFrom] = hdrFrom
    argsMap[kTo] = hdrTo
    channel?.invokeMethod(kOnCallConnected, argsMap)
  }

  override fun onCallIncoming(
    callId: Int, accId: Int, withVideo: Boolean,
    hdrFrom: String?, hdrTo: String?
  ) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgWithVideo] = withVideo
    argsMap[kArgCallId] = callId
    argsMap[kArgAccId] = accId
    argsMap[kFrom]  = hdrFrom
    argsMap[kTo] = hdrTo
    channel?.invokeMethod(kOnCallIncoming, argsMap)
  }

  fun onCallAcceptNotif(callId: Int, withVideo: Boolean) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgWithVideo] = withVideo
    argsMap[kArgCallId] = callId
    channel?.invokeMethod(kOnCallAcceptNotif, argsMap)
  }

  override fun onCallDtmfReceived(callId: Int, tone: Int) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgCallId] = callId
    argsMap[kArgTone] = tone
    channel?.invokeMethod(kOnCallDtmfReceived, argsMap)
  }

  override fun onCallTransferred(callId: Int, statusCode: Int) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgCallId] = callId
    argsMap[kArgStatusCode] = statusCode
    channel?.invokeMethod(kOnCallTransferred, argsMap)
  }

  override fun onCallRedirected(origCallId: Int, relatedCallId: Int, referTo: String?) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgFromCallId] = origCallId
    argsMap[kArgToCallId] = relatedCallId
    argsMap[kArgToExt] = referTo
    channel?.invokeMethod(kOnCallRedirected, argsMap)
  }

  override fun onCallHeld(callId: Int, state: SiprixCore.HoldState?) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgCallId] = callId
    argsMap[kHoldState] = state?.value
    channel?.invokeMethod(kOnCallHeld, argsMap)
  }

  override fun onCallSwitched(callId: Int) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgCallId] = callId
    channel?.invokeMethod(kOnCallSwitched, argsMap)
  }

  override fun onMessageSentState(messageId: Int, success: Boolean, response: String?) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgMsgId] = messageId
    argsMap[kSuccess] = success
    argsMap[kResponse] = response
    channel?.invokeMethod(kOnMessageSentState, argsMap)
}

  override fun onMessageIncoming(messageId: Int, accId: Int, hdrFrom: String?, body: String?) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgMsgId] = messageId
    argsMap[kArgAccId] = accId
    argsMap[kFrom] = hdrFrom
    argsMap[kBody] = body
    channel?.invokeMethod(kOnMessageIncoming, argsMap)
  }
}

////////////////////////////////////////////////////////////////////////////////////////
/// SurfaceTextureRenderer - Displays the video stream on a Surface.

class SurfaceTextureRenderer
  (name: String?) : EglRenderer(name) {
  // Callback for reporting renderer events. Read-only after initilization so no lock required.
  private var rendererEvents: RendererCommon.RendererEvents? = null
  private val layoutLock = Any()
  private var isRenderingPaused = false
  private var isFirstFrameRendered = false
  private var rotatedFrameWidth = 0
  private var rotatedFrameHeight = 0
  private var frameRotation = 0

  private var texture: SurfaceTexture? = null

  fun init(sharedContext: EglBase.Context?,
    rendererEvents: RendererCommon.RendererEvents?
  ) {
    init(sharedContext, rendererEvents, EglBase.CONFIG_PLAIN, GlRectDrawer())
  }

  private fun init(sharedContext: EglBase.Context?,
    rendererEvents: RendererCommon.RendererEvents?, configAttributes: IntArray?,
    drawer: RendererCommon.GlDrawer?
  ) {
    ThreadUtils.checkIsOnMainThread()
    this.rendererEvents = rendererEvents
    synchronized(layoutLock) {
      isFirstFrameRendered = false
      rotatedFrameWidth = 0
      rotatedFrameHeight = 0
      frameRotation = -1
    }
    super.init(sharedContext, configAttributes, drawer)
  }

  override fun init(sharedContext: EglBase.Context?, configAttributes: IntArray?,
    drawer: RendererCommon.GlDrawer?
  ) {
    init(sharedContext, null,  /* rendererEvents */configAttributes, drawer)
  }

  override fun setFpsReduction(fps: Float) {
    synchronized(layoutLock) {
      isRenderingPaused = fps == 0f
    }
    super.setFpsReduction(fps)
  }

  override fun disableFpsReduction() {
    synchronized(layoutLock) {
      isRenderingPaused = false
    }
    super.disableFpsReduction()
  }

  override fun pauseVideo() {
    synchronized(layoutLock) {
      isRenderingPaused = true
    }
    super.pauseVideo()
  }

  // VideoSink interface.
  override fun onFrame(frame: org.webrtc.VideoFrame) {
    updateFrameDimensionsAndReportEvents(frame)
    super.onFrame(frame)
  }

  fun surfaceCreated(texture: SurfaceTexture?) {
    ThreadUtils.checkIsOnMainThread()
    this.texture = texture
    createEglSurface(texture)
  }

  fun surfaceDestroyed() {
    ThreadUtils.checkIsOnMainThread()
    val completionLatch = CountDownLatch(1)
    releaseEglSurface(completionLatch::countDown)
    ThreadUtils.awaitUninterruptibly(completionLatch)
  }

  // Update frame dimensions and report any changes to |rendererEvents|.
  private fun updateFrameDimensionsAndReportEvents(frame: org.webrtc.VideoFrame) {
    synchronized(layoutLock) {
      if (isRenderingPaused) return

      if (rotatedFrameWidth != frame.rotatedWidth ||
        rotatedFrameHeight != frame.rotatedHeight ||
        frameRotation != frame.rotation
      ) {
        rendererEvents?.onFrameResolutionChanged(
          frame.buffer.width, frame.buffer.height, frame.rotation
        )
        rotatedFrameWidth = frame.rotatedWidth
        rotatedFrameHeight = frame.rotatedHeight
        texture?.setDefaultBufferSize(rotatedFrameWidth, rotatedFrameHeight)
        frameRotation = frame.rotation
      }
    }
  }
}//SurfaceTextureRenderer


////////////////////////////////////////////////////////////////////////////////////////
/// FlutterRendererAdapter

class FlutterRendererAdapter(texturesRegistry: TextureRegistry,
                             messenger: BinaryMessenger) : EventChannel.StreamHandler {
  private val textureEntry: SurfaceTextureEntry
  private val surfaceTextureRenderer: SurfaceTextureRenderer
  private val rendererEvents: RendererCommon.RendererEvents
  private val eventChannel: EventChannel
  private var eventSink: EventSink? = null
  var srcCallId: Int = -1

  init {
    textureEntry = texturesRegistry.createSurfaceTexture()//create and register texture

    rendererEvents = RendererEventsListener(this)//createRendererEventsListener()

    surfaceTextureRenderer = SurfaceTextureRenderer("")
    surfaceTextureRenderer.init(SiprixEglBase.getInstance().context, rendererEvents)
    surfaceTextureRenderer.surfaceCreated(textureEntry.surfaceTexture())

    this.eventChannel = EventChannel(messenger, "Siprix/Texture" + textureEntry.id())
    this.eventChannel.setStreamHandler(this)
  }

  fun getRenderer(): SurfaceTextureRenderer {
    return surfaceTextureRenderer
  }

  fun getTextureId(): Long {
    return textureEntry.id()
  }

  fun dispose() {
    surfaceTextureRenderer.surfaceDestroyed()
    surfaceTextureRenderer.release()
    eventChannel.setStreamHandler(null)

    eventSink = null
    textureEntry.release()
  }

  override fun onListen(o: Any?, sink: EventSink?) {
    eventSink = if(sink != null) AnyThreadSink(sink) else null
  }

  override fun onCancel(o: Any?) {
    eventSink = null
  }

  class RendererEventsListener(private val adapter: FlutterRendererAdapter) : RendererCommon.RendererEvents {
    private var _rotation = -1
    private var _width = 0
    private var _height = 0

    override fun onFrameResolutionChanged(videoWidth: Int, videoHeight: Int, rotation: Int) {
      if (adapter.eventSink != null) {
        if (_width != videoWidth || _height != videoHeight) {
          val params = HashMap<String, Any?>()
          params["event"] = "didTextureChangeVideoSize"
          params["id"] = adapter.textureEntry.id()
          params["width"] = videoWidth.toDouble()
          params["height"] = videoHeight.toDouble()
          _width = videoWidth
          _height = videoHeight
          adapter.eventSink!!.success(params.toMap())
        }

        if (_rotation != rotation) {
          val params2 = HashMap<String, Any?>()
          params2["event"] = "didTextureChangeRotation"
          params2["id"] = adapter.textureEntry.id()
          params2["rotation"] = rotation
          _rotation = rotation
          adapter.eventSink!!.success(params2.toMap())
        }
      }
    }//onFrameResolutionChanged

    override fun onFirstFrameRendered() {
    }
  }//RendererEventsListener

  class AnyThreadSink(private val eventSink: EventSink) : EventSink {
    private val handler: Handler = Handler(Looper.getMainLooper())
    override fun success(o: Any) {
      post { eventSink.success(o) }
    }
    override fun error(s: String, s1: String, o: Any) {
      post { eventSink.error(s, s1, o) }
    }
    override fun endOfStream() {
      post { eventSink.endOfStream() }
    }
    private fun post(r: Runnable) {
      if (Looper.getMainLooper() == Looper.myLooper()) {
        r.run()
      } else {
        handler.post(r)
      }
    }
  }

}//FlutterVideoRenderer


////////////////////////////////////////////////////////////////////////////////////////
/// SiprixVoipSdkPlugin

class SiprixVoipSdkPlugin: FlutterPlugin,
  MethodCallHandler, ActivityAware, PluginRegistry.NewIntentListener,
  PluginRegistry.RequestPermissionsResultListener {

  companion object {
    private var permissionRequestCode = 1
    private const val TAG = "SiprixVoipSdkPlugin"
  }

  private lateinit var _appContext : Context
  private lateinit var _messenger: BinaryMessenger
  private lateinit var _textures: TextureRegistry
  private lateinit var _channel : MethodChannel

  private lateinit var _eventListener : EventListener
  private lateinit var _core : SiprixCore

  private var _activity: Activity? = null
  private var _bgService: CallNotifService? = null

  private val renderAdapters = HashMap<Long, FlutterRendererAdapter>()

  private var _pendingIntents : MutableList<Intent> = mutableListOf()
  private var _accountsIds: MutableSet<Int> = mutableSetOf()

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    Log.i(TAG, "onAttachedToEngine this:${this.hashCode()} binding:${flutterPluginBinding.hashCode()}")

    _textures = flutterPluginBinding.textureRegistry
    _messenger = flutterPluginBinding.binaryMessenger
    _appContext = flutterPluginBinding.applicationContext

    _channel = MethodChannel(_messenger, kChannelName)
    _channel.setMethodCallHandler(this)

    _eventListener = EventListener()
    _eventListener.setMethodChannel(_channel)

    //Get core instance (create when hasn't created yet)
    _core = CallNotifService.createSiprixCore(_appContext)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    Log.i(TAG, "onDetachedFromEngine this:${this.hashCode()} binding:${binding.hashCode()}")
  }
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    Log.i(TAG, "onAttachedToActivity this:${this.hashCode()}")
    binding.addOnNewIntentListener(this)
    _activity = binding.activity
    _core.setModelListener(_eventListener)

    setActivityFlags(_activity)
    requestPermissions()
  }

  override fun onDetachedFromActivityForConfigChanges() {
    Log.i(TAG, "onDetachedFromActivityForConfigChanges this:${this.hashCode()}")
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    Log.i(TAG, "onReattachedToActivityForConfigChanges this:${this.hashCode()}")
    binding.addOnNewIntentListener(this)
    _activity = binding.activity
    _core.setModelListener(_eventListener)
  }

  override fun onDetachedFromActivity() {
    Log.i(TAG, "onDetachedFromActivity this:${this.hashCode()}")
    _eventListener.setMethodChannel(null)
    _channel.setMethodCallHandler(null)

    if (_bgService != null) {
      _core.setModelListener(null)

      _activity?.unbindService(_serviceConnection)
      _bgService = null
    }
  }

  private fun startAndBindNotifService(serviceClassName : String?) {
    try{
      if(_bgService != null) return//already bound

      val srvClass = if(serviceClassName!=null) Class.forName(serviceClassName) else CallNotifService::class.java
      val srvIntent = Intent(_appContext, srvClass)
      _activity?.bindService(srvIntent, _serviceConnection, Context.BIND_AUTO_CREATE)

      srvIntent.setAction(CallNotifService.kActionAppStarted)
      _appContext.startService(srvIntent)
    }catch (ex: Exception) {
      Log.e(TAG, "Can't start service: '${ex}'")
    }
  }

  private val _serviceConnection: ServiceConnection = object : ServiceConnection {
    override fun onServiceConnected(className: ComponentName, service: IBinder) {
      // Service is running in our own process we can directly access it.
      val binder: CallNotifService.LocalBinder = service as CallNotifService.LocalBinder
      _bgService = binder.service

      if(_activity != null) {
        handleIntent("onServiceConnected", _activity!!.intent)
      }
    }

    // Called when the connection with the service disconnects unexpectedly.
    override fun onServiceDisconnected(className: ComponentName) {
      _bgService = null
    }
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    val args : HashMap<String, Any?>? = call.arguments as? HashMap<String, Any?>
    if (args==null) {
      result.error( "-", kBadArgumentsError, null)
      return
    }

    if(!_core.isInitialized) {
      if(call.method==kMethodModuleInitialize) { handleModuleInitialize(args, result); }
      else { result.error("UNAVAILABLE", kModuleNotInitializedError, null); }
      return
    }
    
    when(call.method){
      kMethodModuleInitialize   ->  handleModuleInitialize(args, result)
      kMethodModuleUnInitialize ->  handleModuleUnInitialize(args, result)
      kMethodModuleHomeFolder   ->  handleModuleHomeFolder(args, result)
      kMethodModuleVersionCode  ->  handleModuleVersionCode(args, result)
      kMethodModuleVersion      ->  handleModuleVersion(args, result)

      kMethodAccountAdd         ->  handleAccountAdd(args, result)
      kMethodAccountUpdate      ->  handleAccountUpdate(args, result)
      kMethodAccountRegister    ->  handleAccountRegister(args, result)
      kMethodAccountUnregister  ->  handleAccountUnregister(args, result)
      kMethodAccountDelete      ->  handleAccountDelete(args, result)
      kMethodAccountGenInstId   ->  handleAccountGenInstId(args, result)

      kMethodCallInvite        ->   handleCallInvite(args, result)
      kMethodCallReject        ->   handleCallReject(args, result)
      kMethodCallAccept        ->   handleCallAccept(args, result)
      kMethodCallHold          ->   handleCallHold(args, result)
      kMethodCallGetHoldState  ->   handleCallGetHoldState(args, result)
      kMethodCallGetSipHeader  ->   handleCallGetSipHeader(args, result)
      kMethodCallMuteMic       ->   handleCallMuteMic(args, result)
      kMethodCallMuteCam       ->   handleCallMuteCam(args, result)
      kMethodCallSendDtmf      ->   handleCallSendDtmf(args, result)
      kMethodCallPlayFile      ->   handleCallPlayFile(args, result)
      kMethodCallStopPlayFile  ->   handleCallStopPlayFile(args, result)
      kMethodCallRecordFile    ->   handleCallRecordFile(args, result)
      kMethodCallStopRecordFile->   handleCallStopRecordFile(args, result)
      kMethodCallTransferBlind ->   handleCallTransferBlind(args, result)
      kMethodCallTransferAttended -> handleCallTransferAttended(args, result)
      kMethodCallStopRingtone  ->   handleCallStopRingtone(args, result)
      kMethodCallBye ->             handleCallBye(args, result)

      kMethodMixerSwitchToCall ->   handleMixerSwitchToCall(args, result)
      kMethodMixerMakeConference -> handleMixerMakeConference(args, result)

      kMethodMessageSend ->          handleMessageSend(args, result)

      kMethodSubscriptionAdd ->      handleSubscriptionAdd(args, result)
      kMethodSubscriptionDelete ->   handleSubscriptionDelete(args, result)

      kMethodDvcSetForegroundMode->  handleDvcSetForegroundMode(args, result)
      kMethodDvcIsForegroundMode->   handleDvcIsForegroundMode(args, result)

      kMethodDvcGetPlayoutNumber->   handleDvcGetPlayoutNumber(args, result)
      kMethodDvcGetRecordNumber ->   handleDvcGetRecordNumber(args, result)
      kMethodDvcGetVideoNumber  ->   handleDvcGetVideoNumber(args, result)
      kMethodDvcGetPlayout      ->   handleDvcGetPlayout(args, result)
      kMethodDvcGetRecording    ->   handleDvcGetRecording(args, result)
      kMethodDvcGetVideo        ->   handleDvcGetVideo(args, result)
      kMethodDvcSetPlayout      ->   handleDvcSetPlayout(args, result)
      kMethodDvcSetRecording    ->   handleDvcSetRecording(args, result)
      kMethodDvcSetVideo        ->   handleDvcSetVideo(args, result)
      kMethodDvcSetVideoParams  ->   handleDvcSetVideoParams(args, result)

      kMethodVideoRendererCreate ->   handleVideoRendererCreate(args, result)
      kMethodVideoRendererSetSrc ->   handleVideoRendererSetSrc(args, result)
      kMethodVideoRendererDispose->   handleVideoRendererDispose(args, result)

      else                       ->   result.notImplemented()
    }//when
  }


  private fun handleModuleInitialize(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    if (_core.isInitialized) {
      startAndBindNotifService(args["serviceClassName"] as? String)

      Log.i(TAG, "handleModuleInitialize - already initialized")
      result.success("Already initialized")
      return
    }

    //Get arguments from map
    val iniData = IniData()

    val license : String? = args["license"] as? String
    if(license != null) { iniData.setLicense(license) }

    val brandName : String? = args["brandName"] as? String
    if(brandName != null) { iniData.setBrandName(brandName) }

    val logLevelFile : Int? = args["logLevelFile"] as? Int
    if(logLevelFile != null) { iniData.setLogLevelFile(IniData.LogLevel.fromInt(logLevelFile)); }

    val logLevelIde : Int? = args["logLevelIde"] as? Int
    if(logLevelIde != null) { iniData.setLogLevelIde(IniData.LogLevel.fromInt(logLevelIde)); }

    val rtpStartPort : Int? = args["rtpStartPort"] as? Int
    if(rtpStartPort != null) { iniData.setRtpStartPort(rtpStartPort); }

    val tlsVerifyServer : Boolean? = args["tlsVerifyServer"] as? Boolean
    if(tlsVerifyServer != null) { iniData.setTlsVerifyServer(tlsVerifyServer); }

    val singleCallMode : Boolean? = args["singleCallMode"] as? Boolean
    if(singleCallMode != null) { iniData.setSingleCallMode(singleCallMode); }

    val shareUdpTransport : Boolean? = args["shareUdpTransport"] as? Boolean
    if(shareUdpTransport != null) { iniData.setShareUdpTransport(shareUdpTransport); }

    val unregOnDestroy : Boolean? = args["unregOnDestroy"] as? Boolean
    if(unregOnDestroy != null) { iniData.setUnregOnDestroy(unregOnDestroy); }

    val useDnsSrv : Boolean? = args["useDnsSrv"] as? Boolean
    if(useDnsSrv != null) { iniData.setUseDnsSrv(useDnsSrv); }

    val recordStereo : Boolean? = args["recordStereo"] as? Boolean
    if(recordStereo != null) { iniData.setRecordStereo(recordStereo); }

    val enableVideoCall : Boolean? = args["enableVideoCall"] as? Boolean
    if(enableVideoCall != null) { iniData.setEnableVideoCall(enableVideoCall); }

    val transpForceIPv4 : Boolean? = args["transpForceIPv4"] as? Boolean
    if(transpForceIPv4 != null) { iniData.setTranspForceIPv4(transpForceIPv4); }

    val listenTelState : Boolean? = args["listenTelState"] as? Boolean
    if(listenTelState != null) { iniData.setUseTelState(listenTelState); }

    val listenVolChange : Boolean? = args["listenVolChange"] as? Boolean
    if(listenVolChange != null) { iniData.setUseVolChange(listenVolChange); }

    //Init core
    iniData.setUseExternalRinger(true)
    val err = _core.initialize(iniData)
    sendResult(err, result)
    Log.i(TAG, "handleModuleInitialize err:${err}")

    //Bind and start service
    startAndBindNotifService(args["serviceClassName"] as? String)
  }

  private fun handleModuleUnInitialize(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val err = _core.unInitialize()
    sendResult(err, result)
  }

  private fun handleModuleHomeFolder(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val path : String = _core.homeFolder
    result.success(path)
  }

  private fun handleModuleVersionCode(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val versionCode : Int = _core.versionCode
    result.success(versionCode)
  }

  private fun handleModuleVersion(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val version: String = _core.version
    result.success(version)
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Account methods implementation

  private fun parseAccData(args : HashMap<String, Any?>) : AccData {
    //Get arguments from map
    val accData = AccData()

    val sipServer : String? = args["sipServer"] as? String
    if(sipServer != null) { accData.setSipServer(sipServer); }

    val sipExtension : String? = args["sipExtension"] as? String
    if(sipExtension != null) { accData.setSipExtension(sipExtension); }

    val sipPassword : String? = args["sipPassword"] as? String
    if(sipPassword != null) { accData.setSipPassword(sipPassword); }

    val sipAuthId : String? = args["sipAuthId"] as? String
    if(sipAuthId != null) { accData.setSipAuthId(sipAuthId); }

    val sipProxy : String? = args["sipProxy"] as? String
    if(sipProxy != null) { accData.setSipProxyServer(sipProxy); }

    val displName : String? = args["displName"] as? String
    if(displName != null) { accData.setDisplayName(displName); }

    val userAgent : String? = args["userAgent"] as? String
    if(userAgent != null) { accData.setUserAgent(userAgent); }

    val expireTime : Int? = args["expireTime"] as? Int
    if(expireTime != null) { accData.setExpireTime(expireTime); }

    val transport : Int? = args["transport"] as? Int
    if(transport != null) { accData.setTranspProtocol(AccData.SipTransport.fromInt(transport)); }

    val port : Int? = args["port"] as? Int
    if(port != null) { accData.setTranspPort(port); }

    val tlsCaCertPath : String? = args["tlsCaCertPath"] as? String
    if(tlsCaCertPath != null) { accData.setTranspTlsCaCert(tlsCaCertPath); }

    val tlsUseSipScheme : Boolean? = args["tlsUseSipScheme"] as? Boolean
    if(tlsUseSipScheme != null) { accData.setUseSipSchemeForTls(tlsUseSipScheme); }

    val rtcpMuxEnabled : Boolean? = args["rtcpMuxEnabled"] as? Boolean
    if(rtcpMuxEnabled != null) { accData.setRtcpMuxEnabled(rtcpMuxEnabled); }

    val iceEnabled : Boolean? = args["iceEnabled"] as? Boolean
    if(iceEnabled != null) { accData.setIceEnabled(iceEnabled); }

    val instanceId : String? = args["instanceId"] as? String
    if(instanceId != null) { accData.setInstanceId(instanceId); }

    val ringTonePath : String? = args["ringTonePath"] as? String
    if(ringTonePath != null) { accData.setRingToneFile(ringTonePath); }
    
    val keepAliveTime : Int? = args["keepAliveTime"] as? Int
    if(keepAliveTime != null) { accData.setKeepAliveTime(keepAliveTime); }
    
    val rewriteContactIp : Boolean? = args["rewriteContactIp"] as? Boolean
    if(rewriteContactIp != null) { accData.setRewriteContactIp(rewriteContactIp); }

    val verifyIncomingCall : Boolean? = args["verifyIncomingCall"] as? Boolean
    if(verifyIncomingCall != null) { accData.setVerifyIncomingCall(verifyIncomingCall); }

    val forceSipProxy : Boolean? = args["forceSipProxy"] as? Boolean
    if(forceSipProxy != null) { accData.setForceSipProxy(forceSipProxy); }

    val secureMedia : Int? = args["secureMedia"] as? Int
    if(secureMedia != null) { accData.setSecureMediaMode(AccData.SecureMediaMode.fromInt(secureMedia)); }

    val stunServer : String? = args["stunServer"] as? String
    if(stunServer != null) { accData.setStunServer(stunServer); }

    val turnServer : String? = args["turnServer"] as? String
    if(turnServer != null) { accData.setTurnServer(turnServer); }

    val turnUser : String? = args["turnUser"] as? String
    if(turnUser != null) { accData.setTurnUser(turnUser); }

    val turnPassword : String? = args["turnPassword"] as? String
    if(turnPassword != null) { accData.setTurnPassword(turnPassword); }

    val xheaders: HashMap<String, Any?>? = args["xheaders"] as? HashMap<String, Any?>?
    if(xheaders != null) {
      for ((hdrName, hdrVal) in xheaders) {
        val hdrStrVal : String? = hdrVal as? String
        if(hdrStrVal != null)
          accData.addXHeader(hdrName, hdrStrVal)
      }
    }

    val xContactUriParams: HashMap<String, Any?>? = args["xContactUriParams"] as? HashMap<String, Any?>?
    if(xContactUriParams != null) {
      for ((paramName, paramVal) in xContactUriParams) {
        val paramStrVal : String? = paramVal as? String
        if(paramStrVal != null)
          accData.addXContactUriParam(paramName, paramStrVal)
      }
    }

    val aCodecs: ArrayList<Int?>? = args["aCodecs"] as? ArrayList<Int?>?
    if(aCodecs != null) {
      accData.resetAudioCodecs()
      for (c in aCodecs)
        if(c != null)
          accData.addAudioCodec(AccData.AudioCodec.fromInt(c))
    }
    val vCodecs: ArrayList<Int?>? = args["vCodecs"] as? ArrayList<Int?>?
    if(vCodecs != null) {
      accData.resetVideoCodecs()
      for (c in vCodecs)
        if(c != null)
          accData.addVideoCodec(AccData.VideoCodec.fromInt(c))
    }

    return accData
  }

  private fun handleAccountAdd(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val accData = parseAccData(args)
    val accIdArg = SiprixCore.IdOutArg()
    val err = _core.accountAdd(accData, accIdArg)
    if(err == kErrorCodeEOK){
      result.success(accIdArg.value)
    }else{
      result.error(err.toString(), _core.getErrText(err), accIdArg.value)
    }

    _accountsIds.add(accIdArg.value)
    Log.i(TAG, "handleAccountAdd id:${accIdArg.value} err:${err}/${_core.getErrText(err)}")
    raiseIncomingCallWhenAccountsRestored()
    raiseIncomingMsgWhenAccountsRestored()
  }

  private fun handleAccountUpdate(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val accData = parseAccData(args)
    val accId : Int? = args[kArgAccId] as? Int

    if(accId != null) {
      val err = _core.accountUpdate(accData, accId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleAccountRegister(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val accId : Int?     = args[kArgAccId] as? Int
    val expireTime: Int? = args[kArgExpireTime] as? Int

    if((accId != null) && ( expireTime != null)) {
      val err = _core.accountRegister(accId, expireTime)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }    
  }
  
  private fun handleAccountUnregister(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val accId : Int? = args[kArgAccId] as? Int

    if(accId != null) {
      val err = _core.accountUnregister(accId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleAccountDelete(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val accId : Int? = args[kArgAccId] as? Int

    if(accId == null) {
      sendBadArguments(result)
    }else{
      val err = _core.accountDelete(accId)
      sendResult(err, result)
      if(err == kErrorCodeEOK) _accountsIds.remove(accId)
    }
  }

  private fun handleAccountGenInstId(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success(_core.accountGenInstId())
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Calls methods implementation
  
  private fun handleCallInvite(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    if(!hasPermission(Manifest.permission.RECORD_AUDIO)) {
      result.error("Microphone permission required", "-", null)
      return
    }

    //Get arguments from map
    val destData = DestData()

    val toExt : String? = args["extension"] as? String
    if(toExt != null) { destData.setExtension(toExt); }

    val fromAccId : Int? = args[kArgAccId] as? Int
    if(fromAccId != null) { destData.setAccountId(fromAccId); }

    val inviteTimeout : Int? = args["inviteTimeout"] as? Int
    if(inviteTimeout != null) { destData.setInviteTimeout(inviteTimeout); }

    val withVideo : Boolean? = args[kArgWithVideo] as? Boolean
    if(withVideo != null) { destData.setVideoCall(withVideo); }

    val displName : String? = args["displName"] as? String
    if(displName != null) { destData.setDisplayName(displName); }

    val xheaders: HashMap<String, Any?>? = args["xheaders"] as? HashMap<String, Any?>?
    if(xheaders != null) {
      for ((hdrName, hdrVal) in xheaders) {
        val hdrStrVal : String? = hdrVal as? String
        if(hdrStrVal != null)
          destData.addXHeader(hdrName, hdrStrVal)
      }
    }

    val callIdArg = SiprixCore.IdOutArg()
    val err = _core.callInvite(destData, callIdArg)
    if(err == kErrorCodeEOK) {
      result.success(callIdArg.value)
    }else{
      result.error(err.toString(), _core.getErrText(err), null)
    }
  }
  
  private fun handleCallReject(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId    : Int? = args[kArgCallId] as? Int
    val statusCode: Int? = args[kArgStatusCode] as? Int

    if((callId != null) && ( statusCode != null)) {
      val err = _core.callReject(callId, statusCode)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleCallAccept(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    if(!hasPermission(Manifest.permission.RECORD_AUDIO)) {
      result.error("Microphone permission required", "-", null)
      return
    }

    val callId : Int?= args[kArgCallId] as? Int
    val withVideo :Boolean? = args[kArgWithVideo] as? Boolean

    if((callId != null)&&(withVideo != null)) {
      val err = _core.callAccept(callId, withVideo)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleCallHold(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId : Int? = args[kArgCallId] as? Int

    if(callId != null) {
      val err = _core.callHold(callId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleCallGetHoldState(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId :Int? = args[kArgCallId] as? Int

    if(callId == null) {
      sendBadArguments(result)
      return
    }

    val state = SiprixCore.IdOutArg()
    val err = _core.callGetHoldState(callId, state)
    if(err == kErrorCodeEOK){
      result.success(state.value)
    }else{
      result.error(err.toString(), _core.getErrText(err), null)
    }
  }
  
  private fun handleCallGetSipHeader(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId :Int? = args[kArgCallId] as? Int
    val hdrName :String? = args["hdrName"] as? String
    
    if((callId == null)||(hdrName==null)) {
      sendBadArguments(result)
      return
    }

    result.success(_core.callGetSipHeader(callId, hdrName))
  }

  private fun handleCallMuteMic(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId : Int? = args[kArgCallId] as? Int
    val mute :Boolean? = args["mute"] as? Boolean

    if((callId == null)||(mute==null)) {
      sendBadArguments(result)
      return
    }
    val err = _core.callMuteMic(callId, mute)
    sendResult(err, result)
  }
  
  private fun handleCallMuteCam(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId : Int? = args[kArgCallId] as? Int
    val mute :Boolean? = args["mute"] as? Boolean

    if((callId == null)||(mute==null)) {
      sendBadArguments(result)
      return
    }
    val err = _core.callMuteCam(callId, mute)
    sendResult(err, result)
  }

  private fun handleCallSendDtmf(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId :Int?         = args[kArgCallId] as? Int
    val durationMs : Int?    = args["durationMs"] as? Int
    val interToneGapMs: Int? = args["intertoneGapMs"] as? Int
    val method  : Int?       = args["method"] as? Int
    val dtmfs  : String?     = args["dtmfs"] as? String

    if((callId == null)||(durationMs==null)||(interToneGapMs==null)||(dtmfs==null)||(method==null)) {
      sendBadArguments(result)
      return
    }

    val err = _core.callSendDtmf(callId, dtmfs,
      durationMs, interToneGapMs, SiprixCore.DtmfMethod.fromInt(method))
    sendResult(err, result)
  }
  
  private fun handleCallPlayFile(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId : Int?          = args[kArgCallId] as? Int
    val pathToMp3File :String? = args["pathToMp3File"] as? String
    val loop :Boolean?         = args["loop"] as? Boolean

    if((callId == null)||(pathToMp3File==null)||(loop==null)) {
      sendBadArguments(result)
      return
    }

    val playerIdArg = SiprixCore.IdOutArg()
    val err = _core.callPlayFile(callId, pathToMp3File, loop, playerIdArg)
    if(err == kErrorCodeEOK) {
      result.success(playerIdArg.value)
    }else{
      result.error(err.toString(), _core.getErrText(err), null)
    }
  }

  private fun handleCallStopPlayFile(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val playerId : Int? = args[kArgPlayerId] as? Int

    if(playerId != null) {
      val err = _core.callStopPlayFile(playerId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleCallRecordFile(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId : Int?           = args[kArgCallId] as? Int
    val pathToMp3File :String? = args["pathToMp3File"] as? String
    
    if((callId != null)&&((pathToMp3File!=null))) {
      val err = _core.callRecordFile(callId, pathToMp3File)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }

  private fun handleCallStopRecordFile(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId : Int? = args[kArgCallId] as? Int

    if(callId != null) {
      val err = _core.callStopRecordFile(callId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }

  private fun handleCallTransferBlind(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId = args[kArgCallId] as? Int
    val toExt  = args[kArgToExt] as? String

    if((callId != null) && ( toExt != null)) {
      val err = _core.callTransferBlind(callId, toExt)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleCallTransferAttended(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val fromCallId = args[kArgFromCallId] as? Int
    val toCallId   = args[kArgToCallId] as? Int

    if((fromCallId != null) && ( toCallId != null)) {
      val err = _core.callTransferAttended(fromCallId, toCallId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleCallBye(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId = args[kArgCallId] as? Int

    if(callId != null) {
      val err = _core.callBye(callId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }

  private fun handleCallStopRingtone(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    _core.callStopRingtone()
    result.success("Success")
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Mixer methods implementation
  
  private fun handleMixerSwitchToCall(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId = args[kArgCallId] as? Int

    if(callId != null) {
      val err = _core.mixerSwitchToCall(callId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }    
  }

  @Suppress("UNUSED_PARAMETER")
  private fun handleMixerMakeConference(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val err = _core.mixerMakeConference()
    sendResult(err, result)
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix message

  private fun handleMessageSend(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    //Get arguments from map
    val msgData = MsgData()

    val toExt : String? = args["extension"] as? String
    if(toExt != null) { msgData.setExtension(toExt); }

    val fromAccId : Int? = args[kArgAccId] as? Int
    if(fromAccId != null) { msgData.setAccountId(fromAccId); }

    val body : String? = args[kBody] as? String
    if(body != null) { msgData.setBody(body); }

    val msgIdArg = SiprixCore.IdOutArg()
    val err = _core.messageSend(msgData, msgIdArg)
    if(err == kErrorCodeEOK) {
      result.success(msgIdArg.value)
    }else{
      result.error(err.toString(), _core.getErrText(err), null)
    }
  }


  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix subscriptions

  private fun handleSubscriptionAdd(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    //Get arguments from map
    val subscrData = SubscrData()

    val toExt : String? = args["extension"] as? String
    if(toExt != null) { subscrData.setExtension(toExt); }

    val fromAccId : Int? = args[kArgAccId] as? Int
    if(fromAccId != null) { subscrData.setAccountId(fromAccId); }

    val expireTime : Int? = args["expireTime"] as? Int
    if(expireTime != null) { subscrData.setExpireTime(expireTime); }

    val mimeSubType : String? = args["mimeSubType"] as? String
    if(mimeSubType != null) { subscrData.setMimeSubtype(mimeSubType); }

    val eventType : String? = args["eventType"] as? String
    if(eventType != null) { subscrData.setEventType(eventType); }

    val subscrIdArg = SiprixCore.IdOutArg()
    val err = _core.subscrCreate(subscrData, subscrIdArg)
    if(err == kErrorCodeEOK) {
      result.success(subscrIdArg.value)
    }else{
      result.error(err.toString(), _core.getErrText(err), subscrIdArg.value)
    }
  }

  private fun handleSubscriptionDelete(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val subscrId : Int? = args[kArgSubscrId] as? Int

    if(subscrId != null) {
      val err = _core.subscrDestroy(subscrId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }


  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Devices methods implementation

  private fun handleDvcSetForegroundMode(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val foregroundEnable :Boolean? = args[kArgForeground] as? Boolean
    if(foregroundEnable == null) {
      sendBadArguments(result)
      return
    }

    if(_bgService == null) {
      result.error("-", "Service has not bound yet", null)
      return
    }

    if(foregroundEnable) {
      val success = _bgService!!.startForegroundMode()
      if(success) result.success("Foreground mode started")
      else        result.error( "-", "Missed permissions", null)
    }
    else {
      _bgService!!.stopForegroundMode()
      result.success("Foreground mode stopped")
    }
  }

  private fun handleDvcIsForegroundMode(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success(if(_bgService!=null) _bgService!!.isForegroundMode() else false)
  }

  private fun handleDvcGetPlayoutNumber(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success(_core.dvcGetAudioDevices())
  }

  private fun handleDvcGetRecordNumber(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success(0)//TODO add impl
  }

  private fun handleDvcGetVideoNumber(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success(0)//TODO add impl
  }

  private fun handleDvcGetPlayout(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val dvcIndex :Int? = args[kArgDvcIndex] as? Int

    if(dvcIndex != null) {
      val argsMap = HashMap<String, Any?> ()
      argsMap[kArgDvcName] = _core.dvcGetAudioDevice(dvcIndex).name
      argsMap[kArgDvcGuid] = dvcIndex.toString()
      result.success(argsMap)
    }else{
      sendBadArguments(result)
    }
  }

  private fun handleDvcGetRecording(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success("")//TODO add impl
  }

  private fun handleDvcGetVideo(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success("")//TODO add impl
  }

  private fun handleDvcSetPlayout(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val dvcIndex :Int? = args[kArgDvcIndex] as? Int
    if(dvcIndex != null) {
      val dvc = _core.dvcGetAudioDevice(dvcIndex)
      if(!dvc.equals(SiprixCore.AudioDevice.None)) {
        _core.dvcSetAudioDevice(dvc)
        result.success("Success")
      }else{
        result.error( "-", "Bad device index", null)
      }
    }else{
      sendBadArguments(result)
    }
  }

  private fun handleDvcSetRecording(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success("Success")
  }

  private fun handleDvcSetVideo(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    _core.dvcSwitchCamera()
    result.success("Success")
  }

  private fun handleDvcSetVideoParams(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val vdoData = VideoData()

    val noCameraImgPath : String? = args["noCameraImgPath"] as? String
    if(noCameraImgPath != null) { vdoData.setNoCameraImgPath(noCameraImgPath) }

    val framerateFps : Int? = args["framerateFps"] as? Int
    if(framerateFps != null) { vdoData.setFramerate(framerateFps); }

    val bitrateKbps : Int? = args["bitrateKbps"] as? Int
    if(bitrateKbps != null) { vdoData.setBitrate(bitrateKbps); }

    val height : Int? = args["height"] as? Int
    if(height != null) { vdoData.setHeight(height); }

    val width : Int? = args["width"] as? Int
    if(width != null) { vdoData.setWidth(width); }

    val err = _core.dvcSetVideoParams(vdoData)
    sendResult(err, result)
  }



  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix video renderers

  private fun handleVideoRendererCreate(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val renderAdapter = FlutterRendererAdapter(_textures, _messenger)
    val textureId = renderAdapter.getTextureId()

    renderAdapters[textureId] = renderAdapter

    result.success(textureId)
  }

  private fun handleVideoRendererSetSrc(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId = args[kArgCallId] as? Int
    var textureId = args[kArgVideoTextureId] as? Long
    if(textureId==null) textureId = (args[kArgVideoTextureId] as? Int)?.toLong()

    if((callId == null) || ( textureId == null)) {
      sendBadArguments(result)
      return
    }

    val renderAdapter: FlutterRendererAdapter? = renderAdapters[textureId]
    if(renderAdapter != null) {
      renderAdapter.srcCallId = callId
      val err = _core.callSetVideoRenderer(callId, renderAdapter.getRenderer())
      sendResult(err, result)
    }
  }

  private fun handleVideoRendererDispose(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    var textureId = args[kArgVideoTextureId] as? Long
    if(textureId==null) textureId = (args[kArgVideoTextureId] as? Int)?.toLong()
    if(textureId == null) { sendBadArguments(result); return; }

    val renderAdapter: FlutterRendererAdapter? = renderAdapters[textureId]
    if(renderAdapter != null) {
      val nullRenderer : EglRenderer? = null
      _core.callSetVideoRenderer(renderAdapter.srcCallId, nullRenderer)
      renderAdapter.dispose()
      renderAdapters.remove(textureId)
    }
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Helpers methods

  private fun sendResult(err : Int, result: MethodChannel.Result) {
    if (err == kErrorCodeEOK) {
      result.success("Success")
    }
    else{
      result.error(err.toString(), _core.getErrText(err), null)
    }
  }

  private fun sendBadArguments(result: MethodChannel.Result){
    result.error( "-", kBadArgumentsError, null)
  }

  private fun hasPermission(permission: String): Boolean {
    return ((_activity == null) ||
            ContextCompat.checkSelfPermission(_activity!!, permission) == PackageManager.PERMISSION_GRANTED)
  }

  private fun requestPermissions() {
    //Skip if manifest contains predefined tag
    val applicationInfo = _activity!!.packageManager.getApplicationInfo(_activity!!.packageName, PackageManager.GET_META_DATA)
    var skipPermissionRequest = applicationInfo.metaData?.getBoolean("com.siprix.SkipPermissionRequest")
    if(skipPermissionRequest==true) return

    //Add 'CAMERA' if manifest contains it
    val permissions = mutableListOf(Manifest.permission.RECORD_AUDIO)
    var info =_activity!!.packageManager.getPackageInfo(_activity!!.packageName, PackageManager.GET_PERMISSIONS)
    if((info.requestedPermissions!=null) &&
      info.requestedPermissions!!.contains(Manifest.permission.CAMERA))
      permissions.add(Manifest.permission.CAMERA)

    //Add 'POST_NOTIFICATIONS'
    if (Build.VERSION.SDK_INT >= 33)
      permissions.add(Manifest.permission.POST_NOTIFICATIONS)

    //Add 'USE_FULL_SCREEN_INTENT'
    if((Build.VERSION.SDK_INT >= 34) &&
      (info.requestedPermissions!=null) &&
       info.requestedPermissions!!.contains(Manifest.permission.USE_FULL_SCREEN_INTENT))
      permissions.add(Manifest.permission.USE_FULL_SCREEN_INTENT)

    //Add 'BLUETOOTH_CONNECT' if manifest contains it
    if((Build.VERSION.SDK_INT >= 31) &&
       (info.requestedPermissions!=null) &&
        info.requestedPermissions!!.contains(Manifest.permission.BLUETOOTH_CONNECT)) {
      permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
    }

    ActivityCompat.requestPermissions(_activity!!, permissions.toTypedArray(), permissionRequestCode)
  }

  override fun onRequestPermissionsResult(requestCode: Int,
                                          permissions: Array<String?>, grantResults: IntArray
  ): Boolean {
    if((requestCode != permissionRequestCode) ||
      (permissions.isEmpty() && grantResults.isEmpty())) return false

    val firstRun: Boolean = isRunningFirstTime()
    for(index in permissions.indices) {
      if (grantResults[index] == PackageManager.PERMISSION_GRANTED) continue

      val permission = permissions[index]
      if (ActivityCompat.shouldShowRequestPermissionRationale(_activity!!, permission!!)) {
        displayPermissionAlert(permission, false)
      } else if (firstRun) {
        requestPermissionAgain(permission, false)
      } else {
        displayPermissionAlert(permission, true)
      }
    }
    return true
  }

  private fun displayPermissionAlert(permission: String, openAppSettings: Boolean) {
    if (openAppSettings && permission.equals(Manifest.permission.CAMERA)) return
    val message = when (permission) {
      Manifest.permission.CAMERA -> "Permission 'Camera' is required for video calls."
      Manifest.permission.RECORD_AUDIO -> "Permission 'Record audio' is required to access microphone.\nApplication can't make calls without it."
      Manifest.permission.POST_NOTIFICATIONS -> "Permission 'Notifications' is required for displaying incoming call notifications when app is in background"
      else -> "$permission is required [?]" //shouldn't happen
    }

    AlertDialog.Builder(_activity!!)
      .setTitle("Permission required")
      .setMessage(message)
      .setNegativeButton("Cancel"
      ) { dialog: DialogInterface, which: Int -> dialog.cancel() }
      .setPositiveButton(
        if (openAppSettings) "Go to settings" else "Allow"
      ) { dialog: DialogInterface?, which: Int -> requestPermissionAgain(permission, openAppSettings)
      }
      .show()
  }

  private fun requestPermissionAgain(permission: String, openAppSettings: Boolean) {
    if (openAppSettings) {
      val intent: Intent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
      intent.data = Uri.fromParts("package", _activity!!.packageName, null)
      _activity!!.startActivity(intent)
    } else {
      ActivityCompat.requestPermissions(_activity!!, arrayOf(permission), permissionRequestCode)
    }
  }

  private fun isRunningFirstTime(): Boolean {
    val pref: SharedPreferences = _activity!!.getSharedPreferences(TAG, Context.MODE_PRIVATE)
    val firstRun = pref.getBoolean("firstRun", true)
    if (firstRun) pref.edit().putBoolean("firstRun", false).apply()
    return firstRun
  }

  override fun onNewIntent(intent: Intent): Boolean {
    return handleIntent("onNewIntent", intent)
  }

  private fun handleIntent(method: String, intent: Intent) : Boolean {
    Log.i(TAG, "handleIntent '${method}' ${intent}")

    _bgService?.handleIncomingCallIntent(intent)

    if(canHandleIntent(intent)) {
      raiseIncomingCallEvent(intent)
      return true
    }
    return false
  }

  private fun canHandleIntent(intent: Intent):Boolean {
    //Skip intent if extra is null or action not expected
    val isCallIncomingAction = (CallNotifService.kActionIncomingCall == intent.action)//tap on notification
    val isCallAcceptAction = (CallNotifService.kActionIncomingCallAccept == intent.action)//tap on 'Accept'
    return (intent.extras != null) && (isCallIncomingAction || isCallAcceptAction)
  }

  private fun raiseIncomingCallEvent(intent: Intent) : Boolean {
    Log.i(TAG, "raiseIncomingCallEvent: ${intent}")
    if(intent.extras == null) return true

    //Get accId from intent
    val args = intent.extras!!
    val accId = args.getInt(CallNotifService.kExtraAccId)

    //When this instance of plugin doesn't have accId yet - store intent and raise it later
    if(!_accountsIds.contains(accId)) {
        Log.w(TAG, "skip as accounts from previous session hasn't restored yet")
        _pendingIntents.add(intent)
        return false
    }

    //Get rest of the data from intent
    val callId = args.getInt(CallNotifService.kExtraCallId)
    val video = args.getBoolean(CallNotifService.kExtraWithVideo)
    val from = args.getString(CallNotifService.kExtraHdrFrom)
    val to = args.getString(CallNotifService.kExtraHdrTo)

    Log.i(TAG, "raise onCallIncoming $callId")
    _eventListener.onCallIncoming(callId, accId, video, from, to)

    val isCallAcceptAction = (CallNotifService.kActionIncomingCallAccept == intent.action)//tap on 'Accept'
    if(isCallAcceptAction) {
      Log.i(TAG, "raise onCallAcceptNotif $callId")
      _eventListener.onCallAcceptNotif(callId, video)
    }
    return true
  }

  private fun raiseIncomingMsgEvent(args: Bundle) : Boolean {
    val accId = args.getInt(CallNotifService.kExtraAccId)
    if(!_accountsIds.contains(accId)) return false;

    val messageId = args.getInt(CallNotifService.kExtraMsgId)
    val from = args.getString(CallNotifService.kExtraHdrFrom)
    val body = args.getString(CallNotifService.kExtraBody)

    Log.i(TAG, "raise onMessageIncoming $args")
    _eventListener.onMessageIncoming(messageId, accId, from, body)
    return true
  }

  private fun raiseIncomingCallWhenAccountsRestored() {
    val intentsIterator = _pendingIntents.iterator()
    while (intentsIterator.hasNext()) {
      if(raiseIncomingCallEvent(intentsIterator.next())) {
        intentsIterator.remove()
      }
    }
  }

  private fun raiseIncomingMsgWhenAccountsRestored() {
    if(_bgService==null) return

    val msgsIt = _bgService!!.pendingMsgs().iterator()
    while (msgsIt.hasNext()) {
      if (raiseIncomingMsgEvent(msgsIt.next())) {
        msgsIt.remove()
      }
    }
  }

  private fun setActivityFlags(activity: Activity?) {
    if(activity != null) {
      if (Build.VERSION.SDK_INT < 27) {
        activity.window.addFlags(
          WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )
      } else {
        activity.setTurnScreenOn(true)
        activity.setShowWhenLocked(true)
      }
    }
  }
}
