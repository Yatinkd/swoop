import 'package:flutter/material.dart';
import '../main.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(
        child: Text(
          'No new notifications',
          style: TextStyle(color: AppColors.subtle),
        ),
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Privacy')),
      body: const Center(
        child: Text(
          'Privacy settings coming soon',
          style: TextStyle(color: AppColors.subtle),
        ),
      ),
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Help Center')),
      body: const Center(
        child: Text(
          'How can we help you?',
          style: TextStyle(color: AppColors.subtle),
        ),
      ),
    );
  }
}
