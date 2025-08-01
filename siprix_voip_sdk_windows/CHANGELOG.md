## 1.0.10
- Added new account properties 'stunServer','turnServer'
- Added new ini property 'VideoCallEnabled'
- Added new video data property 'Rotation'
- Fixed handling ACK/SDP response (missed 'onCallConnected' event)
- Fixed potential crash when received SIP MESSAGE without body
  //2025.07.31

## 1.0.9
- Added new method 'stopRingtone'
- Fixed build error, caused by previous update
  //2025.06.04

## 1.0.8
- Windows: Fixed plugin build error, caused by last update

## 1.0.7
- Fixed bug with find local account which matches received SIP request
- Added new option 'iceEnabled'
- Windows: Fixed bug with detecting is IPv4 available

## 1.0.6
- Improved CallRecording (capture local+remote sound, use mp3 encoder, write mono or stereo)
- Added new ini properties 'recordStereo', 'useDnsSrv'

## 1.0.5
- Fixed bug with sending statusCode in the 'onTerminated' callback
- Added ability to switch calls automatically after call un-held, connected

## 1.0.4
- Added new ini property 'UnregOnDestroy'

## 1.0.3
- Added ability to send and receive text messages (SIP MESSAGE request)
- Added ability to override DisplayName in outgoing call (method 'Dest_SetDisplayName')
- Added ability to handle received MediaControlEvent 'picture_fast_update'
- Fixed bug in 'RewriteContactIp' option implementation when TCP/TLS transport is using
- Fixed parsing RTCP FB parameters of video in SDP

## 1.0.2 * 
* Fixed handling case when app adds duplicate subscription.
* Now library raises error 'ESubscrAlreadyExist' and also returns existing subscrId

## 1.0.1
* Added new ini property 'brandName'
* Enabled ability to make attended transfer when call on hold

## 1.0.0

* Initial release. 
* Contains implementation based on method channels.
