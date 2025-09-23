import 'package:flutter/material.dart';
import 'package:meadowmiles/models/user_model.dart';
import 'package:meadowmiles/states/authstate.dart';
import 'package:provider/provider.dart';
import 'package:country_code_picker/country_code_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  UserModel? _createdUserModel;

  int _currentStep = 0;
  String _selectedRole = 'renter'; // Default to renter
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String _selectedCountryCode = '+63';
  final _formKey = GlobalKey<FormState>();
  bool _termsAccepted = false;

  void _nextStep() {
    if (_currentStep == 0) {
      if (_emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty ||
          _passwordController.text != _confirmPasswordController.text) {
        setState(() {});
        return;
      }
    }
    if (_currentStep == 1) {
      if (_nameController.text.isEmpty || _mobileController.text.isEmpty) {
        setState(() {});
        return;
      }
    }
    if (_currentStep == 2) {
      if (!_termsAccepted) {
        setState(() {});
        return;
      }
    }
    setState(() {
      if (_currentStep < 2) _currentStep++;
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _nameController.clear();
    _mobileController.clear();
    setState(() {
      _createdUserModel = null;
      _currentStep = 0;
      _selectedRole = 'renter'; // Reset to default renter
      _selectedCountryCode = '+63';
      _passwordVisible = false;
      _confirmPasswordVisible = false;
      _termsAccepted = false;
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  Widget logoPlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 32.0),
              child: Image.asset(
                'assets/logos/meadowmiles_logo2.png',
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  void _createUserModel() {
    String mobile = _mobileController.text.replaceFirst(RegExp(r'^0+'), '');
    _createdUserModel = UserModel(
      uid: "",
      name: _nameController.text,
      email: _emailController.text,
      phoneNumber: '$_selectedCountryCode$mobile',
      userType: UserModelType.values.firstWhere((e) => e.name == _selectedRole),
      createdAt: null, // Set to null for now, can be set later
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var authState = context.watch<AuthState>();

    return Scaffold(
      resizeToAvoidBottomInset: true, // Ensures keyboard does not block content
      body: Column(
        children: [
          logoPlaceholder(),
          Text(
            'Registration',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: Form(
              key: _formKey,
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: _nextStep,
                onStepCancel: _prevStep,
                controlsBuilder: (context, details) {
                  return Row(
                    children: [
                      if (_currentStep < 2)
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: const Text('Next'),
                        ),
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                      if (_currentStep == 2)
                        ElevatedButton(
                          onPressed: () async {
                            _createUserModel();
                            await authState.register(
                              _createdUserModel!,
                              _passwordController.text,
                              context,
                            );
                            // To reset all fields, call _resetForm();
                            _resetForm();
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Register'),
                        ),
                    ],
                  );
                },
                steps: [
                  Step(
                    title: const Text('Account Credentials'),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0
                        ? StepState.complete
                        : StepState.indexed,
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_confirmPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _confirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _confirmPasswordVisible =
                                    !_confirmPasswordVisible,
                              ),
                            ),
                          ),
                        ),
                        if (_passwordController.text !=
                                _confirmPasswordController.text &&
                            _confirmPasswordController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Passwords do not match',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Personal Info'),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1
                        ? StepState.complete
                        : StepState.indexed,
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CountryCodePicker(
                              initialSelection: 'PH',
                              onChanged: (country) {
                                setState(() {
                                  _selectedCountryCode = country.dialCode!;
                                });
                              },
                              showFlag: false,
                              showFlagDialog: true,
                              showDropDownButton: true,
                              padding: const EdgeInsets.only(right: 8.0),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _mobileController,
                                decoration: const InputDecoration(
                                  labelText: 'Mobile Number',
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Terms and Conditions'),
                    isActive: _currentStep >= 2,
                    state: _termsAccepted
                        ? StepState.complete
                        : StepState.indexed,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'By registering, you agree to MeadowMiles\' Terms and Conditions. Please read them carefully before proceeding.\n\n1. You agree to provide accurate information.\n2. You are responsible for your account security.\n3. MeadowMiles is not liable for any damages or losses.\n4. For full terms, visit our website.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _termsAccepted,
                              onChanged: (val) {
                                setState(() {
                                  _termsAccepted = val ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                'I agree to the Terms and Conditions',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                        if (!_termsAccepted && _currentStep == 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'You must agree to the Terms and Conditions to register.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
