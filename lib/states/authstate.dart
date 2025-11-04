import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meadowmiles/main.dart';
import 'package:meadowmiles/models/user_model.dart';

class AuthState extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  UserModel? currentUserModel;

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

  Future<UserModel?> fetchCurrentUserModelSilent() async {
    if (currentUser == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    if (!doc.exists) return null;
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
      currentUserModel = await fetchCurrentUserModelSilent();

      // Check if user account is marked for deletion
      if (currentUserModel != null && currentUserModel!.markDelete) {
        // Sign out the user immediately
        await _auth.signOut();
        currentUserModel = null;

        if (context.mounted) {
          Navigator.of(context).pop(); // Dismiss loading dialog
          Future.delayed(Duration.zero, () {
            if (context.mounted) {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Account Unavailable'),
                  content: const Text(
                    'This account is marked for deletion and cannot be accessed.',
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
        return;
      }

      // Update user's online status to true
      if (currentUser != null) {
        await updateUserOnlineStatus(true);
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
                content: Text(e.toString().split("] ")[1]),
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

  Future<void> updateUserOnlineStatus(bool isOnline) async {
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'online': isOnline});

      // Update the local currentUserModel if it exists
      if (currentUserModel != null) {
        // We need to create a new UserModel with updated online status
        // Since the fields are final, we'll refetch the user data
        currentUserModel = await fetchCurrentUserModelSilent();
      }
    } catch (e) {
      debugPrint('Failed to update online status: $e');
    }
  }

  Future<void> signOut(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(),
    );

    // Update user's online status to false before signing out
    if (currentUser != null) {
      await updateUserOnlineStatus(false);
    }

    await _auth.signOut();
    if (_auth.currentUser == null) {
      currentUserModel = null;
    }
    if (context.mounted) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop(); // Dismiss loading dialog
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil('/start', (route) => false);
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

  // Reset password for a user with verified OTP
  // Sends Firebase's built-in password reset email
  Future<bool> resetPassword(String email, String newPassword) async {
    try {
      // Send Firebase password reset email
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      return false;
    }
  }

  // Alternative method name for clarity
  Future<bool> sendPasswordResetEmail(String email) async {
    return await resetPassword(email, '');
  }
}
