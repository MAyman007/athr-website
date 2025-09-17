import 'package:athr/core/services/ip_info_service.dart';
import 'package:athr/features/auth/access_denied_page.dart';
import 'package:flutter/material.dart';

class GatekeeperPage extends StatefulWidget {
  final Widget child;
  const GatekeeperPage({super.key, required this.child});

  @override
  State<GatekeeperPage> createState() => _GatekeeperPageState();
}

class _GatekeeperPageState extends State<GatekeeperPage> {
  late Future<Map<String, dynamic>> _ipCheckFuture;
  final IpInfoService _ipInfoService = IpInfoService();

  @override
  void initState() {
    super.initState();
    _ipCheckFuture = _ipInfoService.fetchAccessDecision();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _ipCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While the check is in progress, show a loading indicator.
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // On error or no data, we default to granting access as a failsafe.
        if (snapshot.hasError || !snapshot.hasData) {
          return widget.child;
        }

        final bool accessGranted = snapshot.data?['access_granted'] ?? false;
        final String reason =
            snapshot.data?['reason'] ?? 'An unknown error occurred.';

        return accessGranted ? widget.child : AccessDeniedPage(reason: reason);
      },
    );
  }
}
