import 'package:flutter/material.dart';
import 'package:meadowmiles/models/vehicle_model.dart';

class ViewVehiclePage extends StatefulWidget {
  final Vehicle vehicle;
  const ViewVehiclePage({super.key, required this.vehicle});

  @override
  State<ViewVehiclePage> createState() => _ViewVehiclePageState();
}

class _ViewVehiclePageState extends State<ViewVehiclePage> {
  bool isAvailable = true;

  @override
  void initState() {
    super.initState();
    isAvailable = widget.vehicle.isAvailable;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text('${widget.vehicle.make} ${widget.vehicle.model}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: 'vehicle-image-${widget.vehicle.id}',
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.vehicle.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            widget.vehicle.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.car_repair, size: 60),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Icon(
                  index < 3 ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 24),
            _ReadOnlyField(label: 'Make', value: ': ${widget.vehicle.make}'),
            _ReadOnlyField(label: 'Model', value: ': ${widget.vehicle.model}'),
            _ReadOnlyField(
              label: 'Plate Number',
              value: ': ${widget.vehicle.plateNumber}',
            ),
            _ReadOnlyField(label: 'Color', value: ': ${widget.vehicle.color}'),
            _ReadOnlyField(
              label: 'Year',
              value: ': ${widget.vehicle.year.toString()}',
            ),
            _ReadOnlyField(
              label: 'Price per day',
              value: ': ₱${widget.vehicle.pricePerDay.toStringAsFixed(2)}',
            ),
            _ReadOnlyField(
              label: 'Type',
              value:
                  ': ${widget.vehicle.vehicleType.toString().split('.').last}',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  widget.vehicle.isAvailable ? 'Available' : 'Not Available',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: widget.vehicle.isAvailable
                        ? const Color.fromARGB(255, 57, 126, 58)
                        : const Color.fromARGB(255, 155, 28, 19),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() {});
                // Here you would typically update the vehicle's availability in the database
              },
              child: Text('Rent this vehicle!'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
