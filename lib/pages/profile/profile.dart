import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meadowmiles/states/authstate.dart';
import 'package:meadowmiles/models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _userModel;
  bool _isLoading = true;
  bool _isSwitching = false;
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    final userModel = await authState.fetchCurrentUserModelSilent();
    if (mounted) {
      setState(() {
        _userModel = userModel;
        _isLoading = false;
      });
    }
  }

  Future<void> _switchUserType() async {
    if (_userModel == null) return;

    setState(() => _isSwitching = true);

    try {
      final newUserType = _userModel!.userType == UserModelType.renter
          ? UserModelType.rentee
          : UserModelType.renter;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userModel!.uid)
          .update({'userType': newUserType.toString().split('.').last});

      setState(() {
        _userModel = UserModel(
          uid: _userModel!.uid,
          name: _userModel!.name,
          email: _userModel!.email,
          phoneNumber: _userModel!.phoneNumber,
          userType: newUserType,
          createdAt: _userModel!.createdAt,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Switched to ${newUserType == UserModelType.renter ? "Renter" : "Owner"} mode successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch user type: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSwitching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userModel == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load user data')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                if (context.mounted) {
                  await authState.signOut(context);
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Card
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Profile Image
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _userModel!.name.isNotEmpty
                              ? _userModel!.name[0].toUpperCase()
                              : 'U',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(color: Colors.white, fontSize: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    Text(
                      _userModel!.name,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // User Type Badge
                    // Container(
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: 16,
                    //     vertical: 8,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     color: _userModel!.userType == UserModelType.renter
                    //         ? Colors.blue.shade100
                    //         : Colors.green.shade100,
                    //     borderRadius: BorderRadius.circular(20),
                    //     border: Border.all(
                    //       color: _userModel!.userType == UserModelType.renter
                    //           ? Colors.blue
                    //           : Colors.green,
                    //     ),
                    //   ),
                    //   child: Row(
                    //     mainAxisSize: MainAxisSize.min,
                    //     children: [
                    //       Icon(
                    //         _userModel!.userType == UserModelType.renter
                    //             ? Icons.person
                    //             : Icons.business,
                    //         size: 16,
                    //         color: _userModel!.userType == UserModelType.renter
                    //             ? Colors.blue
                    //             : Colors.green,
                    //       ),
                    //       const SizedBox(width: 4),
                    //       Text(
                    //         _userModel!.userType == UserModelType.renter
                    //             ? 'Renter'
                    //             : 'Owner',
                    //         style: TextStyle(
                    //           fontWeight: FontWeight.bold,
                    //           color:
                    //               _userModel!.userType == UserModelType.renter
                    //               ? Colors.blue
                    //               : Colors.green,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Contact Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _buildInfoRow(
                      context,
                      Icons.email,
                      'Email',
                      _userModel!.email,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    _buildInfoRow(
                      context,
                      Icons.phone,
                      'Phone Number',
                      _userModel!.phoneNumber.isNotEmpty
                          ? _userModel!.phoneNumber
                          : 'Not provided',
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Verification Status Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      context,
                      Icons.verified_user,
                      'Verification Status',
                      authState.currentUser?.emailVerified == true
                          ? 'Verified'
                          : 'Unverified',
                      authState.currentUser?.emailVerified == true
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      context,
                      Icons.calendar_today,
                      'Member Since',
                      _userModel!.createdAt != null
                          ? '${_userModel!.createdAt!.day}/${_userModel!.createdAt!.month}/${_userModel!.createdAt!.year}'
                          : 'Unknown',
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Switch User Type Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSwitching ? null : _switchUserType,
                icon: _isSwitching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _userModel!.userType == UserModelType.renter
                            ? Icons.business
                            : Icons.person,
                        color: Colors.white,
                      ),
                label: Text(
                  _isSwitching
                      ? 'Switching...'
                      : _userModel!.userType == UserModelType.renter
                      ? 'Switch to Owner'
                      : 'Switch to Renter',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _userModel!.userType == UserModelType.renter
                      ? Colors.green
                      : Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info text
            Text(
              'Switch between Renter and Owner modes to access different features.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
