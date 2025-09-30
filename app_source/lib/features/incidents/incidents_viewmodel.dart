import 'package:flutter/foundation.dart';
import 'package:athr/core/locator.dart';
import 'package:athr/core/models/incident.dart';
import 'package:athr/core/services/incident_service.dart';

/// Manages the state and business logic for the Incidents page.
class IncidentsViewModel extends ChangeNotifier {
  final IncidentService _incidentService = locator<IncidentService>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- State for Data ---
  List<Incident> _allIncidents = [];
  List<Incident> _filteredIncidents = [];

  List<Incident> get incidents => _filteredIncidents;

  // --- State for Filtering ---
  IncidentSeverity? _selectedSeverity;
  IncidentSeverity? get selectedSeverity => _selectedSeverity;

  String? _searchQuery;
  String? get searchQuery => _searchQuery;

  // --- State for Sorting ---
  int _sortColumnIndex = 1; // Default to date
  int get sortColumnIndex => _sortColumnIndex;

  bool _sortAscending = false; // Default to newest first
  bool get sortAscending => _sortAscending;

  /// Fetches all incidents and applies initial filters/sorting.
  Future<void> loadIncidents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch a large number of incidents to simulate having all data.
      _allIncidents = await _incidentService.fetchIncidents(limit: 10000);
      _applyFiltersAndSorting();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the search query and reapplies filters.
  void setSearchQuery(String? query) {
    _searchQuery = query;
    _applyFiltersAndSorting();
  }

  /// Updates the severity filter and reapplies filters.
  void setSeverityFilter(IncidentSeverity? severity) {
    _selectedSeverity = severity;
    _applyFiltersAndSorting();
  }

  /// Updates the sorting parameters and re-sorts the data.
  void setSort(int columnIndex, bool ascending) {
    _sortColumnIndex = columnIndex;
    _sortAscending = ascending;
    _applyFiltersAndSorting();
  }

  /// The core logic to filter and sort the incident list.
  void _applyFiltersAndSorting() {
    _filteredIncidents = _allIncidents.where((incident) {
      final severityMatch =
          _selectedSeverity == null || incident.severity == _selectedSeverity;
      final query = _searchQuery?.toLowerCase() ?? '';
      final queryMatch =
          query.isEmpty ||
          (incident.originalFilename?.toLowerCase().contains(query) ?? false) ||
          (incident.category?.toLowerCase().contains(query) ?? false) ||
          (incident.source.toLowerCase().contains(query));

      return severityMatch && queryMatch;
    }).toList();

    // Sorting logic
    _filteredIncidents.sort((a, b) {
      int comparison;
      switch (_sortColumnIndex) {
        case 0: // Severity
          comparison = a.severity.index.compareTo(b.severity.index);
          break;
        case 1: // Date
          comparison = (b.postedAt ?? DateTime(0)).compareTo(
            a.postedAt ?? DateTime(0),
          );
          break;
        case 2: // Filename
          comparison = (a.originalFilename ?? '').compareTo(
            b.originalFilename ?? '',
          );
          break;
        case 3: // Category
          comparison = (a.category ?? '').compareTo(b.category ?? '');
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });

    notifyListeners();
  }
}
