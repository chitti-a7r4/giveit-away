import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class WebMobileFrame extends StatelessWidget {
  final Widget child;
  const WebMobileFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return Center(
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxHeight: 900),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      ),
    );
  }
}