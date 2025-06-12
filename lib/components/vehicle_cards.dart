import 'package:flutter/material.dart';
import 'package:meadowmiles/models/vehicle_model.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;

  const VehicleCard({super.key, required this.vehicle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Info
              Expanded(
                child: Column(
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
                        Text(
                          vehicle.vehicleType
                              .toString()
                              .split('.')
                              .last
                              .toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.model,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
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
                    const SizedBox(height: 4),
                    Text(
                      'Location: Manila', // Placeholder location
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < 4
                                ? Icons.star
                                : Icons.star_border, // 4/5 rating for now
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          '4.0',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('View'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right: Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: vehicle.imageUrl.isNotEmpty
                      ? Image.network(
                          vehicle.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.car_repair),
                              ),
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.car_repair),
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
