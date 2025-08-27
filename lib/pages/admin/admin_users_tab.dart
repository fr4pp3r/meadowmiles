import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meadowmiles/models/user_model.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Verified',
    'Unverified',
    'Mark for Deletion',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filterOptions.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                        checkmarkColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Users List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No users found.'));
              }

              final users = docs
                  .map((doc) {
                    try {
                      return UserModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        uid: doc.id,
                      );
                    } catch (e) {
                      return null;
                    }
                  })
                  .where((user) => user != null)
                  .cast<UserModel>()
                  .toList();

              // Apply filters
              final filteredUsers = users.where((user) {
                // Search filter
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  final matchesSearch =
                      user.name.toLowerCase().contains(query) ||
                      user.email.toLowerCase().contains(query);
                  if (!matchesSearch) return false;
                }

                // Status filter
                switch (_selectedFilter) {
                  case 'Verified':
                    return user.verifiedUser == true;
                  case 'Unverified':
                    return user.verifiedUser != true;
                  case 'Mark for Deletion':
                    return user.markDelete == true;
                  default:
                    return true;
                }
              }).toList();

              if (filteredUsers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty && _selectedFilter == 'All'
                            ? 'No users found'
                            : 'No users match your criteria',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return _buildUserCard(user);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.markDelete
              ? Colors.red
              : user.verifiedUser
              ? Colors.green
              : Colors.orange,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  user.markDelete
                      ? Icons.delete
                      : user.verifiedUser
                      ? Icons.verified
                      : Icons.pending,
                  size: 16,
                  color: user.markDelete
                      ? Colors.red
                      : user.verifiedUser == true
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  user.markDelete
                      ? 'Marked for Deletion'
                      : user.verifiedUser
                      ? 'Verified'
                      : 'Unverified',
                  style: TextStyle(
                    color: user.markDelete
                        ? Colors.red
                        : user.verifiedUser == true
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user),
          itemBuilder: (context) => [
            if (user.verifiedUser != true)
              const PopupMenuItem(
                value: 'verify',
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Verify User'),
                  ],
                ),
              ),
            if (user.verifiedUser == true)
              const PopupMenuItem(
                value: 'unverify',
                child: Row(
                  children: [
                    Icon(Icons.pending, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Unverify User'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'Toggle Deletion',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Toggle Deletion'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUserAction(String action, UserModel user) async {
    switch (action) {
      case 'verify':
        await _toggleUserVerification(user, true);
        break;
      case 'unverify':
        await _toggleUserVerification(user, false);
        break;
      case 'view':
        _showUserDetails(user);
        break;
      case 'Toggle Deletion':
        _showDeleteConfirmation(user);
        break;
    }
  }

  Future<void> _toggleUserVerification(UserModel user, bool verified) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'verifiedUser': verified},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              verified
                  ? 'User ${user.name} has been verified'
                  : 'User ${user.name} verification has been removed',
            ),
            backgroundColor: verified ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name:', user.name),
            _buildDetailRow('Email:', user.email),
            _buildDetailRow('Phone:', user.phoneNumber),
            _buildDetailRow(
              'User Type:',
              user.userType.toString().split('.').last.toUpperCase(),
            ),
            _buildDetailRow(
              'Verified:',
              user.verifiedUser == true ? 'Yes' : 'No',
            ),
            _buildDetailRow('User ID:', user.uid),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value.isNotEmpty ? value : 'N/A')),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.markDelete ? 'Unmark' : 'Mark'} User for Deletion'),
        content: Text(
          'Are you sure you want to ${user.markDelete ? 'unmark' : 'mark'} user "${user.name}" for deletion? This will ${user.markDelete ? 'allow' : 'prevent'} them ${user.markDelete ? 'to' : 'from'} logging in and their account can be permanently removed later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteUser(user);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text('${user.markDelete ? 'Unmark' : 'Mark'} for Deletion'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    if (!user.markDelete) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'markDelete': true,
              'markDeleteAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User ${user.name} has been marked for deletion'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error marking user for deletion: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'markDelete': false, 'markDeleteAt': null});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User ${user.name} has been unmarked for deletion'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error unmarking user for deletion: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
