import 'package:siprix_voip_sdk_platform_interface/siprix_voip_sdk_platform_interface.dart';

//////////////////////////////////////////////////////////////////////////////////////////
//SiprixVoipSdkIos implementation

class SiprixVoipSdkAndroid extends SiprixVoipSdkPlatform {
  static void registerWith() {
    SiprixVoipSdkPlatform.instance = SiprixVoipSdkAndroid();
  }  
}