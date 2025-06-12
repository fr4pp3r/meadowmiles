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
                                  '${booking.rentDate.toLocal().toString().split(' ')[0]}',
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
                                  '${booking.returnDate.toLocal().toString().split(' ')[0]}',
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
                  ],
                ),
              ),
            ),
    );
  }
}
