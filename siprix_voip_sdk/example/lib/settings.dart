import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siprix_voip_sdk/devices_model.dart';
import 'package:siprix_voip_sdk/siprix_voip_sdk.dart';

////////////////////////////////////////////////////////////////////////////////////////
//SettingsPage - represents platfrom specific settings

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
    static const routeName = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

typedef OnChangedCallback = void Function(int?);

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DevicesModel>();
    return
      Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.4)),
        body: Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child:Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildBody(devices)
        )
      ));
  }

  List<Widget> _buildBody(DevicesModel devices) {
    if (Platform.isIOS) {
      return [
        const Text('iOS doesn\'t have settings yet')
      ];
    }else if (Platform.isAndroid) {
      return [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          title: const Text('Run phone service in foreground mode'),
          value: devices.foregroundModeEnabled,
          onChanged: onSetForegroundMode
        )
      ];
    }else{
      return [
      _buildPlayoutDevicesDropDown(devices),
      _buildRingtoneDevicesDropDown(devices),
      _buildRecordingDevicesDropDown(devices),
      _buildVideoDevicesDropDown(devices),
      ];
    }
  }

  DropdownMenuItem<int> mediaDeviceItem(MediaDevice dvc) {
    return DropdownMenuItem<int>(value: dvc.index, child:
       Text(dvc.name, style:Theme.of(context).textTheme.bodyMedium, )
    );
  }

  Widget _buildMediaDevicesDropDown(String labelText, List<MediaDevice> dvcList, int selIndex, OnChangedCallback onChanged) {
    return ButtonTheme(alignedDropdown: true, child:
      DropdownButtonFormField<int>(
        decoration: InputDecoration(
          border: const UnderlineInputBorder(),
          labelText: labelText,
        ),
        initialValue: (selIndex < 0) ? null : selIndex,
        onChanged: onChanged,
        items: dvcList.map((element) => mediaDeviceItem(element)).toList()
    ));
  }

  Widget _buildPlayoutDevicesDropDown(DevicesModel devices) {
    return _buildMediaDevicesDropDown('Playout device:', devices.playout, devices.playoutIndex, onSetPlayoutDevice);
  }

  Widget _buildRingtoneDevicesDropDown(DevicesModel devices) {
    return _buildMediaDevicesDropDown('Ringtone device:', devices.playout, devices.ringtoneIndex, onSetRingtoneDevice);
  }

  Widget _buildRecordingDevicesDropDown(DevicesModel devices) {
    return _buildMediaDevicesDropDown('Recording device:', devices.recording, devices.recordingIndex, onSetRecordingDevice);
  }

  Widget _buildVideoDevicesDropDown(DevicesModel devices) {
    return _buildMediaDevicesDropDown('Video device:', devices.video, devices.videoIndex, onSetVideoDevice);
  }

  void onSetRingtoneDevice(int? index) {
    context.read<DevicesModel>().setRingtoneDevice(index)
      .catchError(showSnackBar);
  }

  void onSetPlayoutDevice(int? index) {
    context.read<DevicesModel>().setPlayoutDevice(index)
      .catchError(showSnackBar);
  }

  void onSetRecordingDevice(int? index) {
    context.read<DevicesModel>().setRecordingDevice(index)
      .catchError(showSnackBar);
  }

  void onSetVideoDevice(int? index) {
    context.read<DevicesModel>().setVideoDevice(index)
      .catchError(showSnackBar);
  }

  void onSetForegroundMode(bool enable) {
    context.read<DevicesModel>().setForegroundMode(enable)
      .catchError(showSnackBar);
  }

  void showSnackBar(dynamic err) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }
}
