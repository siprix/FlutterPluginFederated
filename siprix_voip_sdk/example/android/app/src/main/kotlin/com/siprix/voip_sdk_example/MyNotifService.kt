package com.siprix.voip_sdk_example

import android.app.Notification
import android.util.Log
import androidx.core.app.NotificationCompat
import com.siprix.voip_sdk.CallNotifService

//MyNotifService - allows to customize local notifications displayed when received incoming call
class MyNotifService : CallNotifService() {
    private var TAG = "MyNotifService"

    override  fun displayIncomingCallNotification(callId: Int, accId: Int,
        withVideo: Boolean, hdrFrom: String?, hdrTo: String?
    ) {
        Log.d(TAG, "displayIncomingCallNotification $callId")
        //!!! Don't modify bundle and intents
        val bundle = buildCallBundle(callId, accId, withVideo, hdrFrom, hdrTo)
        val contentIntent = getIntentActivity(kActionIncomingCall, bundle)

        //Modify notification and displayed text as it's required by the app
        //val displayName = parseDisplayName(hdrFrom)
        //val sipExt = parseExt(hdrFrom)
        val contentStr = buildContentString(hdrFrom)//if required format own string here using parsed 'displayName' and 'sipExt'
        val builder: NotificationCompat.Builder = NotificationCompat.Builder(this, kCallIncomingChannelId)
            .setSmallIcon(appResources.iconId)
            .setContentText(contentStr)
            .setAutoCancel(true)
            .setDefaults(Notification.DEFAULT_ALL)
            .setContentIntent(contentIntent)
            .setFullScreenIntent(contentIntent, true)
            .setOngoing(true)
            .setDeleteIntent(getIntentService(kActionIncomingCallStopRinger, bundle))
            .setCategory(NotificationCompat.CATEGORY_CALL)

        //!!! Use 'callId' as notification id
        notifMgr.notify(callId, builder.build())
    }
}