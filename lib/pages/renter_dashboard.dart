import 'package:flutter/material.dart';
import 'package:meadowmiles/pages/renter/home/home_tab.dart';
import 'package:meadowmiles/pages/renter/renterbook_tab.dart';
import 'package:meadowmiles/pages/renter/renterhistory_tab.dart';
import 'package:meadowmiles/pages/renter_gps_part.dart';
import 'package:meadowmiles/states/authstate.dart';
import 'package:meadowmiles/states/appstate.dart';
import 'package:meadowmiles/states/renter_gps_state.dart';
import 'package:meadowmiles/states/location_state.dart';
import 'package:provider/provider.dart';

class RenterDashboardPage extends StatelessWidget {
  const RenterDashboardPage({super.key});

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
            content: const Text('Are you sure you want to exit MeadowMiles?'),
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
      child: const _RenterDashboardContent(),
    );
  }
}

class _RenterDashboardContent extends StatefulWidget {
  const _RenterDashboardContent();

  @override
  State<_RenterDashboardContent> createState() =>
      _RenterDashboardContentState();
}

class _RenterDashboardContentState extends State<_RenterDashboardContent> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    HomeTab(),
    RenterBookTab(),
    RenterHistoryTab(),
    RenterGpsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Start GPS state management when entering renter dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renterGpsState = Provider.of<RenterGpsState>(
        context,
        listen: false,
      );
      final appState = Provider.of<AppState>(context, listen: false);
      final locationState = Provider.of<LocationState>(context, listen: false);

      appState.setActiveDashboard('renter');
      renterGpsState.startRenterGpsSession();

      // Sync with any existing device connection from LocationState
      renterGpsState.syncWithLocationState(
        locationState.connectedDeviceId,
        locationState.connectedDeviceName,
      );

      // Set up location listener for database updates across all tabs
      locationState.addListener(_onLocationUpdate);
    });
  }

  void _onLocationUpdate() {
    if (!mounted) return;

    final locationState = Provider.of<LocationState>(context, listen: false);
    final renterGpsState = Provider.of<RenterGpsState>(context, listen: false);

    // Send location data to renter GPS state for database updates
    if (locationState.hasConnectedDevice &&
        locationState.currentLocation != null &&
        renterGpsState.hasConnectedDevice) {
      renterGpsState.updateDeviceLocation(locationState.currentLocation!);
    }
  }

  @override
  void dispose() {
    // Stop GPS state management when leaving renter dashboard
    try {
      final renterGpsState = Provider.of<RenterGpsState>(
        context,
        listen: false,
      );
      renterGpsState.stopRenterGpsSession();

      final locationState = Provider.of<LocationState>(context, listen: false);
      locationState.removeListener(_onLocationUpdate);
    } catch (e) {
      // Handle potential provider access issues during dispose
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
    final authState = Provider.of<AuthState>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MeadowMiles'),
        centerTitle: true,
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            icon: Container(
              width: 48,
              height: 48,
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
                  authState.currentUserModel?.name.isNotEmpty == true
                      ? authState.currentUserModel!.name[0].toUpperCase()
                      : 'U',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            // icon: const CircleAvatar(
            //   // backgroundImage: AssetImage('assets/profile_placeholder.png'),
            //   backgroundColor: Colors.red,
            // ),
            onPressed: () {
              // Handle profile action
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6),
        backgroundColor: Theme.of(context).colorScheme.surface,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.gps_fixed),
            label: 'GPS Device',
          ),
        ],
      ),
    );
  }
}
