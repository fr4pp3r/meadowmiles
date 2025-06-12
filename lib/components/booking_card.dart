import 'package:flutter/material.dart';
import 'package:meadowmiles/models/booking_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancel;
  final VoidCallback? onView;

  const BookingCard({
    super.key,
    required this.booking,
    this.onCancel,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('vehicles')
          .doc(booking.vehicleId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Vehicle not found'),
            ),
          );
        }
        final vehicleData = snapshot.data!.data() as Map<String, dynamic>;
        final make = vehicleData['make'] ?? 'Unknown';
        final model = vehicleData['model'] ?? '';
        final location = vehicleData['location'] ?? '';
        final imageUrl = vehicleData['imageUrl'] ?? '';
        final type = vehicleData['vehicleType'] ?? '';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 90,
                                height: 90,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.car_repair, size: 40),
                              ),
                        )
                      : Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.car_repair, size: 40),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            make,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            model,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              type.toString().toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            booking.rentDate.toLocal().toString().split(' ')[0],
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '-',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            booking.returnDate.toLocal().toString().split(
                              ' ',
                            )[0],
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Status row
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Status: ${booking.status.toString().split('.').last}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (onCancel != null)
                            OutlinedButton(
                              onPressed: onCancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Cancel'),
                            ),
                          const SizedBox(width: 8),
                          if (onView != null)
                            FilledButton(
                              onPressed: onView,
                              child: const Text('View'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
