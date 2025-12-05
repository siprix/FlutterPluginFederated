@file:Suppress("SpellCheckingInspection")
package com.siprix.voip_sdk

import android.Manifest
import android.annotation.SuppressLint
import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Person
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Binder
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

import com.siprix.ISiprixRinger
import com.siprix.ISiprixServiceListener
import com.siprix.SiprixCore
import com.siprix.SiprixRinger


open class CallNotifService : Service() {
    private lateinit var _ringer: ISiprixRinger
    private lateinit var _appResources: LabelResources
    private lateinit var _eventsListener: CoreEventsListener
    private lateinit var _context: Context

    private var _actionReceiver: NotifActionReceiver? = null
    private var _wakeLock: PowerManager.WakeLock? = null
    private val _binder: IBinder = LocalBinder()

    private var _foregroundModeStarted: Boolean = false
    private var _requestCode: Int = 1
    private var _isBound: Boolean = false
    private var _pendingMsgs : MutableList<Bundle> = mutableListOf()

    inner class LocalBinder : Binder() {
        val service: CallNotifService
            get() =// Return this instance of LocalService so clients can call public methods.
                this@CallNotifService
    }

    fun isDetached() : Boolean {
        return this != _context
    }

    fun createInternal(context: Context) {
        Log.d(TAG, "createInternal")
        //Get core instance and set context (it can be service itself or externally provided)
        core = createSiprixCore(context)
        _context = context

        //Create and set event listener
        _eventsListener = CoreEventsListener(this)
        core?.setServiceListener(_eventsListener)

        //Get app resources
        _appResources = LabelResources(context)
        _ringer = SiprixRinger(context)

        createNotifChannel()
    }

