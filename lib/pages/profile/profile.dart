import 'package:flutter/material.dart';
import 'package:meadowmiles/states/appstate.dart';
import 'package:provider/provider.dart';
import 'package:meadowmiles/states/authstate.dart';
import 'package:meadowmiles/models/user_model.dart';
import 'package:meadowmiles/pages/verification/verification_page.dart';
import 'package:meadowmiles/services/verification_service.dart';
import 'package:meadowmiles/services/owner_application_service.dart';
import 'package:meadowmiles/models/owner_application_model.dart';

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

  Future<void> _verifyUser() async {
    if (_userModel == null) return;

    // Check if user already has a pending verification ticket
    final hasPending = await VerificationService.hasPendingVerificationTicket(
      _userModel!.uid,
    );

    if (hasPending) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already have a pending verification request.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Navigate to verification page
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VerificationPage(user: _userModel!),
        ),
      );
    }
  }

  Future<void> _switchUserType() async {
    if (_userModel == null) return;

    var appState = Provider.of<AppState>(context, listen: false);

    setState(() => _isSwitching = true);

    try {
      if (_userModel!.userType == UserModelType.renter) {
        // Check if user has a pending or approved owner application
        final hasPending =
            await OwnerApplicationService.hasPendingOwnerApplication(
              _userModel!.uid,
            );
        final application =
            await OwnerApplicationService.getUserOwnerApplication(
              _userModel!.uid,
            );

        if (!mounted) return;

        if (hasPending ||
            (application != null &&
                application.status == ApplicationStatus.underReview)) {
          // Navigate to application status page
          Navigator.pushNamed(context, '/application_status');
        } else if (application != null &&
            application.status == ApplicationStatus.approved) {
          // User is already approved, just switch dashboard
          appState.setActiveDashboard('rentee');
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/rentee_dashboard',
            (route) => false,
          );
        } else {
          // Navigate to owner application page
          Navigator.pushNamed(context, '/apply_for_owner');
        }
      } else if (_userModel!.userType == UserModelType.rentee &&
          appState.activeDashboard == 'renter') {
        // Perform actions specific to rentees
        appState.setActiveDashboard('rentee');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/rentee_dashboard',
          (route) => false,
        );
      } else if (_userModel!.userType == UserModelType.rentee &&
          appState.activeDashboard == 'rentee') {
        // Perform actions specific to rentees
        appState.setActiveDashboard('renter');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/renter_dashboard',
          (route) => false,
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

    var appState = Provider.of<AppState>(context, listen: false);

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
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        appState.setActiveDashboard('renter');
                      },
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
                      Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                      Theme.of(
                        context,
                      ).colorScheme.secondary.withAlpha((0.05 * 255).toInt()),
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
                            color: Theme.of(context).colorScheme.primary
                                .withAlpha((0.3 * 255).toInt()),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _userModel!.userType == UserModelType.renter
                            ? Colors.blue.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _userModel!.userType == UserModelType.renter
                              ? Colors.blue
                              : Colors.green,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _userModel!.userType == UserModelType.renter
                                ? Icons.person
                                : Icons.business,
                            size: 16,
                            color: _userModel!.userType == UserModelType.renter
                                ? Colors.blue
                                : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _userModel!.userType == UserModelType.renter
                                ? 'Renter'
                                : 'Owner',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  _userModel!.userType == UserModelType.renter
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      _userModel!.verifiedUser ? 'Verified' : 'Unverified',
                      _userModel!.verifiedUser ? Colors.green : Colors.orange,
                    ),
                    !_userModel!.verifiedUser
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.email_outlined,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Start Verification',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  await _verifyUser();
                                },
                                // onPressed: () async {
                                //   try {
                                //     await authState.currentUser
                                //         ?.sendEmailVerification();
                                //     if (context.mounted) {
                                //       ScaffoldMessenger.of(context).showSnackBar(
                                //         const SnackBar(
                                //           content: Text('Verification email sent!'),
                                //           backgroundColor: Colors.orange,
                                //         ),
                                //       );
                                //     }
                                //   } catch (e) {
                                //     if (context.mounted) {
                                //       ScaffoldMessenger.of(context).showSnackBar(
                                //         SnackBar(
                                //           content: Text(
                                //             'Failed to send verification email: $e',
                                //           ),
                                //           backgroundColor: Colors.red,
                                //         ),
                                //       );
                                //     }
                                //   }
                                // },
                              ),
                            ),
                          )
                        : const SizedBox(height: 0),
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
                      ? 'Apply for Owner'
                      : _userModel!.userType == UserModelType.rentee &&
                            appState.activeDashboard == 'renter'
                      ? 'Owner Dashboard'
                      : 'Renter Dashboard',
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
            const SizedBox(height: 16),
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
            color: iconColor.withAlpha((0.1 * 255).toInt()),
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
