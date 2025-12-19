import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siprix_voip_sdk/subscriptions_model.dart';
import 'subscr_add.dart';
import 'subscr_model_app.dart';

////////////////////////////////////////////////////////////////////////////////////////
//SubscrListPage - represents list of BLF subscriptions

class SubscrListPage extends StatefulWidget {
  const SubscrListPage({super.key});

  @override
  State<SubscrListPage> createState() => _SubscrListPageState();
}

enum SubscrAction {delete, add}

class _SubscrListPageState extends State<SubscrListPage> {
  int _selRowIdx=0;

  @override
  Widget build(BuildContext context) {
    final subscriptions = context.watch<SubscriptionsModel>();
    return Column(children: [
      const ListTile(leading: Text('State'), title: Text('Label'), trailing: Text('Action'),),
      const Divider(height: 0),
      Expanded(child: ListView.separated(
        scrollDirection: Axis.vertical,
        itemCount: subscriptions.length+1,
        itemBuilder: (BuildContext context, int index) { return _subscrListTile(subscriptions, index); },
        separatorBuilder: (BuildContext context, int index) => const Divider(height: 0,),
      ))
    ]);
  }

  Widget _subscrListTile(SubscriptionsModel subscriptions, int index) {
    if(index >= subscriptions.length) return _addSubscriptionButton();

    if(subscriptions[index] is! AppBlfSubscrModel) {
      SubscriptionModel subscr = subscriptions[index];
      return Text(subscr.label, style: Theme.of(context).textTheme.titleSmall);
    }else{
      AppBlfSubscrModel blfSubscr = subscriptions[index] as AppBlfSubscrModel;
      return
        ListenableBuilder(listenable: blfSubscr,
          builder: (BuildContext context, Widget? child) {
            return
              ListTile(
                selected: (_selRowIdx == index),
                selectedColor: Colors.black,
                selectedTileColor: Theme.of(context).secondaryHeaderColor,
                leading: _getSubscrIcon(blfSubscr.state, blfSubscr.blfState),
                title: Text('${blfSubscr.label} (${blfSubscr.toExt})', style: Theme.of(context).textTheme.titleSmall),
                subtitle: Text('${blfSubscr.blfState.name}',//subscr.response
                  style: const TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic, color: Colors.grey)),
                trailing: _subscrListTileMenu(index),
                onTap: () { onTapSubscrListTile(index); },
                dense: true,
            );
        });
    }
  }

  void onTapSubscrListTile(int rowIndex) {
    setState(() {
      _selRowIdx = rowIndex;
    });
  }

  Widget _addSubscriptionButton() {
    return
      Align(alignment: Alignment.topRight,
        child:Padding(padding: const EdgeInsets.all(11),
          child:OutlinedButton(onPressed: _addSubscription, child: const Icon(Icons.add_circle)))
      );
  }
  void _addSubscription() {
    Navigator.of(context).pushNamed(SubscrAddPage.routeName);
  }

  PopupMenuButton<SubscrAction> _subscrListTileMenu(int index) {
    return
      PopupMenuButton<SubscrAction>(
        onOpened: () { onTapSubscrListTile(index); },
        onSelected: (SubscrAction action) { _doSubscriptionAction(action, index); },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<SubscrAction>>[
          const PopupMenuItem<SubscrAction>(
            value: SubscrAction.delete,
            child: Wrap(spacing:5, children:[Icon(Icons.delete), Text("Delete"),])
          ),
        ],
      );
  }

  void _doSubscriptionAction(SubscrAction action, int index) {
    context.read<SubscriptionsModel>().deleteSubscription(index).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    });
  }

  Widget _getSubscrIcon(SubscriptionState s, BLFState blfState) {
    Color color = (s==SubscriptionState.destroyed) ? Colors.grey :
                  (blfState == BLFState.terminated)||(blfState == BLFState.unknown) ? Colors.green : Colors.red;
    bool blinking = (blfState==BLFState.early);
    return blinking ? const AnimatedContactIcon() : Icon(Icons.account_circle, color: color);
  }

}//SubscrListPage



////////////////////////////////////////////////////////////////////////////////////////
//AnimatedContactIcon - represents list of BLF subscriptions

class AnimatedContactIcon extends StatefulWidget {
  const AnimatedContactIcon({super.key});

  @override
  State<AnimatedContactIcon> createState() => _AnimatedContactIconState();
}

class _AnimatedContactIconState extends State<AnimatedContactIcon>  with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animationController,
       child: const Icon(Icons.account_circle, color: Colors.red));
  }

}//AnimatedContactIcon