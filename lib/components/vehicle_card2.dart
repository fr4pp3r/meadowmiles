import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';

class VehicleCard2 extends StatelessWidget {
  final Vehicle vehicle;
  final double rating;
  final VoidCallback? onTap;

  const VehicleCard2({
    super.key,
    required this.vehicle,
    this.rating = 0.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        shadowColor: Colors.black,
        margin: const EdgeInsets.all(8),
        child: Container(
          width: 220, // Make the card square
          height: 220,
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              // Car image at the bottom
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
              // Info overlay
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
                            '${vehicle.pricePerDay.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Text(' | day', style: TextStyle(fontSize: 12)),
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
                          index < rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
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
  }
}
