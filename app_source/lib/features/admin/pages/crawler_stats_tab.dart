import 'package:flutter/material.dart';
import '../models/crawler_stats.dart';
import '../services/crawler_service.dart';

class CrawlerStatsTab extends StatefulWidget {
  const CrawlerStatsTab({super.key});

  @override
  State<CrawlerStatsTab> createState() => _CrawlerStatsTabState();
}

class _CrawlerStatsTabState extends State<CrawlerStatsTab> {
  final CrawlerService _crawlerService = CrawlerService();
  List<Leak>? _leaks;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final leaks = await _crawlerService.getCrawlerStats();
      setState(() {
        _leaks = leaks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showLeakDetails(BuildContext context, Leak leak) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(leak.leakName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Group', leak.sourceGroup),
              _detailRow('Discovery Date', leak.discovered),
              _detailRow('Country', leak.country ?? 'Unknown'),
              const Divider(),
              const Text(
                'Source',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  // TODO: Implement URL launching
                },
                child: Text(
                  leak.linkSource,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_leaks == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Leaks Count removed
          Text(
            'Crawler Health',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Health Bar Section
                  Row(
                    children: [
                      Icon(Icons.monitor_heart, color: Colors.green.shade400),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'System Health',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const Text(
                                  '99.9%',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: 0.999,
                                minHeight: 20,
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.green.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          'HEALTHY',
                          style: TextStyle(
                            color: Colors.green.shade400,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Other Metrics
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _HealthMetric(
                        label: 'Last Crawl',
                        value: '5m 30s',
                        icon: Icons.history,
                        color: Colors.orange,
                      ),
                      _HealthMetric(
                        label: 'Pages (24h)',
                        value: '1250',
                        icon: Icons.pages,
                        color: Colors.purple,
                      ),
                      _HealthMetric(
                        label: 'Errors (24h)',
                        value: '0',
                        icon: Icons.error_outline,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Leaks (${_leaks!.length})',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _leaks!.length,
            itemBuilder: (context, index) {
              final leak = _leaks![index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  onTap: () => _showLeakDetails(context, leak),
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    child: const Icon(Icons.warning, color: Colors.red),
                  ),
                  title: Text(leak.leakName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Group: ${leak.sourceGroup}'),
                      Text('Date: ${leak.discovered}'),
                      Text(
                        'Country: ${leak.country ?? 'Unknown'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HealthMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
