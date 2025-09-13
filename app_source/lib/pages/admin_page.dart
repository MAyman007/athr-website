import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Page'),
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
                width: 300,
                height: 150,
                child: Center(child: Text('User Management')),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: SizedBox(
                width: 300,
                height: 150,
                child: Center(child: Text('System Settings')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
