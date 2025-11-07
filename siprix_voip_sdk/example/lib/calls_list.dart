// ignore_for_file: unused_element

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siprix_voip_sdk/siprix_voip_sdk.dart';
import 'package:siprix_voip_sdk/calls_model.dart';
import 'package:siprix_voip_sdk/devices_model.dart';
import 'package:siprix_voip_sdk/logs_model.dart';
import 'package:siprix_voip_sdk/video.dart';

import 'call_add.dart';
import 'calls_model_app.dart';
import 'main.dart';

////////////////////////////////////////////////////////////////////////////////////////
//CallsListPage - represents list of calls

enum CallAction {accept, reject, switchTo, hangup, hold, redirect}

class CallsListPage extends StatefulWidget {
  const CallsListPage({super.key});

  @override
  State<CallsListPage> createState() => _CallsListPageState();
}

class _CallsListPageState extends State<CallsListPage> {
  Timer? _callDurationTimer;

  void _toggleDurationTimer(CallsModel calls) {
    if(calls.isEmpty) {
      _callDurationTimer?.cancel();
      _callDurationTimer = null;
    } else {
      if(_callDurationTimer != null) return;
      _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        calls.calcDuration();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final calls = context.watch<AppCallsModel>();
    CallModel? switchedCall = calls.switchedCall();
    _toggleDurationTimer(calls);

    if(calls.isEmpty) return const CallAddPage(false);

    return
      Column(children: [
        const Divider(height: 1),
        ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(0.0),
          itemCount: calls.length,
          scrollDirection: Axis.vertical,
          separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) {
            return ListenableBuilder(listenable: calls[index], builder: (BuildContext context, Widget? child) {
              return _callModelRowTile(calls, index);
            });
          },
        ),
        const Divider(height: 1),

        if(switchedCall != null) Expanded(child:
                                  SwitchedCallWidget(switchedCall, key:ValueKey(switchedCall.myCallId))),
      ]);
  }//build

  ListTile _callModelRowTile(CallsModel calls, int index) {
    final call = calls[index];
    final bool isSwitched = (calls.switchedCallId == call.myCallId)||calls.confModeStarted;

    return
      ListTile(
        selected: isSwitched,
        selectedColor: Colors.black,
        selectedTileColor: Theme.of(context).secondaryHeaderColor,
        leading: Icon(call.isIncoming ? Icons.call_received_rounded : Icons.call_made_rounded),
        title: Text(call.nameAndExt,
          style: TextStyle(fontWeight: (isSwitched ? FontWeight.bold : FontWeight.normal)),
          overflow: TextOverflow.ellipsis),
        subtitle: Text(call.state.name),
        trailing: isSwitched ? null : IconButton(icon: const Icon(Icons.swap_calls_rounded),
          onPressed: () { calls.switchToCall(call.myCallId); }),
        dense: true,
      );
  }

}//CallsPage


////////////////////////////////////////////////////////////////////////////////////////
//SwitchedCallWidget - provides controls for manipulating current/switched call

class SwitchedCallWidget extends StatefulWidget {
  const SwitchedCallWidget(this.myCall, {super.key});
  final CallModel myCall;

  @override
  State<SwitchedCallWidget> createState() => _SwitchedCallWidgetState();
}

class _SwitchedCallWidgetState extends State<SwitchedCallWidget> {
  final SiprixVideoRenderer _localRenderer  = SiprixVideoRenderer();
  final SiprixVideoRenderer _remoteRenderer = SiprixVideoRenderer();
  static const double eIconSize = 30;

  bool _sendDtmfMode = false;

  final TextEditingController _transferBlindTextCtrl = TextEditingController();
  bool _transferBlindMode = false;

  int? _transferAttendedToCallId;
  bool _transferAttendedMode = false;

  @override
  void initState() {
    super.initState();
    _localRenderer.init(SiprixVoipSdk.kLocalVideoCallId, context.read<LogsModel>());
    _remoteRenderer.init(widget.myCall.myCallId, context.read<LogsModel>());
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return
      ListenableBuilder(
        listenable: widget.myCall,
        builder: (BuildContext context, Widget? child) {
          return
            Stack(children:[
              ... _buildVideoControls(),
              Center(child:
                Column(children: [
                  const Spacer(),
                  _buildNameExtText(),
                  _buildStateAccCallIdText(),
                  _buildCallDuration(),
                  const Spacer(),
                  ... _buildCallControls(),
                  const Spacer(),
                  if(widget.myCall.state==CallState.ringing) _buildIncomingCallAcceptReject(),
                  if(widget.myCall.state!=CallState.ringing) _buildHangupButton(),
                  const Spacer(),
                ])
              )
            ]);
          }
        );
  }//build

