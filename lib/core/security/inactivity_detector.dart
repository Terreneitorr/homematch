import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'inactivity_manager.dart';

class InactivityDetector extends StatefulWidget {
  final Widget child;
  const InactivityDetector({super.key, required this.child});

  @override
  State<InactivityDetector> createState() => _InactivityDetectorState();
}

class _InactivityDetectorState extends State<InactivityDetector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InactivityManager>().resetTimer();
    });
  }

  void _onUserInteraction() {
    context.read<InactivityManager>().resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserInteraction(),
      onPointerMove: (_) => _onUserInteraction(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) {
          _onUserInteraction();
          return false;
        },
        child: widget.child,
      ),
    );
  }
}