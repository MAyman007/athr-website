import 'package:athr/core/models/incident.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:athr/core/locator.dart';
import 'package:athr/core/services/firebase_service.dart';
import 'package:fl_chart/fl_chart.dart';

import 'dashboard_viewmodel.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Create the ViewModel and immediately call loadData().
      create: (context) => DashboardViewModel()..loadData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            // Add a refresh button to allow manual data reloading
            Consumer<DashboardViewModel>(
              builder: (context, viewModel, child) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: viewModel.isLoading ? null : viewModel.loadData,
                );
              },
            ),
            // Settings Button
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                context.push('/dashboard/settings');
              },
            ),
            // Logout Button
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final bool? didRequestLogout = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                        ),
                        TextButton(
                          child: const Text('Logout'),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                        ),
                      ],
                    );
                  },
                );
                if (didRequestLogout == true) {
                  locator<FirebaseService>().signOut();
                }
              },
            ),
          ],
        ),
        body: Consumer<DashboardViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.incidents.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${viewModel.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: viewModel.loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Key Metrics Section
                    Wrap(
                      spacing: 16.0,
                      runSpacing: 16.0,
                      children: [
                        _MetricCard(
                          title: 'Total Incidents',
                          value: viewModel.totalIncidents.toString(),
                          icon: Icons.warning_amber_rounded,
                          color: Colors.orange,
                        ),
                        _MetricCard(
                          title: 'Leaked Credentials',
                          value: viewModel.totalLeakedCredentials.toString(),
                          icon: Icons.key_off_outlined,
                          color: Colors.red,
                        ),
                        _MetricCard(
                          title: 'Compromised Machines',
                          value: viewModel.totalCompromisedMachines.toString(),
                          icon: Icons.computer_outlined,
                          color: Colors.blue,
                        ),
                        _MetricCard(
                          title: 'High Severity',
                          value: viewModel.highSeverityCount.toString(),
                          icon: Icons.security_update_warning,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Charts Section
                    Text(
                      'Incidents by Severity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 250,
                      width: double.infinity,
                      child: _SeverityPieChart(viewModel: viewModel),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Incidents by Category',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 250,
                      width: double.infinity,
                      child: _CategoryBarChart(viewModel: viewModel),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A pie chart that displays the distribution of incidents by severity.
class _SeverityPieChart extends StatelessWidget {
  final DashboardViewModel viewModel;

  const _SeverityPieChart({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final sections = viewModel.incidentsBySeverity.entries.map((entry) {
      final severity = entry.key;
      final count = entry.value;

      return PieChartSectionData(
        color: severity.color,
        value: count.toDouble(),
        title: '$count',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
    }).toList();

    if (sections.isEmpty) {
      return const Center(child: Text('No severity data available.'));
    }

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // You can handle touch events here if needed
          },
        ),
      ),
    );
  }
}

/// A bar chart that displays the distribution of incidents by category.
class _CategoryBarChart extends StatelessWidget {
  final DashboardViewModel viewModel;

  const _CategoryBarChart({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final categoryEntries = viewModel.incidentsByCategory.entries.toList();

    if (categoryEntries.isEmpty) {
      return const Center(child: Text('No category data available.'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            categoryEntries
                .map((e) => e.value)
                .reduce((a, b) => a > b ? a : b) *
            1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final categoryName = categoryEntries[groupIndex].key;
              return BarTooltipItem(
                '$categoryName\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: (rod.toY - 1).toString(),
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = meta.axisPosition.toInt();
                if (index >= 0 && index < categoryEntries.length) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 4.0,
                    child: Text(
                      categoryEntries[index].key,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return Container();
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: categoryEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.value.toDouble() + 1,
                color: Theme.of(context).primaryColor,
                width: 16,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// A reusable card widget for displaying a key metric.
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 2,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
