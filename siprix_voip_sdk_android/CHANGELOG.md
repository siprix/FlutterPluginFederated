## 1.0.21
- Added new method 'UpgradeToVideo'
- Fixed handling case when call started with video on hold
- iOS/Android: Fixed handling device rotation on capturing video
- iOS/Android: Added new method 'SwitchCamera' 
  //2025.09.29

## 1.0.20
- Fixes related to 16K page size support
  //2025.09.20

## 1.0.19
- Fixed remote hold detection (when all media lines are sendonly or inactive)
- Modified handling 'sips' scheme (put 'sips' to Contact header)
- iOS: Added ability to activate audio session manually (when push notification not received)
- iOS: Modified internal video rendering implementation
- iOS: Fixed ability to use jpeg image instead of camera
- iOS: Added new method 'getCallKitCallUUID'
- Android: added ability to skip permissions request
- Added new method 'WriteLog', and integrated it in the iOS/Android flutter plugins
- Updated 'SiprixVideoRenderer::onResize' callback in Flutter wrapper;
- Modifed 'unInitialize' implementation in the Flutter plugins
  //2025.09.14

## 1.0.18
- Added G729 codec support
- Fixed handling connection candidates of inactive media lines
- Added fallback to first available H264 codec when baseline profile missed
  //2025.08.31

## 1.0.17
- Improved detection of the avialability IPv4/IPv6 interfaces
- Updated previous fix, which reduces delay on collecting candidates
- Added fix for H264 profile-level-id negotiation
  //2025.08.24

## 1.0.16
- Fixed crash on ios/macos when license string is empty
- Added fix which prevents long delay on collecting candidates when enabled STUN
- Added handler for case when connection can't be created because of wrong STUN/TURN address
- Added new option 'ini.transpForceIPv4'
  //2025.08.16

## 1.0.15
- Prevent potential crash on hold when call initiated as video/fixed handling Hold events
- Fixed bug which prevents adding multiple TLS transports
- Fixed TURN address resolution
- 'OnMessageIncoming' API update (added messageId arg)
- Added 16K page size support
- Added ability to display notification when message received
- Fixed bug with select audio device on tabled without earpice
  //2025.08.09

## 1.0.14
- Added new account properties 'stunServer','turnServer'
- Added new ini property 'VideoCallEnabled'
- Added new video data property 'Rotation'
- Fixed handling ACK/SDP response (missed 'onCallConnected' event)
- Fixed potential crash when received SIP MESSAGE without body
  //2025.07.31

## 1.0.13
- Added new method 'stopRingtone'
- Added new option 'listenVolChange'
  //2025.06.04

## 1.0.12
- Modified foreground service type (allows to access microphone Android 15 when app is in background)

## 1.0.11
- Fixed bug with find local account which matches received SIP request
- Added new option 'iceEnabled'
- Added ability to request 'USE_FULL_SCREEN_INTENT' permission, when it's declared in app's manifest

## 1.0.10
- Improved CallRecording (capture local+remote sound, use mp3 encoder, write mono or stereo)
- Added new ini properties 'recordStereo', 'useDnsSrv'
- Fixed bug which prevents stop foreground service after re-create Activity
- Fixed crash when library instance has been destroyed and re-initialized in the same process
- Fixed crash on create service and resolve app name

## 1.0.9
- Fixed bug with sending statusCode in the 'onTerminated' callback
- Added ability to switch calls automatically after call un-held, connected

## 1.0.8
- Added new ini property 'UnregOnDestroy'
- Set compileSdk version to 35
- Notifications:
  * Set notification style 'CallStyle.forIncomingCall' on devices with SDK_INT>=31
  * Added ability to set notification icon in app resources
  * Added ability to customize notification using own native class
- Permissions:
  * Request permission 'BLUETOOTH_CONNECT' in runtime, prevent crash when it missed
  * Request camera permission only when manifest contains it
- Fix vibrate in background

## 1.0.7
- Updated SiprixRinger implementation (don't set audioManager mode; modified vibraror)

## 1.0.6
- Added ability to send and receive text messages (SIP MESSAGE request)
- Added ability to override DisplayName in outgoing call (method 'Dest_SetDisplayName')
- Added ability to handle received MediaControlEvent 'picture_fast_update'
- Fixed bug in 'RewriteContactIp' option implementation when TCP/TLS transport is using
- Fixed parsing RTCP FB parameters of video in SDP
- Android: updated permissions request functionality
- Android: added ability to switch camera by invoke 'setVideoDevice(0)'

## 1.0.5
* Send call incoming/accepts events to the app only after sync accounts
  (happens when activity destroyed, but service continues running and received new call)

## 1.0.4
* Fixed potential crash when app switched between networks 

## 1.0.3
* Added ability to handle AirPlaneMode ON/OFF
* Fixes related to handle networks switching; 

## 1.0.2 * 
* Fixed handling case when app adds duplicate subscription.
* Now library raises error 'ESubscrAlreadyExist' and also returns existing subscrId

## 1.0.1
* Added new ini property 'brandName'
* Enabled ability to make attended transfer when call on hold

## 1.0.0
* Initial release. 
* Contains implementation based on method channels.
