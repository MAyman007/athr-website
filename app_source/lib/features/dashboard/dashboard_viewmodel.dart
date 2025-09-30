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

  // Private cached metric lists
  List<Incident> _leakedCredentialsIncidents = [];
  List<Incident> _compromisedMachinesIncidents = [];
  List<Incident> _highSeverityIncidents = [];
  int _uniqueEmailCount = 0;
  Map<IncidentSeverity, int> _incidentsBySeverity = {};
  Map<String, int> _incidentsByCategory = {};
  Map<String, int> _incidentsBySource = {};
  Map<String, int> _machinesByCountry = {};
  Map<String, int> _incidentsByUsername = {};
  Map<DateTime, int> _incidentsByDate = {};

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
      // Fetch all incidents for the dashboard metrics. Pagination is handled
      // by the MetricDetailsViewModel for the details page.
      _incidents = await _incidentService.fetchIncidents(limit: 10000);
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
    final leaked = <Incident>[];
    final compromised = <Incident>[];
    final highSeverity = <Incident>[];
    final severityMap = <IncidentSeverity, int>{};
    final categoryMap = <String, int>{};
    final sourceMap = <String, int>{};
    final countryMap = <String, int>{};
    final usernameMap = <String, int>{};
    final dateMap = <DateTime, int>{};
    final uniqueEmails = <String>{};

    for (final incident in _incidents) {
      // Leaked Credentials
      if (incident.emails.isNotEmpty) {
        leaked.add(incident);
        uniqueEmails.addAll(incident.emails);
      }

      // Compromised Machines
      if (incident.logs.isNotEmpty) {
        compromised.add(incident);
      }

      // High Severity Count
      if (incident.severity == IncidentSeverity.high ||
          incident.severity == IncidentSeverity.critical) {
        highSeverity.add(incident);
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

      // Incidents by Source
      sourceMap.update(
        incident.source,
        (count) => count + 1,
        ifAbsent: () => 1,
      );

      // Compromised Assets by Country & Top Affected User Accounts
      for (final log in incident.logs) {
        final country = log.machineCountry;
        if (country != null) {
          countryMap.update(country, (count) => count + 1, ifAbsent: () => 1);
        }
        final username = log.machineUsername;
        if (username != null && username.isNotEmpty) {
          usernameMap.update(username, (count) => count + 1, ifAbsent: () => 1);
        }
      }

      // Incidents by Date
      if (incident.postedAt != null) {
        final date = DateTime(
          incident.postedAt!.year,
          incident.postedAt!.month,
        );
        dateMap.update(date, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    _leakedCredentialsIncidents = leaked;
    _compromisedMachinesIncidents = compromised;
    _highSeverityIncidents = highSeverity;
    _uniqueEmailCount = uniqueEmails.length;
    _incidentsBySeverity = severityMap;
    _incidentsByCategory = categoryMap;
    _incidentsBySource = sourceMap;
    _machinesByCountry = countryMap;
    _incidentsByUsername = usernameMap;
    _incidentsByDate = dateMap;
  }

  // --- Calculated Metrics ---

  /// Total number of incidents fetched.
  int get totalIncidents => _incidents.length;

  /// Total number of unique leaked emails.
  int get totalLeakedCredentials => _uniqueEmailCount;

  /// Total number of unique compromised machines.
  int get totalCompromisedMachines => _compromisedMachinesIncidents.length;

  /// Count of incidents with 'high' or 'critical' severity.
  int get highSeverityCount => _highSeverityIncidents.length;

  List<Incident> get leakedCredentialsIncidents => _leakedCredentialsIncidents;
  List<Incident> get compromisedMachinesIncidents =>
      _compromisedMachinesIncidents;
  List<Incident> get highSeverityIncidents => _highSeverityIncidents;

  /// A map of incident counts grouped by severity, suitable for charts.
  Map<IncidentSeverity, int> get incidentsBySeverity => _incidentsBySeverity;

  /// A map of incident counts grouped by category, suitable for charts.
  Map<String, int> get incidentsByCategory => _incidentsByCategory;

  /// A map of incident counts grouped by source.
  Map<String, int> get incidentsBySource => _incidentsBySource;

  /// A map of compromised machine counts grouped by country.
  Map<String, int> get machinesByCountry => _machinesByCountry;

  /// A map of incident counts grouped by username.
  Map<String, int> get incidentsByUsername => _incidentsByUsername;

  /// A map of incident counts grouped by date.
  Map<DateTime, int> get incidentsByDate => _incidentsByDate;
}
