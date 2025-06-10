import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meadowmiles/main.dart';
import 'package:meadowmiles/models/user_model.dart';

class AppState extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  // Recommended: Async method to fetch the current user's Firestore profile
  Future<UserModel?> fetchCurrentUserModel() async {
    if (currentUser == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid: doc.id);
  }

  Future<void> loadCurrentUserModel() async {
    if (currentUser == null) {
      _userModel = null;
      notifyListeners();
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    if (!doc.exists) {
      _userModel = null;
    } else {
      _userModel = UserModel.fromMap(doc.data()!, uid: doc.id);
    }
    notifyListeners();
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
      await loadCurrentUserModel();
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        Future.delayed(Duration.zero, () {
          if (userModel?.userType == UserModelType.rentee) {
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/rentee_dashboard');
            }
          } else {
            if (context.mounted) {
              signOut(context);
            }
          }
        });
      }
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
    _userModel = null;
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
      await loadCurrentUserModel();
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        Future.delayed(Duration.zero, () {
          if (context.mounted) {
            showDialog(
              barrierDismissible: false,
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
            barrierDismissible: false,
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