    fun destroyInternal() {
        Log.d(TAG, "destroyInternal $core")
        stopForegroundMode()
        notifMgr.cancelAll()

        if(core != null) {
            core?.setServiceListener(null)
            core?.setModelListener(null)
            core?.unInitialize()
            core = null
        }

        if(_actionReceiver!=null)
            _context.unregisterReceiver(_actionReceiver)
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate")
        createInternal(this)
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "onDestroy")
        destroyInternal()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.d(TAG, "onTaskRemoved")
        super.onTaskRemoved(rootIntent)
    }

    override fun onBind(intent: Intent): IBinder? {
        _isBound = true
        return _binder
    }

    override fun onUnbind(intent: Intent?): Boolean {
        _isBound = false
        return super.onUnbind(intent) // Or return true if you want to allow rebind
    }

    fun pendingMsgs() : MutableList<Bundle> { return _pendingMsgs }



    private fun createNotifChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            //Create message channel
            val msgChannel = NotificationChannel(
                    kMsgChannelId, _appResources.appName, NotificationManager.IMPORTANCE_DEFAULT
            )
            msgChannel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            msgChannel.description = _appResources.msgChannelDescr
            notifMgr.createNotificationChannel(msgChannel)

            //Create call channel
            val callChannel = NotificationChannel(
                kCallChannelId, _appResources.appName, NotificationManager.IMPORTANCE_HIGH
            )
            callChannel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            callChannel.description = _appResources.callChannelDescr
            //callChannel.enableLights(true);
            notifMgr.createNotificationChannel(callChannel)
        }
    }

    protected fun getIntentActivity(action: String?, bundle: Bundle): PendingIntent {
        val activityIntent = _context.packageManager.getLaunchIntentForPackage(_context.packageName)
        if(activityIntent==null) {
            Log.e(TAG, "Can't get launch intent!")
        }
        activityIntent?.action = action

        activityIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        activityIntent?.putExtras(bundle)
        return PendingIntent.getActivity(
            _context, _requestCode++, activityIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    protected fun getIntentService(action: String?, bundle: Bundle): PendingIntent {
        if (_actionReceiver == null) {
            _actionReceiver = NotifActionReceiver(this)

            val filter = IntentFilter()
            filter.addAction(kActionIncomingCallReject)
            filter.addAction(kActionIncomingCallStopRinger)
            _context.registerReceiver(_actionReceiver, filter)
        }

        val rcvrIntent = Intent(action)
        rcvrIntent.putExtras(bundle)
        return PendingIntent.getBroadcast(
            _context, _requestCode++, rcvrIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun handleIncomingCallIntent(intent: Intent) {
        val callId = intent.extras?.getInt(kExtraCallId) ?: 0
        if (callId <= 0) return

        if (kActionIncomingCallReject == intent.action) {
            core!!.callReject(callId)
        }
        cancelNotification(callId)
    }

    protected fun cancelNotification(callId: Int) {
        notifMgr.cancel(getNotifId(callId))
    }

    protected val appResources: LabelResources
        get() = _appResources

    protected val notifMgr: NotificationManager
        get() = _context.getSystemService(NOTIFICATION_SERVICE) as NotificationManager

    protected fun getNotifId(callId: Int) : Int{
        return kCallBaseNotifId + callId
    }

    fun buildBundle(callId: Int, accId: Int,
                     withVideo: Boolean, hdrFrom: String?, hdrTo: String?) : Bundle{
        val bundle = Bundle()
        bundle.putInt(kExtraCallId, callId)
        bundle.putInt(kExtraAccId, accId)
        bundle.putBoolean(kExtraWithVideo, withVideo)
        bundle.putString(kExtraHdrFrom, hdrFrom)
        bundle.putString(kExtraHdrTo, hdrTo)
        return bundle
    }

    open fun shouldShowNotificationWhenInForeground(): Boolean = false

    open fun displayIncomingCallNotification(
        callId: Int, accId: Int,
        withVideo: Boolean, hdrFrom: String?, hdrTo: String?
    ) {
        Log.d(TAG, "displayIncomingCallNotif $callId")
        val bundle = buildBundle(callId, accId, withVideo, hdrFrom, hdrTo)

        val contentIntent = getIntentActivity(kActionIncomingCall, bundle)
        val pendingAcceptCall = getIntentActivity(kActionIncomingCallAccept, bundle)
        val pendingRejectCall = getIntentService(kActionIncomingCallReject, bundle)
        val contentStr = buildContentString(hdrFrom)

        if (Build.VERSION.SDK_INT >= 31) {
            val caller = Person.Builder().setName(contentStr).setImportant(true).build()
            val builder: Notification.Builder = Notification.Builder(_context, kCallChannelId)
                .setSmallIcon(_appResources.iconId)
                .setAutoCancel(true)
                .setContentIntent(contentIntent)
                .setFullScreenIntent(contentIntent, true)
                .setOngoing(true)
                .setCategory(NotificationCompat.CATEGORY_CALL)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .setStyle(Notification.CallStyle.forIncomingCall(caller, pendingRejectCall, pendingAcceptCall))

            notifMgr.notify(getNotifId(callId), builder.build())
        } else {
            val builder: NotificationCompat.Builder = NotificationCompat.Builder(_context, kCallChannelId)
                .setSmallIcon(_appResources.iconId)
                .setContentTitle(_appResources.contentLabel)
                .setContentText(contentStr)
                .setAutoCancel(true)
                .setDefaults(Notification.DEFAULT_ALL)
                .setContentIntent(contentIntent)
                .setFullScreenIntent(contentIntent, true)
                .setOngoing(true)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .addAction(0, _appResources.rejectBtnLabel, pendingRejectCall)
                .addAction(0, _appResources.acceptBtnLabel, pendingAcceptCall)
                .setDeleteIntent(getIntentService(kActionIncomingCallStopRinger, bundle))
                .setCategory(NotificationCompat.CATEGORY_CALL)

            notifMgr.notify(getNotifId(callId), builder.build())
        }
    }

    fun buildBundle(messageId: Int, accId: Int,
                    hdrFrom: String?, body: String?) : Bundle{
        val bundle = Bundle()
        bundle.putInt(kExtraMsgId, messageId)
        bundle.putInt(kExtraAccId, accId)
        bundle.putString(kExtraHdrFrom, hdrFrom)
        bundle.putString(kExtraBody, body)
        return bundle
    }

    open fun displayIncomingMsgNotification(
        messageId: Int, accId: Int,
        hdrFrom: String?, body: String?
    ) {
        Log.d(TAG, "displayIncomingMsgNotif $messageId")
        val bundle = buildBundle(messageId, accId, hdrFrom, body)

        val contentIntent = getIntentActivity(kActionIncomingMsg, bundle)

        val builder: NotificationCompat.Builder = NotificationCompat.Builder(_context, kMsgChannelId)
            .setSmallIcon(_appResources.iconId)
            .setContentTitle(_appResources.msgContentLabel)
            .setContentText(body)
            .setAutoCancel(true)
            .setDefaults(Notification.DEFAULT_ALL)
            .setContentIntent(contentIntent)
            .setFullScreenIntent(contentIntent, true)
            //.setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
        notifMgr.notify(getNotifId(messageId), builder.build())

        if(!_isBound) _pendingMsgs.add(bundle)
    }

    fun stopForegroundMode() {
        if(!_foregroundModeStarted) return

        releaseWakelock()
        if (Build.VERSION.SDK_INT >= 33) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        }else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        _foregroundModeStarted = false
    }

    fun startForegroundMode(): Boolean {
        if(_foregroundModeStarted) return true
        if(isDetached()) return false

        if (ContextCompat.checkSelfPermission(_context, Manifest.permission.FOREGROUND_SERVICE)
            != PackageManager.PERMISSION_GRANTED) return false

        acquireWakelock()

        val contentIntent = getIntentActivity(kActionForeground, Bundle())
        val builder: Notification.Builder = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(_context, kCallChannelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(_context)
        }

        builder.setSmallIcon(_appResources.iconId)
            .setContentTitle(_appResources.appName)
            .setContentText(_appResources.foregroundDescr)
            .setContentIntent(contentIntent)
            .build() // getNotification()

        if (Build.VERSION.SDK_INT >= 30) {
            startForeground(kForegroundId, builder.build(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            )
        } else {
            startForeground(kForegroundId, builder.build())
        }
        _foregroundModeStarted = true
        return true
    }

    fun isForegroundMode() :Boolean { return _foregroundModeStarted }

    private fun acquireWakelock() {
        if (ContextCompat.checkSelfPermission(_context, Manifest.permission.WAKE_LOCK)
            != PackageManager.PERMISSION_GRANTED) return

        if (_wakeLock == null) {
            val powerManager = _context.getSystemService(POWER_SERVICE) as PowerManager
            _wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Siprix:WakeLock.")
        }
        if (_wakeLock != null && !_wakeLock!!.isHeld) {
            _wakeLock!!.acquire()
        }
    }

    private fun releaseWakelock() {
        if (_wakeLock != null && _wakeLock!!.isHeld) {
            _wakeLock!!.release()
        }
    }

    //Handle 'Reject'/'StopRinger' action
    class NotifActionReceiver(service : CallNotifService) : BroadcastReceiver() {
        private val _service = service

        override fun onReceive(context: Context, intent: Intent?) {
            Log.d(TAG, "onReceive $intent")
            when(intent?.action) {
                kActionIncomingCallReject -> _service.handleIncomingCallIntent(intent)
                kActionIncomingCallStopRinger -> _service._ringer.stop()
            }
        }
    }

    //Handle core events
    class CoreEventsListener(service : CallNotifService) : ISiprixServiceListener {
        private val _service = service

        override fun onRingerState(start: Boolean) {
            try {
                if (start) _service._ringer.start()
                else       _service._ringer.stop()
            } catch (ex: Exception) {
                core?.moduleWriteLog("Ringer error: '${ex}")
            }
        }

        override fun onCallTerminated(callId: Int, statusCode: Int) {
            _service.cancelNotification(callId)
        }

        override fun onCallIncoming(
            callId: Int, accId: Int, withVideo: Boolean,
            hdrFrom: String, hdrTo: String
        ) {
            Log.i(TAG, "onCallIncoming $callId")
            if (_service.shouldShowNotificationWhenInForeground() || !_service.isAppInForeground()) {
                _service.displayIncomingCallNotification(callId, accId, withVideo, hdrFrom, hdrTo)
            }
        }

        override fun onMessageIncoming(messageId: Int, accId: Int,
                                       hdrFrom: String?, body: String?) {
            Log.i(TAG, "onMessageIncoming $messageId")
            if (_service.shouldShowNotificationWhenInForeground() || !_service.isAppInForeground()) {
                _service.displayIncomingMsgNotification(messageId, accId, hdrFrom, body)
            }
        }
    }

    private fun isAppInForeground(): Boolean {
        val am = _context.getSystemService(ACTIVITY_SERVICE) as ActivityManager
        val appProcs = am.runningAppProcesses
        for (app in appProcs) {
            if (app.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND) {
                val found = listOf(*app.pkgList).contains(_context.packageName)
                if (found) return true
            }
        }
        return false
    }

    protected fun parseDisplayName(hdrFrom: String?)  : String {
        if(hdrFrom == null) return "?"
        val startIndex = hdrFrom.indexOf("\"")
        val endIndex = if(startIndex == -1) -1 else hdrFrom.indexOf("\"", startIndex + 1)
        return if(endIndex==-1) "?" else hdrFrom.substring(startIndex+1, endIndex)
    }

    protected fun parseExt(hdrFrom: String?)  : String {
        if(hdrFrom == null) return "?"
        val startIndex = hdrFrom.indexOf(':')
        val endIndex = if(startIndex == -1) -1 else hdrFrom.indexOf("@", startIndex + 1)
        return if(endIndex==-1) "?" else hdrFrom.substring(startIndex+1, endIndex)
    }

    protected fun buildContentString(hdrFrom: String?) : String {
        //hdrFrom has format: "displName" <sip:ext@domain:port>
        if(hdrFrom==null) return "???"

        //Return string same as uses flutter app in 'CallModel.nameAndExt'
        val displName = parseDisplayName(hdrFrom)
        val sipExt = parseExt(hdrFrom)
        return if(displName.isEmpty()) sipExt else "$displName ($sipExt)"
    }

    class LabelResources (context: Context) {
        private val _context = context
        val appName: String
        val callChannelDescr: String
        val msgChannelDescr: String
        val foregroundDescr: String

        val msgContentLabel: String
        val contentLabel: String
        val rejectBtnLabel: String
        val acceptBtnLabel: String
        val iconId: Int

        init {
            appName = getStrResource("app_name") ?:
                        if(_context.applicationInfo!=null) _context.applicationInfo.loadLabel(_context.packageManager).toString()
                        else _context.packageName

            callChannelDescr = getStrResource(kResourceChannelDescrLabel)?: "Incoming calls notifications channel"
            msgChannelDescr = getStrResource(kResourceMsgChannelDescrLabel)?: "Messages notifications channel"
            foregroundDescr = getStrResource(kResourceForegroundDescrLabel)?: "Siprix call notification service"

            msgContentLabel = getStrResource(kResourceMsgContentLabel) ?: "Incoming message"
            contentLabel = getStrResource(kResourceContentLabel) ?: "Incoming call"
            rejectBtnLabel = getStrResource(kResourceRejectBtnLabel)?: "Reject call"
            acceptBtnLabel = getStrResource(kResourceAcceptBtnLabel)?: "Accept call"

            val res = getResource(kResourceNotifIcon, "drawable")
            iconId = if(res != 0) res else getResource("ic_launcher", "mipmap")
        }

        companion object {
            const val kResourceForegroundDescrLabel = "foreground_descr_label"
            const val kResourceChannelDescrLabel = "channel_descr_label"
            const val kResourceMsgChannelDescrLabel = "msg_channel_descr_label"
            const val kResourceRejectBtnLabel = "reject_btn_label"
            const val kResourceAcceptBtnLabel = "accept_btn_label"
            const val kResourceContentLabel = "content_label"
            const val kResourceMsgContentLabel = "msg_content_label"
            const val kResourceNotifIcon = "ic_notif_icon"
        }

        @SuppressLint("DiscouragedApi")
        private fun getStrResource(resName: String): String? {
            val stringRes = _context.resources.getIdentifier(resName, "string", _context.packageName)
            return if(stringRes != 0) _context.getString(stringRes) else null
        }

        @SuppressLint("DiscouragedApi")
        private fun getResource(resName: String, defType: String): Int {
            return _context.resources.getIdentifier(resName, defType, _context.packageName)
        }
    }

    companion object {
        private const val TAG = "CallNotifService"
        const val kCallChannelId = "kSiprixCallChannelId_"
        const val kMsgChannelId  = "kSiprixMsgChannelId_"

        const val kActionAppStarted = "kActionAppStarted"
        const val kActionForeground = "kActionForeground"
        
        const val kActionIncomingCall = "kActionIncomingCall"
        const val kActionIncomingCallAccept = "kActionIncomingCallAccept"
        const val kActionIncomingCallReject = "kActionIncomingCallReject"
        const val kActionIncomingCallStopRinger = "kActionIncomingCallStopRinger"
        const val kActionIncomingMsg = "kActionIncomingMsg"

        const val kExtraCallId   = "kExtraCallId"
        const val kExtraMsgId    = "kExtraMsgId"
        const val kExtraAccId    = "kExtraAccId"
        const val kExtraWithVideo= "kExtraWithVideo"
        const val kExtraHdrFrom  = "kExtraHdrFrom"
        const val kExtraHdrTo    = "kExtraHdrTo"
        const val kExtraBody     = "kExtraBody"

        const val kCallBaseNotifId = 555
        const val kForegroundId = 777

        //Single instance, provides access to calling functionality
        private var core: SiprixCore? = null

        @Synchronized
        fun createSiprixCore(appContext : Context): SiprixCore {
            if(core == null) {
                core = SiprixCore(appContext)
                Log.d(TAG, "createSiprixCore ${core}")
            }
            else Log.d(TAG, "createSiprixCore return existing ${core}")
            return core!!
        }
    }
}
