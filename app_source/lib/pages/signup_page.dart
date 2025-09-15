import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Form Keys
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();
  final _step4Key = GlobalKey<FormState>();

  // Step 1: Account Details
  final _organizationNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _workEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  double _passwordStrength = 0;
  String _passwordStrengthText = 'Weak';
  bool _isPasswordObscured = true;

  // Step 2: Primary Assets
  final _domainController = TextEditingController();
  final List<String> _domains = [];

  // Step 3: High-Value Assets
  final _ipRangeController = TextEditingController();
  final List<String> _ipRanges = [];
  final _keywordController = TextEditingController();
  final List<String> _keywords = [];

  // Step 4: Alerts
  final _primaryEmailController = TextEditingController();
  final _secondaryEmailController = TextEditingController();
  String _alertFrequency = 'Daily Digest';

  // Regex for validation
  // More robust domain regex: disallows leading/trailing hyphens and IP addresses.
  final _domainRegex = RegExp(
    r'^(?!-)(?!.*--)[a-zA-Z0-9-]{1,63}(?<!-)(\.[a-zA-Z]{2,})+$',
  );
  // Stricter CIDR regex.
  final _cidrRegex = RegExp(
    r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\/([0-9]|[1-2][0-9]|3[0-2]))?$',
  );

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
    // When the email in step 1 changes, update the initial value in step 4
    _workEmailController.addListener(() {
      if (mounted) {
        setState(() {
          _primaryEmailController.text = _workEmailController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _organizationNameController.dispose();
    _fullNameController.dispose();
    _workEmailController.dispose();
    _passwordController.dispose();
    _domainController.dispose();
    _ipRangeController.dispose();
    _keywordController.dispose();
    _primaryEmailController.dispose();
    _secondaryEmailController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    String password = _passwordController.text;
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
      // Needs all 5 conditions to be strong
      strengthText = 'Strong';
    } else if (strength > 0.5) {
      strengthText = 'Medium';
    }

    setState(() {
      _passwordStrength = strength.clamp(0.0, 1.0);
      _passwordStrengthText = strengthText;
    });
  }

  void _addDomain() => _addItemToList(_domainController, _domains);
  void _removeDomain(String domain) => setState(() => _domains.remove(domain));

  void _addIpRange() => _addItemToList(_ipRangeController, _ipRanges);
  void _removeIpRange(String ipRange) =>
      setState(() => _ipRanges.remove(ipRange));

  void _addKeyword() => _addItemToList(_keywordController, _keywords);
  void _removeKeyword(String keyword) =>
      setState(() => _keywords.remove(keyword));

  void _addItemToList(TextEditingController controller, List<String> list) {
    final text = controller.text.trim();
    final formState = _getFormKeyForStep(_currentStep)?.currentState;

    // Trigger validation on the form field
    if (formState?.validate() ?? false) {
      if (text.isNotEmpty && !list.contains(text)) {
        setState(() {
          list.add(text);
          controller.clear();
        });
      }
    }
  }

  GlobalKey<FormState>? _getFormKeyForStep(int step) {
    switch (step) {
      case 0:
        return _step1Key;
      case 1:
        return _step2Key;
      case 2:
        return _step3Key;
      case 3:
        return _step4Key;
      default:
        return null;
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  void _onStepContinue() {
    bool isStepValid = false;
    switch (_currentStep) {
      case 0:
        isStepValid = _step1Key.currentState?.validate() ?? false;
        break;
      case 1:
        isStepValid = _step2Key.currentState?.validate() ?? false;
        if (_domains.isEmpty) {
          isStepValid = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least one domain.')),
          );
        }
        break;
      case 2:
        isStepValid = _step3Key.currentState?.validate() ?? false;
        break;
      case 3:
        isStepValid = _step4Key.currentState?.validate() ?? false;
        break;
    }

    if (isStepValid) {
      if (_currentStep < 3) {
        setState(() => _currentStep += 1);
      } else {
        _finishOnboarding();
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) setState(() => _currentStep -= 1);
  }

  Future<void> _finishOnboarding() async {
    if (!(_step4Key.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _workEmailController.text.trim(),
            password: _passwordController.text,
          );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('User creation failed, please try again.');
      }

      await user.updateDisplayName(_fullNameController.text.trim());
      await _createOrganizationAndUserData(user);

      if (mounted) {
        context.go('/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else {
        message = 'An error occurred. Please check your details.';
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createOrganizationAndUserData(User user) async {
    final firestore = FirebaseFirestore.instance;
    final orgRef = firestore.collection('organizations').doc();
    final userRef = firestore.collection('users').doc(user.uid);
    final batch = firestore.batch();

    batch.set(orgRef, {
      'name': _organizationNameController.text.trim(),
      'domains': _domains,
      'ipRanges': _ipRanges,
      'keywords': _keywords,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(userRef, {
      'orgId': orgRef.id,
      'email': user.email,
      'fullName': _fullNameController.text.trim(),
      'role': 'admin',
      'settings': {
        'primaryNotificationEmail': _primaryEmailController.text.trim(),
        'secondaryNotificationEmail': _secondaryEmailController.text.trim(),
        'alertFrequency': _alertFrequency,
      },
    });

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Creating your organization...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Athr',
          style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  'Athr Onboarding',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Stepper(
                    type: StepperType.vertical,
                    currentStep: _currentStep,
                    onStepContinue: _onStepContinue,
                    onStepCancel: _onStepCancel,
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Row(
                          children: <Widget>[
                            ElevatedButton(
                              onPressed: details.onStepContinue,
                              child: Text(
                                _currentStep == 3 ? 'Finish' : 'Continue',
                              ),
                            ),
                            if (_currentStep > 0)
                              TextButton(
                                onPressed: details.onStepCancel,
                                child: const Text('Back'),
                              ),
                          ],
                        ),
                      );
                    },
                    steps: _getSteps(),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Already have an organization profile? Log in',
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('Create Your Secure Account'),
        content: Form(
          key: _step1Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              TextFormField(
                controller: _organizationNameController,
                decoration: const InputDecoration(
                  labelText: 'Organization Name',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your organization name';
                  }
                  if (value.length > 100) {
                    return 'Organization name cannot exceed 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Your Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  if (value.length > 100) {
                    return 'Full name cannot exceed 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _workEmailController,
                decoration: const InputDecoration(
                  labelText: 'Your Work Email',
                  helperText: 'Please use your professional work email.',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  if (value.length > 100) {
                    return 'Email cannot exceed 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _isPasswordObscured,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordObscured = !_isPasswordObscured;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters long.';
                  }
                  if (!RegExp(r'[a-z]').hasMatch(value)) {
                    return 'Password must contain a lowercase letter.';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return 'Password must contain an uppercase letter.';
                  }
                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                    return 'Password must contain a number.';
                  }
                  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
                    return 'Password must contain a special character.';
                  }
                  if (value.length > 100) {
                    return 'Password cannot exceed 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: _passwordStrength,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _passwordStrength > 0.8
                          ? Colors.green
                          : _passwordStrength > 0.5
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Password Strength: $_passwordStrengthText'),
                ],
              ),
              const SizedBox(height: 24),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodySmall,
                  children: [
                    const TextSpan(
                      text: 'By creating an account, you agree to our ',
                    ),
                    TextSpan(
                      text: 'Terms of Service',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchURL('../terms-of-service'),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchURL('../privacy-policy'),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ],
          ),
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Define Your Primary Assets'),
        content: Form(
          key: _step2Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the domains your organization owns. Athr will monitor for leaked credentials, code, and brand impersonation related to these domains.',
              ),
              const SizedBox(height: 16),
              _ChipInputSection(
                controller: _domainController,
                items: _domains,
                labelText: 'Domain',
                hintText: 'e.g., your-company.com',
                onAdd: _addDomain,
                onRemove: _removeDomain,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final trimmedValue = value.trim();
                  if (trimmedValue.length > 100) {
                    return 'Domain cannot exceed 100 characters';
                  }
                  if (!_domainRegex.hasMatch(trimmedValue)) {
                    return 'Invalid domain format';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Add High-Value Assets'),
        content: Form(
          key: _step3Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IP Ranges',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Monitor for mentions in threat intelligence feeds, malware logs, and public vulnerability scans.',
              ),
              const SizedBox(height: 16),
              _ChipInputSection(
                controller: _ipRangeController,
                items: _ipRanges,
                labelText: 'IP Range (CIDR notation)',
                hintText: 'e.g., 192.168.1.0/24',
                onAdd: _addIpRange,
                onRemove: _removeIpRange,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final trimmedValue = value.trim();
                  if (trimmedValue.length > 45) {
                    return 'IP Range cannot exceed 45 characters';
                  }
                  if (!_cidrRegex.hasMatch(trimmedValue)) {
                    return 'Invalid CIDR notation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Brand & Project Keywords',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Track mentions of internal project names or brands on code repositories, paste sites, and forums.',
              ),
              const SizedBox(height: 16),
              _ChipInputSection(
                controller: _keywordController,
                items: _keywords,
                labelText: 'Keyword',
                hintText: 'e.g., Project-Chimera',
                onAdd: _addKeyword,
                onRemove: _removeKeyword,
                validator: (value) {
                  final trimmedValue = value?.trim() ?? '';
                  if (trimmedValue.length > 100) {
                    return 'Keyword cannot exceed 100 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Configure Your Alerts'),
        content: Form(
          key: _step4Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Where should we send critical alerts?'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _primaryEmailController,
                decoration: const InputDecoration(
                  labelText: 'Primary Notification Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  if (value.length > 100) {
                    return 'Email cannot exceed 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _secondaryEmailController,
                decoration: const InputDecoration(
                  labelText: 'Optional Secondary Email',
                  prefixIcon: Icon(Icons.group),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  if (value.length > 100) {
                    return 'Email cannot exceed 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Set frequency for non-critical summary reports.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RadioListTile<String>(
                title: const Text('Instant'),
                subtitle: const Text('Receive alerts as they happen.'),
                value: 'Instant',
                groupValue: _alertFrequency,
                onChanged: (value) => setState(() => _alertFrequency = value!),
              ),
              RadioListTile<String>(
                title: const Text('Daily Digest'),
                subtitle: const Text('A summary of all alerts once a day.'),
                value: 'Daily Digest',
                groupValue: _alertFrequency,
                onChanged: (value) => setState(() => _alertFrequency = value!),
              ),
              RadioListTile<String>(
                title: const Text('Weekly Summary'),
                subtitle: const Text('A single report summarizing the week.'),
                value: 'Weekly Summary',
                groupValue: _alertFrequency,
                onChanged: (value) => setState(() => _alertFrequency = value!),
              ),
            ],
          ),
        ),
        isActive: _currentStep >= 3,
        state: _currentStep >= 3 ? StepState.indexed : StepState.disabled,
      ),
    ];
  }
}

/// A reusable widget for text input with a list of chips.
class _ChipInputSection extends StatelessWidget {
  final TextEditingController controller;
  final List<String> items;
  final String labelText;
  final String hintText;
  final VoidCallback onAdd;
  final Function(String) onRemove;
  final String? Function(String?)? validator;

  const _ChipInputSection({
    required this.controller,
    required this.items,
    required this.labelText,
    required this.hintText,
    required this.onAdd,
    required this.onRemove,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: labelText,
                  hintText: hintText,
                  border: const OutlineInputBorder(),
                ),
                validator: validator,
                onFieldSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, size: 30),
              onPressed: onAdd,
              color: Theme.of(context).primaryColor,
              tooltip: 'Add',
            ),
          ],
        ),
        if (items.isNotEmpty) const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: items
              .map(
                (item) => Chip(
                  label: Text(item),
                  onDeleted: () => onRemove(item),
                  deleteIcon: const Icon(Icons.cancel, size: 18),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
