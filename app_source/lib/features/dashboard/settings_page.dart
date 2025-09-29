import 'package:athr/features/dashboard/settings_viewmodel.dart'
    hide DomainEntry;
import 'package:athr/features/dashboard/settings_viewmodel.dart' as vm;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsViewModel()..loadSettings(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Builder(
        builder: (context) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(child: Text('Error: ${viewModel.errorMessage}'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Monitored Domains'),
                    const _DomainManagementSection(),
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, 'Other Monitored Assets'),
                    _ChipInputSection(
                      label: 'IP Ranges (CIDR)',
                      hint: 'e.g., 192.168.1.0/24',
                      controller: viewModel.ipRangeController,
                      items: viewModel.ipRanges,
                      onAdd: viewModel.addIpRange,
                      onRemove: viewModel.removeIpRange,
                      validator: viewModel.validateIpRange,
                    ),
                    const SizedBox(height: 16),
                    _ChipInputSection(
                      label: 'Keywords',
                      hint: 'e.g., Project-Chimera',
                      controller: viewModel.keywordController,
                      items: viewModel.keywords,
                      onAdd: viewModel.addKeyword,
                      onRemove: viewModel.removeKeyword,
                    ),
                    const Divider(height: 48),
                    _buildSectionTitle(context, 'Scanning Schedule'),
                    const Text(
                      'Set the periods between each rescan for new leaks.',
                    ),
                    ...['1 hour', '3 hours', '12 hours', '1 day', '1 week']
                        .map(
                          (period) => RadioListTile<String>(
                            title: Text(period),
                            value: period,
                            groupValue: viewModel.rescanPeriod,
                            onChanged: (value) =>
                                viewModel.setRescanPeriod(value!),
                          ),
                        )
                        .toList(),
                    const Divider(height: 48),
                    _buildSectionTitle(context, 'Alerting'),
                    const Text('Frequency for non-critical summary reports.'),
                    ...['Instant', 'Daily Digest', 'Weekly Summary']
                        .map(
                          (frequency) => RadioListTile<String>(
                            title: Text(frequency),
                            value: frequency,
                            groupValue: viewModel.alertFrequency,
                            onChanged: (value) =>
                                viewModel.setAlertFrequency(value!),
                          ),
                        )
                        .toList(),
                    const Divider(height: 48),
                    _buildSectionTitle(context, 'Team'),
                    _InviteCoworkerSection(),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: viewModel.isSaving
                              ? null
                              : () async {
                                  final success = await viewModel
                                      .saveSettings();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Settings saved successfully!'
                                              : 'Failed to save settings: ${viewModel.errorMessage}',
                                        ),
                                        backgroundColor: success
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    );
                                  }
                                },
                          child: viewModel.isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _ChipInputSection extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final List<dynamic> items; // Can be List<String> or List<DomainEntry>
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final String? Function(String?)? validator;

  const _ChipInputSection({
    required this.label,
    required this.hint,
    required this.controller,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    this.validator,
  });

  @override
  State<_ChipInputSection> createState() => _ChipInputSectionState();
}

class _ChipInputSectionState extends State<_ChipInputSection> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    border: const OutlineInputBorder(),
                  ),
                  validator: widget.validator,
                  onFieldSubmitted: (_) {
                    if (_formKey.currentState?.validate() ?? false) {
                      widget.onAdd();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    widget.onAdd();
                  }
                },
                tooltip: 'Add ${widget.label}',
              ),
            ],
          ),
          if (widget.items.isNotEmpty) const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: widget.items.map((item) {
              final String label = item is vm.DomainEntry
                  ? item.domain
                  : item as String;
              return Chip(
                label: Text(label),
                onDeleted: () => widget.onRemove(label),
                avatar: widget.label == 'Domains'
                    ? const Icon(Icons.domain, size: 18)
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DomainManagementSection extends StatelessWidget {
  const _DomainManagementSection();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter the domains your organization owns. Athr will monitor for leaked credentials, code, and brand impersonation related to these domains.',
        ),
        const SizedBox(height: 16.0),
        Form(
          key: GlobalKey<FormState>(), // A local key is fine here
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: viewModel.domainController,
                  decoration: const InputDecoration(
                    labelText: 'Domain',
                    hintText: 'e.g., your-company.com',
                    border: OutlineInputBorder(),
                  ),
                  validator: viewModel.validateDomain,
                  onFieldSubmitted: (_) => viewModel.addDomain(),
                ),
              ),
              const SizedBox(width: 8.0),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: IconButton(
                  icon: const Icon(Icons.add_circle, size: 30),
                  onPressed: viewModel.addDomain,
                  color: Theme.of(context).primaryColor,
                  tooltip: 'Add Domain',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _DomainVerificationSection(),
      ],
    );
  }
}

class _DomainVerificationSection extends StatelessWidget {
  const _DomainVerificationSection();

  void _showDomainVerificationDialog(
    BuildContext context,
    vm.DomainEntry domainEntry,
  ) {
    final viewModel = context.read<SettingsViewModel>();
    final token = viewModel.generateDomainVerificationToken(domainEntry.domain);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Verify Domain: ${domainEntry.domain}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'To verify ownership, please add the following TXT record to your DNS provider:',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          token,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: token));
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard!'),
                            ),
                          );
                        },
                        tooltip: 'Copy',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Once the record is added, click "Check" to complete verification. DNS changes may take some time to propagate.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Check'),
              onPressed: () async {
                // In a real app, this would trigger a backend check.
                // Here, we just simulate success.
                await viewModel.verifyDomain(domainEntry.domain);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...viewModel.domains.map((domainEntry) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: Icon(
                domainEntry.isVerified ? Icons.check_circle : Icons.pending,
                color: domainEntry.isVerified ? Colors.green : Colors.orange,
              ),
              title: Text(domainEntry.domain),
              subtitle: Text(
                domainEntry.isVerified ? 'Verified' : 'Verification required',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!domainEntry.isVerified)
                    TextButton(
                      onPressed: () =>
                          _showDomainVerificationDialog(context, domainEntry),
                      child: const Text('Verify'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => viewModel.removeDomain(domainEntry.domain),
                    tooltip: 'Remove Domain',
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _InviteCoworkerSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invite Coworker', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: viewModel.coworkerEmailController,
                decoration: const InputDecoration(
                  hintText: 'coworker@your-company.com',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: viewModel.coworkerRole,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ['Admin', 'Member']
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (value) => viewModel.setCoworkerRole(value!),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () async {
                final message = await viewModel.inviteCoworker();
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              },
              tooltip: 'Send Invite',
            ),
          ],
        ),
      ],
    );
  }
}
