import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ATHR Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              child: SizedBox(
                width: 200,
                height: 100,
                child: Center(child: Text('Report 1')),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: SizedBox(
                width: 200,
                height: 100,
                child: Center(child: Text('Report 2')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
