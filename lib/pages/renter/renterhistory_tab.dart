import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meadowmiles/models/booking_model.dart';
import 'package:provider/provider.dart';
import 'package:meadowmiles/states/authstate.dart';
import 'package:meadowmiles/components/booking_card.dart';
import 'package:meadowmiles/pages/booking/renterview_booking.dart';

class RenterHistoryTab extends StatefulWidget {
  const RenterHistoryTab({super.key});

  @override
  State<RenterHistoryTab> createState() => _RenterHistoryTabState();
}

class _RenterHistoryTabState extends State<RenterHistoryTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, Map<String, dynamic>> _vehicleCache = {};
  Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdditionalData(List<Booking> bookings) async {
    // Get unique vehicle IDs and owner IDs
    final vehicleIds = bookings.map((b) => b.vehicleId).toSet();
    final ownerIds = bookings.map((b) => b.ownerId).toSet();

    // Load vehicles data
    for (final vehicleId in vehicleIds) {
      if (!_vehicleCache.containsKey(vehicleId)) {
        try {
          final vehicleDoc = await FirebaseFirestore.instance
              .collection('vehicles')
              .doc(vehicleId)
              .get();
          if (vehicleDoc.exists) {
            _vehicleCache[vehicleId] = vehicleDoc.data() as Map<String, dynamic>;
          }
        } catch (e) {
          print('Error loading vehicle $vehicleId: $e');
        }
      }
    }

    // Load users data (owners)
    for (final ownerId in ownerIds) {
      if (!_userCache.containsKey(ownerId)) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(ownerId)
              .get();
          if (userDoc.exists) {
            _userCache[ownerId] = userDoc.data() as Map<String, dynamic>;
          }
        } catch (e) {
          print('Error loading user $ownerId: $e');
        }
      }
    }
  }

  List<Booking> _filterBookings(List<Booking> bookings) {
    if (_searchQuery.isEmpty) {
      return bookings;
    }

    return bookings.where((booking) {
      final query = _searchQuery.toLowerCase();
      
      // Search in booking data
      bool matches = booking.id.toLowerCase().contains(query) ||
          booking.vehicleId.toLowerCase().contains(query) ||
          booking.status.toString().toLowerCase().contains(query) ||
          booking.totalPrice.toString().contains(query);

      // Search in vehicle data
      final vehicleData = _vehicleCache[booking.vehicleId];
      if (vehicleData != null) {
        final make = vehicleData['make']?.toString().toLowerCase() ?? '';
        final model = vehicleData['model']?.toString().toLowerCase() ?? '';
        final vehicleName = '$make $model'.toLowerCase();
        matches = matches || vehicleName.contains(query) ||
            make.contains(query) || model.contains(query);
      }

      // Search in owner data
      final userData = _userCache[booking.ownerId];
      if (userData != null) {
        final firstName = userData['firstName']?.toString().toLowerCase() ?? '';
        final lastName = userData['lastName']?.toString().toLowerCase() ?? '';
        final fullName = '$firstName $lastName'.toLowerCase();
        final email = userData['email']?.toString().toLowerCase() ?? '';
        matches = matches || fullName.contains(query) ||
            firstName.contains(query) || lastName.contains(query) ||
            email.contains(query);
      }

      return matches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context);
    final userId = authState.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Not logged in.'));
    }
    
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by vehicle, owner name, or booking details...',
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
        ),
        
        // Bookings List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('renterId', isEqualTo: userId)
                .orderBy('rentDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: \\${snapshot.error}'));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No bookings found.'));
              }
              
              final allBookings = docs
                  .map(
                    (doc) => Booking.fromMap(
                      doc.data() as Map<String, dynamic>,
                      id: doc.id,
                    ),
                  )
                  .where(
                    (booking) =>
                        booking.status == BookingStatus.returned ||
                        booking.status == BookingStatus.cancelled,
                  )
                  .toList();

              return FutureBuilder<void>(
                future: _loadAdditionalData(allBookings),
                builder: (context, loadingSnapshot) {
                  if (loadingSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredBookings = _filterBookings(allBookings);

                  if (filteredBookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No booking history found'
                                : 'No bookings match your search',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Try searching by vehicle name, owner name, or booking details',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      final isCancellable =
                          booking.status != BookingStatus.cancelled &&
                          booking.status != BookingStatus.returned;
                      return BookingCard(
                        booking: booking,
                        onCancel: isCancellable
                            ? () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Cancel Booking'),
                                    content: const Text(
                                      'Are you sure you want to cancel this booking?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await FirebaseFirestore.instance
                                      .collection('bookings')
                                      .doc(booking.id)
                                      .update({'status': 'cancelled'});
                                }
                              }
                            : null,
                        onView: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  RenterViewBookingPage(booking: booking),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
