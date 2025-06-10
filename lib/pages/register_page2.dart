// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:country_code_picker/country_code_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:meadowmiles/main.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../models/user_model.dart';

// class RegisterPage extends StatefulWidget {
//   const RegisterPage({super.key});

//   @override
//   State<RegisterPage> createState() => _RegisterPageState();
// }

// class _RegisterPageState extends State<RegisterPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _mobileController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController =
//       TextEditingController();
//   bool _acceptedTerms = false;
//   bool _submitted = false;
//   bool _passwordVisible = false;
//   bool _confirmPasswordVisible = false; // Add this for confirm password
//   String _selectedCountryCode = '+63'; // Default to PH country code

//   void _register() async {
//     if (_nameController.text.isNotEmpty &&
//         _emailController.text.isNotEmpty &&
//         _mobileController.text.isNotEmpty &&
//         _passwordController.text.isNotEmpty &&
//         _confirmPasswordController.text.isNotEmpty &&
//         _passwordController.text == _confirmPasswordController.text &&
//         _acceptedTerms) {
//       showDialog(
//         context: context,
//         builder: (context) {
//           String? selectedRole;
//           return StatefulBuilder(
//             builder: (context, setState) => AlertDialog(
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text('Register as:'),
//                   const SizedBox(height: 8),
//                   DropdownButton<String>(
//                     value: selectedRole,
//                     hint: const Text('Select role'),
//                     isExpanded: true,
//                     items: const [
//                       DropdownMenuItem(value: 'admin', child: Text('Admin')),
//                       DropdownMenuItem(
//                         value: 'renter',
//                         child: Text('Renter (Customer)'),
//                       ),
//                       DropdownMenuItem(
//                         value: 'rentee',
//                         child: Text('Rentee (Owner of car)'),
//                       ),
//                     ],
//                     onChanged: (value) {
//                       setState(() {
//                         selectedRole = value;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: selectedRole == null
//                       ? () {
//                           selectedRole = null;
//                           Navigator.of(context).pop();
//                         }
//                       : () async {
//                           final email = _emailController.text.trim();
//                           final password = _passwordController.text.trim();

//                           try {
//                             showDialog(
//                               context: context,
//                               barrierDismissible: false,
//                               builder: (context) => const LoadingDialog(),
//                             );

//                             UserCredential userCredential = await FirebaseAuth
//                                 .instance
//                                 .createUserWithEmailAndPassword(
//                                   email: email,
//                                   password: password,
//                                 );

//                             String uid = userCredential.user!.uid;

//                             final user = UserModel(
//                               uid: uid,
//                               name: _nameController.text.trim(),
//                               email: _emailController.text.trim(),
//                               phoneNumber:
//                                   _selectedCountryCode +
//                                   _mobileController.text.trim(),
//                               userType: UserModelType.values.firstWhere(
//                                 (e) =>
//                                     e.toString() ==
//                                     'UserModelType.${selectedRole!}',
//                                 orElse: () => UserModelType.rentee,
//                               ),
//                               createdAt: null, // Will be set by Firestore
//                             );

//                             await FirebaseFirestore.instance
//                                 .collection('users')
//                                 .doc(uid)
//                                 .set({
//                                   ...user.toMap(),
//                                   'createdAt': FieldValue.serverTimestamp(),
//                                 });

//                             if (context.mounted) {
//                               if (Navigator.of(
//                                 context,
//                                 rootNavigator: true,
//                               ).canPop()) {
//                                 Navigator.of(
//                                   context,
//                                   rootNavigator: true,
//                                 ).pop();
//                               }
//                             }

//                             if (context.mounted) {
//                               showDialog(
//                                 barrierDismissible: false,
//                                 context: context,
//                                 builder: (context) => AlertDialog(
//                                   title: const Text('Success'),
//                                   content: const Text(
//                                     'Registration successful!',
//                                   ),
//                                   actions: [
//                                     TextButton(
//                                       onPressed: () {
//                                         Navigator.of(context).pop();
//                                         Navigator.of(context).pop();
//                                         Navigator.of(context).pop();
//                                       },
//                                       child: const Text('Go back to login'),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             }
//                             _resetForm();
//                           } catch (e) {
//                             // Dismiss loading dialog on error
//                             if (context.mounted) {
//                               if (Navigator.of(
//                                 context,
//                                 rootNavigator: true,
//                               ).canPop()) {
//                                 Navigator.of(
//                                   context,
//                                   rootNavigator: true,
//                                 ).pop();
//                               }
//                             }
//                             if (context.mounted) {
//                               showDialog(
//                                 barrierDismissible: false,
//                                 context: context,
//                                 builder: (context) => AlertDialog(
//                                   title: const Text('Error'),
//                                   content: Text('Failed to register user: $e'),
//                                   actions: [
//                                     TextButton(
//                                       onPressed: () {
//                                         Navigator.of(context).pop();
//                                         Navigator.of(context).pop();
//                                       },
//                                       child: const Text('OK'),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             }
//                           }
//                         },
//                   child: const Text('OK'),
//                 ),
//               ],
//             ),
//           );
//         },
//       );
//       return;
//     } else {
//       setState(() {
//         _submitted = true;
//       });
//     }
//   }

