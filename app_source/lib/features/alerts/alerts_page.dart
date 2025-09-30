import 'package:athr/core/models/incident.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'alerts_viewmodel.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // The DashboardViewModel already loads incidents, we can reuse that data.
      // For a more advanced app, this might have its own data loading.
      create: (context) => AlertsViewModel()..loadAlerts(),
      child: const _AlertsView(),
    );
  }
}

class _AlertsView extends StatelessWidget {
  const _AlertsView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AlertsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('New Alerts')),
      body: Builder(
        builder: (context) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(child: Text('Error: ${viewModel.errorMessage}'));
          }

          if (viewModel.unreadAlerts.isEmpty) {
            return const Center(child: Text('No new alerts.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: viewModel.unreadAlerts.length,
            itemBuilder: (context, index) {
              final alert = viewModel.unreadAlerts[index];
              return _AlertCard(alert: alert);
            },
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Incident alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: alert.severity.color),
        title: Text(
          alert.originalFilename ?? 'Unknown Incident',
          style: textTheme.titleMedium,
        ),
        subtitle: Text(
          '${alert.severity.name.toUpperCase()} | ${alert.category ?? 'Uncategorized'} | ${alert.postedAt != null ? DateFormat.yMMMd().format(alert.postedAt!) : 'N/A'}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Mark as read when tapped
          context.read<AlertsViewModel>().markAsRead(alert.artifactId);

          // Navigate to a non-existent detail page for now.
          // We will build this page in a future step.
          context.push('/dashboard/details/${alert.artifactId}');

          // Show a snackbar for feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Alert for "${alert.originalFilename}" marked as read.',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
