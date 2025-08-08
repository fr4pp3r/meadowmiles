import 'package:flutter/material.dart';
import 'package:meadowmiles/states/authstate.dart';
import 'package:provider/provider.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  Widget logoPlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = constraints.maxWidth * 1; // 50% of the available width
        // if (size > 240) {
        //   size = 240; // Optional: cap max size for aesthetics
        // }
        return SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            'assets/logos/meadowmiles_logo.png',
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var authState = context.watch<AuthState>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Prevent back button from closing the app on the start page
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 32.0,
                right: 32.0,
                top: 100.0,
                bottom: 32.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Replace with your logo asset
                  // Image.asset(
                  //   'assets/logo.png',
                  //   height: 120,
                  // ),
                  logoPlaceholder(),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Your next adventure starts here.',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Rent your perfect ride today!',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // if (appState.currentUser != null) {
                        //   appState.signOut(context);
                        // }
                        if (authState.currentUser == null) {
                          Navigator.pushNamed(context, '/login');
                        } else {
                          Navigator.pushNamed(context, '/renter_dashboard');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                      ),
                      child: Text(
                        'Get Started',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
