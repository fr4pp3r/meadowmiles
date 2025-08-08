import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDataTab extends StatefulWidget {
  const AdminDataTab({super.key});

  @override
  State<AdminDataTab> createState() => _AdminDataTabState();
}

class _AdminDataTabState extends State<AdminDataTab>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.directions_car), text: 'Vehicles'),
              Tab(icon: Icon(Icons.book_online), text: 'Bookings'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
            indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUsersDataTab(),
              _buildVehiclesDataTab(),
              _buildBookingsDataTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersDataTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        return Column(
          children: [
            // Stats Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total Users', docs.length.toString()),
                  _buildStatItem(
                    'Verified',
                    docs
                        .where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['verifiedUser'] == true;
                        })
                        .length
                        .toString(),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBulkActions('users'),
                      icon: const Icon(Icons.batch_prediction),
                      label: const Text('Bulk Actions'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _exportData('users'),
                      icon: const Icon(Icons.download),
                      label: const Text('Export Data'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Data List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: data['verifiedUser'] == true
                            ? Colors.green
                            : Colors.grey,
                        child: Text(
                          (data['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(data['name'] ?? 'Unknown'),
                      subtitle: Text(data['email'] ?? 'No email'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) =>
                            _handleDataAction(value, 'users', doc.id, data),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVehiclesDataTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        return Column(
          children: [
            // Stats Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total Vehicles', docs.length.toString()),
                  _buildStatItem(
                    'Available',
                    docs
                        .where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['isAvailable'] == true;
                        })
                        .length
                        .toString(),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBulkActions('vehicles'),
                      icon: const Icon(Icons.batch_prediction),
                      label: const Text('Bulk Actions'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _exportData('vehicles'),
                      icon: const Icon(Icons.download),
                      label: const Text('Export Data'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Data List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: data['isAvailable'] == true
                            ? Colors.green
                            : Colors.red,
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        '${data['make'] ?? 'Unknown'} ${data['model'] ?? ''}',
                      ),
                      subtitle: Text('Price: ₱${data['pricePerDay'] ?? 0}/day'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) =>
                            _handleDataAction(value, 'vehicles', doc.id, data),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBookingsDataTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        return Column(
          children: [
            // Stats Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total Bookings', docs.length.toString()),
                  _buildStatItem(
                    'Active',
                    docs
                        .where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['status'] == 'active';
                        })
                        .length
                        .toString(),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBulkActions('bookings'),
                      icon: const Icon(Icons.batch_prediction),
                      label: const Text('Bulk Actions'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _exportData('bookings'),
                      icon: const Icon(Icons.download),
                      label: const Text('Export Data'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Data List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(data['status'] ?? ''),
                        child: const Icon(
                          Icons.book_online,
                          color: Colors.white,
                        ),
                      ),
                      title: Text('Booking ${doc.id.substring(0, 8)}...'),
                      subtitle: Text(
                        'Status: ${data['status'] ?? 'Unknown'} • ₱${data['totalPrice'] ?? 0}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) =>
                            _handleDataAction(value, 'bookings', doc.id, data),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'returned':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _handleDataAction(
    String action,
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) {
    switch (action) {
      case 'edit':
        _showEditDialog(collection, docId, data);
        break;
      case 'delete':
        _showDeleteConfirmation(collection, docId, data);
        break;
    }
  }

  void _showEditDialog(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${collection.substring(0, collection.length - 1)}'),
        content: const Text(
          'Advanced editing interface will be implemented here.\n\nFor now, you can modify data directly in the Firebase Console.',
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

  void _showDeleteConfirmation(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) {
    final itemName = collection == 'users'
        ? data['name'] ?? 'Unknown'
        : collection == 'vehicles'
        ? '${data['make'] ?? 'Unknown'} ${data['model'] ?? ''}'
        : 'Booking ${docId.substring(0, 8)}...';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text(
          'Are you sure you want to delete "$itemName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteItem(collection, docId, itemName);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(
    String collection,
    String docId,
    String itemName,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemName has been deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBulkActions(String collection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Actions - ${collection.toUpperCase()}'),
        content: const Text(
          'Bulk operations will be implemented here:\n\n'
          '• Bulk delete\n'
          '• Bulk status updates\n'
          '• Bulk verification\n'
          '• Import from CSV',
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

  void _exportData(String collection) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Export functionality for $collection will be implemented',
        ),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }
}
