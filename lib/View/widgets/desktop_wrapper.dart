import 'package:flutter/material.dart';

class DesktopWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const DesktopWrapper({super.key, required this.child, this.maxWidth = 900});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
