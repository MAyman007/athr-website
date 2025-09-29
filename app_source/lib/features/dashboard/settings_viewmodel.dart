import 'package:athr/core/locator.dart';
import 'package:athr/core/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class DomainEntry {
  final String domain;
  bool isVerified;
  String? verificationToken;

  DomainEntry({
    required this.domain,
    this.isVerified = false,
    this.verificationToken,
  });
}

class SettingsViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = locator<FirebaseService>();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Form Controllers
  final domainController = TextEditingController();
  final ipRangeController = TextEditingController();
  final keywordController = TextEditingController();
  final coworkerEmailController = TextEditingController();

  // State
  List<DomainEntry> _domains = [];
  List<DomainEntry> get domains => _domains;

  List<String> _ipRanges = [];
  List<String> get ipRanges => _ipRanges;

  List<String> _keywords = [];
  List<String> get keywords => _keywords;

  String _alertFrequency = 'Daily Digest';
  String get alertFrequency => _alertFrequency;

  String _rescanPeriod = '1 day';
  String get rescanPeriod => _rescanPeriod;

  String _coworkerRole = 'Member';
  String get coworkerRole => _coworkerRole;

  // Regex for validation
  final domainRegex = RegExp(
    r'^(?!-)(?!.*--)[a-zA-Z0-9-]{1,63}(?<!-)(\.[a-zA-Z]{2,})+$',
  );
  final cidrRegex = RegExp(
    r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\/([0-9]|[1-2][0-9]|3[0-2]))?$',
  );

  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final settings = await _firebaseService.getUserAndOrgSettings();
      _domains = List<String>.from(
        settings['domains'] ?? [],
      ).map((domain) => DomainEntry(domain: domain, isVerified: true)).toList();
      _ipRanges = List<String>.from(settings['ipRanges'] ?? []);
      _keywords = List<String>.from(settings['keywords'] ?? []);
      _alertFrequency = settings['alertFrequency'] ?? 'Daily Digest';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSettings() async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.updateUserAndOrgSettings(
        domains: _domains.map((d) => d.domain).toList(),
        ipRanges: _ipRanges,
        keywords: _keywords,
        alertFrequency: _alertFrequency,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // --- Chip Input Methods ---

  void addDomain() {
    _addItemToList(domainController, _domains);
  }

  void removeDomain(String domain) {
    _domains.removeWhere((d) => d.domain == domain);
    notifyListeners();
  }

  void addIpRange() {
    _addItemToList(ipRangeController, _ipRanges);
  }

  void removeIpRange(String ipRange) {
    _removeItemFromList(ipRange, _ipRanges);
  }

  void addKeyword() {
    _addItemToList(keywordController, _keywords);
  }

  void removeKeyword(String keyword) {
    _removeItemFromList(keyword, _keywords);
  }

  void _addItemToList(TextEditingController controller, List<dynamic> list) {
    final text = controller.text.trim().toLowerCase();
    if (text.isNotEmpty) {
      if (controller == domainController &&
          !_domains.any((d) => d.domain == text)) {
        _domains.add(DomainEntry(domain: text));
      } else if (controller != domainController &&
          !list.cast<String>().contains(text)) {
        list.add(text);
      }
      controller.clear();
      notifyListeners();
    }
  }

  void _removeItemFromList(String item, List<String> list) {
    list.remove(item);
    notifyListeners();
  }

  // --- Validation ---

  String? validateDomain(String? value) {
    if (value == null || value.isEmpty) return null;
    final trimmedValue = value.trim();
    if (trimmedValue.length > 100) {
      return 'Domain cannot exceed 100 characters';
    }
    if (!domainRegex.hasMatch(trimmedValue)) {
      return 'Invalid domain format';
    }
    return null;
  }

  String? validateIpRange(String? value) {
    if (value == null || value.isEmpty) return null;
    final trimmedValue = value.trim();
    if (trimmedValue.length > 45) {
      return 'IP Range cannot exceed 45 characters';
    }
    if (!cidrRegex.hasMatch(trimmedValue)) {
      return 'Invalid CIDR notation';
    }
    return null;
  }

  // --- Alerting ---
  void setAlertFrequency(String value) {
    _alertFrequency = value;
    notifyListeners();
  }

  // --- Scanning ---
  void setRescanPeriod(String value) {
    _rescanPeriod = value;
    notifyListeners();
  }

  // --- Team ---
  void setCoworkerRole(String value) {
    _coworkerRole = value;
    notifyListeners();
  }

  Future<String> inviteCoworker() async {
    final email = coworkerEmailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'Please enter a valid email address.';
    }

    // This is a fake implementation as requested.
    // In a real app, you would call a service method here.
    debugPrint('Inviting $email as a $coworkerRole...');
    await Future.delayed(const Duration(seconds: 1)); // Simulate network call
    coworkerEmailController.clear();
    notifyListeners();
    return 'Invitation sent to $email.';
  }

  // --- Domain Verification ---

  String generateDomainVerificationToken(String domain) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    final token = String.fromCharCodes(
      Iterable.generate(
        24,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    final verificationValue = 'athr-domain-verification=dv-$token';
    _domains.firstWhere((d) => d.domain == domain).verificationToken =
        verificationValue;
    notifyListeners();
    return verificationValue;
  }

  Future<void> verifyDomain(String domain) async {
    _domains.firstWhere((d) => d.domain == domain).isVerified = true;
    notifyListeners();
  }
}