  Text _buildNameExtText() {
    return Text(widget.myCall.nameAndExt, style: Theme.of(context).textTheme.titleLarge);
  }

  Widget _buildStateAccCallIdText() {
    return
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('State: ${widget.myCall.state.name}', style: Theme.of(context).textTheme.titleMedium),
        Text('Acc: ${widget.myCall.accUri}'),
        Text('CallId: ${widget.myCall.myCallId}'),

        if(widget.myCall.receivedDtmf.isNotEmpty)
          Text('DTMF: ${widget.myCall.receivedDtmf}'),
    ]);
  }

  List<Widget> _buildVideoControls() {
    List<Widget> children = [];
    if(widget.myCall.hasVideo) {
      //Received video
      children.add(
        Center(child: SiprixVideoView(_remoteRenderer)));

      //Camera preview
      children.add(
        SizedBox(width: 130, height: 100, child: SiprixVideoView(_localRenderer)));

      //Button 'Mute camera'
      children.add(
          IconButton(onPressed: _muteCam, iconSize: eIconSize,
            icon: Icon(widget.myCall.isCamMuted ? Icons.videocam_off_outlined : Icons.videocam_outlined, color: Colors.red))
      );
    }
    return children;
  }

  List<Widget> _buildCallControls() {
    List<Widget> children = [];

    if((widget.myCall.state != CallState.connected) &&
       (widget.myCall.state != CallState.holding)&&
       (widget.myCall.state != CallState.held)) {
      return children;
    }

    if(_sendDtmfMode)         { children.add(_buildSendDtmf());         return children; }
    if(_transferBlindMode)    { children.add(_buildTransferBlind());    return children; }
    if(_transferAttendedMode) { children.add(_buildTransferAttended()); return children; }

    final bool isCallConnected = (widget.myCall.state == CallState.connected);

    children.add(Wrap(spacing: 25, runSpacing: 15, crossAxisAlignment: WrapCrossAlignment.start, children: [
      IconButton.filledTonal(iconSize: eIconSize, onPressed: _muteMic,
        icon: widget.myCall.isMicMuted ? const Icon(Icons.mic_off_rounded) : const Icon(Icons.mic_rounded),
      ),

      IconButton.filledTonal(iconSize: eIconSize, onPressed: isCallConnected ? _toggleSendDtmfMode : null,
        icon: const Icon(Icons.dialpad_rounded),
      ),

      MenuAnchor(builder: (BuildContext context, MenuController controller, Widget? child) {
        return IconButton.filledTonal(icon: const Icon(Icons.volume_up), iconSize: eIconSize,
          onPressed: () {
            if (controller.isOpen) { controller.close();  }
            else                   { controller.open();   }
          });
        },
        menuChildren: _buildPlayoutDevicesMenu()
      )
    ]));

    children.add(const SizedBox(height: 10));

    children.add(Wrap(spacing: 25, runSpacing: 15, crossAxisAlignment: WrapCrossAlignment.start, children: [
      IconButton.filledTonal( iconSize: eIconSize, onPressed: _showAddCallPage, icon: const Icon(Icons.add),
      ),

      IconButton.filledTonal(iconSize: eIconSize,
        onPressed: (widget.myCall.state == CallState.holding) ? null : _holdCall,
        icon: Icon(widget.myCall.isLocalHold ? Icons.play_arrow : Icons.pause)
      ),

      MenuAnchor(builder: (BuildContext context, MenuController controller, Widget? child) {
        return IconButton.filledTonal(icon: const Icon(Icons.more_horiz), iconSize: eIconSize,
          onPressed: ()  {
            if (controller.isOpen) { controller.close();  }
            else                   { controller.open();   }
          },);
        },
        menuChildren: [
          MenuItemButton(leadingIcon: Icon(widget.myCall.isFilePlaying ? Icons.stop : Icons.play_arrow),
            onPressed: isCallConnected ? _playFile : null,
            child: Text(widget.myCall.isFilePlaying ? "Stop playing" : 'Play file')),

          MenuItemButton(leadingIcon: Icon(Icons.radio_button_checked, color: widget.myCall.isRecStarted ? Colors.red : null),
            onPressed: isCallConnected ? _recordFile : null,
            child: Text(widget.myCall.isRecStarted ? 'Stop record': 'Record')),

          const Divider(),

          MenuItemButton(leadingIcon: const Icon(Icons.phone_forwarded),
              onPressed: context.read<AppCallsModel>().hasConnectedFewCalls() ? _toggleTransferAttendedMode : null,
              child: const Text('Transfer attended')),

          MenuItemButton(leadingIcon: const Icon(Icons.forward),
              onPressed: isCallConnected ? _toggleTransferBlindMode : null,
              child: const Text('Transfer')),
        ]
      ),
    ]));

    return children;
  }

  Text _buildCallDuration() {
    String label;
    switch(widget.myCall.state) {
      case CallState.connected:  label = widget.myCall.durationStr;
      case CallState.held:  label = "On Hold (${widget.myCall.holdState.name})";
      default: label = "-:-";
    }
    return Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green));
  }

  Widget _buildIncomingCallAcceptReject() {
    return
      Wrap(spacing: 50, runSpacing: 10, children: [
        IconButton.filledTonal(onPressed: _rejectCall, icon: const Icon(Icons.call_end),
            style: OutlinedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
        ),

        IconButton.filledTonal(onPressed: _acceptCall, icon: const Icon(Icons.call),
            style: OutlinedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
        )
      ]);
  }

  Widget _buildHangupButton() {
    final bool enabled = (widget.myCall.state!=CallState.disconnecting);
    return
      IconButton.filledTonal(iconSize: eIconSize, icon:const Icon(Icons.call_end),
          style: OutlinedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: enabled ? _hangUpCall : null,
          color: Colors.red
      );
  }

  void showSnackBar(dynamic err) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }

  List<MenuItemButton> _buildPlayoutDevicesMenu() {
    final devices = context.watch<DevicesModel>();
    return [
      for(var dvc in devices.playout)
        MenuItemButton(onPressed: () { _setPlayoutDevice(dvc.index); }, child: Text(dvc.name)),
    ];
  }

  void _setPlayoutDevice(int index) {
    final devices = context.read<DevicesModel>();
    devices.setPlayoutDevice(index)
      .catchError(showSnackBar);
  }

  void _hangUpCall() {
    widget.myCall.bye()
      .catchError(showSnackBar);
  }

  void _acceptCall() {
    widget.myCall.accept(widget.myCall.hasVideo)
      .catchError(showSnackBar);
  }

  void _rejectCall() {
    widget.myCall.reject()
      .catchError(showSnackBar);
  }

  void _sendDtmf(String tone) {
    widget.myCall.sendDtmf(tone)
      .catchError(showSnackBar);
  }

  void _holdCall() {
    widget.myCall.hold()
      .catchError(showSnackBar);
  }

  void _muteMic() {
    widget.myCall.muteMic(!widget.myCall.isMicMuted)
      .catchError(showSnackBar);
  }

  void _muteCam() {
    widget.myCall.muteCam(!widget.myCall.isCamMuted)
      .catchError(showSnackBar);
  }

  void _recordFile() async {
    if(widget.myCall.isRecStarted){
      widget.myCall.stopRecordFile()
        .catchError(showSnackBar);
    }
    else {
      String pathToFile = await MyApp.getRecFilePathName(widget.myCall.myCallId);
        widget.myCall.recordFile(pathToFile)
          .catchError(showSnackBar);
    }
  }

  void _playFile() async{
    if(widget.myCall.isFilePlaying) {
      widget.myCall.stopPlayFile()
        .catchError(showSnackBar);
    }
    else {
      //write 'asset/music.mp3' to temp folder
      String pathToFile = await MyApp.writeAssetAndGetFilePath("music.mp3");
        widget.myCall.playFile(pathToFile)
          .catchError(showSnackBar);
    }
  }

  void _makeConference() {
    final calls = context.read<AppCallsModel>();
    calls.makeConference().catchError(showSnackBar);
  }

  void _transferBlind(String ext) async {
    widget.myCall.transferBlind(ext)
      .catchError(showSnackBar);
  }

  void _transferAttended(int? toCallId) async {
    if(toCallId==null) return;

    widget.myCall.transferAttended(toCallId)
      .catchError(showSnackBar);
  }

  void _showAddCallPage() {
    Navigator.of(context).pushNamed(CallAddPage.routeName);
  }

  void _toggleSendDtmfMode() {
    setState(() => _sendDtmfMode = !_sendDtmfMode );
  }

  void _toggleTransferBlindMode() {
    setState(() => _transferBlindMode = !_transferBlindMode );
  }

  void _toggleTransferAttendedMode() {
    setState(() => _transferAttendedMode = !_transferAttendedMode );
  }

  Widget _buildSendDtmf() {
    const double spacing=8;
    return
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: spacing,),
          Wrap(spacing: spacing, children: <Widget>[
              OutlinedButton(child: const Text('1'), onPressed: (){ _sendDtmf("1"); }),
              OutlinedButton(child: const Text('2'), onPressed: (){ _sendDtmf("2"); }),
              OutlinedButton(child: const Text('3'), onPressed: (){ _sendDtmf("3"); }),
            ]
          ),
          const SizedBox(height: spacing),
          Wrap(spacing: spacing, children: <Widget>[
              OutlinedButton(child: const Text('4'), onPressed: (){ _sendDtmf("4"); }),
              OutlinedButton(child: const Text('5'), onPressed: (){ _sendDtmf("5"); }),
              OutlinedButton(child: const Text('6'), onPressed: (){ _sendDtmf("6"); }),
            ]
          ),
          const SizedBox(height: spacing),
          Wrap(spacing: spacing, children: <Widget>[
              OutlinedButton(child: const Text('7'), onPressed: (){ _sendDtmf("7"); }),
              OutlinedButton(child: const Text('8'), onPressed: (){ _sendDtmf("8"); }),
              OutlinedButton(child: const Text('9'), onPressed: (){ _sendDtmf("9"); }),
            ]
          ),
          const SizedBox(height:spacing),
          Wrap(spacing:spacing, children: <Widget>[
              OutlinedButton(child: const Text('*'), onPressed: (){ _sendDtmf("*"); }),
              OutlinedButton(child: const Text('0'), onPressed: (){ _sendDtmf("0"); }),
              OutlinedButton(child: const Text('#'), onPressed: (){ _sendDtmf("#"); }),
            ]
          ),
          const SizedBox(height:spacing),
          IconButton.filledTonal(onPressed: _toggleSendDtmfMode, icon:const Icon(Icons.close)),
        ],
    );
  }

  Widget _buildTransferBlind({String action="Transfer"}) {
    const double spacing=10;
    return
      Row(spacing: spacing, mainAxisSize: MainAxisSize.min,
        children: [
          Text("$action to:", style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600)),

          SizedBox(width: 120,
            child: TextField(decoration: const InputDecoration(hintText: 'Extension', isDense: true),
              textAlign: TextAlign.center, controller: _transferBlindTextCtrl, onChanged: (data){ setState(() {}); },)
          ),

          OutlinedButton(onPressed: _transferBlindTextCtrl.text.isEmpty ? null : () {
            _transferBlind(_transferBlindTextCtrl.text);
            _toggleTransferBlindMode();
          },
              child: Text(action)),
          IconButton.filledTonal(onPressed: _toggleTransferBlindMode, icon:const Icon(Icons.close)),
      ]);
  }

  Widget _buildTransferAttended() {
    const double spacing=10;
    final calls = context.read<AppCallsModel>();
    CallModel? srcCall = calls.switchedCall();
    final int srcCallId = (srcCall!=null) ? srcCall.myCallId : 0;
    for(var i = 0; i < calls.length; i++) {
      if(srcCallId != calls[i].myCallId) { _transferAttendedToCallId = calls[i].myCallId; break; }
    }

    return
      Row(spacing: spacing, mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Transfer to:", style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600)),

          DropdownButton<int?>(
            value: _transferAttendedToCallId,
            onChanged: (int? value) { setState(() => _transferAttendedToCallId = value! );  },
            items: [
              for(var i = 0; i < calls.length; i++)
                if(srcCallId != calls[i].myCallId)
                  DropdownMenuItem<int>(value: calls[i].myCallId, child: Text(calls[i].nameAndExt))
              ]
          ),

          OutlinedButton(onPressed: () { _transferAttended(_transferAttendedToCallId); }, child: const Text('Transfer')),
          IconButton.filledTonal(onPressed: _toggleTransferAttendedMode, icon:const Icon(Icons.close)),
      ]);
  }


}//_CallsPageState