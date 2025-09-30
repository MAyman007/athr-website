import 'package:athr/core/models/incident.dart';
import 'package:athr/core/models/log.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dashboard_viewmodel.dart';

class MetricDetailsPage extends StatefulWidget {
  final String metricId;

  const MetricDetailsPage({super.key, required this.metricId});

  @override
  State<MetricDetailsPage> createState() => _MetricDetailsPageState();
}

enum SortBy { severity, date }

class _MetricDetailsPageState extends State<MetricDetailsPage> {
  final ScrollController _scrollController = ScrollController();

  // Local state for pagination and sorting
  List<Incident> _displayIncidents = [];
  List<Incident> _sourceIncidents = [];
  int _currentPage = 1;
  final int _pageSize = 100;
  bool _hasMoreData = true;
  SortBy _sortBy = SortBy.date;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeIncidents();
      _setupScrollListener();
    });
  }

  void _initializeIncidents() {
    final viewModel = context.read<DashboardViewModel>();
    _sourceIncidents = _getFilteredIncidents(viewModel);
    _sortIncidents();
    _loadMoreData();
  }

  void _sortIncidents() {
    switch (_sortBy) {
      case SortBy.severity:
        _sourceIncidents.sort(
          (a, b) => a.severity.index.compareTo(b.severity.index),
        );
        break;
      case SortBy.date:
        _sourceIncidents.sort((a, b) {
          if (a.postedAt == null && b.postedAt == null) return 0;
          if (a.postedAt == null) return 1;
          if (b.postedAt == null) return -1;
          return b.postedAt!.compareTo(a.postedAt!);
        });
        break;
    }
    // Reset and reload data with new sort order
    setState(() {
      _currentPage = 1;
      _displayIncidents.clear();
      _hasMoreData = true;
    });
    _loadMoreData();
  }

  void _loadMoreData() {
    final int offset = (_currentPage - 1) * _pageSize;
    if (offset >= _sourceIncidents.length) {
      setState(() => _hasMoreData = false);
      return;
    }

    final int end = (offset + _pageSize > _sourceIncidents.length)
        ? _sourceIncidents.length
        : offset + _pageSize;
    setState(() {
      _displayIncidents.addAll(_sourceIncidents.getRange(offset, end));
      _currentPage++;
      _hasMoreData = _displayIncidents.length < _sourceIncidents.length;
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // If we're at the end of the list, load more data.
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          _hasMoreData) {
        _loadMoreData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getTitle() {
    switch (widget.metricId) {
      case 'total-incidents':
        return 'Total Incidents';
      case 'leaked-credentials':
        return 'Leaked Credentials';
      case 'compromised-machines':
        return 'Compromised Machines';
      case 'high-severity':
        return 'High Severity Incidents';
      default:
        return 'Metric Details';
    }
  }

  List<Incident> _getFilteredIncidents(DashboardViewModel viewModel) {
    switch (widget.metricId) {
      case 'total-incidents':
        return viewModel.incidents;
      case 'leaked-credentials':
        return viewModel.leakedCredentialsIncidents;
      case 'compromised-machines':
        return viewModel.compromisedMachinesIncidents;
      case 'high-severity':
        return viewModel.highSeverityIncidents;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (SortBy result) {
              _sortBy = result;
              _sortIncidents();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortBy>>[
              const PopupMenuItem<SortBy>(
                value: SortBy.severity,
                child: Text('Sort by Severity'),
              ),
              const PopupMenuItem<SortBy>(
                value: SortBy.date,
                child: Text('Sort by Date'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (viewModel.isLoading && _displayIncidents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_sourceIncidents.isEmpty) {
            return Center(
              child: Text(
                'No incidents found for this category.',
                style: textTheme.titleMedium,
              ),
            );
          }

          return ListView.builder(
            // The +1 in itemCount is for the loading indicator at the bottom.
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            itemCount: _displayIncidents.length + (_hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              // If it's the last item and there's more data, show a loader.
              if (index == _displayIncidents.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              final incident = _displayIncidents[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              incident.originalFilename ?? 'Unknown File',
                              style: textTheme.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Chip(
                            label: Text(
                              incident.severity.name.toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: incident.severity.color,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        context,
                        icon: Icons.source,
                        label: 'Source',
                        value: incident.source,
                      ),
                      if (incident.postedAt != null)
                        _buildDetailRow(
                          context,
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value: DateFormat.yMMMd().format(incident.postedAt!),
                        ),
                      // Show relevant details based on the metric type
                      if (widget.metricId == 'leaked-credentials' &&
                          incident.emails.isNotEmpty)
                        ..._buildEmailDetails(context, incident.emails),
                      if (widget.metricId == 'compromised-machines' &&
                          incident.logs.isNotEmpty)
                        ..._buildMachineDetails(context, incident.logs),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open File'),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Permission denied. You do not have access to this file.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildEmailDetails(BuildContext context, List<String> emails) {
    return [
      _buildDetailRow(
        context,
        icon: Icons.email_outlined,
        label: 'Leaked Emails',
        value: emails.join(', '),
      ),
    ];
  }

  List<Widget> _buildMachineDetails(BuildContext context, List<Log> logs) {
    final widgets = <Widget>[];
    // To avoid too much clutter, we'll just show the first log's details.
    // In a real app, you might have an expandable section for multiple logs.
    if (logs.isNotEmpty) {
      final log = logs.first;
      widgets.add(
        _buildDetailRow(
          context,
          icon: Icons.computer_outlined,
          label: 'Machine Name',
          value: log.machineName,
        ),
      );
      if (log.machineIp != null) {
        widgets.add(
          _buildDetailRow(
            context,
            icon: Icons.lan_outlined,
            label: 'IP Address',
            value: log.machineIp!,
          ),
        );
      }
      if (log.machineUsername != null) {
        widgets.add(
          _buildDetailRow(
            context,
            icon: Icons.person_outline,
            label: 'Username',
            value: log.machineUsername!,
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          Text('$label: ', style: textTheme.bodyMedium),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
