import 'package:flutter/material.dart';
import 'package:meadowmiles/states/appstate.dart';
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
    Center(child: Text('Bookings')),
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

    return Scaffold(
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
              authState.signOut(context).then((_) {
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
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Bookings',
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
    );
  }
}
