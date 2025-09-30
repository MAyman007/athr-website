import 'package:athr/core/models/incident.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Athr Dashboard'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          // Alerts Button
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'New Alerts',
            onPressed: () => context.push('/dashboard/alerts'),
          ),
          // Incidents Button
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: 'All Incidents',
            onPressed: () => context.push('/dashboard/incidents'),
          ),
          const VerticalDivider(indent: 12, endIndent: 12),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DashboardViewModel>().isLoading
                ? null
                : context.read<DashboardViewModel>().loadData(),
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
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                      ),
                      TextButton(
                        child: const Text('Logout'),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Key Metrics Section
                  Text(
                    'Overall Metrics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    spacing: 16.0,
                    runSpacing: 16.0,
                    children: [
                      _MetricCard(
                        title: 'Total Incidents',
                        value: viewModel.totalIncidents.toString(),
                        icon: Icons.warning_amber_rounded,
                        color: Colors.orange,
                        onTap: () =>
                            context.push('/dashboard/details/total-incidents'),
                      ),
                      _MetricCard(
                        title: 'Leaked Credentials',
                        value: viewModel.totalLeakedCredentials.toString(),
                        icon: Icons.key_off_outlined,
                        color: Colors.red,
                        onTap: () => context.push(
                          '/dashboard/details/leaked-credentials',
                        ),
                      ),
                      _MetricCard(
                        title: 'Compromised Machines',
                        value: viewModel.totalCompromisedMachines.toString(),
                        icon: Icons.computer_outlined,
                        color: Colors.blue,
                        onTap: () => context.push(
                          '/dashboard/details/compromised-machines',
                        ),
                      ),
                      _MetricCard(
                        title: 'High Severity',
                        value: viewModel.highSeverityCount.toString(),
                        icon: Icons.security_update_warning,
                        color: Colors.purple,
                        onTap: () =>
                            context.push('/dashboard/details/high-severity'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 74),

                  // Use a LayoutBuilder to create a responsive layout for charts
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
                        // Wide layout: Charts side-by-side
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildSeverityChart(
                                    context,
                                    viewModel,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _buildDateChart(context, viewModel),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildCategoryChart(
                                    context,
                                    viewModel,
                                  ),
                                ),

                                const SizedBox(width: 24),
                                Expanded(
                                  child: _buildSourceChart(context, viewModel),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildCountryChart(context, viewModel),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _buildUsernameChart(
                                    context,
                                    viewModel,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        // Narrow layout: Charts stacked
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSeverityChart(context, viewModel),
                            const SizedBox(height: 24),
                            _buildDateChart(context, viewModel),
                            const SizedBox(height: 24),
                            _buildCategoryChart(context, viewModel),
                            const SizedBox(height: 24),
                            _buildSourceChart(context, viewModel),
                            const SizedBox(height: 24),
                            _buildCountryChart(context, viewModel),
                            const SizedBox(height: 24),
                            _buildUsernameChart(context, viewModel),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeverityChart(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incidents by Severity',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(height: 250, child: _SeverityPieChart(viewModel: viewModel)),
      ],
    );
  }

  Widget _buildCategoryChart(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incidents by Category',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          width: double.infinity,
          child: _CategoryBarChart(viewModel: viewModel),
        ),
      ],
    );
  }

  Widget _buildSourceChart(BuildContext context, DashboardViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Leak Sources',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          width: double.infinity,
          child: _VerticalBarChart(
            data: viewModel.incidentsBySource,
            color: Colors.teal,
            title: 'Sources',
          ),
        ),
      ],
    );
  }

  Widget _buildCountryChart(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compromised Assets by Country',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          width: double.infinity,
          child: _VerticalBarChart(
            data: viewModel.machinesByCountry,
            color: Colors.indigo,
            title: 'Countries',
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameChart(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Affected User Accounts',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          width: double.infinity,
          child: _VerticalBarChart(
            data: viewModel.incidentsByUsername,
            color: Colors.green,
            title: 'Usernames',
          ),
        ),
      ],
    );
  }

  Widget _buildDateChart(BuildContext context, DashboardViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incidents Over Time',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          width: double.infinity,
          child: _DateLineChart(
            data: viewModel.incidentsByDate,
            color: Colors.blueAccent,
            title: 'Incidents',
          ),
        ),
      ],
    );
  }
}

