import 'package:athr/core/models/incident.dart';
import 'package:athr/core/models/recommendation.dart';
import 'package:athr/core/services/recommendation_service.dart';
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
              if (widget.metricId == 'compromised-machines') {
                return _CompromisedMachineCard(incident: incident);
              } else {
                return _DefaultIncidentCard(
                  incident: incident,
                  metricId: widget.metricId,
                );
              }
            },
          );
        },
      ),
    );
  }

  static _showOpenFilePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final passwordController = TextEditingController();
        return AlertDialog(
          title: const Text('Authentication Required'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'Please enter your account password to access this file.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildDialogDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.grey),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  static List<Widget> _buildEmailDetails(
    BuildContext context,
    List<String> emails,
  ) {
    return [
      _buildDetailRow(
        context,
        icon: Icons.email_outlined,
        label: 'Leaked Emails',
        value: emails.join(', '),
      ),
    ];
  }

  static Widget _buildDetailRow(
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

class _DefaultIncidentCard extends StatefulWidget {
  const _DefaultIncidentCard({required this.incident, required this.metricId});

  final Incident incident;
  final String metricId;

  @override
  State<_DefaultIncidentCard> createState() => _DefaultIncidentCardState();
}

class _DefaultIncidentCardState extends State<_DefaultIncidentCard> {
  bool _isExpanded = false;
  bool _showRecommendations = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final incident = widget.incident;

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
                    style: textTheme.labelSmall?.copyWith(color: Colors.white),
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
            _MetricDetailsPageState._buildDetailRow(
              context,
              icon: Icons.source,
              label: 'Source',
              value: incident.source,
            ),
            if (incident.postedAt != null)
              _MetricDetailsPageState._buildDetailRow(
                context,
                icon: Icons.calendar_today,
                label: 'Date',
                value: DateFormat.yMMMd().format(incident.postedAt!),
              ),
            if (incident.category != null &&
                widget.metricId != 'leaked-credentials')
              _MetricDetailsPageState._buildDetailRow(
                context,
                icon: Icons.category_outlined,
                label: 'Category',
                value: incident.category!,
              ),
            // Leaked credentials emails are important enough to show without expansion
            if (widget.metricId == 'leaked-credentials' &&
                incident.emails.isNotEmpty)
              ..._MetricDetailsPageState._buildEmailDetails(
                context,
                incident.emails,
              ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: AnimatedRotation(
                        turns: _isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.arrow_right),
                      ),
                      label: const Text('Details'),
                      onPressed: () =>
                          setState(() => _isExpanded = !_isExpanded),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open File'),
                      onPressed: () =>
                          _MetricDetailsPageState._showOpenFilePasswordDialog(
                            context,
                          ),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.recommend_outlined),
                  label: const Text('Recommended Actions'),
                  onPressed: () {
                    setState(
                      () => _showRecommendations = !_showRecommendations,
                    );
                  },
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                width: double.infinity,
                child: _isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MetricDetailsPageState._buildDialogDetailRow(
                              'SHA256 Hash',
                              incident.hashSha256,
                            ),
                            _MetricDetailsPageState._buildDialogDetailRow(
                              'Source Path',
                              incident.sourcePath,
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            if (_showRecommendations)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _RecommendedActionsSection(
                  incident: widget.incident,
                  metricId: widget.metricId,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompromisedMachineCard extends StatefulWidget {
  final Incident incident;

  const _CompromisedMachineCard({required this.incident});

  @override
  State<_CompromisedMachineCard> createState() =>
      _CompromisedMachineCardState();
}

class _CompromisedMachineCardState extends State<_CompromisedMachineCard> {
  bool _isExpanded = false;
  bool _showRecommendations = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final log = widget.incident.logs.isNotEmpty
        ? widget.incident.logs.first
        : null;

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
                    log?.machineName ?? 'Unknown Machine',
                    style: textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    widget.incident.severity.name.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(color: Colors.white),
                  ),
                  backgroundColor: widget.incident.severity.color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MetricDetailsPageState._buildDetailRow(
              context,
              icon: Icons.source,
              label: 'Source',
              value: widget.incident.source,
            ),
            if (widget.incident.postedAt != null)
              _MetricDetailsPageState._buildDetailRow(
                context,
                icon: Icons.calendar_today,
                label: 'Date',
                value: DateFormat.yMMMd().format(widget.incident.postedAt!),
              ),
            if (log != null) ...[
              _MetricDetailsPageState._buildDetailRow(
                context,
                icon: Icons.cookie_outlined,
                label: 'Leaked Cookies',
                value: (log.leakedCookies ?? 0) > 0 ? 'Yes' : 'No',
              ),
              _MetricDetailsPageState._buildDetailRow(
                context,
                icon: Icons.history_edu_outlined,
                label: 'Leaked Autofills',
                value: (log.leakedAutofills ?? 0) > 0 ? 'Yes' : 'No',
              ),
              if (widget.incident.logs.any((l) => l.domainsLeaked.isNotEmpty))
                _MetricDetailsPageState._buildDetailRow(
                  context,
                  icon: Icons.public,
                  label: 'Leaked Accounts',
                  value: widget.incident.logs
                      .expand((l) => l.domainsLeaked)
                      .toSet()
                      .join(', '),
                ),
            ],
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log != null)
                  TextButton.icon(
                    icon: AnimatedRotation(
                      turns: _isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.arrow_right),
                    ),
                    label: const Text('Details'),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.recommend_outlined),
                  label: const Text('Recommended Actions'),
                  onPressed: () {
                    setState(
                      () => _showRecommendations = !_showRecommendations,
                    );
                  },
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                width: double.infinity,
                child: _isExpanded && log != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MetricDetailsPageState._buildDialogDetailRow(
                              'IP Address',
                              log.machineIp,
                            ),
                            _MetricDetailsPageState._buildDialogDetailRow(
                              'Username',
                              log.machineUsername,
                            ),
                            _MetricDetailsPageState._buildDialogDetailRow(
                              'Country',
                              log.machineCountry,
                            ),
                            _MetricDetailsPageState._buildDialogDetailRow(
                              'Location',
                              log.machineLocations,
                            ),
                            _MetricDetailsPageState._buildDialogDetailRow(
                              'Malware Path',
                              log.malwarePath,
                            ),
                            _MetricDetailsPageState._buildDialogDetailRow(
                              'HWID',
                              log.machineHwid,
                            ),
                            _MetricDetailsPageState._buildDialogDetailRow(
                              'Malware Install Date',
                              log.malwareInstallDate != null
                                  ? DateFormat.yMMMd().format(
                                      log.malwareInstallDate!,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            if (_showRecommendations)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _RecommendedActionsSection(
                  incident: widget.incident,
                  metricId: 'compromised-machines',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedActionsSection extends StatefulWidget {
  final Incident incident;
  final String metricId;

  const _RecommendedActionsSection({
    required this.incident,
    required this.metricId,
  });

  @override
  State<_RecommendedActionsSection> createState() =>
      _RecommendedActionsSectionState();
}

class _RecommendedActionsSectionState
    extends State<_RecommendedActionsSection> {
  // Use a list of booleans to track the expansion state of each panel.
  late Future<List<Recommendation>> _recommendationsFuture;

  // Helper to get a color based on severity
  Color _getColorForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.amber.shade700;
      case 'low':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch the data only once when the widget is initialized.
    _recommendationsFuture = RecommendationService()
        .getRecommendationsForIncident(widget.incident, widget.metricId);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<List<Recommendation>>(
      future: _recommendationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final recommendations = snapshot.data ?? [];
        if (recommendations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  'Recommended Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final rec = recommendations[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.shield,
                        color: _getColorForSeverity(rec.severity),
                      ),
                      title: Text(rec.title, style: textTheme.titleMedium),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showRecommendationDialog(context, rec),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRecommendationDialog(
    BuildContext context,
    Recommendation recommendation,
  ) {
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: ListTile(
            leading: Icon(
              Icons.shield,
              color: _getColorForSeverity(recommendation.severity),
              size: 28,
            ),
            title: Text(recommendation.title, style: textTheme.titleLarge),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recommendation.summary, style: textTheme.bodyMedium),
                  const Divider(height: 24),
                  ...recommendation.steps.map(
                    (step) => ListTile(
                      leading: const Padding(
                        padding: EdgeInsets.only(left: 8.0, top: 4.0),
                        child: Icon(Icons.circle, size: 8),
                      ),
                      title: Text(step),
                      dense: true,
                    ),
                  ),
                  if (recommendation.notes != null &&
                      recommendation.notes!.isNotEmpty)
                    _buildNotesBox(context, recommendation.notes!),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
          actionsPadding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
        );
      },
    );
  }

  Widget _buildNotesBox(BuildContext context, String notes) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.secondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notes,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
