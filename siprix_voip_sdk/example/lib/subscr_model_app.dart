import 'package:siprix_voip_sdk/subscriptions_model.dart';


enum BLFState {trying, proceeding, early, terminated, confirmed, unknown}

////////////////////////////////////////////////////////////////////////////////////////
//AppBlfSubscrModel

class AppBlfSubscrModel extends SubscriptionModel {
  AppBlfSubscrModel(String ext, int accId) :
    super(toExt:ext, fromAccId:accId, mimeSubType:"dialog-info+xml", eventType:"dialog");

  AppBlfSubscrModel.fromJson(Map<String, dynamic> jsonMap) : super.fromJson(jsonMap);

  BLFState _blfState = BLFState.unknown;

  BLFState get blfState => _blfState;

  @override
  void onSubscrStateChanged(SubscriptionState s, String resp) {
    //Parse 'response' (contains XML body received in NOTIFY request)
    // and use parsed attributes for UI rendering
    int startIndex = resp.indexOf('<state');
    if(startIndex != -1) {
      startIndex = resp.indexOf('>', startIndex);
      int endIndex = resp.indexOf('</state>', startIndex);
      String blfStateStr = resp.substring(startIndex+1, endIndex);
      switch (blfStateStr) {
        case "trying"     : _blfState = BLFState.trying;     break;
        case "proceeding" : _blfState = BLFState.proceeding; break;
        case "early"      : _blfState = BLFState.early;      break;
        case "terminated" : _blfState = BLFState.terminated; break;
        case "confirmed"  : _blfState = BLFState.confirmed;  break;
        default:            _blfState = BLFState.unknown;
      }
    }

    state = s;
    response = resp;
    notifyListeners();
  }
}


SubscriptionModel createSubscrFromJson(Map<String, dynamic> jsonMap) {
  switch(jsonMap["runtimeType"]) {
    case "AppBlfSubscrModel": return AppBlfSubscrModel.fromJson(jsonMap);
    default:                  return SubscriptionModel.fromJson(jsonMap);
  }
}