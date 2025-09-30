import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:athr/core/models/log.dart';

import 'package:athr/core/models/incident.dart';
import 'incidents_viewmodel.dart';

class IncidentsPage extends StatelessWidget {
  const IncidentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => IncidentsViewModel()..loadIncidents(),
      child: const _IncidentsView(),
    );
  }
}

class _IncidentsView extends StatefulWidget {
  const _IncidentsView();

  @override
  State<_IncidentsView> createState() => _IncidentsViewState();
}

class _IncidentsViewState extends State<_IncidentsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showOpenFilePasswordDialog(BuildContext context) {
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

  void _showIncidentDetailsDialog(BuildContext context, Incident incident) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(incident.originalFilename ?? 'Incident Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow('Artifact ID', incident.artifactId.toString()),
                _buildDetailRow('Source', incident.source),
                _buildDetailRow('Source Path', incident.sourcePath),
                _buildDetailRow('Severity', incident.severity.name),
                _buildDetailRow('Category', incident.category),
                _buildDetailRow('MIME Type', incident.mimeType),
                _buildDetailRow('Size', _formatSize(incident.sizeBytes)),
                _buildDetailRow('SHA256 Hash', incident.hashSha256),
                _buildDetailRow(
                  'Collected At',
                  incident.createdAt != null
                      ? DateFormat.yMMMd().add_jm().format(incident.createdAt!)
                      : null,
                ),
                _buildDetailRow(
                  'Posted At',
                  incident.postedAt != null
                      ? DateFormat.yMMMd().add_jm().format(incident.postedAt!)
                      : null,
                ),
                if (incident.emails.isNotEmpty)
                  _buildDetailRow('Emails', incident.emails.join(', ')),
                if (incident.logs.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    'Associated Logs',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final log in incident.logs) _buildLogDetails(log),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open File'),
              onPressed: () => _showOpenFilePasswordDialog(context),
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  String _formatSize(int sizeBytes) {
    if (sizeBytes < 1024) {
      return '$sizeBytes bytes';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(2)} KB';
    } else if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildLogDetails(Log log) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Machine Name', log.machineName),
            _buildDetailRow('IP Address', log.machineIp),
            _buildDetailRow('Username', log.machineUsername),
            _buildDetailRow('Country', log.machineCountry),
            _buildDetailRow('Location', log.machineLocations),
            _buildDetailRow('HWID', log.machineHwid),
            _buildDetailRow('Malware Path', log.malwarePath),
            _buildDetailRow(
              'Install Date',
              log.malwareInstallDate != null
                  ? DateFormat.yMMMd().format(log.malwareInstallDate!)
                  : null,
            ),
            _buildDetailRow('Leaked Cookies', log.leakedCookies?.toString()),
            _buildDetailRow(
              'Leaked Autofills',
              log.leakedAutofills?.toString(),
            ),
            if (log.domainsLeaked.isNotEmpty)
              _buildDetailRow('Leaked Domains', log.domainsLeaked.join(', ')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<IncidentsViewModel>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Incident Management')),
      body: Builder(
        builder: (context) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.errorMessage != null) {
            return Center(child: Text('Error: ${viewModel.errorMessage}'));
          }

          final incidentSource = _IncidentDataSource(
            incidents: viewModel.incidents,
            context: context,
            onRowTap: (incident) =>
                _showIncidentDetailsDialog(context, incident),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter & Search Incidents', style: textTheme.titleLarge),
                const SizedBox(height: 16),
                _buildFilterControls(context, viewModel),
                const SizedBox(height: 24),
                PaginatedDataTable(
                  header: const Text('All Incidents'),
                  columns: _buildDataColumns(context, viewModel),
                  source: incidentSource,
                  sortColumnIndex: viewModel.sortColumnIndex,
                  sortAscending: viewModel.sortAscending,
                  rowsPerPage: 10,
                  showCheckboxColumn: false,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterControls(
    BuildContext context,
    IncidentsViewModel viewModel,
  ) {
    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      children: [
        // Search Field
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by name, category...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.setSearchQuery(null);
                      },
                    )
                  : null,
            ),
            onChanged: (value) => viewModel.setSearchQuery(value),
          ),
        ),
        // Severity Dropdown
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<IncidentSeverity?>(
            value: viewModel.selectedSeverity,
            decoration: const InputDecoration(
              labelText: 'Severity',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Severities'),
              ),
              ...IncidentSeverity.values.map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.name[0].toUpperCase() + s.name.substring(1)),
                ),
              ),
            ],
            onChanged: (value) => viewModel.setSeverityFilter(value),
          ),
        ),
      ],
    );
  }

  List<DataColumn> _buildDataColumns(
    BuildContext context,
    IncidentsViewModel viewModel,
  ) {
    return [
      DataColumn(
        label: const Text('Severity'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Date'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Filename'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Category'),
        onSort: (columnIndex, ascending) =>
            viewModel.setSort(columnIndex, ascending),
      ),
      const DataColumn(label: Text('Source')),
    ];
  }
}

/// Data source for the PaginatedDataTable.
class _IncidentDataSource extends DataTableSource {
  final List<Incident> incidents;
  final BuildContext context;
  final void Function(Incident) onRowTap;

  _IncidentDataSource({
    required this.incidents,
    required this.context,
    required this.onRowTap,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= incidents.length) return null;
    final incident = incidents[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(
          Chip(
            label: Text(incident.severity.name.toUpperCase()),
            backgroundColor: incident.severity.color,
            labelStyle: const TextStyle(color: Colors.white),
          ),
        ),
        DataCell(
          Text(
            incident.postedAt != null
                ? DateFormat.yMd().format(incident.postedAt!)
                : 'N/A',
          ),
        ),
        DataCell(Text(incident.originalFilename ?? 'N/A')),
        DataCell(Text(incident.category ?? 'N/A')),
        DataCell(Text(incident.source)),
      ],
      onSelectChanged: (selected) {
        if (selected ?? false) onRowTap(incident);
      },
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => incidents.length;

  @override
  int get selectedRowCount => 0;
}
