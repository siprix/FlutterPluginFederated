import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';

//import 'package:firebase_core/firebase_core.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:siprix_voip_sdk/accounts_model.dart';
import 'package:siprix_voip_sdk/messages_model.dart';
import 'package:siprix_voip_sdk/network_model.dart';
import 'package:siprix_voip_sdk/cdrs_model.dart';
import 'package:siprix_voip_sdk/devices_model.dart';
import 'package:siprix_voip_sdk/logs_model.dart';
import 'package:siprix_voip_sdk/subscriptions_model.dart';
import 'package:siprix_voip_sdk/siprix_voip_sdk.dart';

import 'accouns_model_app.dart';
import 'calls_model_app.dart';
import 'subscr_model_app.dart';

import 'account_add.dart';
import 'call_add.dart';
import 'subscr_add.dart';
import 'settings.dart';
import 'home.dart';

//const FirebaseOptions gFCMOptions = FirebaseOptions(
//      apiKey: '...',            //Copy from `google-services.json` - `client.api_key.current_key`
//      appId: '...',             //Copy from `google-services.json` - `client.client_info.mobilesdk_app_id`
//      messagingSenderId: '...', //Copy from `google-services.json` - `project_info.project_number`
//      projectId: '...',         //Copy from `google-services.json` - `project_info.project_id`
//      storageBucket: '...'      //Copy from `google-services.json` - `project_info.storage_bucket`
//);

void main() async {
  //Wait while Firebase initialized
  //await _initializeFCM();

  //Create models
  LogsModel logsModel = LogsModel(true);//Set 'false' when logs won't rendering on UI
  CdrsModel cdrsModel = CdrsModel();//List of recent calls (Call Details Records)

  DevicesModel devicesModel = DevicesModel(logsModel);//List of devices
  NetworkModel networkModel = NetworkModel(logsModel);//Network state details
  AppAccountsModel accountsModel = AppAccountsModel(logsModel);//List of accounts
  MessagesModel messagesModel = MessagesModel(accountsModel, logsModel);
  AppCallsModel callsModel = AppCallsModel(accountsModel, logsModel, cdrsModel);//List of calls
  SubscriptionsModel subscrModel = SubscriptionsModel<AppBlfSubscrModel>(accountsModel, AppBlfSubscrModel.fromJson, logsModel);//List of subscriptions

  //Run app
  runApp(
    MultiProvider(providers:[
      ChangeNotifierProvider(create: (context) => accountsModel),
      ChangeNotifierProvider(create: (context) => networkModel),
      ChangeNotifierProvider(create: (context) => devicesModel),
      ChangeNotifierProvider(create: (context) => messagesModel),
      ChangeNotifierProvider(create: (context) => subscrModel),
      ChangeNotifierProvider(create: (context) => callsModel),
      ChangeNotifierProvider(create: (context) => cdrsModel),
      ChangeNotifierProvider(create: (context) => logsModel),
    ],
    child: const MyApp(),
  ));
}

