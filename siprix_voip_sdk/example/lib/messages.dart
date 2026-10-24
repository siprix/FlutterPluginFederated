import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siprix_voip_sdk/messages_model.dart';

import 'accouns_model_app.dart';

enum MsgAction {delete, deleteAll}

////////////////////////////////////////////////////////////////////////////////////////
//MessagesListPage - represents list of BLF subscriptions

class MessagesListPage extends StatefulWidget {
  const MessagesListPage({super.key});

  @override
  State<MessagesListPage> createState() => _MessagesListPagePageState();
}


class _MessagesListPagePageState extends State<MessagesListPage> {
  final _bodyTextCtrl = TextEditingController();
  final _phoneNumbCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _selMsgRowIdx=0;
  String _errText="";

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<MessagesModel>();
    return Column(children: [
      Expanded(child: ListView.separated(
        scrollDirection: Axis.vertical,
        itemCount: messages.length,
        itemBuilder: (BuildContext context, int index) { return _messageListTileSelector(messages, index); },
        separatorBuilder: (BuildContext context, int index) => const Divider(height: 0,),
      )),
      Padding(padding: const EdgeInsets.all(10), child:
        Form(key: _formKey, child:
          Column(children:[
            Row(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Expanded(child: _buildAccountsMenu()),
              const SizedBox(width: 5),
              Expanded(child: _buildPhoneNumberField())
            ]),
            _buildMessageBodyField()
          ])
        )
      )
    ]);
  }

  Widget _messageListTileSelector(MessagesModel messages, int index) {
      MessageModel msg = messages[index];
      //Use ListenableBuilder for outgoing messages to display sent status
      return
        msg.isIncoming ? _messageListTile(messages, index)
                       : ListenableBuilder(listenable: msg, builder: (BuildContext context, Widget? child)
                           => _messageListTile(messages, index));
  }

  Widget _messageListTile(MessagesModel messages, int index) {
    MessageModel msg = messages[index];
    return
      ListTile(
        dense: true,
        selected: (_selMsgRowIdx == index),
        selectedColor: Colors.black,
        selectedTileColor: Theme.of(context).secondaryHeaderColor,
        leading:
          msg.isIncoming ? const Icon(Icons.call_received_rounded, color: Colors.green)
          : Column(children:[const Icon(Icons.call_made_rounded,color: Colors.lightGreen),
              Icon(Icons.check, size: 14, color: msg.sentSuccess ? Colors.deepPurple : Colors.grey),
            ]),
        title: Text(msg.body,
          textAlign: msg.isIncoming ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.titleSmall
        ),
        subtitle: (_selMsgRowIdx == index) ? _getMsgRowSubTitle(msg) : null,
        trailing: _getMsgRowTrailing(index),
        onTap: () {
          setState(() {
            _phoneNumbCtrl.text = msg.getReplyExt();
            _selMsgRowIdx = index;
          });
        },
      );
  }

  Widget _getMsgRowSubTitle(MessageModel msg) {
    String text  = msg.isIncoming ? "From: ${msg.ext}\nTo:${msg.accUri}\n${msg.timestamp}"
                                  : "From: ${msg.accUri}\nTo:${msg.ext}\n${msg.timestamp}";
    if(!msg.isIncoming) text+=". Response: ${msg.response}";

    return
      Text(text, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
  }

  Widget _getMsgRowTrailing(int index) {
    return
      PopupMenuButton<MsgAction>(
        onSelected: (MsgAction action) { _onMsgMenuAction(action, index); },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<MsgAction>>[
          const PopupMenuItem<MsgAction>(
            value: MsgAction.delete,
            child: Wrap(spacing:5, children:[Icon(Icons.delete), Text("Delete"),])
          ),
        ]);
  }

  void _onMsgMenuAction(MsgAction action, int index) {
    context.read<MessagesModel>().remove(index);
  }

  Widget _buildAccountsMenu() {
    final accounts = context.watch<AppAccountsModel>();
    return
        DropdownButtonFormField<int>(
          isExpanded: true,
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: 'Source account'
          ),
          initialValue: accounts.selAccountId,
          onChanged: (int? accId) {
            accounts.setSelectedAccountById(accId!);
          },
          items: List.generate(accounts.length, (index)
                  => DropdownMenuItem<int>(value: accounts[index].myAccId, child: Text(accounts[index].uri))
        ),
      );
  }

   Widget _buildPhoneNumberField() {
    return
      TextFormField(
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          labelText: 'Destination phone number',
        ),
        controller: _phoneNumbCtrl,
        validator: (value) { return (value == null || value.isEmpty) ? "Phone number can't be empty" : null; },
    );
  }

  Widget _buildMessageBodyField() {
    return
      TextFormField(
        controller: _bodyTextCtrl,
        validator: (value) { return (value == null || value.isEmpty) ? "Text to send can't be empty" : null; },
        decoration: InputDecoration(
          border: const UnderlineInputBorder(),
          labelText: 'Enter text to send',
          suffixIcon: IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send))
        )
    );
  }


  void _sendMessage() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    //Check selected account
    final accounts = context.read<AppAccountsModel>();
    if(accounts.selAccountId==null) return;

    //Send
    MessageDestination msgDest = MessageDestination(_phoneNumbCtrl.text, accounts.selAccountId!, _bodyTextCtrl.text);
    context.read<MessagesModel>().send(msgDest)
      .then((_) => setState((){ _errText=""; }))
      .catchError((error) {
        setState(() { _errText = error.toString();  });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errText)));
      });

    _bodyTextCtrl.text="";
  }

}//_MessagesListPagePageState

