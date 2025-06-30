import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meadowmiles/models/vehicle_model.dart';
import 'package:meadowmiles/pages/booking/add_booking.dart';

class ViewVehiclePage extends StatefulWidget {
  final Vehicle vehicle;
  const ViewVehiclePage({super.key, required this.vehicle});

  @override
  State<ViewVehiclePage> createState() => _ViewVehiclePageState();
}

class _ViewVehiclePageState extends State<ViewVehiclePage> {
  bool isAvailable = true;
  String? _ownerName;
  bool _isOwnerLoading = false;

  @override
  void initState() {
    super.initState();
    isAvailable = widget.vehicle.isAvailable;
    _fetchOwnerName();
  }

  Future<void> _fetchOwnerName() async {
    setState(() => _isOwnerLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.vehicle.ownerId)
          .get();
      if (doc.exists) {
        setState(() {
          _ownerName = doc.data()?['name'] ?? '';
          _isOwnerLoading = false;
        });
      } else {
        setState(() {
          _ownerName = null;
          _isOwnerLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _ownerName = null;
        _isOwnerLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(forceMaterialTransparency: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 6,
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: widget.vehicle.imageUrl.isNotEmpty
                        ? Image.network(
                            widget.vehicle.imageUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.car_repair, size: 60),
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
              Container(
                // Add elevation using Material widget
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.vehicle.make,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '₱ ${widget.vehicle.pricePerDay}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.vehicle.model,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              'per day',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
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
                              // widget.vehicle.location,
                              'Location: ${widget.vehicle.location}',
                              style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey.shade300,
                              child: const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _isOwnerLoading
                                  ? SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _ownerName ?? 'Unknown',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.call,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  // Implement call functionality here
                                },
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Car Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.vehicle.description.isNotEmpty
                              ? widget.vehicle.description
                              : 'No description provided.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isAvailable
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddBookingPage(
                                          vehicle: widget.vehicle,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isAvailable ? 'Rent Now' : 'Not Available',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
