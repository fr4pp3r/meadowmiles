import 'package:flutter/material.dart';
import 'package:meadowmiles/components/vehicle_cards.dart';
import 'package:meadowmiles/models/vehicle_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meadowmiles/pages/renter/home/home_browse.dart';
import 'package:meadowmiles/pages/vehicle/view_vehicle.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  VehicleType? _selectedVehicleType;
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final query = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('isAvailable', isEqualTo: true)
          .get();
      setState(() {
        _vehicles = query.docs
            .map((doc) => Vehicle.fromMap(doc.data(), id: doc.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Optionally show error
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you ready to start your next adventure?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 8.0),
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Looking for a ride?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16.0),
                          DropdownButtonFormField<VehicleType>(
                            value: _selectedVehicleType,
                            style: Theme.of(context).textTheme.bodySmall,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              labelText: 'Vehicle Type',
                              labelStyle: Theme.of(context).textTheme.bodySmall,
                              hintText: 'Select vehicle type',
                              hintStyle: Theme.of(context).textTheme.bodySmall,
                            ),
                            items: VehicleType.values.map((type) {
                              return DropdownMenuItem<VehicleType>(
                                value: type,
                                child: Text(type.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedVehicleType = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a vehicle type';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _makeController,
                            style: Theme.of(context).textTheme.bodySmall,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              labelText: 'Preferred Make/Brand',
                              labelStyle: Theme.of(context).textTheme.bodySmall,
                              hintText: 'e.g. Toyota, Ford, Tesla',
                              hintStyle: Theme.of(context).textTheme.bodySmall,
                            ),
                            validator: (value) {
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _modelController,
                            style: Theme.of(context).textTheme.bodySmall,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              labelText: 'Preferred Model',
                              labelStyle: Theme.of(context).textTheme.bodySmall,
                              hintText: 'e.g. Camry, F-150, Model 3',
                              hintStyle: Theme.of(context).textTheme.bodySmall,
                            ),
                            validator: (value) {
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _colorController,
                            style: Theme.of(context).textTheme.bodySmall,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              labelText: 'Preferred Color',
                              labelStyle: Theme.of(context).textTheme.bodySmall,
                              hintText: 'e.g. Red, Blue, Black',
                              hintStyle: Theme.of(context).textTheme.bodySmall,
                            ),
                            validator: (value) {
                              return null;
                            },
                          ),
                          const SizedBox(height: 24.0),
                          SizedBox(
                            width: 150,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                              onPressed: () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => HomeBrowsePage(
                                        vehicleType: _selectedVehicleType,
                                        make: _makeController.text.trim(),
                                        model: _modelController.text.trim(),
                                        color: _colorController.text.trim(),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                'Browse',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ], // <-- This closes the children: [ of the Column inside the Container
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Vehicles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HomeBrowsePage(),
                      ),
                    );
                  },
                  child: Text(
                    'View All',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _isLoading
                  ? SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Row(
                      children: _vehicles.isEmpty
                          ? [Text('No vehicles found.')]
                          : _vehicles
                                .map(
                                  (vehicle) => GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ViewVehiclePage(vehicle: vehicle),
                                        ),
                                      );
                                    },
                                    child: SizedBox(
                                      width: 400,
                                      height: 250,
                                      child: VehicleCard(
                                        vehicle: vehicle,
                                        disableHero: true,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                    ),
            ),
          ], // <-- This closes the children: [ of the main Column in build
        ),
      ),
    );
  }
}
