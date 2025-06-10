import 'package:flutter/material.dart';
import 'package:meadowmiles/models/vehicle_model.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.make} ${vehicle.model}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Plate: ${vehicle.plateNumber}\n'
                      'Color: ${vehicle.color}\n'
                      'Price per day: Php ${vehicle.pricePerDay.toStringAsFixed(2)}\n'
                      'Year: ${vehicle.year}\n',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      vehicle.isAvailable ? "Available" : "Not Available",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: vehicle.isAvailable
                            ? const Color.fromARGB(255, 57, 126, 58)
                            : const Color.fromARGB(255, 155, 28, 19),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                height: 100,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: vehicle.imageUrl.isNotEmpty
                      ? Hero(
                          tag: 'vehicle-image-${vehicle.id}',
                          child: Image.network(
                            vehicle.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.car_repair),
                                ),
                          ),
                        )
                      : Hero(
                          tag: 'vehicle-image-${vehicle.id}',
                          child: Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.car_repair),
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
