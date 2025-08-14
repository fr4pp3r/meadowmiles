import 'package:flutter/material.dart';
import 'package:meadowmiles/pages/rentee/renteebook_tab.dart';
import 'package:meadowmiles/pages/rentee/renteehistory_tab.dart';
import 'package:meadowmiles/pages/rentee_gps_page.dart';
import 'package:meadowmiles/pages/revenue.dart';
import 'package:meadowmiles/pages/vehicle/vehicle_tab.dart';
import 'package:meadowmiles/states/authstate.dart';
import 'package:provider/provider.dart';

class RenteeDashboardPage extends StatefulWidget {
  const RenteeDashboardPage({super.key});

  @override
  State<RenteeDashboardPage> createState() => _RenteeDashboardPageState();
}

class _RenteeDashboardPageState extends State<RenteeDashboardPage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    RenteeBookTab(),
    RenteeHistoryTab(),
    VehicleTab(),
    RevenuePage(),
    RenteeGpsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: false);
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Owner Dashboard'),
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
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.book_online),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car),
              label: 'Vehicles',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on),
              label: 'GPS',
            ),
          ],
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
