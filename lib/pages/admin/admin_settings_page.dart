import 'package:flutter/material.dart';
import 'package:meadowmiles/states/authstate.dart';
import 'package:provider/provider.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _notificationsEnabled = true;
  bool _autoBackupEnabled = true;
  bool _maintenanceModeEnabled = false;
  String _selectedTheme = 'System';

  final List<String> _themeOptions = ['Light', 'Dark', 'System'];

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: Text(
                            authState.currentUserModel?.name.isNotEmpty == true
                                ? authState.currentUserModel!.name[0]
                                      .toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authState.currentUserModel?.name ??
                                    'Administrator',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                authState.currentUserModel?.email ??
                                    'admin@meadowmiles.com',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Administrator',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // System Settings Section
            _buildSectionTitle('System Settings'),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: const Text(
                      'Receive admin notifications and alerts',
                    ),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                    secondary: const Icon(Icons.notifications),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Auto Backup'),
                    subtitle: const Text('Automatically backup database daily'),
                    value: _autoBackupEnabled,
                    onChanged: (value) {
                      setState(() {
                        _autoBackupEnabled = value;
                      });
                    },
                    secondary: const Icon(Icons.backup),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Maintenance Mode'),
                    subtitle: const Text('Put the app in maintenance mode'),
                    value: _maintenanceModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _maintenanceModeEnabled = value;
                      });
                      if (value) {
                        _showMaintenanceModeDialog();
                      }
                    },
                    secondary: const Icon(Icons.construction),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // App Settings Section
            _buildSectionTitle('App Settings'),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Theme'),
                    subtitle: Text('Current: $_selectedTheme'),
                    leading: const Icon(Icons.palette),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemeDialog(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Database Management'),
                    subtitle: const Text('Advanced database operations'),
                    leading: const Icon(Icons.storage),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDatabaseDialog(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('System Logs'),
                    subtitle: const Text('View application logs and errors'),
                    leading: const Icon(Icons.description),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLogsDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions Section
            _buildSectionTitle('Actions'),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Export All Data'),
                    subtitle: const Text('Download complete database backup'),
                    leading: const Icon(Icons.download, color: Colors.blue),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _exportAllData(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Clear Cache'),
                    subtitle: const Text('Clear all cached data'),
                    leading: const Icon(Icons.clear_all, color: Colors.orange),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _clearCache(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Reset Settings'),
                    subtitle: const Text('Reset all settings to default'),
                    leading: const Icon(Icons.restore, color: Colors.red),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showResetDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // App Version
            Center(
              child: Text(
                'MeadowMiles Admin v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showMaintenanceModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maintenance Mode'),
        content: const Text(
          'Enabling maintenance mode will prevent users from accessing the app. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _maintenanceModeEnabled = false;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maintenance mode enabled'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _themeOptions.map((theme) {
            return RadioListTile<String>(
              title: Text(theme),
              value: theme,
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDatabaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Database Management'),
        content: const Text(
          'Advanced database operations:\n\n'
          '• Database optimization\n'
          '• Index management\n'
          '• Query performance monitoring\n'
          '• Data integrity checks',
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

  void _showLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Logs'),
        content: const Text(
          'Log viewing functionality will be implemented here.\n\n'
          'Features:\n'
          '• Error logs\n'
          '• User activity logs\n'
          '• System performance logs\n'
          '• Security audit logs',
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

  void _exportAllData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export functionality will be implemented'),
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear all cached data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all admin settings to their default values. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notificationsEnabled = true;
                _autoBackupEnabled = true;
                _maintenanceModeEnabled = false;
                _selectedTheme = 'System';
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to default'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final authState = Provider.of<AuthState>(context, listen: false);
              await authState.signOut(context);
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/start', (route) => false);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
