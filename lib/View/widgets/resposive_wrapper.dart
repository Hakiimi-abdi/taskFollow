import 'package:flutter/material.dart';

class ResposiveWrapper extends StatelessWidget {
  final Widget child;
  const ResposiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 450),
        child: child,
      ),
    );
  }
}
