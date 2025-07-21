import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';

class VehicleCard2 extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;

  const VehicleCard2({super.key, required this.vehicle, this.onTap});

  Future<double> _fetchAverageRating() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('vehicleId', isEqualTo: vehicle.id)
        .get();
    if (snapshot.docs.isEmpty) return 0.0;
    double total = 0;
    int count = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final rate = (data['rate'] is int)
          ? (data['rate'] as int).toDouble()
          : (data['rate'] ?? 0).toDouble();
      if (rate > 0) {
        total += rate;
        count++;
      }
    }
    if (count == 0) return 0.0;
    return total / count;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _fetchAverageRating(),
      builder: (context, snapshot) {
        final avgRating = snapshot.data ?? 0.0;
        return GestureDetector(
          onTap: onTap,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            shadowColor: Colors.black,
            margin: const EdgeInsets.all(8),
            child: Container(
              width: 220,
              height: 220,
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: vehicle.imageUrl.isNotEmpty
                          ? Image.network(
                              vehicle.imageUrl,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            )
                          : Image.asset(
                              'assets/logos/meadowmiles_logo2.png',
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.make,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                '₱',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                vehicle.pricePerDay.toStringAsFixed(0),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                ' | day',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.model,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < avgRating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
