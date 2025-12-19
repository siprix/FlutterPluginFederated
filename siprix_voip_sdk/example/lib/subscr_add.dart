import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siprix_voip_sdk/accounts_model.dart';
import 'package:siprix_voip_sdk/subscriptions_model.dart';
import 'accouns_model_app.dart';
import 'subscr_model_app.dart';

////////////////////////////////////////////////////////////////////////////////////////
//SubscrAddPage - allows enter extension and account for creating BLF subscriptions

class SubscrAddPage extends StatefulWidget {
  const SubscrAddPage({super.key});
  static const routeName = "/addBlf";

  @override
  State<SubscrAddPage> createState() => _SubscrAddPageState();
}

class _SubscrAddPageState extends State<SubscrAddPage> {
  final _formKey = GlobalKey<FormState>();
  final AppBlfSubscrModel _subscr = AppBlfSubscrModel("", 0);
  String _errText="";

  @override
  void initState() {
    super.initState();
     final accounts = context.read<AppAccountsModel>();
     if(accounts.selAccountId != null)  _subscr.fromAccId = accounts.selAccountId!;
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.read<AppAccountsModel>();
    return Scaffold(
        appBar: AppBar(title: const Text('Add BLF subscription'), backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.4)),
        body: accounts.isEmpty ? _buildEmptyBody() : _buildBody(accounts),
    );
  }

  Widget _buildEmptyBody() {
   return const Padding(padding: EdgeInsets.all(16.0),
      child: Text('Can\'t add BFL subscription. Required to add account')
    );
  }

  Widget _buildBody(AccountsModel accounts) {
    return Form(key: _formKey, child:
      Container(padding: const EdgeInsets.all(10.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAccountsMenu(accounts),
            _buildLabelField(),
            _buildExtensionField(),
            const SizedBox(height: 15),
            OutlinedButton(onPressed: _addSubscription, child: const Icon(Icons.add_circle)),
            const Spacer(),
            Text(_errText, style: const TextStyle(color: Colors.red))
          ]
        ),
    ));
  }

  Widget _buildAccountsMenu(AccountsModel accounts) {
    return ButtonTheme(child: DropdownButtonFormField<int>(
      decoration: const InputDecoration(labelText: 'Select account:'),
      value: _subscr.fromAccId,
      onChanged: (int? accId) { setState(() { if(accId!=null)  _subscr.fromAccId = accId; }); },
      items: List.generate(accounts.length, (index) => accMenuItem(accounts[index], index)),
    ));
  }

  DropdownMenuItem<int> accMenuItem(AccountModel acc, int index) {
    return DropdownMenuItem<int>(value: acc.myAccId, child: Text(acc.uri));
  }

  Widget _buildLabelField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Contact label'),
      validator: (value) { return (value == null || value.isEmpty) ? 'Please enter label.' : null; },
      onChanged: (String? value) { setState(() { if((value!=null) && value.isNotEmpty) _subscr.label = value; }); },
    );
  }

  Widget _buildExtensionField() {
    return TextFormField(
      style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
      decoration: const InputDecoration(labelText: 'Extension to subscribe'),
      validator: (value) { return (value == null || value.isEmpty) ? 'Please enter extension.' : null; },
      onChanged: (String? value) { setState(() { if((value!=null) && value.isNotEmpty) _subscr.toExt = value; }); },
    );
  }

  void _addSubscription() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    //Add
    context.read<SubscriptionsModel>().addSubscription(_subscr)
      .then((_) => setState((){ _errText=""; }))
      .catchError((error) {
        setState(() { _errText = error.toString();  });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errText)));
      });

    Navigator.of(context).pop();
  }
}

