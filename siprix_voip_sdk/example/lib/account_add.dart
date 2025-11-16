import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:siprix_voip_sdk/accounts_model.dart';
import 'package:siprix_voip_sdk/network_model.dart';

import 'accouns_model_app.dart';
import 'main.dart';

////////////////////////////////////////////////////////////////////////////////////////
//AccountPage - represents fields of selected account. Used for adding/editing accounts

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  static const routeName = '/addAccount';

  @override
  AccountPageState createState() => AccountPageState();
}

class AccountPageState extends State<AccountPage> {
  final _formKey = GlobalKey<FormState>();
  AccountModel _account = AccountModel();
  bool _passwordVisible = false;
  bool _advancedMode = false;
  List<Codec> _audioCodecsList=[];
  List<Codec> _videoCodecsList=[];
  String _errText = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _account = ModalRoute.of(context)!.settings.arguments as AccountModel;
    _audioCodecsList = Codec.getCodecsList(_account.aCodecs, audio:true);
    _videoCodecsList = Codec.getCodecsList(_account.vCodecs, audio:false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
        title: Text(isAddMode() ? 'Add Account' : 'Edit Account'),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 12), child:
            OutlinedButton(
              onPressed: () {  setState(() { _advancedMode = !_advancedMode; }); },
              child: Wrap(spacing:5, children: [
                Icon(_advancedMode ? Icons.density_medium : Icons.density_small),
                Text(_advancedMode ? 'Simple mode' : 'Advanced mode')
              ])
          ))
        ]

      ),
      body: SingleChildScrollView(scrollDirection: Axis.vertical,
        child: Form(key: _formKey,
          child: Padding(padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
            child:_advancedMode ? buildAdvanced() : buildSimple()
          )
        )
      )
    );
  }

  Widget buildSimple() {
    return
      Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSipServer(),
          _buildSipExtension(),
          _buildPassword(),
          _buildExpireTimeout(),
          _buildTransportsDropDown(),
          _buildRewriteContactIp(),
          _buildSubmitButton(),
          Text(_errText, style: const TextStyle(color: Colors.red), ),
        ]
    );
  }

  Widget buildAdvanced() {
    return
      Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExpansionTile("Credentials", true, _buildCredentialsCtrlList()),
          const SizedBox(height: 5),
          _buildExpansionTile("Transport",  false, _buildTransportCtrlList()),
          const SizedBox(height: 5),
          _buildExpansionTile("Media",  false, _buildMediaCtrlList()),
          const SizedBox(height: 5),
          _buildExpansionTile("Audio codecs", false, _buildCodecsList(_audioCodecsList)),
          const SizedBox(height: 5),
          _buildExpansionTile("Video codecs", false, _buildCodecsList(_videoCodecsList)),
          const SizedBox(height: 5),
          _buildExpansionTile("Other",  false, _buildOtherCtrlList()),
          const SizedBox(height: 5),
          _buildSubmitButton(),
          Text(_errText, style: const TextStyle(color: Colors.red), ),
        ]
      );
  }

  Widget _buildSubmitButton() {
    return
      Padding(padding: const EdgeInsets.all(20),
        child: ElevatedButton(onPressed:_submit,
          child: Wrap(spacing:5,
            children: [const Icon(Icons.archive), Text(isAddMode() ? 'Add' : 'Update')
          ])
        )
      );
  }

  Widget _buildExpansionTile(String panelName, bool isExpanded, List<Widget> panelControls) {
    return ExpansionTile(dense: true,
        title: Text(panelName, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600)),
        shape: Border.all(color: Colors.grey),
        collapsedShape: Border.all(color: Colors.grey),
        tilePadding: const EdgeInsets.fromLTRB(10, 0, 20, 0),
        backgroundColor: Theme.of(context).secondaryHeaderColor,
        collapsedBackgroundColor: Theme.of(context).secondaryHeaderColor,
        initiallyExpanded: isExpanded,
        children: [
          Container(padding: const EdgeInsets.fromLTRB(15,0,15,15), color: Colors.white,
            child: Column(children: panelControls)
          )
        ]
      );
  }

  List<Widget> _buildCredentialsCtrlList() {
    return [
      _buildSipServer(),
      _buildSipExtension(),
      _buildPassword(),
      _buildExpireTimeout(),
    ];
  }

  Widget _buildSipServer() {
    return  TextFormField(
      decoration: const InputDecoration(labelText: 'Sip server/domain'),
       validator: (value) { return (value == null || value.isEmpty) ? 'Please enter domain' : null; },
       onChanged: (String? value) { setState(() { if((value!=null) && value.isNotEmpty) _account.sipServer = value; }); },
       initialValue: _account.sipServer,
       enabled: isAddMode(),
    );
  }

  Widget _buildSipExtension() {
    return TextFormField(
        decoration: const InputDecoration(labelText: 'Sip extension'),
        validator: (value) { return (value == null || value.isEmpty) ? 'Please enter user name.' : null; },
        onChanged: (String? value) { setState(() { if((value!=null) && value.isNotEmpty) _account.sipExtension = value; }); },
        initialValue: _account.sipExtension,
        enabled: isAddMode(),
      );
  }

  Widget _buildPassword() {
    return TextFormField(
        obscureText: !_passwordVisible,
        decoration: InputDecoration(labelText: 'Sip password',
          suffixIcon: IconButton(
              icon: Icon(_passwordVisible? Icons.visibility_off : Icons.visibility,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {  setState(() { _passwordVisible = !_passwordVisible; }); },
          )
        ),
        validator: (value) { return (value == null || value.isEmpty) ? 'Please enter password.' : null; },
        onChanged: (String? value) { setState(() { if((value!=null) && value.isNotEmpty) _account.sipPassword = value; }); },
        initialValue: _account.sipPassword,
      );
  }

  Widget _buildExpireTimeout() {
    return TextFormField(
        obscureText: false,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(labelText: 'Expire time (seconds)'),
        onChanged: (String? val) { setState(() { if((val!=null) && val.isNotEmpty) _account.expireTime = int.parse(val);  }); },
        initialValue: _account.expireTime?.toString(),
        enabled: isAddMode(),
      );
  }

  List<Widget> _buildMediaCtrlList() {
    return [
      _buildSecureMediaDropDown(),

      TextFormField(
        decoration: const InputDecoration(labelText: 'STUN server'),
        onChanged: (String? value) { setState(() { _account.stunServer = value; }); },
        initialValue: _account.stunServer,
      ),

      TextFormField(
        decoration: const InputDecoration(labelText: 'TURN server'),
        onChanged: (String? value) { setState(() { _account.turnServer = value; }); },
        initialValue: _account.turnServer,
      ),

      TextFormField(
        decoration: const InputDecoration(labelText: 'TURN user name'),
        onChanged: (String? value) { setState(() { _account.turnUser = value; }); },
        initialValue: _account.turnUser,
      ),

      TextFormField(
        decoration: const InputDecoration(labelText: 'TURN password'),
        onChanged: (String? value) { setState(() { _account.turnPassword = value; }); },
        initialValue: _account.turnPassword,
      )
    ];
  }

  Widget _buildSecureMediaDropDown() {
    return ButtonTheme(alignedDropdown: true, child:
      DropdownButtonFormField<SecureMedia>(
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          labelText: 'Media encryption:',
          contentPadding: EdgeInsets.all(0),
        ),
        value: _account.secureMedia,
        elevation: 1,
        onChanged: (SecureMedia? value) { setState(() { _account.secureMedia = value!; }); },
        items: SecureMedia.values.map((t) => _secureMediaItem(t)).toList()
    ));
  }

  DropdownMenuItem<SecureMedia> _secureMediaItem(SecureMedia secureMedia) {
    return DropdownMenuItem<SecureMedia>(value: secureMedia, child:
       Text(secureMedia.name, style:Theme.of(context).textTheme.bodyMedium, )
    );
  }

  List<Widget> _buildTransportCtrlList() {
    return [
      _buildTransportsDropDown(),
      TextFormField(
        obscureText: false,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
        decoration: _buildDecoration('Sip port'),
        onChanged: (String? val) { setState(() { if((val!=null)&&(val.isNotEmpty)) _account.port = int.parse(val);  }); },
        initialValue: _account.port?.toString(),
        enabled: isAddMode(),
      ),
      TextFormField(
        obscureText: false,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
        decoration: _buildDecoration('Keep alive time (seconds)'),
        onChanged: (String? val) { setState(() { if((val!=null) && val.isNotEmpty) _account.keepAliveTime = int.parse(val);  }); },
        initialValue: _account.keepAliveTime?.toString()
      ),
      _buildRewriteContactIp()
    ];
  }

  List<Widget> _buildCodecsList(List<Codec> items) {
    return [
      ReorderableListView(shrinkWrap: true,
        footer: Codec.validateSel(items) ? null : const Text("At least one codec should be selected", style: TextStyle(color: Colors.red), ),
        children: <Widget>[
          for (int c=0; c<items.length; ++c)
            ListTile(key: Key('$c'),
              leading: Checkbox(value: items[c].selected,
                onChanged: (bool? sel) { setState(() { items[c].selected = sel!; }); },
              ),
              title: Text(Codec.name(items[c].id)),
              trailing:  Icon(Icons.drag_handle)
            ),
        ],
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (oldIndex < newIndex) { newIndex -= 1; }
            final Codec item = items.removeAt(oldIndex);
            items.insert(newIndex, item);
          });
        },
    )];
  }

  List<Widget> _buildOtherCtrlList() {
    return [
      TextFormField(
        decoration: _buildDecoration('AuthId (auth username)'),
        onChanged: (String? value) { setState(() { _account.sipAuthId = value; }); },
        initialValue: _account.sipAuthId,
      ),
      TextFormField(
        decoration: _buildDecoration('Sip proxy server'),
        onChanged: (String? value) { setState(() { _account.sipProxy = value; }); },
        initialValue: _account.sipProxy,
      ),
      TextFormField(
        decoration: _buildDecoration('Display name'),
        onChanged: (String? value) { setState(() { _account.displName = value; }); },
        initialValue: _account.displName,
      ),
      TextFormField(
        decoration: _buildDecoration('User agent'),
        onChanged: (String? value) { setState(() { _account.userAgent = value; }); },
        initialValue: _account.userAgent,
      ),
      _buildUpgradeToVideModeDropDown()
    ];
  }

  InputDecoration _buildDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      //labelStyle: const TextStyle(color: Colors.grey)
    );
  }

  bool isAddMode() {
    return (_account.myAccId == 0);
  }

  DropdownMenuItem<SipTransport> transportItem(SipTransport transp) {
    return DropdownMenuItem<SipTransport>(value: transp, child:
      Text(transp.name, style:Theme.of(context).textTheme.bodyMedium,)
    );
  }

  Widget _buildTransportsDropDown() {
    return ButtonTheme(alignedDropdown: true, child:
      DropdownButtonFormField<SipTransport>(
        decoration: InputDecoration(
          border: const UnderlineInputBorder(),
          labelText: 'Sip signalling transport:',
          labelStyle: TextStyle(color: isAddMode() ? null : Theme.of(context).disabledColor),
        ),
        value: _account.transport,
        onChanged: isAddMode() ? (SipTransport? value) { setState(() { _account.transport = value!; }); } : null,
        items: SipTransport.values.map((t) => transportItem(t)).toList()
    ));
  }

  Widget _buildRewriteContactIp() {
    return CheckboxListTile(
      contentPadding: const EdgeInsetsDirectional.all(0),
      title: const Text('Rewrite Contact IP address'),
      onChanged: (bool? val) {  setState(() { _account.rewriteContactIp = val;  }); },
      value: _account.rewriteContactIp,
      tristate:true,
    );
  }

  Widget _buildUpgradeToVideModeDropDown() {
    return ButtonTheme(alignedDropdown: true, child:
      DropdownButtonFormField<UpgradeToVideoMode>(
        decoration: InputDecoration(
          border: const UnderlineInputBorder(),
          labelText: 'Upgrade to video mode:',
          labelStyle: TextStyle(color: isAddMode() ? null : Theme.of(context).disabledColor),
        ),
        value: _account.upgradeToVideo,
        onChanged: (UpgradeToVideoMode? value) { setState(() { _account.upgradeToVideo = value!; }); },
        items: UpgradeToVideoMode.values.map((t) => _upgradeTovideoModeItem(t)).toList()
    ));
  }

  DropdownMenuItem<UpgradeToVideoMode> _upgradeTovideoModeItem(UpgradeToVideoMode mode) {
    return DropdownMenuItem<UpgradeToVideoMode>(value: mode, child:
      Text(mode.name, style:Theme.of(context).textTheme.bodyMedium,)
    );
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate() ||
       !Codec.validateSel(_videoCodecsList) ||
       !Codec.validateSel(_audioCodecsList)) return;

    _account.aCodecs = Codec.getSelectedCodecsIds(_audioCodecsList);
    _account.vCodecs = Codec.getSelectedCodecsIds(_videoCodecsList);

    if(isAddMode()) {
      _account.ringTonePath = MyApp.getRingtonePath();
    }

    Future<void> action = isAddMode()
                          ? context.read<AppAccountsModel>().addAccount(_account)
                          : context.read<AppAccountsModel>().updateAccount(_account);
    action.then((_) { Navigator.pop(context, true); })
      .catchError((error) {
        setState(() { _errText = error;  });
    });
  }//_submit

}//AccountPageState