/*
Future<void> _initializeFCM() async {
  if(Platform.isAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: gFCMOptions);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: gFCMOptions);

  //!!! Method is working in the background isolate!
  //!!! At this moment Activity may not exist or whole App could be completely stopped
  //!!! Code below initializes Siprix, adds saved accounts and refreshes registration (makes app ready to receive incoming call)

  debugPrint("[!!!] Handling a background message id:'${message.messageId}' data:'${message.data}'");

  try{
    debugPrint("Initialize siprix");
    _MyAppState._initializeSiprix();

    debugPrint("Read and add accounts");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String accJsonStr = prefs.getString('accounts') ?? '';
    if(accJsonStr.isNotEmpty) {
      AppAccountsModel tmpAccsModel = AppAccountsModel();
      await tmpAccsModel.loadFromJson(accJsonStr);
      tmpAccsModel.refreshRegistration();
    }
  } on Exception catch (err) {
      debugPrint('Error: ${err.toString()}');
  }
}
*/

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static String _ringtonePath="";

  @override
  State<MyApp> createState() => _MyAppState();

  /// Returns ringtone's path saved on device
  static String getRingtonePath() => _ringtonePath;

  /// Write ringtone file from asset to device
  void writeRingtoneAsset() async {
    _ringtonePath = await writeAssetAndGetFilePath("ringtone.mp3");
  }

  /// Write file from assest to device and returns path to it
  static Future<String> writeAssetAndGetFilePath(String assetsFileName) async {
    var homeFolder = await SiprixVoipSdk().homeFolder();
    var filePath = '$homeFolder$assetsFileName';

    var file = File(filePath);
    var exists = file.existsSync();
    debugPrint("writeAsset: '$filePath' exists:$exists");
    if (exists) return filePath;

    final byteData = await rootBundle.load('assets/$assetsFileName');
    await file.create(recursive: true);
    file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return filePath;
  }

  /// Returns path and file name for recorded file
  static Future<String> getRecFilePathName(int callId) async {
    String dateTime = DateFormat('yyyyMMdd_HHmmss_').format(DateTime.now());
    var homeFolder = await SiprixVoipSdk().homeFolder();
    var filePath = '$homeFolder$dateTime$callId.mp3';
    return filePath;
  }
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    _initializeSiprix(context.read<LogsModel>());
    widget.writeRingtoneAsset();//after initialize Siprix as uses its 'homeFolder'
    _readSavedState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: <String, WidgetBuilder>{
        CallAddPage.routeName: (BuildContext context) => const CallAddPage(true),
        SettingsPage.routeName: (BuildContext context) => const SettingsPage(),
        AccountPage.routeName: (BuildContext context) => const AccountPage(),
        SubscrAddPage.routeName: (BuildContext context) => const SubscrAddPage(),
      },
      home: const HomePage(),
      title: 'Siprix VoIP app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
    );
  }

  static void _initializeSiprix([LogsModel? logsModel]) async {
    debugPrint('_initializeSiprix');
    InitData iniData = InitData();
    iniData.license  = "...license-credentials...";
    iniData.logLevelFile = LogLevel.debug;
    iniData.logLevelIde = LogLevel.info;
    //- uncomment if required -//
    //iniData.singleCallMode = false;
    //iniData.tlsVerifyServer = false;
    //if(Platform.isIOS) {
    //  iniData.enableCallKit = true;
    //  iniData.enablePushKit = true; //Enable only when added PushNotif support on server side
    //  iniData.unregOnDestroy = false;
    //}
    //if(Platform.isAndroid) {
    //  iniData.listenTelState = true;
    //  iniData.listenVolChange = true;
    //  iniData.serviceClassName = "com.siprix.voip_sdk_example.MyNotifService";
    //}
    await SiprixVoipSdk().initialize(iniData, logsModel);

    //Set video params (if required)
    //VideoData vdoData = VideoData();
    //vdoData.noCameraImgPath = await MyApp.writeAssetAndGetFilePath("noCamera.jpg");
    //vdoData.bitrateKbps = 800;
    //SiprixVoipSdk().setVideoParams(vdoData);
  }

  void _readSavedState() {
    debugPrint('_readSavedState');
    SharedPreferences.getInstance().then((prefs) {
      String accJsonStr = prefs.getString('accounts') ?? '';
      String subsJsonStr = prefs.getString('subscriptions') ?? '';
      String cdrsJsonStr = prefs.getString('cdrs') ?? '';
      String msgsJsonStr = prefs.getString('msgs') ?? '';
      _loadModels(accJsonStr, cdrsJsonStr, subsJsonStr, msgsJsonStr);
    });
  }

  void _loadModels(String accJsonStr, String cdrsJsonStr,
                  String subsJsonStr, String msgsJsonStr) async {
    //Accounts
    AppAccountsModel accs = context.read<AppAccountsModel>();
    accs.onSaveChanges = _saveAccountChanges;

    //Subscriptions
    SubscriptionsModel subs = context.read<SubscriptionsModel>();
    subs.onSaveChanges = _saveSubscriptionChanges;

    MessagesModel msgs = context.read<MessagesModel>();
    msgs.onSaveChanges = _saveMessagesChanges;

    //CDRs (Call Details Records)
    CdrsModel cdrs = context.read<CdrsModel>();
    cdrs.onSaveChanges = _saveCdrsChanges;

    //Load messages, than accounts, then other models
    msgs.loadFromJson(msgsJsonStr);
    accs.loadFromJson(accJsonStr);
    subs.loadFromJson(subsJsonStr);
    cdrs.loadFromJson(cdrsJsonStr);

    //Assign contact name resolver
    context.read<AppCallsModel>().onResolveContactName = _resolveContactName;

    //Load devices
    context.read<DevicesModel>().load();
  }

  void _saveCdrsChanges(String cdrsJsonStr) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('cdrs', cdrsJsonStr);
    });
  }

  void _saveAccountChanges(String accountsJsonStr) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('accounts', accountsJsonStr);
    });
  }

  void _saveSubscriptionChanges(String subscrJsonStr) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('subscriptions', subscrJsonStr);
    });
  }

  void _saveMessagesChanges(String msgsJsonStr) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('msgs', msgsJsonStr);
    });
  }

  String _resolveContactName(String phoneNumber) {
    return ""; //TODO add own implementation
    //if(phoneNumber=="100") { return "MyFriend100"; } else
    //if(phoneNumber=="101") { return "MyFriend101"; }
    //else                  { return "";        }
  }
}




