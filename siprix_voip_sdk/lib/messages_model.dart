import 'package:intl/intl.dart';
import 'package:siprix_voip_sdk_platform_interface/siprix_voip_sdk_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'siprix_voip_sdk.dart';


/// Message destination -  contains lists of parameters for sending message
class MessageDestination implements ISiprixData {
  MessageDestination(this.toExt, this.fromAccId, this.body, {this.contentType});
  /// Extension (phone number) where to send message
  final String toExt;
  /// Id of the account which should send INVITE request
  final int    fromAccId;
  /// Set display name in the SIP header From (overrides value set in the account specified by 'fromAccId')
  final String body;
  /// Put this value into header ContentType
  final String? contentType;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {
      'extension': toExt,
      'accId'    : fromAccId,
      'body'     : body,
    };
    if(contentType!=null) ret['contentType'] = contentType;
    return ret;
  }
}


/// Holds properties of sent/received SIP message item
class MessageModel extends ChangeNotifier {
  MessageModel.outgoing(int id, String accUri, MessageDestination dest)
    : _myMessageId=id, _isIncoming=false, _ext=dest.toExt, _accUri=accUri, _body=dest.body;

  MessageModel.incoming(String accUri, String fromExt, String body)
    : _myMessageId=0, _isIncoming = true, _ext=fromExt, _accUri=accUri, _body=body;

  static final _fmt = DateFormat('MMM dd, HH:mm a');

  ///Unique id assigned by library (allows get message sent status)
  int _myMessageId=0;
  ///Is this message received from remote side or sent by local side
  bool _isIncoming=false;
  ///Extension from which received (to which sent) this message
  String _ext="";
  ///Account URI using to send/receive this message
  String _accUri="";
  ///Message body
  String _body="";

  ///State of the subscription dialog
  bool _sentSuccess = true;
  ///Response received from remote side in the body of SIP NOTIFY request
  String _response="";

  ///Timestamp when this message sent/received
  DateTime _timestamp = DateTime.now();

  //Getters
  ///Is this message received from remote side or sent by local side
  bool get isIncoming => _isIncoming;
  bool get sentSuccess => _sentSuccess;
  int get myMessageId => _myMessageId;
  String get response => _response;
  String get body => _body;
  String get accUri => _accUri;
  String get ext => _ext;

  /// Formatted string with date/time when message has been sent/received
  String get timestamp => _fmt.format(_timestamp);

  /// Get extension to reply this message
  String getReplyExt() {
    String replyExt = _ext;
    final int startIndex = replyExt.indexOf(':');
    if(startIndex == -1) return replyExt;

    final int endIndex = replyExt.indexOf('>', startIndex + 1);
    return (endIndex == -1) ? replyExt : replyExt.substring(startIndex+1, endIndex);
  }

  /// Converts instance to json
  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {
      'isIncoming': _isIncoming,
      'extension': _ext,
      'accUri'   : _accUri,
      'body'     : _body,
      'ts'       : _timestamp.millisecondsSinceEpoch,
    };
    return ret;
  }

  /// Creates instance of SubscriptionModel with values read from json
  MessageModel.fromJson(Map<String, dynamic> jsonMap) {
    jsonMap.forEach((key, value) {
      if((key == 'isIncoming')&&(value is bool))  { _isIncoming = value; } else
      if((key == 'extension')&&(value is String)) { _ext = value;    } else
      if((key == 'accUri')&&(value is String))    { _accUri = value; } else
      if((key == 'body')&&(value is String))      { _body = value;   } else
      if((key == 'ts')&&(value is int))  {
         _timestamp = DateTime.fromMillisecondsSinceEpoch(value);
      }
    });
  }

  ///Handle event raised by library (override on app level)
  void onMessageSentStateChanged(bool success, String resp) {
    _response = resp;
    _sentSuccess = success;
    notifyListeners();
  }
}


/// Model invokes this callback when has changes which should be saved by the app
typedef SaveChangesCallback = void Function(String jsonStr);


/// Subscriptions list model (contains list of subscriptions, methods for managing them, handlers of library event)
class MessagesModel extends ChangeNotifier {
  final List<MessageModel> _messages = [];
  final IAccountsModel _accountsModel;
  final ILogsModel? _logs;
  final int maxItems;

  MessagesModel(this._accountsModel, [this._logs, this.maxItems=25]) {
    SiprixVoipSdk().messagesListener = MessagesStateListener(
      sentState: onMessageSentState,
      incoming : onMessageIncoming
    );
  }

  /// Returns true when list of messages is empty
  bool get isEmpty => _messages.isEmpty;
  /// Returns number of messages in list
  int get length => _messages.length;
  /// Returns subscription by its index in list
  MessageModel operator [](int i) => _messages[i];

  /// Callback which model invokes when messages changes should be saved
  SaveChangesCallback? onSaveChanges;

  ///Send message
  Future<void> send(MessageDestination msgDest, {bool saveChanges=true}) async {
    _logs?.print('Sending new message ext:${msgDest.toExt} accId:${msgDest.fromAccId}');

    try {
      //When accUri present - model loaded from json, search accId as it might be changed
      String accUri = _accountsModel.getUri(msgDest.fromAccId);

      //Send and get assigned id
      int myMessageId = await SiprixVoipSdk().sendMessage(msgDest) ?? 0;

      //Add to the list and notify UI
      _messages.add(MessageModel.outgoing(myMessageId, accUri, msgDest));
      if(_messages.length > maxItems)  _messages.removeAt(0);
      notifyListeners();

      //Log and save changes
      _logs?.print('Message post successfully with id: $myMessageId');
      if(saveChanges) _raiseSaveChanges();

    } on PlatformException catch (err) {
        _logs?.print('Can\'t send message: ${err.code} ${err.message} ');
        return Future.error((err.message==null) ? err.code : err.message!);
    }
  }


  ///Delete message by index
  Future<void> remove(int index) async {
      _messages.removeAt(index);
      notifyListeners();
      _raiseSaveChanges();
  }

  ///Handle library event raised when received confirmation on sent message
  void onMessageSentState(int messageId, bool success, String resp) {
    _logs?.print('onMessageSentState $success messageId:$messageId resp:$resp');
    int idx = _messages.indexWhere((msg) => (msg.myMessageId == messageId));
    if(idx != -1) {
      _messages[idx].onMessageSentStateChanged(success, resp);
    }
  }

  ///Handle library event raised when received new message from remote side
  void onMessageIncoming(int messageId, int accId, String from, String body) {
    _logs?.print('onMessageIncoming messageId:$messageId accId:$accId from:$from');

    int idx = _messages.indexWhere((msg) => (msg.myMessageId == messageId));
    if(idx != -1) {
      _logs?.print('message with id:$messageId already exist');
      return;
    }

    String accUri = _accountsModel.getUri(accId);
    MessageModel newMsg = MessageModel.incoming(accUri, from, body);
    _messages.add(newMsg);

    notifyListeners();

    if(_messages.length > maxItems)  _messages.removeAt(0);
    _raiseSaveChanges();
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
    return jsonEncode(_messages);
  }

  /// Load list of subscriptions from json string (app should invoke it after loading accounts)
  bool loadFromJson(String jsonStr) {
    try {
      if(jsonStr.isEmpty) return false;

      final List<dynamic> parsedList = jsonDecode(jsonStr);
      for (var parsedMsg in parsedList) {
        _messages.add(MessageModel.fromJson(parsedMsg));
      }
      return parsedList.isNotEmpty;
    }catch (e) {
      _logs?.print('Can\'t load messages from json. Err: $e');
      return false;
    }
  }

}//MessagesModel

