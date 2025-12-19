// ignore_for_file: non_constant_identifier_names

import 'package:siprix_voip_sdk_platform_interface/siprix_voip_sdk_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'siprix_voip_sdk.dart';


/// Holds properties of SIP subscription item
class SubscriptionModel extends ChangeNotifier implements ISiprixData {
  SubscriptionModel({required this.toExt, required this.fromAccId,
                    required this.mimeSubType, required this.eventType, this.body});
  ///Unique id assigned by library (valid only during current session)
  int mySubscrId=0;
  ///Remote extension, which will notify us when its state changed
  String toExt="";
  ///Account id using for sending subscribe request
  int    fromAccId=0;
  ///Account URI used serialize as the 'fromAccId' valid only during current session and may got new value
  String accUri="";
  ///MimeSubType which library will put in the SIP header 'Accept'
  String mimeSubType="";
  ///Event type which library will put in the SIP header 'Event'
  String eventType="";
  ///String which library will put into the SIP request
  String? body;
  ///Label using for display this subscription on UI
  String label="";
  ///Expire time in seconds (how often library will update this subscription)
  int? expireTime;

  ///State of the subscription dialog
  SubscriptionState state = SubscriptionState.created;
  ///Response received from remote side in the body of SIP NOTIFY request
  String response="";

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {
      'extension': toExt,
      'label'    : label,
      'accId'    : fromAccId,
      'accUri'   : accUri,
      'mimeSubType': mimeSubType,
      'eventType': eventType,
      'runtimeType':runtimeType.toString()
    };
    if(expireTime !=null)  ret['expireTime']  = expireTime;
    if(body       !=null)  ret['body'] = body;
    return ret;
  }

  /// Creates instance of SubscriptionModel with values read from json
  SubscriptionModel.fromJson(Map<String, dynamic> jsonMap) {
    jsonMap.forEach((key, value) {
      if((key == 'extension')&&(value is String))   { toExt = value;       } else
      if((key == 'label')&&(value is String))       { label = value;       } else
      if((key == 'accId')&&(value is int))          { fromAccId = value;   } else
      if((key == 'accUri')&&(value is String))      { accUri = value;      } else
      if((key == 'mimeSubType')&&(value is String)) { mimeSubType = value; } else
      if((key == 'body')&&(value is String))        { body = value;        } else
      if((key == 'eventType')&&(value is String))   { eventType = value;   } else
      if((key == 'expireTime')&&(value is int))     { expireTime = value;  }
    });
  }

  ///Create BLF subscription
  factory SubscriptionModel.BLF(String ext, int accId) {
    return SubscriptionModel(toExt:ext, fromAccId:accId,
                            mimeSubType:"dialog-info+xml", eventType:"dialog");
  }

  ///Create Presence subscription
  factory SubscriptionModel.Presence(String ext, int accId) {
    return SubscriptionModel(toExt:ext, fromAccId:accId,
                            mimeSubType:"pidf+xml", eventType:"presence");
  }

  ///Handle event raised by library (override on app level)
  void onSubscrStateChanged(SubscriptionState s, String resp) {
    response = resp;
    state = s;
  }
}


///Subscription state - using as member of SubscriptionModel
enum SubscriptionState { created, updated, destroyed}

/// Model invokes this callback when has changes which should be saved by the app
typedef SaveChangesCallback = void Function(String jsonStr);


/// Subscriptions list model ((contains list of subscriptions, methods for managing them, handlers of library event)
class SubscriptionsModel extends ChangeNotifier {
  final SubscriptionModel Function(Map<String, dynamic>) _itemCreateFunc;
  final List<SubscriptionModel> _subscriptions = [];
  final IAccountsModel _accountsModel;
  final ILogsModel? _logs;

  SubscriptionsModel(this._accountsModel, this._itemCreateFunc, [this._logs]) {
    SiprixVoipSdk().subscrListener = SubscrStateListener(
      subscrStateChanged : onSubscrStateChanged
    );
  }