/*
//=======================================//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siprix_voip_sdk/accounts_model.dart';
import 'package:siprix_voip_sdk/calls_model.dart';
import 'package:siprix_voip_sdk/logs_model.dart';
import 'package:siprix_voip_sdk/siprix_voip_sdk.dart';

void main() async {
  AccountsModel accountsModel = AccountsModel();
  CallsModel callsModel = CallsModel(accountsModel);
  runApp(
    MultiProvider(providers:[
      ChangeNotifierProvider(create: (context) => accountsModel),
      ChangeNotifierProvider(create: (context) => callsModel),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeSiprix();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siprix VoIP app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(body:buildBody())
    );
  }

  Widget buildBody() {
    final accounts = context.watch<AppAccountsModel>();
    final calls = context.watch<AppCallsModel>();
    return Column(children: [
      ListView.separated(
        shrinkWrap: true,
        itemCount: accounts.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          AccountModel acc = accounts[index];
          return
            ListTile(title: Text(acc.uri, style: Theme.of(context).textTheme.titleSmall),
                subtitle: Text(acc.regText),
                tileColor: Colors.blue
            );
        },
      ),
      ElevatedButton(onPressed: _addAccount, child: const Icon(Icons.add_card)),
      const Divider(height: 1),
      ListView.separated(
        shrinkWrap: true,
        itemCount: calls.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          CallModel call = calls[index];
          return
            ListTile(title: Text(call.nameAndExt, style: Theme.of(context).textTheme.titleSmall),
              subtitle: Text(call.state.name), tileColor: Colors.amber,
              trailing: IconButton(
                onPressed: (){ call.bye(); },
                icon: const Icon(Icons.call_end))
            );
        },
      ),
      ElevatedButton(onPressed: _addCall, child: const Icon(Icons.add_call)),
      const Spacer(),
    ]);
  }

  void _initializeSiprix([LogsModel? logsModel]) async {
    InitData iniData = InitData();
    iniData.license  = "...license-credentials...";
    iniData.logLevelFile = LogLevel.info;
    SiprixVoipSdk().initialize(iniData, logsModel);
  }

  void _addAccount() {
    AccountModel account = AccountModel();
    account.sipServer = "192.168.0.122";
    account.sipExtension = "1016";
    account.sipPassword = "12345";
    account.expireTime = 300;
    context.read<AppAccountsModel>().addAccount(account)
      .catchError(showSnackBar);
  }

  void _addCall() {
    final accounts = context.read<AppAccountsModel>();
    if(accounts.selAccountId==null) return;

    CallDestination dest = CallDestination("1012", accounts.selAccountId!, false);

    context.read<AppCallsModel>().invite(dest)
      .catchError(showSnackBar);
  }

  void showSnackBar(dynamic err) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }
}
*/
