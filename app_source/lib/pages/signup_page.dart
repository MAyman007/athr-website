import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:developer' as developer;
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  int _currentStep = 0;

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

  // Step 2: Primary Assets
  final _domainController = TextEditingController();
  final List<String> _domains = [];

  // Step 3: High-Value Assets
  final _ipRangeController = TextEditingController();
  final List<String> _ipRanges = [];
  final _keywordController = TextEditingController();
  final List<String> _keywords = [];

  // Step 4: Alerts
  final _secondaryEmailController = TextEditingController();
  String _alertFrequency = 'Daily Digest';

  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
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
      if (password.length >= 8) strength += 0.3;
      if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
      if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.2;
      if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
      if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) strength += 0.1;
    }

    if (strength > 0.8) {
      strengthText = 'Strong';
    } else if (strength > 0.5) {
      strengthText = 'Medium';
    }

    setState(() {
      _passwordStrength = strength.clamp(0.0, 1.0);
      _passwordStrengthText = strengthText;
    });
  }

  void _addDomain() {
    if (_domainController.text.isNotEmpty &&
        !_domains.contains(_domainController.text)) {
      setState(() {
        _domains.add(_domainController.text);
        _domainController.clear();
      });
    }
  }

  void _removeDomain(String domain) {
    setState(() {
      _domains.remove(domain);
    });
  }

  void _addIpRange() {
    if (_ipRangeController.text.isNotEmpty &&
        !_ipRanges.contains(_ipRangeController.text)) {
      setState(() {
        _ipRanges.add(_ipRangeController.text);
        _ipRangeController.clear();
      });
    }
  }

  void _removeIpRange(String ipRange) {
    setState(() {
      _ipRanges.remove(ipRange);
    });
  }

  void _addKeyword() {
    if (_keywordController.text.isNotEmpty &&
        !_keywords.contains(_keywordController.text)) {
      setState(() {
        _keywords.add(_keywordController.text);
        _keywordController.clear();
      });
    }
  }

  void _removeKeyword(String keyword) {
    setState(() {
      _keywords.remove(keyword);
    });
  }

  Future<void> _launchURL(String url, bool isHome) async {
    final Uri uri = Uri.parse(url);
    if (isHome) {
      if (!await launchUrl(uri, webOnlyWindowName: '_self')) {
        throw 'Could not launch $url';
      }
    } else {
      if (!await launchUrl(uri)) {
        throw 'Could not launch $url';
      }
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
        if (isStepValid && _domains.isEmpty) {
          // Optionally show a snackbar if at least one domain is required
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least one domain.')),
          );
          isStepValid = false;
        }
        break;
      case 2:
        isStepValid = _step3Key.currentState?.validate() ?? false;
        if (isStepValid && _ipRanges.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least one IP range.')),
          );
          isStepValid = false;
        }
        break;
      case 3:
        isStepValid = _step4Key.currentState?.validate() ?? false;
        break;
    }

    if (isStepValid) {
      if (_currentStep < 3) {
        setState(() {
          _currentStep += 1;
        });
      } else {
        _finishOnboarding();
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  void _finishOnboarding() {
    if (_step4Key.currentState?.validate() ?? false) {
      developer.log('--- Onboarding Data ---');
      developer.log('Organization: ${_organizationNameController.text}');
      developer.log('Full Name: ${_fullNameController.text}');
      developer.log('Work Email: ${_workEmailController.text}');
      developer.log('Domains: $_domains');
      developer.log('IP Ranges: $_ipRanges');
      developer.log('Keywords: $_keywords');
      developer.log('Secondary Email: ${_secondaryEmailController.text}');
      developer.log('Alert Frequency: $_alertFrequency');
      developer.log('-----------------------');

      // Set a flag to trigger a rebuild to a loading state,
      // then navigate after the build is complete.
      setState(() {
        _isFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      // After finishing, show a loading indicator and navigate post-frame.
      // This decouples navigation from the Stepper's state transition.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/dashboard');
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _launchURL("../", true),
          child: Text(
            'Athr',
            style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
          ),
        ),
        // centerTitle: true,
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
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Stepper(
                    type: StepperType.vertical,
                    currentStep: _currentStep,
                    onStepContinue: _onStepContinue,
                    onStepCancel: _onStepCancel,
                    controlsBuilder:
                        (BuildContext context, ControlsDetails details) {
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
                  onPressed: () {
                    context.go('/login');
                  },
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
      // Step 1: Create Your Secure Account
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
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter your organization name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Your Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter your full name'
                    : null,
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
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.length < 8)
                    ? 'Password must be at least 8 characters'
                    : null,
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
                        ..onTap = () =>
                            _launchURL('../terms-of-service', false),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchURL('../privacy-policy', false),
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
      // Step 2: Define Your Primary Assets
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _domainController,
                      decoration: const InputDecoration(
                        labelText: 'Domain',
                        hintText: 'e.g., your-company.com',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, size: 30),
                    onPressed: _addDomain,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _domains
                    .map(
                      (domain) => Chip(
                        label: Text(domain),
                        onDeleted: () => _removeDomain(domain),
                        deleteIcon: const Icon(Icons.cancel),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      // Step 3: Add High-Value Assets
      Step(
        title: const Text('Add High-Value Assets'),
        content: Form(
          key: _step3Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IP Ranges
              const Text(
                'IP Ranges',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Monitor for mentions in threat intelligence feeds, malware logs, and public vulnerability scans.',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ipRangeController,
                      decoration: const InputDecoration(
                        labelText: 'IP Range (CIDR notation)',
                        hintText: 'e.g., 192.168.1.0/24',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, size: 30),
                    onPressed: _addIpRange,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _ipRanges
                    .map(
                      (ip) => Chip(
                        label: Text(ip),
                        onDeleted: () => _removeIpRange(ip),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              // Brand & Project Keywords
              const Text(
                'Brand & Project Keywords',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Track mentions of internal project names or brands on code repositories, paste sites, and forums.',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _keywordController,
                      decoration: const InputDecoration(
                        labelText: 'Keyword',
                        hintText: 'e.g., Project-Chimera',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, size: 30),
                    onPressed: _addKeyword,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _keywords
                    .map(
                      (keyword) => Chip(
                        label: Text(keyword),
                        onDeleted: () => _removeKeyword(keyword),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      // Step 4: Configure Your Alerts
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
                initialValue: _workEmailController.text,
                decoration: const InputDecoration(
                  labelText: 'Primary Notification Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
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
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
    ];
  }
}
