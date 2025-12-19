import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siprix_voip_sdk/accounts_model.dart';
import 'accouns_model_app.dart';
import 'account_add.dart';

////////////////////////////////////////////////////////////////////////////////////////
//AccountsListPage - represents list of accounts

class AccountsListPage extends StatefulWidget {
  const AccountsListPage({super.key});

  @override
  State<AccountsListPage> createState() => _AccountsListPageState();
}

enum AccAction {delete, unregister, register, edit}

class _AccountsListPageState extends State<AccountsListPage> {
  int _selRowIdx=0;
  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AppAccountsModel>();
    return Column(children: [
      const ListTile(leading: Text('State'), title: Text('Name'), trailing: Text('Action')),
      const Divider(height: 0),
      Expanded(child:ListView.separated(
        scrollDirection: Axis.vertical,
        itemCount: accounts.length+1,
        itemBuilder: (BuildContext context, int index) { return _accListTile(accounts, index); },
        separatorBuilder: (BuildContext context, int index) => const Divider(height: 0,),
      )),
    ]);
  }

  Widget _accListTile(AccountsModel accounts, int index) {
    if(index >= accounts.length) return _addAccountButton();

    AccountModel acc = accounts[index];
    return
      ListTile(
        selected: (_selRowIdx == index),//(accounts.selAccountId == acc.myAccId),
        selectedColor: Colors.black,
        selectedTileColor: Theme.of(context).secondaryHeaderColor,
        leading: _getAccIcon(acc.regState),
        title: Text(acc.uri, style: Theme.of(context).textTheme.titleSmall, overflow: TextOverflow.ellipsis),
        subtitle: Text('ID: ${acc.myAccId} REG: ${acc.regText}', overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic, color: Colors.grey)),
        trailing: _buildTrailingSection(accounts, index),
        onTap: () { onTapAccListTile(index); },
        dense: true,
      );
  }

  void onTapAccListTile(int rowIndex) {
    setState(() {
      _selRowIdx = rowIndex;
    });
  }

  void onTapSetSelectedAccount(int accId) {
    context.read<AppAccountsModel>().setSelectedAccountById(accId);
  }

  Widget _buildTrailingSection(AccountsModel accounts, int index) {
    AccountModel acc = accounts[index];
    return
      Wrap(children:[
        if(accounts.selAccountId == acc.myAccId)
          IconButton(onPressed: null,
            icon: const Icon(Icons.check_circle), tooltip: "Default account")
        else if(_selRowIdx == index)
          IconButton(onPressed: (){ onTapSetSelectedAccount(acc.myAccId); },
            icon: const Icon(Icons.radio_button_unchecked_outlined)),

        _accListTileMenu(acc, index)
      ]);
  }

  PopupMenuButton<AccAction> _accListTileMenu(AccountModel acc, int index) {
    return
      PopupMenuButton<AccAction>(
        onOpened: () { onTapAccListTile(index); },
        onSelected: (AccAction action) { _doAccountAction(action, index); },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<AccAction>>[
          const PopupMenuItem<AccAction>(
            value: AccAction.edit,
            child: Wrap(spacing:5, children:[Icon(Icons.edit), Text("Edit")])
          ),
          PopupMenuItem<AccAction>(
            value: AccAction.register,
            enabled: (acc.regState!=RegState.inProgress),
            child: const Wrap(spacing:5, children:[Icon(Icons.refresh), Text("Register"),])
          ),
          PopupMenuItem<AccAction>(
            value: AccAction.unregister,
            enabled: (acc.regState!=RegState.inProgress)&&(acc.regState!=RegState.removed),
            child: const Wrap(spacing:5, children:[Icon(Icons.cancel_presentation), Text("Unregister")])
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<AccAction>(
            value: AccAction.delete,
            child: Wrap(spacing:5, children:[Icon(Icons.delete), Text("Delete"),])
          ),
        ],
      );
  }

  Widget _addAccountButton() {
    return
      Align(alignment: Alignment.topRight,
        child:Padding(padding: const EdgeInsets.all(11),
          child:OutlinedButton(onPressed: _addAccount, child: const Icon(Icons.add_circle)))
      );
  }

  void _addAccount() {
    Navigator.of(context).pushNamed(AccountPage.routeName, arguments: AccountModel());
  }

  void _editAccount(int index) {
    final accModel = context.read<AppAccountsModel>();
    Navigator.of(context).pushNamed(AccountPage.routeName, arguments: accModel[index]);
  }

  void _doAccountAction(AccAction action, int index) {
    final accModel = context.read<AppAccountsModel>();
    Future<void> f;
    switch(action) {
      case AccAction.delete:     f = accModel.deleteAccount(index);     break;
      case AccAction.unregister: f = accModel.unregisterAccount(index); break;
      case AccAction.register:   f = accModel.registerAccount(index);   break;
      case AccAction.edit:       _editAccount(index);                   return;
    }
    f.catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    });
  }

  Widget _getAccIcon(RegState s) {
    switch(s){
      case RegState.success:    return const Icon(Icons.cloud_done_outlined, color: Colors.green);
      case RegState.failed:     return const Icon(Icons.cloud_off_outlined, color: Colors.red);
      case RegState.inProgress: return const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 3,));
      default:                  return const Icon(Icons.done, color: Colors.grey);
    }
  }

}//AccountsListPage