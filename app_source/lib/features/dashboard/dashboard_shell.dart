import 'package:flutter/material.dart';

/// A shell widget for the dashboard section of the app.
/// It provides a consistent layout and can hold shared state.
class DashboardShell extends StatelessWidget {
  final Widget child;

  const DashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
