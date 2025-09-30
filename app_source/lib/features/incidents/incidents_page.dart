import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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

  _IncidentDataSource({required this.incidents, required this.context});

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
        // Navigate to detail page when a row is clicked
        // context.push('/dashboard/details/${incident.artifactId}');
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
