import 'dart:async';

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player_example/examples/drm_player.dart';
import 'package:bccm_player_example/examples/queue.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'examples/list_of_players.dart';
import 'examples/playground.dart';
import 'examples/native_controls.dart';
import 'examples/custom_controls.dart';
import 'examples/simple_player.dart';
import 'examples/downloader.dart';

Future<void> main() async {
  await BccmPlayerInterface.instance.setup();

  // FocusDebugger.instance.activate();

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
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(navigationMode: NavigationMode.directional),
      child: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        },
        child: DefaultTabController(
          length: 8,
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
                  Tab(text: 'Queue'),
                  Tab(text: 'Playground'),
                  Tab(text: 'List Of Players'),
                  Tab(text: 'Simple player'),
                  Tab(text: 'Custom controls'),
                  Tab(text: 'Native controls'),
                  Tab(text: 'Downloader'),
                  Tab(text: 'DRM'),
                ]),
              ),
              // tabs with Playground #1 then a new "ListOfPlayers" tab at #2 and controls to navigate between the tabs
              body: const TabBarView(
                children: [
                  QueueExample(),
                  Playground(),
                  ListOfPlayers(),
                  SimplePlayer(),
                  CustomControls(),
                  NativeControls(),
                  Downloader(),
                  DrmPlayer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
