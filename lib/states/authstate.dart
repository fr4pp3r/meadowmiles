import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meadowmiles/main.dart';
import 'package:meadowmiles/models/user_model.dart';

class AuthState extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> fetchCurrentUserModel(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(),
    );
    if (currentUser == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    if (!doc.exists) return null;
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    return UserModel.fromMap(doc.data()!, uid: doc.id);
  }

  Future<void> signIn(
    String email,
    String password,
    BuildContext context,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(),
    );
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        Future.delayed(Duration.zero, () {
          if (context.mounted) {
            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sign in failed'),
                content: Text('$e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        });
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> signOut(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(),
    );
    await _auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    notifyListeners();
  }

  Future<void> register(
    UserModel userModel,
    String password,
    BuildContext context,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(),
    );
    try {
      await _auth.createUserWithEmailAndPassword(
        email: userModel.email,
        password: password,
      );
      userModel.uid = _auth.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userModel.uid)
          .set({
            ...userModel.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
          });
      // Sign out the user after registration
      await _auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        Future.delayed(Duration.zero, () {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Registration Successful'),
                content: const Text(
                  'Your account has been created successfully. Verify your email to complete the registration.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        });
      }
    } catch (e) {
      Future.delayed(Duration.zero, () {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Registration failed'),
              content: Text('$e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      });
    } finally {
      notifyListeners();
    }
  }
}
