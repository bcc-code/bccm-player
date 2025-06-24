import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player_example/examples/drm_player.dart';
import 'package:bccm_player_example/examples/preload_players.dart';
import 'package:bccm_player_example/examples/queue.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'examples/custom_controls.dart';
import 'examples/downloader.dart';
import 'examples/list_of_players.dart';
import 'examples/native_controls.dart';
import 'examples/playground.dart';
import 'examples/simple_player.dart';

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
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.primaries.first,
            title: const Text('Plugin example app', style: TextStyle(color: Colors.white)),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: CastButton(color: Colors.black),
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: double.infinity),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => QueueExample())),
                  child: Text('Queu'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => Playground())),
                  child: Text('Playground'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ListOfPlayers())),
                  child: Text('List of Players'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => SimplePlayer())),
                  child: Text('Simple Players'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => CustomControls())),
                  child: Text('Custom Controls'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => NativeControls())),
                  child: Text('Native Controls'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => Downloader())),
                  child: Text('Downloader'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => DrmPlayer())),
                  child: Text('DRM Player'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => PreloadPlayerPage())),
                  child: Text('Preload Player'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
