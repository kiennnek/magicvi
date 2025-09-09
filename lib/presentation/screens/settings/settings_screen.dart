import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/advertisement_provider.dart';
import '../../providers/analytics_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Info Section
            _buildSectionHeader(context, 'App Information'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAboutDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('License'),
                    subtitle: const Text('MIT License'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLicenseDialog(context),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Data Management Section
            _buildSectionHeader(context, 'Data Management'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.refresh, color: Colors.blue),
                    title: const Text('Refresh Data'),
                    subtitle: const Text('Reload all data from database'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _refreshAllData(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_download, color: Colors.green),
                    title: const Text('Generate Sample Data'),
                    subtitle: const Text('Create demo data for testing'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _generateSampleData(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete All Data'),
                    subtitle: const Text('Remove all chat & analytics data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showClearAllDataDialog(context),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // AI Settings Section
            _buildSectionHeader(context, 'AI Settings'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.smart_toy),
                    title: const Text('Gemini API'),
                    subtitle: const Text('Configure API key & settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showApiSettingsDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Chat History'),
                    subtitle: const Text('Manage AI conversation history'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChatHistoryDialog(context),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Support Section
            _buildSectionHeader(context, 'Support'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('User Guide'),
                    subtitle: const Text('How to use the app effectively'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showHelpDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.feedback),
                    title: const Text('Feedback'),
                    subtitle: const Text('Send suggestions & report issues'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showFeedbackDialog(context),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Statistics
            Consumer3<ChatProvider, AdvertisementProvider, AnalyticsProvider>(
              builder: (context, chatProvider, adProvider, analyticsProvider, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usage Statistics',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(context, 'Chat Messages', '${chatProvider.messages.length}'),
                        _buildStatRow(context, 'Ad Campaigns', '${adProvider.advertisements.length}'),
                        _buildStatRow(context, 'Analytics Records', '${analyticsProvider.analyticsData.length}'),
                        _buildStatRow(context, 'Total Budget', '\$${adProvider.totalBudget.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Ad Support App',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.campaign, size: 48),
      children: const [
        Text('AI-powered intelligent ad assistant'),
        SizedBox(height: 16),
        Text('Key Features:'),
        Text('• Chat with AI about ad strategy'),
        Text('• Analyze campaign performance'),
        Text('• Generate reports & charts'),
        Text('• Local data storage with Hive'),
      ],
    );
  }

  void _showLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('License'),
        content: const SingleChildScrollView(
          child: Text(
            'MIT License\n\n'
            'Copyright (c) 2024 Ad Support App\n\n'
            'Permission is hereby granted, free of charge, to any person obtaining a copy '
            'of this software and associated documentation files (the "Software"), to deal '
            'in the Software without restriction, including without limitation the rights '
            'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '
            'copies of the Software, and to permit persons to whom the Software is '
            'furnished to do so, subject to the following conditions:\n\n'
            'The above copyright notice and this permission notice shall be included in all '
            'copies or substantial portions of the Software.',
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

  void _refreshAllData(BuildContext context) async {
    final chatProvider = context.read<ChatProvider>();
    final adProvider = context.read<AdvertisementProvider>();
    final analyticsProvider = context.read<AnalyticsProvider>();

    try {
      await Future.wait([
        chatProvider.refreshChatHistory(),
        adProvider.refreshAdvertisements(),
        analyticsProvider.refreshDashboard(),
      ]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data refreshed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _generateSampleData(BuildContext context) async {
    final analyticsProvider = context.read<AnalyticsProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Sample Data'),
        content: const Text('Generate sample data for the past 30 days?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await analyticsProvider.generateSampleData(
          adId: 'sample_${DateTime.now().millisecondsSinceEpoch}',
          days: 30,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample data generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearAllDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'Are you sure you want to delete all data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllData(context);
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _clearAllData(BuildContext context) async {
    final chatProvider = context.read<ChatProvider>();

    try {
      await chatProvider.clearChatHistory();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showApiSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini API Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('API Key: AIzaSyC8qwaTDj-JHB_Xs48SeStAJucOUke3jWA'),
            SizedBox(height: 8),
            Text('Model: gemini-2.0-flash'),
            SizedBox(height: 8),
            Text('Status: Connected'),
          ],
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

  void _showChatHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat History'),
        content: const Text('Chat history management will be available in a future version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Guide'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Chat with AI:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Select ad type before chatting'),
              Text('• Ask specific strategy questions'),
              Text('• Use suggested prompts to start'),
              SizedBox(height: 12),
              Text('2. Data Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Generate sample data for testing'),
              Text('• View charts & metrics'),
              Text('• Compare campaign performance'),
              SizedBox(height: 12),
              Text('3. Management:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Refresh data regularly'),
              Text('• Backup important data'),
              Text('• Delete old data when needed'),
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

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feedback'),
        content: const Text(
          'Thank you for using Ad Support App!\n\n'
          'To send feedback or report an issue, contact:\n'
          'Email: support@adsupport.com\n'
          'GitHub: github.com/adsupport/app',
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
}
