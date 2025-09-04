import 'package:flutter/material.dart';
import 'package:meadowmiles/pages/admin/admin_users_tab.dart';
import 'package:meadowmiles/pages/admin/admin_support_tab.dart';
import 'package:meadowmiles/pages/admin/admin_data_tab.dart';
import 'package:meadowmiles/pages/admin/admin_settings_page.dart';
import 'package:meadowmiles/states/appstate.dart';
import 'package:meadowmiles/states/renter_gps_state.dart';
import 'package:provider/provider.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const AdminUsersTab(),
    const AdminSupportTab(),
    const AdminDataTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Set dashboard to admin when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      final renterGpsState = Provider.of<RenterGpsState>(
        context,
        listen: false,
      );

      appState.setActiveDashboard('admin');

      // Stop any renter GPS session that might be active
      if (renterGpsState.isActive) {
        renterGpsState.stopRenterGpsSession();
      }
    });
  }

  @override
  void dispose() {
    // Clean up when leaving admin dashboard
    try {
      final renterGpsState = Provider.of<RenterGpsState>(
        context,
        listen: false,
      );
      if (renterGpsState.isActive) {
        renterGpsState.stopRenterGpsSession();
      }
    } catch (e) {
      debugPrint('Error stopping GPS session: $e');
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text(
              'Are you sure you want to exit MeadowMiles Admin?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );

        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Admin Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          centerTitle: false,
          forceMaterialTransparency: true,
          elevation: 0,
          actions: [
            // Profile Avatar
            IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha((0.3 * 255).toInt()),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'A',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminSettingsPage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
            BottomNavigationBarItem(
              icon: Icon(Icons.support_agent),
              label: 'Support',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.storage), label: 'Data'),
          ],
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
