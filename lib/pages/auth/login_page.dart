import 'package:flutter/material.dart';
import 'package:meadowmiles/models/user_model.dart';
import 'package:meadowmiles/states/authstate.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  Widget logoPlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = constraints.maxWidth * 0.5;
        return SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            'assets/logos/meadowmiles_logo2.png',
            fit: BoxFit.cover,
          ), // Placeholder for logo
        );
      },
    );
  }

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login(BuildContext context, AuthState authState) async {
    final email = _usernameController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Login Failed'),
          content: const Text('Please enter email and password.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    await authState.signIn(email, password, context);
    _clearFields();
    if (authState.currentUser != null) {
      if (context.mounted) {
        final userModel = await authState.fetchCurrentUserModel(context);
        // Navigate to the appropriate dashboard based on user type
        if (userModel?.userType == UserModelType.rentee) {
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/rentee_dashboard');
          }
        } else if (userModel?.userType == UserModelType.renter) {
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/renter_dashboard');
          }
        }
      }
    }
  }

  void _clearFields() {
    _usernameController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    var authState = context.watch<AuthState>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 32, right: 32, bottom: 16),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  logoPlaceholder(),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      Text(
                        'LOG IN!',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Enter your credentials to login.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        style: Theme.of(context).textTheme.bodySmall,
                        decoration: InputDecoration(
                          labelText: 'Username/Email',
                          labelStyle: Theme.of(context).textTheme.bodySmall,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      Container(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            // Handle "Forgot your username?" tap here
                          },
                          child: Text(
                            'Forgot your username?',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      TextField(
                        controller: _passwordController,
                        style: Theme.of(context).textTheme.bodySmall,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: Theme.of(context).textTheme.bodySmall,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        obscureText: true,
                      ),
                      Container(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            // Handle "Forgot your username?" tap here
                          },
                          child: Text(
                            'Forgot your password?',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 100,
                    child: OutlinedButton.icon(
                      label: Text(
                        'Login',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => _login(context, authState),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Or login with:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 140, // Set your desired fixed width here
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          icon: Image.asset(
                            'assets/logos/google_logo.png',
                            width: 20,
                            height: 20,
                          ),
                          label: Text(
                            'Google',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          onPressed: () {
                            // Handle Google login
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 140, // Set your desired fixed width here
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          icon: Icon(
                            Icons.facebook,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          label: Text(
                            'Facebook',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          onPressed: () {
                            // Handle Facebook login
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New User? ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          'Sign Up',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Need help? Check out our ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'Help Center',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ),
                    ],
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
