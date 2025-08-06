import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meadowmiles/models/booking_model.dart';
import 'package:meadowmiles/models/vehicle_model.dart';
import 'package:url_launcher/url_launcher.dart';

class RenteeViewBookingPage extends StatefulWidget {
  final Booking booking;
  const RenteeViewBookingPage({super.key, required this.booking});

  @override
  State<RenteeViewBookingPage> createState() => _RenteeViewBookingPageState();
}

class _RenteeViewBookingPageState extends State<RenteeViewBookingPage> {
  Vehicle? _vehicle;
  String? _renterName;
  String? _renterMobile;
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
      // Fetch renter
      final renterDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.booking.renterId)
          .get();
      if (renterDoc.exists) {
        setState(() {
          _renterName = renterDoc.data()?['name'] ?? 'Unknown';
          _renterMobile = renterDoc.data()?['phoneNumber'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _renterName = 'Unknown';
          _renterMobile = '';
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
        return 'Waiting for your approval';
      case BookingStatus.onProcess:
        return 'Booking is being processed, meet up soon for vehicle handover';
      case BookingStatus.active:
        return 'Vehicle is currently rented';
      case BookingStatus.returned:
        return 'Vehicle has been returned';
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
                                  fit: BoxFit.cover,
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
                                    fontSize: 22,
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
                                    fontSize: 18,
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
                                    fontSize: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  '₱${_vehicle!.pricePerDay.toStringAsFixed(0)} / day',
                                  style: TextStyle(
                                    fontSize: 18,
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
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _vehicle!.location,
                                  style: TextStyle(
                                    fontSize: 16,
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
                                Icon(Icons.star, color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  booking.rate > 0
                                      ? '${booking.rate.toStringAsFixed(1)} (Renter Rating)'
                                      : 'No rating yet',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _renterName ?? 'Unknown',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                if ((_renterMobile ?? '').isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.call,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Call Renter',
                                    onPressed: () async {
                                      final uri = Uri(
                                        scheme: 'tel',
                                        path: _renterMobile,
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
                    if (booking.status == BookingStatus.pending)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        label: const Text(
                          'Mark as On Process',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Mark as On Process'),
                              content: const Text(
                                'Are you sure you want to mark this booking as "On Process"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
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
                                .update({'status': 'onProcess'});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Booking marked as On Process.',
                                  ),
                                ),
                              );
                              Navigator.of(context).pop();
                            }
                          }
                        },
                      ),
                    if (booking.status == BookingStatus.onProcess)
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Activate Booking',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Mark as Active'),
                              content: const Text(
                                'Are you sure you want to mark this booking as "Active"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
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
                                .update({'status': 'active'});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Booking marked as Active.'),
                                ),
                              );
                              Navigator.of(context).pop();
                            }
                          }
                          // final result = await Navigator.of(context).push(
                          //   MaterialPageRoute(
                          //     builder: (context) =>
                          //         AddTransactionProofPage(booking: booking),
                          //   ),
                          // );
                          // if (result == true && context.mounted) {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //     const SnackBar(
                          //       content: Text(
                          //         'Transaction info added and booking activated.',
                          //       ),
                          //     ),
                          //   );
                          //   Navigator.of(context).pop();
                          // }
                        },
                      ),
                    if (booking.status == BookingStatus.active)
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.assignment_return,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Mark as Returned',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: Colors.purple,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Mark as Returned'),
                              content: const Text(
                                'Are you sure the vehicle has been returned? This will allow the renter to rate their experience.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Yes, Mark as Returned'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('bookings')
                                .doc(booking.id)
                                .update({'status': 'returned'});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Booking marked as returned. The renter can now rate their experience.',
                                  ),
                                ),
                              );
                              Navigator.of(context).pop();
                            }
                          }
                        },
                      ),
                    if (booking.status == BookingStatus.returned)
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
                              'Rental Completed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.rate > 0
                                  ? 'Renter has rated: ${booking.rate.toStringAsFixed(1)} stars'
                                  : 'Waiting for renter to rate their experience',
                              style: const TextStyle(color: Colors.green),
                              textAlign: TextAlign.center,
                            ),
                            if (booking.feedback.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Renter Feedback:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '"${booking.feedback}"',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
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

// AddTransactionProofPage stub (to be implemented)
class AddTransactionProofPage extends StatefulWidget {
  final Booking booking;
  const AddTransactionProofPage({super.key, required this.booking});

  @override
  State<AddTransactionProofPage> createState() =>
      _AddTransactionProofPageState();
}

class _AddTransactionProofPageState extends State<AddTransactionProofPage> {
  final _formKey = GlobalKey<FormState>();
  final _transactionIdController = TextEditingController();
  String? _proofUrl;
  bool _isUploading = false;

  @override
  void dispose() {
    _transactionIdController.dispose();
    super.dispose();
  }

  Future<void> _uploadProof() async {
    // TODO: Implement file picker and upload to Supabase, then set _proofUrl
    // For now, just simulate upload
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _proofUrl =
          'https://example.com/proof.jpg'; // Replace with actual upload result
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction ID & Proof')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _transactionIdController,
                decoration: const InputDecoration(
                  labelText: 'Transaction ID / Receipt Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Proof'),
                    onPressed: _isUploading ? null : _uploadProof,
                  ),
                  if (_isUploading) ...[
                    const SizedBox(width: 12),
                    const CircularProgressIndicator(),
                  ],
                  if (_proofUrl != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.check_circle, color: Colors.green),
                    const Text(' Uploaded'),
                  ],
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading
                      ? null
                      : () async {
                          if (_formKey.currentState?.validate() != true ||
                              _proofUrl == null) {
                            return;
                          }
                          await FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(widget.booking.id)
                              .update({
                                'transactionId': _transactionIdController.text,
                                'proofUrl': _proofUrl,
                                'status': 'active',
                              });
                          if (context.mounted) Navigator.of(context).pop(true);
                        },
                  child: const Text('Finish & Activate Booking'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
