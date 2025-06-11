import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meadowmiles/models/booking_model.dart';
import 'package:provider/provider.dart';
import 'package:meadowmiles/states/authstate.dart';

class RenterBookTab extends StatelessWidget {
  const RenterBookTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context);
    final userId = authState.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Not logged in.'));
    }
    return StreamBuilder<QuerySnapshot>(
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
        final bookings = docs
            .map(
              (doc) => Booking.fromMap(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ),
            )
            .toList();
        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final isCancellable =
                booking.status != BookingStatus.cancelled &&
                booking.status != BookingStatus.returned;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.primary.withAlpha(
                1,
              ), // Light primary color using withAlpha
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('vehicles')
                    .doc(booking.vehicleId)
                    .get(),
                builder: (context, vehicleSnap) {
                  if (vehicleSnap.connectionState == ConnectionState.waiting) {
                    return const ListTile(title: Text('Loading vehicle...'));
                  }
                  if (!vehicleSnap.hasData || !vehicleSnap.data!.exists) {
                    return ListTile(
                      title: Text('Vehicle: ${booking.vehicleId} (not found)'),
                    );
                  }
                  final vehicleData =
                      vehicleSnap.data!.data() as Map<String, dynamic>;
                  final make = vehicleData['make'] ?? 'Unknown';
                  final model = vehicleData['model'] ?? '';
                  return ListTile(
                    title: Text(
                      '$make $model',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              const TextSpan(
                                text: 'From: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: booking.rentDate
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              const TextSpan(
                                text: 'To: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: booking.returnDate
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              const TextSpan(
                                text: 'Status: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: booking.status.toString().split('.').last,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (booking.status == BookingStatus.cancelled)
                          TextButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Remove Booking'),
                                  content: const Text(
                                    'Are you sure you want to remove this booking from your list?',
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
                                    .update({'renterId': ''});
                              }
                            },
                            child: const Text('Remove'),
                          )
                        else
                          TextButton(
                            onPressed: isCancellable
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
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
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
                            child: const Text('Cancel'),
                          ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Booking Details'),
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                        children: [
                                          const TextSpan(
                                            text: 'Booking ID: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(text: booking.id),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    RichText(
                                      text: TextSpan(
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                        children: [
                                          const TextSpan(
                                            text: 'Vehicle: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(text: '$make $model'),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    RichText(
                                      text: TextSpan(
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                        children: [
                                          const TextSpan(
                                            text: 'From: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: booking.rentDate
                                                .toLocal()
                                                .toString()
                                                .split(' ')[0],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    RichText(
                                      text: TextSpan(
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                        children: [
                                          const TextSpan(
                                            text: 'To: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: booking.returnDate
                                                .toLocal()
                                                .toString()
                                                .split(' ')[0],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    RichText(
                                      text: TextSpan(
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                        children: [
                                          const TextSpan(
                                            text: 'Status: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: booking.status
                                                .toString()
                                                .split('.')
                                                .last,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('View'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
