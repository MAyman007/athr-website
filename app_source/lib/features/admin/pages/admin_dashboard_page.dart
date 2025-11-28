import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../viewmodels/admin_dashboard_viewmodel.dart';
import '../../../core/locator.dart';
import '../../../core/services/admin_auth_service.dart';
import 'package:go_router/go_router.dart';
import 'admin_settings_page.dart';
import 'admin_orgs_page.dart';
import 'admin_users_page.dart';
import 'admin_incidents_page.dart';
import 'crawler_stats_tab.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminDashboardViewModel()..fetchStats(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
                Tab(text: 'Crawlers Stats', icon: Icon(Icons.bug_report)),
              ],
            ),
            toolbarHeight: 75,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/athr_logo.png', height: 50),
                const SizedBox(width: 16),
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 22,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            actions: [
              // Refresh Button
              Consumer<AdminDashboardViewModel>(
                builder: (context, viewModel, child) {
                  return IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Data',
                    onPressed: viewModel.isLoading ? null : viewModel.refresh,
                  );
                },
              ),
              // Settings Button
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Admin Settings',
                onPressed: () => _showAdminSettings(context),
              ),
              const VerticalDivider(indent: 12, endIndent: 12),
              // Logout Button
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sign Out',
                onPressed: () => _showSignOutDialog(context),
              ),
            ],
          ),
          body: TabBarView(
            children: [
              Consumer<AdminDashboardViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading && viewModel.stats == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (viewModel.errorMessage != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${viewModel.errorMessage}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: viewModel.refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final stats = viewModel.stats;
                  if (stats == null) {
                    return const Center(child: Text('No data available'));
                  }

                  return RefreshIndicator(
                    onRefresh: () => viewModel.fetchStats(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Metric cards
                          Wrap(
                            spacing: 16.0,
                            runSpacing: 16.0,
                            children: [
                              _MetricCard(
                                title: 'Total Organizations',
                                value: stats.totalOrganizations.toString(),
                                icon: Icons.business_rounded,
                                color: Colors.orange,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const AdminOrgsPage(),
                                  ),
                                ),
                              ),
                              _MetricCard(
                                title: 'Total Users',
                                value: stats.totalUsers.toString(),
                                icon: Icons.people_rounded,
                                color: Colors.blue,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AdminUsersPage(),
                                  ),
                                ),
                              ),
                              _MetricCard(
                                title: 'Total Incidents',
                                value: stats.totalIncidents.toString(),
                                icon: Icons.warning_amber_rounded,
                                color: Colors.purple,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AdminIncidentsPage(),
                                  ),
                                ),
                              ),
                              _MetricCard(
                                title: 'Avg Users/Org',
                                value: viewModel.averageUsersPerOrg
                                    .toStringAsFixed(1),
                                icon: Icons.analytics_rounded,
                                color: Colors.green,
                                onTap: () => _showPlatformInsightsDialog(
                                  context,
                                  viewModel,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),

                          // Charts Section
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 900) {
                                // Wide layout: Charts in rows
                                return Column(
                                  children: [
                                    // First row of charts
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildPlanDistributionChart(
                                            viewModel,
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: _buildTopOrganizationsByUsers(
                                            viewModel,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    // Second row of charts
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child:
                                              _buildTopOrganizationsByIncidents(
                                                viewModel,
                                              ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: _buildLoginActivityChart(
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
                                  children: [
                                    _buildPlanDistributionChart(viewModel),
                                    const SizedBox(height: 24),
                                    _buildTopOrganizationsByUsers(viewModel),
                                    const SizedBox(height: 24),
                                    _buildTopOrganizationsByIncidents(
                                      viewModel,
                                    ),
                                    const SizedBox(height: 24),
                                    _buildLoginActivityChart(viewModel),
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
              const CrawlerStatsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanDistributionChart(AdminDashboardViewModel viewModel) {
    final planData = viewModel.organizationsByPlan;
    if (planData.isEmpty) {
      return const _ChartSection(
        title: 'Organizations by Plan',
        child: Center(child: Text('No data available')),
      );
    }

    return _ChartSection(
      title: 'Organizations by Plan',
      child: SizedBox(height: 300, child: _PlanPieChart(data: planData)),
    );
  }

  Widget _buildTopOrganizationsByUsers(AdminDashboardViewModel viewModel) {
    final userData = viewModel.topOrganizationsByUsers;
    if (userData.isEmpty) {
      return const _ChartSection(
        title: 'Top Organizations by Users',
        child: Center(child: Text('No data available')),
      );
    }

    return _ChartSection(
      title: 'Top Organizations by Users',
      child: SizedBox(
        height: 300,
        child: _HorizontalBarChart(data: userData, color: Colors.blue),
      ),
    );
  }

  Widget _buildTopOrganizationsByIncidents(AdminDashboardViewModel viewModel) {
    final incidentData = viewModel.topOrganizationsByIncidents;
    if (incidentData.isEmpty) {
      return const _ChartSection(
        title: 'Top Organizations by Incidents',
        child: Center(child: Text('No data available')),
      );
    }

    return _ChartSection(
      title: 'Top Organizations by Incidents',
      child: SizedBox(
        height: 300,
        child: _HorizontalBarChart(data: incidentData, color: Colors.purple),
      ),
    );
  }

  Widget _buildLoginActivityChart(AdminDashboardViewModel viewModel) {
    final loginData = viewModel.loginActivityByDate;
    if (loginData.isEmpty) {
      return const _ChartSection(
        title: 'User Login Activity (Last 30 Days)',
        child: Center(child: Text('No login data available')),
      );
    }

    return _ChartSection(
      title: 'User Login Activity (Last 30 Days)',
      child: SizedBox(
        height: 300,
        child: _LoginActivityLineChart(data: loginData),
      ),
    );
  }

  void _showPlatformInsightsDialog(
    BuildContext context,
    AdminDashboardViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Platform Insights',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _InsightRow(
                    icon: Icons.apartment,
                    label: 'Organizations',
                    value: viewModel.organizations.length.toString(),
                    color: Colors.orange,
                  ),
                  const Divider(height: 24),
                  _InsightRow(
                    icon: Icons.person_outline,
                    label: 'Average Users per Org',
                    value: viewModel.averageUsersPerOrg.toStringAsFixed(1),
                    color: Colors.blue,
                  ),
                  const Divider(height: 24),
                  _InsightRow(
                    icon: Icons.warning_amber_outlined,
                    label: 'Average Incidents per Org',
                    value: viewModel.averageIncidentsPerOrg.toStringAsFixed(1),
                    color: Colors.purple,
                  ),
                  const Divider(height: 24),
                  _InsightRow(
                    icon: Icons.trending_up,
                    label: 'Total Platform Users',
                    value: (viewModel.stats?.totalUsers ?? 0).toString(),
                    color: Colors.green,
                  ),
                  const Divider(height: 24),
                  _InsightRow(
                    icon: Icons.security,
                    label: 'Total Incidents Tracked',
                    value: (viewModel.stats?.totalIncidents ?? 0).toString(),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context) async {
    final bool? didRequestLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (didRequestLogout == true && context.mounted) {
      await locator<AdminAuthService>().signOut();
      if (context.mounted) {
        context.go('/admin/login');
      }
    }
  }

  void _showAdminSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AdminSettingsPage()));
  }
}

// Chart section wrapper
class _ChartSection extends StatefulWidget {
  final String title;
  final Widget child;

  const _ChartSection({required this.title, required this.child});

  @override
  State<_ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<_ChartSection> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        child: Card(
          elevation: _isHovered ? 8 : 2,
          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  widget.child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Insight row for system health card
class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Plan distribution pie chart
class _PlanPieChart extends StatefulWidget {
  final Map<String, int> data;

  const _PlanPieChart({required this.data});

  @override
  State<_PlanPieChart> createState() => _PlanPieChartState();
}

class _PlanPieChartState extends State<_PlanPieChart> {
  int? _touchedIndex;
  int? _lastTouchedIndex;
  bool _isTooltipHovered = false;
  Timer? _clearTimer;

  static const List<Color> _planColors = [
    Color(0xFF9C27B0), // Purple - Enterprise
    Color(0xFF2196F3), // Blue - Professional
    Color(0xFF4CAF50), // Green - Basic
    Color(0xFFFF9800), // Orange - Other
  ];

  void _scheduleClearLastIndex([int ms = 220]) {
    _clearTimer?.cancel();
    _clearTimer = Timer(Duration(milliseconds: ms), () {
      if (!_isTooltipHovered && _touchedIndex == null) {
        setState(() {
          _lastTouchedIndex = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList();
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);
    final displayIndex = _touchedIndex ?? _lastTouchedIndex;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: entries.asMap().entries.map((mapEntry) {
                    final index = mapEntry.key;
                    final entry = mapEntry.value;
                    final isTouched = _touchedIndex == index;
                    final color = _planColors[index % _planColors.length];

                    return PieChartSectionData(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.7), color],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      value: entry.value.toDouble(),
                      title: entry.value.toString(),
                      radius: isTouched ? 110 : 100,
                      titleStyle: TextStyle(
                        fontSize: isTouched ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 2),
                        ],
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _lastTouchedIndex = _touchedIndex;
                          _touchedIndex = null;
                          _scheduleClearLastIndex();
                        } else {
                          _clearTimer?.cancel();
                          _touchedIndex = pieTouchResponse
                              .touchedSection!
                              .touchedSectionIndex;
                          _lastTouchedIndex = _touchedIndex;
                        }
                      });
                    },
                  ),
                ),
              ),
              // Custom tooltip overlay
              if (displayIndex != null &&
                  displayIndex >= 0 &&
                  displayIndex < entries.length)
                Positioned(
                  top: 16,
                  child: MouseRegion(
                    onEnter: (_) {
                      _clearTimer?.cancel();
                      setState(() {
                        _isTooltipHovered = true;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        _isTooltipHovered = false;
                      });
                      _scheduleClearLastIndex();
                    },
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade800,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color:
                                    _planColors[displayIndex %
                                        _planColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entries[displayIndex].key,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${entries[displayIndex].value} org${entries[displayIndex].value != 1 ? 's' : ''} '
                                  '(${(entries[displayIndex].value / total * 100).toStringAsFixed(1)}%)',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.asMap().entries.map((mapEntry) {
              final index = mapEntry.key;
              final entry = mapEntry.value;
              final color = _planColors[index % _planColors.length];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// Horizontal bar chart
class _HorizontalBarChart extends StatefulWidget {
  final Map<String, int> data;
  final Color color;

  const _HorizontalBarChart({required this.data, required this.color});

  @override
  State<_HorizontalBarChart> createState() => _HorizontalBarChartState();
}

class _HorizontalBarChartState extends State<_HorizontalBarChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList();
    if (entries.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxValue = entries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue.toDouble() * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  response == null ||
                  response.spot == null) {
                _touchedIndex = null;
              } else {
                _touchedIndex = response.spot!.touchedBarGroupIndex;
              }
            });
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = entries[groupIndex];
              return BarTooltipItem(
                '${entry.key}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '${entry.value}',
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
                if (index >= 0 && index < entries.length) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 8.0,
                    child: Text(
                      entries[index].key,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return Container();
              },
              reservedSize: 60,
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
        barGroups: entries.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final isTouched = _touchedIndex == index;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.value.toDouble(),
                gradient: LinearGradient(
                  colors: [widget.color.withOpacity(0.7), widget.color],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: isTouched ? 24 : 18,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MetricCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        setState(() => _isHovered = true);
        if (widget.onTap != null) _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        if (widget.onTap != null) _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 280,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isHovered
                    ? [
                        widget.color.withOpacity(0.15),
                        widget.color.withOpacity(0.05),
                      ]
                    : [
                        widget.color.withOpacity(0.1),
                        widget.color.withOpacity(0.02),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? widget.color.withOpacity(0.5)
                    : widget.color.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(widget.icon, size: 40, color: widget.color),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(_isHovered ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, size: 28, color: widget.color),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.value,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Login Activity Line Chart
class _LoginActivityLineChart extends StatefulWidget {
  final Map<DateTime, int> data;

  const _LoginActivityLineChart({required this.data});

  @override
  State<_LoginActivityLineChart> createState() =>
      _LoginActivityLineChartState();
}

class _LoginActivityLineChartState extends State<_LoginActivityLineChart>
    with TickerProviderStateMixin {
  int? _touchedIndex;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for data points
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.4,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.4,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_pulseController);

    // Shimmer effect for the line
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Glow effect
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Color animation for gradient
    _colorAnimation =
        ColorTween(
          begin: const Color(0xFF2196F3),
          end: const Color(0xFF00BCD4),
        ).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList();
    if (entries.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Convert to FlSpot for line chart
    final spots = <FlSpot>[];
    for (var i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].value.toDouble()));
    }

    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final maxYValue = maxY + (maxY * 0.1); // Add 10% padding

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _shimmerAnimation,
        _glowAnimation,
      ]),
      builder: (context, child) {
        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxYValue / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: _touchedIndex != null
                      ? Colors.grey[300]!.withOpacity(0.8)
                      : Colors.grey[300]!,
                  strokeWidth: _touchedIndex != null ? 1.5 : 1,
                );
              },
            ),
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
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    final date = entries[index].key;
                    final isTouched = _touchedIndex == index;
                    // Show every 5th date
                    if (index % 5 == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isTouched
                                ? const Color(0xFF2196F3)
                                : Colors.grey[600]!,
                            fontSize: isTouched ? 12 : 11,
                            fontWeight: isTouched
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          child: Text('${date.day}/${date.month}'),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxYValue / 5,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
                left: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            minX: 0,
            maxX: (entries.length - 1).toDouble(),
            minY: 0,
            maxY: maxYValue,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                gradient: LinearGradient(
                  colors: _touchedIndex != null
                      ? [
                          _colorAnimation.value ?? const Color(0xFF1976D2),
                          const Color(0xFF2196F3),
                          const Color(0xFF00BCD4),
                        ]
                      : [const Color(0xFF2196F3), const Color(0xFF1976D2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                barWidth: _touchedIndex != null ? 5 : 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    final isTouched = _touchedIndex == index;
                    final dotRadius = isTouched
                        ? 6 * _pulseAnimation.value
                        : 4.0;

                    // Add glow effect for touched point
                    if (isTouched) {
                      return _GlowingDotPainter(
                        radius: dotRadius.toDouble(),
                        glowIntensity: _glowAnimation.value,
                        innerColor: Colors.white,
                        strokeColor:
                            _colorAnimation.value ?? const Color(0xFF1976D2),
                        strokeWidth: 3,
                      );
                    }

                    return FlDotCirclePainter(
                      radius: dotRadius.toDouble(),
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: const Color(0xFF2196F3),
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: _touchedIndex != null
                        ? [
                            const Color(
                              0xFF2196F3,
                            ).withOpacity(0.5 * _glowAnimation.value),
                            const Color(
                              0xFF00BCD4,
                            ).withOpacity(0.3 * _glowAnimation.value),
                            const Color(0xFF2196F3).withOpacity(0.05),
                          ]
                        : [
                            const Color(0xFF2196F3).withOpacity(0.3),
                            const Color(0xFF2196F3).withOpacity(0.05),
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.lineBarSpots == null ||
                      response.lineBarSpots!.isEmpty) {
                    _touchedIndex = null;
                    _pulseController.reverse();
                  } else {
                    _touchedIndex = response.lineBarSpots!.first.x.toInt();
                    _pulseController.forward();
                  }
                });
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => Colors.blueGrey.shade800,
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                tooltipMargin: 8,
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    final index = barSpot.x.toInt();
                    if (index < 0 || index >= entries.length) {
                      return null;
                    }
                    final date = entries[index].key;
                    final count = entries[index].value;
                    return LineTooltipItem(
                      '${date.day}/${date.month}/${date.year}\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: '$count login${count != 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
              getTouchedSpotIndicator:
                  (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color:
                              (_colorAnimation.value ?? const Color(0xFF2196F3))
                                  .withOpacity(0.6 * _glowAnimation.value),
                          strokeWidth: 3,
                          dashArray: [8, 4],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 10 * _pulseAnimation.value,
                              color:
                                  (_colorAnimation.value ??
                                          const Color(0xFF1976D2))
                                      .withOpacity(0.3),
                              strokeWidth: 0,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
            ),
          ),
        );
      },
    );
  }
}

// Custom glowing dot painter for fancy hover effects
class _GlowingDotPainter extends FlDotPainter {
  final double radius;
  final double glowIntensity;
  final Color innerColor;
  final Color strokeColor;
  final double strokeWidth;

  _GlowingDotPainter({
    required this.radius,
    required this.glowIntensity,
    required this.innerColor,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    // Draw outer glow layers
    final glowPaint1 = Paint()
      ..color = strokeColor.withOpacity(0.15 * glowIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offsetInCanvas, radius * 2.5, glowPaint1);

    final glowPaint2 = Paint()
      ..color = strokeColor.withOpacity(0.25 * glowIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offsetInCanvas, radius * 1.8, glowPaint2);

    final glowPaint3 = Paint()
      ..color = strokeColor.withOpacity(0.4 * glowIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offsetInCanvas, radius * 1.4, glowPaint3);

    // Draw stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(offsetInCanvas, radius, strokePaint);

    // Draw inner circle
    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offsetInCanvas, radius - strokeWidth, innerPaint);

    // Draw highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6 * glowIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      offsetInCanvas.translate(-radius * 0.3, -radius * 0.3),
      radius * 0.4,
      highlightPaint,
    );
  }

  @override
  Size getSize(FlSpot spot) {
    return Size(radius * 2.5 * 2, radius * 2.5 * 2);
  }

  @override
  Color get mainColor => innerColor;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    return this;
  }

  @override
  List<Object?> get props => [
    radius,
    glowIntensity,
    innerColor,
    strokeColor,
    strokeWidth,
  ];
}
