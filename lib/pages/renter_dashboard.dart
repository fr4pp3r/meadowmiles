import 'package:flutter/material.dart';
import 'package:meadowmiles/appstate.dart';
import 'package:meadowmiles/pages/renter/home/home_tab.dart';
import 'package:provider/provider.dart';

class RenterDashboardPage extends StatefulWidget {
  const RenterDashboardPage({super.key});

  @override
  State<RenterDashboardPage> createState() => _RenterDashboardPageState();
}

class _RenterDashboardPageState extends State<RenterDashboardPage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    HomeTab(),
    // TODO: Replace with actual Bookings page
    Center(child: Text('Bookings - View, Edit, Cancel')),
    // TODO: Replace with actual Rented Vehicles page
    Center(child: Text('Rented Vehicles - Return & Pay')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MeadowMiles'),
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
              appState.signOut(context).then((_) {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              });
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Rented',
          ),
        ],
      ),
    );
  }
}
