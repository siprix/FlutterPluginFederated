import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'siprix_voip_sdk.dart';


/// LogLevel enum. Using as value of 'IniData.logLevelFile' 'IniData.logLevelIde'
enum LogLevel {
  ///Most detailed log level
  stack(SiprixVoipSdk.kLogLevelStack, "Stack"),
  ///Detailed log level for regulr debugging
  debug(SiprixVoipSdk.kLogLevelDebug, "Debug"),
  ///Default log level
  info(SiprixVoipSdk.kLogLevelInfo, "Info"),
  ///Display warnings only
  warning(SiprixVoipSdk.kLogLevelWarning, "Warning"),
  ///Display errors only
  error(SiprixVoipSdk.kLogLevelError, "Error"),
  ///Don't display any logs
  none(SiprixVoipSdk.kLogLevelNone, "None");

  const LogLevel(this.id, this.name);
  /// Value
  final int id;
  /// User friendly name of the selected option
  final String name;
}


typedef LogUploadedCallback = void Function(bool success, String message);

/// Contains log string which can be displayed on UI. App can replace it with the own class or don't use
class LogsModel extends ChangeNotifier implements ILogsModel {
  String _logStr = "";
  final bool _uiLog;

  /// Cummulative log string
  String get logStr => _logStr;
  ///Callback triggered when received event 'onLogUploadStatus' from library
  LogUploadedCallback? onLogUploaded;

  LogsModel(this._uiLog) {
    SiprixVoipSdk().trialListener = TrialModeListener(
      notified : _onTrialModeNotified
    );

    SiprixVoipSdk().logUploadListener = LogUploadListener(
      uploaded: _onLogFileUploaded
    );
  }

  @override
  void print(String str) {
    debugPrint(str);

    if(_uiLog) {
      _logStr += DateFormat('HH:mm:ss ').format(DateTime.now());
      _logStr += str;
      _logStr += '\n';
      notifyListeners();
    }
  }

  /// Handle trial mode notification raised by library when license not set or wrong
  void _onTrialModeNotified() {
    print("--- SIPRIX SDK is working in TRIAL mode ---");
  }

  /// Handle notification raised by library when got log upload status
  void _onLogFileUploaded(bool success, String message) {
    onLogUploaded?.call(success, message);
  }
}
