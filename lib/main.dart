import 'package:flutter/material.dart';
import 'package:meadowmiles/states/appstate.dart';
import 'package:meadowmiles/states/authstate.dart';
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
      },
      home: const StartPage(),
    );
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
