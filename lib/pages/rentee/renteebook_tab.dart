import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meadowmiles/models/booking_model.dart';
import 'package:provider/provider.dart';
import 'package:meadowmiles/states/authstate.dart';
import 'package:meadowmiles/components/booking_card.dart';
import 'package:meadowmiles/pages/booking/renteeview_booking.dart';

class RenteeBookTab extends StatelessWidget {
  const RenteeBookTab({super.key});

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
          .where('ownerId', isEqualTo: userId)
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
            .where(
              (booking) =>
                  booking.status != BookingStatus.returned &&
                  booking.status != BookingStatus.cancelled,
            )
            .toList();
        if (bookings.isEmpty) {
          return const Center(child: Text('No active/pending bookings found.'));
        } else {
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
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
                onView: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          RenteeViewBookingPage(booking: booking),
                    ),
                  );
                },
              );
            },
          );
        }
      },
    );
  }
}
