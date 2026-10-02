import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
//import 'dart:io' show Platform;

import 'package:siprix_voip_sdk/network_model.dart';
import 'package:siprix_voip_sdk/logs_model.dart';
import 'package:siprix_voip_sdk/siprix_voip_sdk.dart';

import 'calls_model_app.dart';
import 'messages.dart';
import 'subscr_list.dart';
import 'accounts_list.dart';
import 'settings.dart';
import 'calls_list.dart';

////////////////////////////////////////////////////////////////////////////////////////
//HomePage

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static const routeName = "/home";

   @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _pageController = PageController();
  int _selectedPageIndex = 0;

  @override
  void initState() {
    super.initState();
    //Switch tab when incoming call received
    context.read<AppCallsModel>().onNewIncomingCall = (){ if(_selectedPageIndex != 1) _onTabTapped(1); };
  }

  @override
  Widget build(BuildContext context) {
    return
      Scaffold(
        appBar: AppBar(backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
          titleSpacing: 0,
          title: ListTile(
            title:Text('Siprix VoIP SDK', style: Theme.of(context).textTheme.headlineSmall, overflow: TextOverflow.ellipsis),
            subtitle: Text('www.siprix-voip.com', style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
          ),
          actions: [
            Padding(padding: const EdgeInsets.only(right: 20),
              child:IconButton(icon: const Icon(Icons.settings), onPressed:_onShowSettings)),
          ]
        ),
        body: PageView(controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            AccountsListPage(),
            CallsListPage(),
            SubscrListPage(),
            MessagesListPage(),
            LogsPage()
          ]),
        bottomSheet: _networkLostIndicator(),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(icon: Icon(Icons.widgets), label: 'Accounts'),
                  BottomNavigationBarItem(icon: _callsTabIcon(), label: 'Calls'),
            const BottomNavigationBarItem(icon: Icon(Icons.hub), label: 'BLF'),
            const BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
            const BottomNavigationBarItem(icon: Icon(Icons.text_snippet), label: 'Logs'),
          ],
          currentIndex: _selectedPageIndex,
          type: BottomNavigationBarType.fixed,
          onTap: _onTabTapped,
        )
     );
  }

  Widget _callsTabIcon() {
    final calls = context.watch<AppCallsModel>();
    const icon = Icon(Icons.phone_in_talk);
    return calls.isEmpty ? icon : Badge(label: Text('${calls.length}'), child:icon);
  }

  Widget? _networkLostIndicator() {
    if(context.watch<NetworkModel>().networkLost) {
      return Container(color: Colors.red,
          child: const Text("Internet connection lost",
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center)
        );
    }
    return null;
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedPageIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  void _onShowSettings() {
    Navigator.of(context).pushNamed(SettingsPage.routeName);
  }
}

////////////////////////////////////////////////////////////////////////////////////////
//LogsPage - represents diagnostic messages

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(5.0),
      child: Stack(children:[
        Consumer<LogsModel>(
          builder: (context, logsModel, child) {
            return SelectableText(logsModel.logStr, style: Theme.of(context).textTheme.bodySmall);
          }
        ),
        Positioned(right: 0, child:
          OutlinedButton(onPressed: () { LogUploadDialog.show(context); },
            child: const Icon(Icons.upload_file),
          )
        )
      ])
    );
  }
}


////////////////////////////////////////////////////////////////////////////////////////
//LogUploadDialog - popup control with status

class LogUploadDialog extends StatefulWidget {
  const LogUploadDialog({super.key});

  static const String _kRouteName = "/LogUploadDialogRoute";
  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      routeSettings: RouteSettings(name: _kRouteName),
      builder: (BuildContext context) {
        return LogUploadDialog();
      },
    );
  }

  @override
  State<LogUploadDialog> createState() => _LogUploadDialogState();
}

class _LogUploadDialogState extends State<LogUploadDialog> {
  static const double kSpacing=8;
  final _controller = TextEditingController();
  bool _isSubmittingTooLong=false;
  bool _isSubmitting=false;
  String? _responseDescription;
  bool? _responseSuccess;

  @override
  void initState() {
    super.initState();
    context.read<LogsModel>().onLogUploaded = (bool success, String response) {
      _responseDescription = response;
      _responseSuccess = success;
      debugPrint("onLogUploaded: ${success ? "success" : "failed"} ${response}");
      setState(() { _isSubmitting = false; });
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return
      AlertDialog(
        title: _buildTitle(),
        titlePadding: EdgeInsets.all(10),
        contentPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        content: _buildContent(),
        actions: _buildActions(),
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 10, 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      );
  }

  Widget _buildTitle() {
    return Row(children:[
      Text("Upload log file for review", style: Theme.of(context).textTheme.titleMedium),
      Spacer(),
      Icon(Icons.upload_file),
    ]);
  }

  Widget _buildContent() {
    return
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Please describe what went wrong and what you expected to happen (at least 40 characters)"),
        const SizedBox(height: kSpacing),
        TextField(
          minLines: 3,
          maxLines: 8,
          controller: _controller,
          enabled: !_isSubmitting && (_responseSuccess==null),
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            contentPadding: const EdgeInsets.all(4),
            hintText: '...',
            border: OutlineInputBorder(),
          ),
        ),

        _buildResponse(),

        if(_isSubmitting)
          Align(alignment: Alignment.center, child:
            CircularProgressIndicator(strokeWidth: 4),
          )
      ]);
  }

  List<Widget> _buildActions() {
    return [
      TextButton(onPressed: _isSubmitting && !_isSubmittingTooLong  ? null : _closeDialog,
                    child: Text((_responseSuccess != null) ? 'Close' : 'Cancel')),

      ValueListenableBuilder<TextEditingValue>(valueListenable: _controller,
        builder: (context, value, child) { return
          FilledButton.icon(onPressed: (_controller.text.length < 40)||(_responseSuccess != null)||_isSubmitting ? null : _submit,
            label: const Text('Submit'),
          );
        },
      )
    ];
  }

  Widget _buildResponse() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: kSpacing),
        if(_responseSuccess==true) ...[
          Text("Log file successfully uploaded.", style: TextStyle(fontWeight: FontWeight.w600)),
          Text("Assigned id: ${_responseDescription!}"),
          IconButton(onPressed: _onCopyResult, icon: Icon(Icons.copy), iconSize: 18)
        ] else if(_responseSuccess==false) ...[
          Text("Upload failed", style: TextStyle(fontWeight: FontWeight.w600)),
          Text(_responseDescription!),
          SizedBox(height: kSpacing),
        ] else if(_isSubmittingTooLong) ...[
          Text("It takes longer than expected..."),
        ]
      ]);
  }

  void _onCopyResult() async {
    if(_responseDescription != null)
      await Clipboard.setData(ClipboardData(text: _responseDescription!));
  }

  void _submit() async {
    setState(() { _isSubmitting = true; });

    try{
      await SiprixVoipSdk().uploadLogFile(_controller.text);
    } on PlatformException catch (err) {
      _responseDescription = err.message!;
      _responseSuccess = false;
      setState(() { _isSubmitting = false; });
    }

    if(_isSubmitting) {
      Future.delayed(Duration(seconds: 5)).then((_) {
        setState(() { _isSubmittingTooLong = true; });
      });
    }
  }

  void _closeDialog() {
    Navigator.of(context).pop();
  }
}