import 'package:flutter/foundation.dart';
import '../../core/locator.dart';
import '../../core/models/incident.dart';
import '../../core/services/incident_service.dart';

/// Manages the state and business logic for the Dashboard.
class DashboardViewModel extends ChangeNotifier {
  final IncidentService _incidentService = locator<IncidentService>();

  // Private state
  bool _isLoading = false;
  List<Incident> _incidents = [];
  String? _errorMessage;

  // Private cached metrics
  int _totalIncidents = 0;
  int _totalLeakedCredentials = 0;
  int _totalCompromisedMachines = 0;
  int _highSeverityCount = 0;
  Map<IncidentSeverity, int> _incidentsBySeverity = {};
  Map<String, int> _incidentsByCategory = {};

  // Public getters for state
  bool get isLoading => _isLoading;
  List<Incident> get incidents => _incidents;
  String? get errorMessage => _errorMessage;

  /// Loads incident data from the service and updates the state.
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _incidents = await _incidentService.fetchIncidents();
      _calculateMetrics(); // Calculate metrics once after data is fetched.
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculates and caches all the dashboard metrics.
  void _calculateMetrics() {
    _totalIncidents = _incidents.length;

    final uniqueEmails = <String>{};
    final uniqueMachines = <String>{};
    int highSeverityCount = 0;
    final severityMap = <IncidentSeverity, int>{};
    final categoryMap = <String, int>{};

    for (final incident in _incidents) {
      // Leaked Credentials
      if (incident.emails.isNotEmpty) {
        uniqueEmails.addAll(incident.emails);
      }

      // Compromised Machines
      for (final log in incident.logs) {
        uniqueMachines.add(log.machineName);
      }

      // High Severity Count
      if (incident.severity == IncidentSeverity.high ||
          incident.severity == IncidentSeverity.critical) {
        highSeverityCount++;
      }

      // Incidents by Severity
      severityMap.update(
        incident.severity,
        (count) => count + 1,
        ifAbsent: () => 1,
      );

      // Incidents by Category
      final category = incident.category ?? 'Uncategorized';
      categoryMap.update(category, (count) => count + 1, ifAbsent: () => 1);
    }

    _totalLeakedCredentials = uniqueEmails.length;
    _totalCompromisedMachines = uniqueMachines.length;
    _highSeverityCount = highSeverityCount;
    _incidentsBySeverity = severityMap;
    _incidentsByCategory = categoryMap;
  }

  // --- Calculated Metrics ---

  /// Total number of incidents fetched.
  int get totalIncidents => _totalIncidents;

  /// Total number of unique leaked credentials (emails).
  int get totalLeakedCredentials => _totalLeakedCredentials;

  /// Total number of unique compromised machines.
  int get totalCompromisedMachines => _totalCompromisedMachines;

  /// Count of incidents with 'high' or 'critical' severity.
  int get highSeverityCount => _highSeverityCount;

  /// A map of incident counts grouped by severity, suitable for charts.
  Map<IncidentSeverity, int> get incidentsBySeverity => _incidentsBySeverity;

  /// A map of incident counts grouped by category, suitable for charts.
  Map<String, int> get incidentsByCategory => _incidentsByCategory;
}
