import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'signup_viewmodel.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignupViewModel(),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatelessWidget {
  const _SignupView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignupViewModel>();

    if (viewModel.isLoading) {
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => viewModel.launchURL("../", inApp: true),
              child: const Text(
                'Athr',
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Onboarding',
              style: TextStyle(
                fontSize: 28,
                color: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
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
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  Expanded(
                    child: Stepper(
                      type: StepperType.vertical,
                      currentStep: viewModel.currentStep,
                      onStepContinue: () async {
                        final isLastStep = viewModel.currentStep == 3;
                        viewModel.onStepContinue();

                        if (viewModel.errorMessage != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(viewModel.errorMessage!)),
                          );
                          return;
                        }

                        if (isLastStep) {
                          final success = await context
                              .read<SignupViewModel>()
                              .finishOnboarding();
                          if (success && context.mounted) {
                            context.go('/dashboard');
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(viewModel.errorMessage!)),
                            );
                          }
                        }
                      },
                      onStepCancel: viewModel.onStepCancel,
                      controlsBuilder: (context, details) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            children: <Widget>[
                              ElevatedButton(
                                onPressed: details.onStepContinue,
                                child: Text(
                                  viewModel.currentStep == 3
                                      ? 'Finish'
                                      : 'Continue',
                                ),
                              ),
                              if (viewModel.currentStep > 0)
                                TextButton(
                                  onPressed: details.onStepCancel,
                                  child: const Text('Back'),
                                ),
                            ],
                          ),
                        );
                      },
                      steps: _getSteps(context),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Already have an organization profile? Log in',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Step> _getSteps(BuildContext context) {
    final viewModel = context.read<SignupViewModel>();

    return [
      Step(
        title: const Text('Create Your Secure Account'),
        content: Form(
          key: viewModel.step1Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: viewModel.organizationNameController,
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
              const SizedBox(height: 16.0),
              TextFormField(
                controller: viewModel.fullNameController,
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
              const SizedBox(height: 16.0),
              TextFormField(
                controller: viewModel.workEmailController,
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
              const SizedBox(height: 16.0),
              TextFormField(
                controller: viewModel.passwordController,
                obscureText: viewModel.isPasswordObscured,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      viewModel.isPasswordObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: viewModel.togglePasswordVisibility,
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
                    value: viewModel.passwordStrength,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      viewModel.passwordStrength > 0.8
                          ? Colors.green
                          : viewModel.passwordStrength > 0.5
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Password Strength: ${viewModel.passwordStrengthText}'),
                ],
              ),
              const SizedBox(height: 24.0),
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
                            viewModel.launchURL('../terms-of-service'),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () =>
                            viewModel.launchURL('../privacy-policy'),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ],
          ),
        ),
        isActive: viewModel.currentStep >= 0,
        state: viewModel.currentStep > 0
            ? StepState.complete
            : StepState.indexed,
      ),
      Step(
        title: const Text('Define Your Primary Assets'),
        content: Form(
          key: viewModel.step2Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the domains your organization owns. Athr will monitor for leaked credentials, code, and brand impersonation related to these domains.',
              ),
              const SizedBox(height: 16.0),
              _ChipInputSection(
                controller: viewModel.domainController,
                items: viewModel.domains,
                labelText: 'Domain',
                hintText: 'e.g., your-company.com',
                onAdd: viewModel.addDomain,
                onRemove: viewModel.removeDomain,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final trimmedValue = value.trim();
                  if (trimmedValue.length > 100) {
                    return 'Domain cannot exceed 100 characters';
                  }
                  if (!viewModel.domainRegex.hasMatch(trimmedValue)) {
                    return 'Invalid domain format';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        isActive: viewModel.currentStep >= 1,
        state: viewModel.currentStep > 1
            ? StepState.complete
            : StepState.indexed,
      ),
      Step(
        title: const Text('Add High-Value Assets'),
        content: Form(
          key: viewModel.step3Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IP Ranges (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Monitor for mentions in threat intelligence feeds, malware logs, and public vulnerability scans.',
              ),
              const SizedBox(height: 16.0),
              _ChipInputSection(
                controller: viewModel.ipRangeController,
                items: viewModel.ipRanges,
                labelText: 'IP Range (CIDR notation)',
                hintText: 'e.g., 192.168.1.0/24',
                onAdd: viewModel.addIpRange,
                onRemove: viewModel.removeIpRange,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final trimmedValue = value.trim();
                  if (trimmedValue.length > 45) {
                    return 'IP Range cannot exceed 45 characters';
                  }
                  if (!viewModel.cidrRegex.hasMatch(trimmedValue)) {
                    return 'Invalid CIDR notation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              const Text(
                'Brand & Project Keywords (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Track mentions of internal project names or brands on code repositories, paste sites, and forums.',
              ),
              const SizedBox(height: 16.0),
              _ChipInputSection(
                controller: viewModel.keywordController,
                items: viewModel.keywords,
                labelText: 'Keyword',
                hintText: 'e.g., Project-Chimera',
                onAdd: viewModel.addKeyword,
                onRemove: viewModel.removeKeyword,
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
        isActive: viewModel.currentStep >= 2,
        state: viewModel.currentStep > 2
            ? StepState.complete
            : StepState.indexed,
      ),
      Step(
        title: const Text('Configure Your Alerts'),
        content: Form(
          key: viewModel.step4Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Where should we send critical alerts?'),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: viewModel.primaryEmailController,
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
              const SizedBox(height: 16.0),
              TextFormField(
                controller: viewModel.secondaryEmailController,
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
              const SizedBox(height: 24.0),
              const Text(
                'Set frequency for non-critical summary reports.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RadioListTile<String>(
                title: const Text('Instant'),
                subtitle: const Text('Receive alerts as they happen.'),
                value: 'Instant',
                groupValue: viewModel.alertFrequency,
                onChanged: (value) => viewModel.setAlertFrequency(value!),
              ),
              RadioListTile<String>(
                title: const Text('Daily Digest'),
                subtitle: const Text('A summary of all alerts once a day.'),
                value: 'Daily Digest',
                groupValue: viewModel.alertFrequency,
                onChanged: (value) => viewModel.setAlertFrequency(value!),
              ),
              RadioListTile<String>(
                title: const Text('Weekly Summary'),
                subtitle: const Text('A single report summarizing the week.'),
                value: 'Weekly Summary',
                groupValue: viewModel.alertFrequency,
                onChanged: (value) => viewModel.setAlertFrequency(value!),
              ),
            ],
          ),
        ),
        isActive: viewModel.currentStep >= 3,
        state: viewModel.currentStep >= 3
            ? StepState.indexed
            : StepState.disabled,
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
            const SizedBox(width: 8.0),
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
