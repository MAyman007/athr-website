import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:athr/core/services/firebase_service.dart';
import 'package:athr/core/locator.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = locator<FirebaseService>();

  // Stepper State
  int _currentStep = 0;
  int get currentStep => _currentStep;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Form Keys
  final step1Key = GlobalKey<FormState>();
  final step2Key = GlobalKey<FormState>();
  final step3Key = GlobalKey<FormState>();
  final step4Key = GlobalKey<FormState>();

  // Step 1: Account Details
  final organizationNameController = TextEditingController();
  final fullNameController = TextEditingController();
  final workEmailController = TextEditingController();
  final passwordController = TextEditingController();
  double _passwordStrength = 0;
  double get passwordStrength => _passwordStrength;
  String _passwordStrengthText = 'Weak';
  String get passwordStrengthText => _passwordStrengthText;
  bool _isPasswordObscured = true;
  bool get isPasswordObscured => _isPasswordObscured;
  bool _isWorkEmailVerified = false;
  bool get isWorkEmailVerified => _isWorkEmailVerified;
  String? _verifiedWorkEmail;
  bool _isSecondaryEmailVerified = false;
  bool get isSecondaryEmailVerified => _isSecondaryEmailVerified;
  String? _verifiedSecondaryEmail;

  // Step 2: Primary Assets
  final domainController = TextEditingController();
  final List<DomainEntry> _domains = [];
  List<DomainEntry> get domains => List.unmodifiable(_domains);

  // Helper to check if all domains are verified
  bool get allDomainsVerified {
    if (_domains.isEmpty) {
      return false;
    }
    return _domains.every((d) => d.isVerified);
  }

  // Step 3: High-Value Assets
  final ipRangeController = TextEditingController();
  final List<String> _ipRanges = [];
  List<String> get ipRanges => List.unmodifiable(_ipRanges);
  final keywordController = TextEditingController();
  final List<String> _keywords = [];
  List<String> get keywords => List.unmodifiable(_keywords);

  // Step 4: Alerts
  final primaryEmailController = TextEditingController();
  final secondaryEmailController = TextEditingController();
  String _alertFrequency = 'Daily Digest';
  String get alertFrequency => _alertFrequency;

  // Regex for validation
  final domainRegex = RegExp(
    r'^(?!-)(?!.*--)[a-zA-Z0-9-]{1,63}(?<!-)(\.[a-zA-Z]{2,})+$',
  );
  final cidrRegex = RegExp(
    r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\/([0-9]|[1-2][0-9]|3[0-2]))?$',
  );

  SignupViewModel() {
    passwordController.addListener(_updatePasswordStrength);
    workEmailController.addListener(() {
      if (_verifiedWorkEmail != null) {
        // If the text is changed back to the verified email, restore its status.
        if (workEmailController.text.trim() == _verifiedWorkEmail) {
          if (!_isWorkEmailVerified) {
            _isWorkEmailVerified = true;
            notifyListeners();
          }
        } else if (_isWorkEmailVerified) {
          // If the text is changed from the verified email, invalidate it.
          _isWorkEmailVerified = false;
          notifyListeners();
        }
      }
      primaryEmailController.text = workEmailController.text;
      notifyListeners();
    });
    secondaryEmailController.addListener(() {
      if (_verifiedSecondaryEmail != null) {
        // If the text is changed back to the verified email, restore its status.
        if (secondaryEmailController.text.trim() == _verifiedSecondaryEmail) {
          if (!_isSecondaryEmailVerified) {
            _isSecondaryEmailVerified = true;
            notifyListeners();
          }
        } else if (_isSecondaryEmailVerified) {
          // If the text is changed from the verified email, invalidate it.
          _isSecondaryEmailVerified = false;
          notifyListeners();
        }
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    organizationNameController.dispose();
    fullNameController.dispose();
    workEmailController.dispose();
    passwordController.dispose();
    domainController.dispose();
    ipRangeController.dispose();
    keywordController.dispose();
    primaryEmailController.dispose();
    secondaryEmailController.dispose();
    super.dispose();
  }

  void togglePasswordVisibility() {
    _isPasswordObscured = !_isPasswordObscured;
    notifyListeners();
  }

  void _updatePasswordStrength() {
    String password = passwordController.text;
    double strength = 0;
    String strengthText = 'Weak';

    if (password.isEmpty) {
      strength = 0;
      strengthText = 'Weak';
    } else {
      if (password.length >= 8) strength += 0.2;
      if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
      if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.2;
      if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
      if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) strength += 0.2;
    }

    if (strength >= 0.9) {
      strengthText = 'Strong';
    } else if (strength > 0.5) {
      strengthText = 'Medium';
    }

    _passwordStrength = strength.clamp(0.0, 1.0);
    _passwordStrengthText = strengthText;
    notifyListeners();
  }

  void setAlertFrequency(String value) {
    _alertFrequency = value;
    notifyListeners();
  }

  void addDomain() {
    if (step2Key.currentState?.validate() ?? false) {
      final text = domainController.text.trim();
      if (text.isNotEmpty && !_domains.any((d) => d.domain == text)) {
        _domains.add(DomainEntry(domain: text));
        domainController.clear();
        notifyListeners();
      }
    }
  }

  void removeDomain(String domain) {
    _domains.removeWhere((d) => d.domain == domain);
    notifyListeners();
  }

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

  void addIpRange() => _addItemToList(ipRangeController, _ipRanges, step3Key);
  void removeIpRange(String ipRange) => _removeItemFromList(ipRange, _ipRanges);
  void addKeyword() => _addItemToList(keywordController, _keywords, step3Key);
  void removeKeyword(String keyword) => _removeItemFromList(keyword, _keywords);

  void _addItemToList(
    TextEditingController controller,
    List<String> list,
    GlobalKey<FormState> key,
  ) {
    if (key.currentState?.validate() ?? false) {
      final text = controller.text.trim();
      if (text.isNotEmpty && !list.contains(text)) {
        list.add(text);
        controller.clear();
        notifyListeners();
      }
    }
  }

  void _removeItemFromList(String item, List<String> list) {
    list.remove(item);
    notifyListeners();
  }

  void onStepContinue() {
    _errorMessage = null;
    bool isStepValid = false;
    switch (_currentStep) {
      case 0:
        isStepValid = step1Key.currentState?.validate() ?? false;
        if (isStepValid && !_isWorkEmailVerified) {
          isStepValid = false;
          _errorMessage = 'Please verify your work email.';
        }
        break;
      case 1:
        isStepValid = step2Key.currentState?.validate() ?? false;
        if (_domains.isEmpty || !allDomainsVerified) {
          isStepValid = false;
          _errorMessage = 'Please add and verify at least one domain.';
        }
        break;
      case 2:
        isStepValid = step3Key.currentState?.validate() ?? false;
        break;
      case 3:
        isStepValid = step4Key.currentState?.validate() ?? false;
        break;
    }

    if (isStepValid) {
      if (_currentStep < 3) {
        _currentStep += 1;
      } else {
        // This will be handled by the View to call finishOnboarding
      }
    }
    notifyListeners();
  }

  void onStepCancel() {
    if (_currentStep > 0) {
      _currentStep -= 1;
      notifyListeners();
    }
  }

  Future<bool> finishOnboarding() async {
    if (!(step4Key.currentState?.validate() ?? false)) {
      return false;
    }

    if (secondaryEmailController.text.trim().isNotEmpty &&
        !_isSecondaryEmailVerified) {
      _errorMessage = 'Please verify your secondary email.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await _firebaseService
          .createUserWithEmailAndPassword(
            email: workEmailController.text.trim(),
            password: passwordController.text,
          );

      final User? user = userCredential.user;
      if (user == null) throw Exception('User creation failed.');

      await _firebaseService.setupNewUserAndOrganization(
        user: user,
        fullName: fullNameController.text.trim(),
        organizationName: organizationNameController.text.trim(),
        domains: _domains.map((d) => d.domain).toList(),
        ipRanges: _ipRanges,
        keywords: _keywords,
        primaryNotificationEmail: primaryEmailController.text.trim(),
        secondaryNotificationEmail: secondaryEmailController.text.trim(),
        alertFrequency: _alertFrequency,
      );
      _isLoading = false;
      // No need to call notifyListeners() on success, as we are navigating away.
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        _errorMessage = 'An account already exists for that email.';
      } else {
        _errorMessage = 'An error occurred. Please check your details.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> launchURL(String url, {bool inApp = false}) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, webOnlyWindowName: inApp ? '_self' : '_blank')) {
      _errorMessage = 'Could not launch $url';
    }
  }

  // Mock verification. In a real app, this would involve a backend call.
  Future<bool> verifyWorkEmail(String code) async {
    _isWorkEmailVerified = true;
    _verifiedWorkEmail = workEmailController.text.trim();
    notifyListeners();
    return true;
  }

  Future<bool> verifySecondaryEmail(String code) async {
    _isSecondaryEmailVerified = true;
    _verifiedSecondaryEmail = secondaryEmailController.text.trim();
    notifyListeners();
    return true;
  }

  // Mock domain verification
  Future<bool> verifyDomain(String domain) async {
    _domains.firstWhere((d) => d.domain == domain).isVerified = true;
    notifyListeners();
    return true;
  }
}

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
