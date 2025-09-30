import 'package:flutter/foundation.dart';
import '../../core/locator.dart';
import '../../core/models/incident.dart';
import '../../core/services/incident_service.dart';

/// Defines the available sorting options for the incident list.
enum SortBy { severity, date }

/// Manages the state and business logic for the MetricDetailsPage.
class MetricDetailsViewModel extends ChangeNotifier {
  final IncidentService _incidentService = locator<IncidentService>();
  final String metricId;

  MetricDetailsViewModel({required this.metricId});

  // Private state
  bool _isLoading = false;
  List<Incident> _incidents = [];
  String? _errorMessage;
  int _currentPage = 1;
  static const int _pageSize = 100;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  SortBy _sortBy = SortBy.severity; // Default sort order

  // Public getters for state
  bool get isLoading => _isLoading;
  List<Incident> get incidents => _incidents;
  String? get errorMessage => _errorMessage;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  SortBy get sortBy => _sortBy;

  /// Updates the sort order and re-sorts the incident list.
  void setSortBy(SortBy newSortBy) {
    if (_sortBy == newSortBy) return;

    _sortBy = newSortBy;
    _sortIncidents();
    notifyListeners();
  }

  /// Loads the initial set of incident data based on the metricId.
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _hasMoreData = true;
    _incidents.clear();
    notifyListeners();

    try {
      final newIncidents = await _incidentService.fetchIncidents(
        page: _currentPage,
        limit: _pageSize,
        metricId: metricId == 'total-incidents' ? null : metricId,
      );
      _incidents.addAll(newIncidents);
      _sortIncidents();
      if (newIncidents.length < _pageSize) {
        _hasMoreData = false;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads the next page of incident data.
  Future<void> loadMoreData() async {
    if (_isLoading || _isLoadingMore || !_hasMoreData) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final newIncidents = await _incidentService.fetchIncidents(
        page: _currentPage,
        limit: _pageSize,
        metricId: metricId == 'total-incidents' ? null : metricId,
      );

      if (newIncidents.isEmpty || newIncidents.length < _pageSize) {
        _hasMoreData = false;
      }

      _incidents.addAll(newIncidents);
      _sortIncidents();
    } catch (e) {
      // In a real app, you might want to handle this error more gracefully
      _currentPage--; // Rollback page count on error
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Sorts incidents by severity from most to least critical.
  void _sortIncidents() {
    switch (_sortBy) {
      case SortBy.severity:
        _incidents.sort((a, b) => a.severity.index.compareTo(b.severity.index));
        break;
      case SortBy.date:
        _incidents.sort((a, b) {
          // Sort by date, newest first. Handle nulls by placing them at the end.
          if (a.postedAt == null && b.postedAt == null) return 0;
          if (a.postedAt == null) return 1;
          if (b.postedAt == null) return -1;
          return b.postedAt!.compareTo(a.postedAt!);
        });
        break;
    }
  }
}
