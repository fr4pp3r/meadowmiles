import 'package:flutter/material.dart';
import 'package:meadowmiles/pages/rentee/renteebook_tab.dart';
import 'package:meadowmiles/pages/rentee/renteehistory_tab.dart';
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
    Center(child: Text('Revenues')),
    Center(child: Text('Reports')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    var authState = context.watch<AuthState>();

    return WillPopScope(
      onWillPop: () async {
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
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Owner Dashboard'),
          centerTitle: true,
          forceMaterialTransparency: true,
          actions: [
            IconButton(
              icon: const CircleAvatar(
                // backgroundImage: AssetImage('assets/profile_placeholder.png'),
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                // Handle profile action
                authState.signOut(context);
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
              icon: Icon(Icons.attach_money),
              label: 'Revenues',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ],
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
