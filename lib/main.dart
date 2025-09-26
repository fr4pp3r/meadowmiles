import 'package:flutter/material.dart';
import 'package:meadowmiles/pages/admin_dashboard.dart';
import 'package:meadowmiles/pages/profile/profile.dart';
import 'package:meadowmiles/pages/owner/apply_for_owner_page.dart';
import 'package:meadowmiles/pages/owner/application_status_page.dart';
import 'package:meadowmiles/states/appstate.dart';
import 'package:meadowmiles/states/authstate.dart';
import 'package:meadowmiles/states/location_state.dart';
import 'package:meadowmiles/pages/auth/login_page.dart';
import 'package:meadowmiles/pages/auth/register_page.dart';
import 'package:meadowmiles/pages/rentee_dashboard.dart';
import 'package:meadowmiles/pages/renter_dashboard.dart';
import 'package:meadowmiles/pages/start_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meadowmiles/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:meadowmiles/states/renter_gps_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://tqqnvdlefaltvqlnbyub.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxcW52ZGxlZmFsdHZxbG5ieXViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk1MzYwMTMsImV4cCI6MjA2NTExMjAxM30.4ppaD5zRt9eLrhJGDrSMgr-OZRnxjCqXR3tPznxNJgM',
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => LocationState()),
        ChangeNotifierProvider(create: (_) => RenterGpsState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: meadowMilesTheme(),
      routes: <String, WidgetBuilder>{
        '/start': (context) => const StartPage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/rentee_dashboard': (context) => const RenteeDashboardPage(),
        '/renter_dashboard': (context) => const RenterDashboardPage(),
        '/profile': (context) => const ProfilePage(), // Temporary route
        '/admin_dashboard': (context) => const AdminDashboardPage(),
        '/apply_for_owner': (context) => const ApplyForOwnerPage(),
        '/application_status': (context) => const ApplicationStatusPage(),
      },
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize location service
    final locationState = Provider.of<LocationState>(context, listen: false);
    try {
      await locationState.initializeLocation();
    } catch (e) {
      print('Failed to initialize location service: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const StartPage();
  }
}

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          width: 120,
          height: 120,
          child: Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