//   void _resetForm() {
//     _nameController.clear();
//     _emailController.clear();
//     _mobileController.clear();
//     _passwordController.clear();
//     _confirmPasswordController.clear();
//     setState(() {
//       _acceptedTerms = false;
//       _submitted = false;
//     });
//   }

//   Widget logoPlaceholder() {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         double size = constraints.maxWidth * 0.5;
//         return SizedBox(
//           width: size,
//           height: size,
//           child: Image.asset(
//             'assets/logos/meadowmiles_logo2.png',
//             fit: BoxFit.contain,
//           ), // Placeholder for logo
//         );
//       },
//     );
//   }

//   OutlineInputBorder _customBorder(bool isError, BuildContext context) {
//     return OutlineInputBorder(
//       borderRadius: BorderRadius.circular(30.0),
//       borderSide: BorderSide(
//         color: isError ? Colors.red : Colors.grey,
//         width: 2.0,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       body: SafeArea(
//         child: Form(
//           key: _formKey,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   logoPlaceholder(),
//                   const SizedBox(height: 16.0),
//                   TextField(
//                     controller: _nameController,
//                     style: Theme.of(context).textTheme.bodySmall,
//                     decoration: InputDecoration(
//                       labelText: 'Name',
//                       labelStyle: Theme.of(context).textTheme.bodySmall,
//                       border: _customBorder(
//                         _nameController.text.isEmpty && _submitted,
//                         context,
//                       ),
//                       enabledBorder: _customBorder(
//                         _nameController.text.isEmpty && _submitted,
//                         context,
//                       ),
//                       focusedBorder: _customBorder(
//                         _nameController.text.isEmpty && _submitted,
//                         context,
//                       ),
//                     ),
//                     onChanged: (_) => setState(() {}),
//                   ),
//                   const SizedBox(height: 8.0),
//                   TextField(
//                     controller: _emailController,
//                     style: Theme.of(context).textTheme.bodySmall,
//                     decoration: InputDecoration(
//                       labelText: 'Email',
//                       labelStyle: Theme.of(context).textTheme.bodySmall,
//                       border: _customBorder(
//                         _emailController.text.isEmpty && _submitted,
//                         context,
//                       ),
//                       enabledBorder: _customBorder(
//                         _emailController.text.isEmpty && _submitted,
//                         context,
//                       ),
//                       focusedBorder: _customBorder(
//                         _nameController.text.isEmpty && _submitted,
//                         context,
//                       ),
//                     ),
//                     keyboardType: TextInputType.emailAddress,
//                     onChanged: (_) => setState(() {}),
//                   ),
//                   const SizedBox(height: 8.0),
//                   Row(
//                     children: [
//                       SizedBox(
//                         width: 120,
//                         child: CountryCodePicker(
//                           textStyle: Theme.of(context).textTheme.bodySmall,
//                           initialSelection: 'PH',
//                           onChanged: (code) {
//                             setState(() {
//                               _selectedCountryCode = code.dialCode ?? '+63';
//                             });
//                           },
//                           showFlag: true,
//                           showDropDownButton: true,
//                           padding: const EdgeInsets.only(right: 8.0),
//                         ),
//                       ),
//                       Expanded(
//                         child: TextField(
//                           controller: _mobileController,
//                           style: Theme.of(context).textTheme.bodySmall,
//                           decoration: InputDecoration(
//                             labelText: 'Mobile Number',
//                             labelStyle: Theme.of(context).textTheme.bodySmall,
//                             border: _customBorder(
//                               _mobileController.text.isEmpty && _submitted,
//                               context,
//                             ),
//                             enabledBorder: _customBorder(
//                               _mobileController.text.isEmpty && _submitted,
//                               context,
//                             ),
//                             focusedBorder: _customBorder(
//                               _mobileController.text.isEmpty && _submitted,
//                               context,
//                             ),
//                           ),
//                           keyboardType: TextInputType.phone,
//                           onChanged: (value) {
//                             // Remove leading zeroes
//                             final newValue = value.replaceFirst(
//                               RegExp(r'^0+'),
//                               '',
//                             );
//                             if (value != newValue) {
//                               _mobileController.value = TextEditingValue(
//                                 text: newValue,
//                                 selection: TextSelection.collapsed(
//                                   offset: newValue.length,
//                                 ),
//                               );
//                             } else {
//                               setState(() {});
//                             }
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8.0),
//                   TextField(
//                     controller: _passwordController,
//                     style: Theme.of(context).textTheme.bodySmall,
//                     decoration: InputDecoration(
//                       labelText: 'Password',
//                       labelStyle: Theme.of(context).textTheme.bodySmall,
//                       border: _customBorder(
//                         _passwordController.text.isEmpty && _submitted,
//                         context,
//                       ),
//                       enabledBorder: _customBorder(
//                         _passwordController.text.isEmpty && _submitted,
//                         context,
//                       ),
//                       focusedBorder: _customBorder(
//                         _mobileController.text.isEmpty && _submitted,
//                         context,
//                       ),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _passwordVisible
//                               ? Icons.visibility
//                               : Icons.visibility_off,
//                           color: Theme.of(context).iconTheme.color,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _passwordVisible = !_passwordVisible;
//                           });
//                         },
//                       ),
//                     ),
//                     obscureText: !_passwordVisible, // Use the state variable
//                     onChanged: (_) => setState(() {}),
//                   ),
//                   const SizedBox(height: 8.0),
//                   TextField(
//                     controller: _confirmPasswordController,
//                     style: Theme.of(context).textTheme.bodySmall,
//                     decoration: InputDecoration(
//                       labelText: 'Confirm Password',
//                       labelStyle: Theme.of(context).textTheme.bodySmall,
//                       border: _customBorder(
//                         _confirmPasswordController.text.isEmpty && _submitted,
//                         context,
//                       ),
//                       enabledBorder: _customBorder(
//                         _confirmPasswordController.text.isEmpty && _submitted,
//                         context,
//                       ),
//                       focusedBorder: _customBorder(
//                         _mobileController.text.isEmpty && _submitted,
//                         context,
//                       ),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _confirmPasswordVisible
//                               ? Icons.visibility
//                               : Icons.visibility_off,
//                           color: Theme.of(context).iconTheme.color,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _confirmPasswordVisible = !_confirmPasswordVisible;
//                           });
//                         },
//                       ),
//                     ),
//                     obscureText: !_confirmPasswordVisible,
//                     onChanged: (_) => setState(() {}),
//                   ),
//                   _confirmPasswordController.text.isNotEmpty &&
//                           _passwordController.text !=
//                               _confirmPasswordController.text
//                       ? Padding(
//                           padding: const EdgeInsets.only(top: 8.0),
//                           child: Text(
//                             'Passwords do not match',
//                             style: Theme.of(
//                               context,
//                             ).textTheme.bodySmall?.copyWith(color: Colors.red),
//                           ),
//                         )
//                       : const SizedBox(height: 29),
//                   const SizedBox(height: 8.0),
//                   Row(
//                     children: [
//                       Checkbox(
//                         value: _acceptedTerms,
//                         onChanged: (value) {
//                           setState(() {
//                             _acceptedTerms = value ?? false;
//                           });
//                         },
//                       ),
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               _acceptedTerms = !_acceptedTerms;
//                             });
//                           },
//                           child: GestureDetector(
//                             onTap: () {
//                               showAboutDialog(context: context);
//                             },
//                             child: Text(
//                               'I accept the Terms and Conditions',
//                               style: Theme.of(context).textTheme.bodySmall
//                                   ?.copyWith(
//                                     color: Theme.of(
//                                       context,
//                                     ).colorScheme.onSurface,
//                                     decoration: TextDecoration.underline,
//                                   ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16.0),
//                   ElevatedButton(
//                     onPressed: () {
//                       _register();
//                     },
//                     child: const Text('Register'),
//                   ),
//                   const SizedBox(height: 16.0),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Need help? Check out our ',
//                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: Theme.of(context).colorScheme.primary,
//                         ),
//                       ),
//                       GestureDetector(
//                         onTap: () {},
//                         child: Text(
//                           'Help Center',
//                           style: Theme.of(context).textTheme.bodySmall
//                               ?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: Theme.of(context).colorScheme.onSurface,
//                                 decoration: TextDecoration.underline,
//                               ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
