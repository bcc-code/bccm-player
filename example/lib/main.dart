import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player_example/examples/single_player.dart';
import 'package:flutter/material.dart';

import 'examples/list_of_players.dart';
import 'examples/playground.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BccmPlayerInterface.instance.setup();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: CastButton(color: Colors.white),
              ),
            ],
            bottom: const TabBar(tabs: [
              Tab(text: 'Playground'),
              Tab(text: 'List Of Players'),
              Tab(text: 'Single player'),
            ]),
          ),
          // tabs with Playground #1 then a new "ListOfPlayers" tab at #2 and controls to navigate between the tabs
          body: const TabBarView(
            children: [
              Playground(),
              ListOfPlayers(),
              SinglePlayer(),
            ],
          ),
        ),
      ),
    );
  }
}
