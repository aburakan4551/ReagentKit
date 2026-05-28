import 'package:flutter/material.dart';

/// Placeholder screen for subscription settings.
/// 
/// Intercepted and bypassed in review mode, returning an empty layout.
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox.shrink(),
      ),
    );
  }
}
