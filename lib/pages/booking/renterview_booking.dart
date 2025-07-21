import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meadowmiles/models/booking_model.dart';
import 'package:meadowmiles/models/vehicle_model.dart';
import 'package:url_launcher/url_launcher.dart';

class RenterViewBookingPage extends StatefulWidget {
  final Booking booking;
  const RenterViewBookingPage({super.key, required this.booking});

  @override
  State<RenterViewBookingPage> createState() => _RenterViewBookingPageState();
}

class _RenterViewBookingPageState extends State<RenterViewBookingPage> {
  Vehicle? _vehicle;
  String? _ownerName;
  String? _ownerMobile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Fetch vehicle
    final vehicleDoc = await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(widget.booking.vehicleId)
        .get();
    if (vehicleDoc.exists) {
      _vehicle = Vehicle.fromMap(vehicleDoc.data()!, id: vehicleDoc.id);
      // Fetch owner
      final ownerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_vehicle!.ownerId)
          .get();
      if (ownerDoc.exists) {
        setState(() {
          _ownerName = ownerDoc.data()?['name'] ?? 'Unknown';
          _ownerMobile = ownerDoc.data()?['phoneNumber'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _ownerName = 'Unknown';
          _ownerMobile = '';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.onProcess:
        return Colors.blue;
      case BookingStatus.active:
        return Colors.green;
      case BookingStatus.returned:
        return Colors.purple;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.onProcess:
        return Icons.sync;
      case BookingStatus.active:
        return Icons.directions_car;
      case BookingStatus.returned:
        return Icons.check_circle_outline;
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusTitle(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Booking Pending';
      case BookingStatus.onProcess:
        return 'Processing';
      case BookingStatus.active:
        return 'Active Rental';
      case BookingStatus.returned:
        return 'Vehicle Returned';
      case BookingStatus.cancelled:
        return 'Booking Cancelled';
    }
  }

  String _getStatusDescription(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Waiting for owner approval';
      case BookingStatus.onProcess:
        return 'Your booking is being processed';
      case BookingStatus.active:
        return 'Enjoy your rental!';
      case BookingStatus.returned:
        return 'Vehicle has been returned to owner';
      case BookingStatus.cancelled:
        return 'This booking has been cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        forceMaterialTransparency: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicle == null
          ? const Center(child: Text('Vehicle not found.'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      child: SizedBox(
                        width: double.infinity,
                        height: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _vehicle!.imageUrl.isNotEmpty
                              ? Image.network(
                                  _vehicle!.imageUrl,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.car_repair,
                                          size: 60,
                                        ),
                                      ),
                                )
                              : Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.car_repair, size: 60),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _vehicle!.make,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _vehicle!.vehicleType
                                      .toString()
                                      .split('.')
                                      .last
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _vehicle!.model,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  '₱${_vehicle!.pricePerDay.toStringAsFixed(0)} / day',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _vehicle!.location,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  booking.rate.toStringAsFixed(1),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _ownerName ?? 'Unknown',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                if ((_ownerMobile ?? '').isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.call,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Call Owner',
                                    onPressed: () async {
                                      final uri = Uri(
                                        scheme: 'tel',
                                        path: _ownerMobile,
                                      );
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Could not launch dialer.',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                              ],
                            ),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              'Booking Information',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  'Booking ID: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(booking.id),
                              ],
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Status: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  booking.status
                                      .toString()
                                      .split('.')
                                      .last
                                      .toUpperCase(),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Rent Date: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  booking.rentDate.toLocal().toString().split(
                                    ' ',
                                  )[0],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Return Date: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  booking.returnDate.toLocal().toString().split(
                                    ' ',
                                  )[0],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Total Price: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '₱${booking.totalPrice.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (booking.address.isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Address: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(child: Text(booking.address)),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Status indicator
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          booking.status,
                        ).withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(
                            booking.status,
                          ).withAlpha((0.3 * 255).toInt()),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(booking.status),
                            color: _getStatusColor(booking.status),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getStatusTitle(booking.status),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(booking.status),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getStatusDescription(booking.status),
                                  style: TextStyle(
                                    color: _getStatusColor(
                                      booking.status,
                                    ).withAlpha((0.8 * 255).toInt()),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (booking.status == BookingStatus.returned &&
                        booking.rate == 0)
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.rate_review,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Rate Your Experience',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  RateBookingPage(booking: booking),
                            ),
                          );
                          if (result == true && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thank you for your feedback!'),
                              ),
                            );
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    if (booking.status == BookingStatus.returned &&
                        booking.rate > 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Booking Completed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Thank you for rating your experience!',
                              style: TextStyle(color: Colors.green),
                            ),
                            if (booking.feedback.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Your feedback: "${booking.feedback}"',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

// RateBookingPage stub (to be implemented)
class RateBookingPage extends StatefulWidget {
  final Booking booking;
  const RateBookingPage({super.key, required this.booking});

  @override
  State<RateBookingPage> createState() => _RateBookingPageState();
}

class _RateBookingPageState extends State<RateBookingPage> {
  final _formKey = GlobalKey<FormState>();
  double _rating = 5.0;
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Your Experience')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate your experience:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: _rating.toStringAsFixed(1),
                onChanged: _isSubmitting
                    ? null
                    : (v) => setState(() => _rating = v),
              ),
              Row(
                children: [
                  for (int i = 1; i <= 5; i++)
                    Icon(
                      i <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  const SizedBox(width: 8),
                  Text(_rating.toStringAsFixed(1)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Feedback',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please provide feedback.'
                    : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (_formKey.currentState?.validate() != true) return;
                          setState(() => _isSubmitting = true);
                          await FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(widget.booking.id)
                              .update({
                                'rate': _rating,
                                'feedback': _feedbackController.text,
                              });
                          if (context.mounted) Navigator.of(context).pop(true);
                        },
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Submit Rating'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
