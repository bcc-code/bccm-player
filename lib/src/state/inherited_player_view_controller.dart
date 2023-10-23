import 'package:flutter/material.dart';

import '../../../bccm_player.dart';

class InheritedBccmPlayerViewController extends InheritedNotifier<BccmPlayerViewController> {
  final BccmPlayerViewController controller;

  const InheritedBccmPlayerViewController({
    super.key,
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  static BccmPlayerViewController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedBccmPlayerViewController>()!.controller;
  }
}
