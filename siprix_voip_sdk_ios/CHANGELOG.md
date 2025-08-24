## 1.0.21
- Improved detection of the avialability IPv4/IPv6 interfaces
- Updated previous fix, which reduces delay on collecting candidates
- Added fix for H264 profile-level-id negotiation
  //2025.08.24

## 1.0.20
- Fixed crash on ios/macos when license string is empty
- Added fix which prevents long delay on collecting candidates when enabled STUN
- Added handler for case when connection can't be created because of wrong STUN/TURN address
- iOS: Added ability to toggle front/back camera
- Added new option 'ini.transpForceIPv4'
  //2025.08.16

## 1.0.19
- Prevent potential crash on hold when call initiated as video/fixed handling Hold events
- Fixed bug which prevents adding multiple TLS transports
- Fixed TURN address resolution
- 'OnMessageIncoming' API update (added messageId arg)
  //2025.08.09

## 1.0.18
- Added new account properties 'stunServer','turnServer'
- Added new ini property 'VideoCallEnabled'
- Added new video data property 'Rotation'
- iOS: Fixed conflict class names preventing upload to AppStore
- Fixed handling ACK/SDP response (missed 'onCallConnected' event)
- Fixed potential crash when received SIP MESSAGE without body
  //2025.07.31

## 1.0.17
- Fixed sound issue when received incoming call in terminated state
  //2025.06.04

## 1.0.16
- Fixed bug with find local account which matches received SIP request
- Added new option 'iceEnabled'

## 1.0.15
- Improved CallRecording (capture local+remote sound, use mp3 encoder, write mono or stereo)
- Added new ini properties 'recordStereo', 'useDnsSrv'

## 1.0.14
- Fixed bug with sending statusCode in the 'onTerminated' callback
- Added ability to switch calls automatically after call un-held, connected
- Fixed switching between calls and join calls to conference when enabled CallKit

## 1.0.13
- Added new ini property 'UnregOnDestroy'
- Send events from library to the app using UI thread

## 1.0.12
- iOS: Redesigned and improved CallKit+PushKit implementation

## 1.0.11
- Added ability to send and receive text messages (SIP MESSAGE request)
- Added ability to override DisplayName in outgoing call (method 'Dest_SetDisplayName')
- Added ability to handle received MediaControlEvent 'picture_fast_update'
- Fixed bug in 'RewriteContactIp' option implementation when TCP/TLS transport is using
- Fixed parsing RTCP FB parameters of video in SDP
- iOS: Added PushKit support

## 1.0.10
* Fixed closing app caused by SIGPIPE signal

## 1.0.9
* Updated TLS transport implementation (use TLS1.3 by default, ability to use also 1.2 and 1.0)
* Improved ability to detect lost/switched network connections and automatically restore registration
* Added more detailed log output for some cases

## 1.0.8
* Fixed potential crash when app switched between networks and updates registration 

## 1.0.7
* Few more fixes related to handle networks switching and restore registration when app becomes active; 
* Don't unregister account(s) when app stopped by swiping out

## 1.0.6
* Fixed crash when app restored from background

## 1.0.5
* Added ability to re-create transports when app become active after long time in background

## 1.0.4
* Added CallKit support to iOS (library automatically manages it)
* Fixed logs flooding with UDP transport error

## 1.0.3
* Added MinimumOSVersion in plist

## 1.0.2
* Fixed handling case when app adds duplicate subscription.
* Now library raises error 'ESubscrAlreadyExist' and also returns existing subscrId

## 1.0.1
* Fixed podspec file for ios/macos
* Added new ini property 'brandName'
* Enabled ability to make attended transfer when call on hold

## 1.0.0
* Initial release. 
* Contains implementation based on method channels.
