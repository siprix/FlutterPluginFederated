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
