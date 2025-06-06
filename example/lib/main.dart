import 'dart:async';

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player_example/app.dart';
import 'package:flutter/material.dart';

FutureOr<void> main() async {
  await BccmPlayerInterface.instance.setup();
  // FocusDebugger.instance.activate();
  runApp(const MaterialApp(home: MyApp()));
}