/// A legend widget for the severity pie chart.
class _SeverityLegend extends StatelessWidget {
  final Map<IncidentSeverity, int> incidentsBySeverity;

  const _SeverityLegend({required this.incidentsBySeverity});

  @override
  Widget build(BuildContext context) {
    // Sort severities for a consistent order in the legend.
    final sortedEntries = incidentsBySeverity.entries.toList()
      ..sort((a, b) => b.key.index.compareTo(a.key.index));

    if (sortedEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedEntries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Container(width: 16, height: 16, color: entry.key.color),
                  const SizedBox(width: 8),
                  Text(
                    // Capitalize the first letter of the severity name.
                    '${entry.key.name[0].toUpperCase()}${entry.key.name.substring(1)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// A pie chart that displays the distribution of incidents by severity.
class _SeverityPieChart extends StatelessWidget {
  final DashboardViewModel viewModel;

  const _SeverityPieChart({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.incidentsBySeverity.isEmpty) {
      return const Center(child: Text('No severity data available.'));
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: viewModel.incidentsBySeverity.entries.map((entry) {
                final severity = entry.key;
                final count = entry.value;
                return PieChartSectionData(
                  gradient: LinearGradient(
                    colors: [severity.color.withOpacity(0.7), severity.color],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  value: count.toDouble(),
                  title: count.toString(),
                  radius: 90,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                  ),
                  borderSide: BorderSide(
                    color: Colors.black.withOpacity(0.2),
                    width: 1,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 35,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _SeverityLegend(
            incidentsBySeverity: viewModel.incidentsBySeverity,
          ),
        ),
      ],
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
            (categoryEntries
                .map((e) => e.value)
                .reduce((a, b) => a > b ? a : b)
                .toDouble() +
            3),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final categoryName = categoryEntries[groupIndex].key;
              final rodValue = (rod.toY - 1).toInt();
              return BarTooltipItem(
                '$categoryName\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '$rodValue incident${rodValue == 1 ? '' : 's'}',
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
                final index = value.toInt();
                if (index >= 0 && index < categoryEntries.length) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 8.0,
                    // angle: -0.7, // Rotate labels for better fit
                    child: Text(
                      categoryEntries[index].key,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return Container();
              },
              reservedSize: 60, // Increased size for rotated labels
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                // Don't show 0 or the top-most value which is for padding.
                if (value == 0 || value == meta.max) {
                  return Container();
                }
                // The bar values are offset by 1, so we subtract 1 here for the label.
                return Text(
                  (value - 1).toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.left,
                );
              },
            ),
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
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.7),
                    Theme.of(context).primaryColor,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// A reusable vertical bar chart widget.
class _VerticalBarChart extends StatelessWidget {
  final Map<String, int> data;
  final Color color;
  final String title;

  const _VerticalBarChart({
    required this.data,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text('No data available for $title.'));
    }

    // Sort data to show the highest values and take top 10
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(10).toList();

    final double maxY =
        topEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = topEntries[groupIndex];
              return BarTooltipItem(
                '${entry.key}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text:
                        '${entry.value} incident${entry.value == 1 ? '' : 's'}',
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
                final index = value.toInt();
                if (index >= 0 && index < topEntries.length) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 8.0,
                    // angle: -0.7, // Rotate labels for better fit
                    child: Text(
                      topEntries[index].key,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return Container();
              },
              reservedSize: 60, // Increased size for rotated labels
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: topEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.value.toDouble(),
                color: color,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// A reusable line chart widget for time-series data.
class _DateLineChart extends StatelessWidget {
  final Map<DateTime, int> data;
  final Color color;
  final String title;

  const _DateLineChart({
    required this.data,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text('No data available for $title.'));
    }

    // Sort data by date
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries
        .map(
          (entry) => FlSpot(
            entry.key.millisecondsSinceEpoch.toDouble(),
            entry.value.toDouble(),
          ),
        )
        .toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (spots.last.x - spots.first.x) / 4, // Adjust interval
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return SideTitleWidget(
                  meta: meta,
                  space: 8.0,
                  child: Text(
                    DateFormat.MMM().format(date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(colors: [color.withOpacity(0.5), color]),
            barWidth: 5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = DateTime.fromMillisecondsSinceEpoch(
                  spot.x.toInt(),
                );
                return LineTooltipItem(
                  '${DateFormat.yMMM().format(date)}\n${spot.y.toInt()} incidents',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

/// A reusable horizontal bar chart widget.
// class _HorizontalBarChart extends StatelessWidget {
//   final Map<String, int> data;
//   final Color barColor;
//   final String title;

//   const _HorizontalBarChart({
//     required this.data,
//     required this.barColor,
//     required this.title,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (data.isEmpty) {
//       return Center(child: Text('No data available for $title.'));
//     }

//     // Sort data to show the highest values on top and take top 10
//     final sortedEntries = data.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));
//     final topEntries = sortedEntries
//         .take(10)
//         .toList()
//         .reversed
//         .toList(); // Reverse for chart

//     final double maxY =
//         topEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;

//     return BarChart(
//       BarChartData(
//         alignment: BarChartAlignment.spaceAround,
//         maxY: maxY,
//         barTouchData: BarTouchData(
//           enabled: true,
//           touchTooltipData: BarTouchTooltipData(
//             getTooltipColor: (group) => Colors.blueGrey,
//             getTooltipItem: (group, groupIndex, rod, rodIndex) {
//               final entry = topEntries[groupIndex];
//               return BarTooltipItem(
//                 '${entry.key}\n',
//                 const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                 ),
//                 children: <TextSpan>[
//                   TextSpan(
//                     text:
//                         '${entry.value} incident${entry.value == 1 ? '' : 's'}',
//                     style: const TextStyle(
//                       color: Colors.yellow,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//         titlesData: FlTitlesData(
//           show: true,
//           leftTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               getTitlesWidget: (double value, TitleMeta meta) {
//                 final index = value.toInt();
//                 if (index >= 0 && index < topEntries.length) {
//                   return SideTitleWidget(
//                     meta: meta,
//                     space: 8.0,
//                     child: Text(
//                       topEntries[index].key,
//                       style: const TextStyle(fontSize: 10),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   );
//                 }
//                 return Container();
//               },
//               reservedSize: 100,
//             ),
//           ),
//           bottomTitles: const AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//           topTitles: const AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//           rightTitles: const AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//         ),
//         borderData: FlBorderData(show: false),
//         barGroups: topEntries.asMap().entries.map((entry) {
//           final index = entry.key;
//           final data = entry.value;
//           return BarChartGroupData(
//             x: index,
//             barRods: [
//               BarChartRodData(
//                 toY: data.value.toDouble(),
//                 color: barColor,
//                 width: 12,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//             ],
//           );
//         }).toList(),
//         gridData: const FlGridData(show: false),
//       ),
//       swapAnimationDuration: const Duration(milliseconds: 150),
//     );
//   }
// }

/// A reusable card widget for displaying a key metric.
class _MetricCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    // ignore: unused_element
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final duration = const Duration(milliseconds: 200);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: duration,
          width: 220,
          transform: Matrix4.translationValues(0, _isHovered ? -5 : 0, 0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: widget.color, width: 5)),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_isHovered ? 0.2 : 0.05),
                blurRadius: _isHovered ? 15 : 10,
                offset: _isHovered ? const Offset(0, 8) : const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.icon, size: 32, color: widget.color),
              const SizedBox(height: 16),
              Text(
                widget.value,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.title,
                style: textTheme.bodyMedium?.copyWith(
                  color: textTheme.bodySmall?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
