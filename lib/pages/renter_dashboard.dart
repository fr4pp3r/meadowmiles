import 'package:flutter/material.dart';
import 'package:meadowmiles/pages/renter/home/home_tab.dart';
import 'package:meadowmiles/pages/renter/renterbook_tab.dart';
import 'package:meadowmiles/pages/renter/renterhistory_tab.dart';
import 'package:meadowmiles/states/authstate.dart';
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
    RenterBookTab(),
    RenterHistoryTab(),
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
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_online),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }
}