  /// Returns true when list of subscriptions is empty
  bool get isEmpty => _subscriptions.isEmpty;
  /// Returns number of subscriptions in list
  int get length => _subscriptions.length;
  /// Returns subscription by its index in list
  SubscriptionModel operator [](int i) => _subscriptions[i];

  /// Callback which model invokes when subscriptions changes should be saved
  SaveChangesCallback? onSaveChanges;

  ///Add new subscription
  Future<void> addSubscription(SubscriptionModel sub, {bool saveChanges=true}) async {
    _logs?.print('Adding new subscription ext:${sub.toExt} accId:${sub.fromAccId}');

    try {
      //When accUri present - model loaded from json, search accId as it might be changed
      if(sub.accUri.isNotEmpty) { sub.fromAccId = _accountsModel.getAccId(sub.accUri);  }
      else                      { sub.accUri    = _accountsModel.getUri(sub.fromAccId); }

      //Add
      sub.mySubscrId  = await SiprixVoipSdk().addSubscription(sub) ?? 0;

      _integrateAddedSubscription(sub, saveChanges);

    } on PlatformException catch (err) {
      if(err.code == SiprixVoipSdk.eSubscrAlreadyExist.toString()) {
        int existingSubscrId = err.details;
        int idx = _subscriptions.indexWhere((s) => (s.mySubscrId == existingSubscrId));
        if(idx==-1) {
          //This case is possible in Android when:
          // - activity started as usual and initialized SDK Core
          // - activity destroyed, but SDK Core is still running (as Service)
          // - activity started again, loaded saved state and has to sync it
          sub.mySubscrId = existingSubscrId;
          _integrateAddedSubscription(sub, saveChanges);
        }
      }
      else {
        _logs?.print('Can\'t add subscription: ${err.code} ${err.message} ');
        return Future.error((err.message==null) ? err.code : err.message!);
      }
    } on Exception catch (err) {
         _logs?.print('Can\'t add subscription: ${err.toString()}');
        return Future.error(err.toString());
    }
  }

  void _integrateAddedSubscription(SubscriptionModel sub, bool saveChanges) {
    _subscriptions.add(sub);

    notifyListeners();

    _logs?.print('Added successfully with id: ${sub.mySubscrId}');
    if(saveChanges) _raiseSaveChanges();
  }

  ///Delete subscription by index (sends SUBSCRIBE request with expire=0)
  Future<void> deleteSubscription(int index) async {
    try {
      int subscrId = _subscriptions[index].mySubscrId;
      await SiprixVoipSdk().deleteSubscription(subscrId);

      _subscriptions.removeAt(index);

      notifyListeners();
      _raiseSaveChanges();
      _logs?.print('Deleted subscription subscrId:$subscrId');

    } on PlatformException catch (err) {
      _logs?.print('Can\'t delete subscription: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  ///Handle library event raised when received NOTIFY request
  void onSubscrStateChanged(int subscrId, SubscriptionState s, String resp) {
    _logs?.print('onSubscrStateChanged subscrId:$subscrId resp:$resp ${s.toString()}');
    int idx = _subscriptions.indexWhere((sub) => (sub.mySubscrId == subscrId));
    if(idx != -1) {
      _subscriptions[idx].onSubscrStateChanged(s, resp);
    }
  }

  void _raiseSaveChanges() {
    if(onSaveChanges != null) {
      Future.delayed(Duration.zero, () {
        onSaveChanges?.call(storeToJson());
      });
    }
  }

  /// Store list of subscriptions to json string
  String storeToJson() {
    return jsonEncode(_subscriptions);
  }

  /// Load list of subscriptions from json string (app should invoke it after loading accounts)
  bool loadFromJson(String jsonStr) {
    try {
      if(jsonStr.isEmpty) return false;

      final List<dynamic> parsedList = jsonDecode(jsonStr);
      for (var parsedSubscr in parsedList) {
        addSubscription(_itemCreateFunc(parsedSubscr), saveChanges:false);
      }
      return parsedList.isNotEmpty;
    }catch (e) {
      _logs?.print('Can\'t load subscriptions from json. Err: $e');
      return false;
    }
  }

}//SubscriptionsModel

