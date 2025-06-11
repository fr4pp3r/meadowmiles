import 'package:flutter/material.dart';
import 'package:meadowmiles/models/vehicle_model.dart';
import 'package:meadowmiles/components/vehicle_cards.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeBrowsePage extends StatefulWidget {
  final VehicleType? vehicleType;
  final String? make;
  final String? model;
  final String? color;
  const HomeBrowsePage({
    super.key,
    this.vehicleType,
    this.make,
    this.model,
    this.color,
  });

  @override
  State<HomeBrowsePage> createState() => _HomeBrowsePageState();
}

class _HomeBrowsePageState extends State<HomeBrowsePage> {
  List<Vehicle> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchVehicles();
  }

  Future<void> _searchVehicles() async {
    setState(() => _isLoading = true);
    // Only filter by isAvailable and vehicleType in Firestore
    Query query = FirebaseFirestore.instance
        .collection('vehicles')
        .where('isAvailable', isEqualTo: true);
    if (widget.vehicleType != null) {
      query = query.where(
        'vehicleType',
        isEqualTo: widget.vehicleType!.toString().split('.').last,
      );
    }
    final snapshot = await query.get();
    final makeFilter = (widget.make ?? '').trim().toLowerCase();
    final modelFilter = (widget.model ?? '').trim().toLowerCase();
    final colorFilter = (widget.color ?? '').trim().toLowerCase();
    setState(() {
      _results = snapshot.docs
          .map(
            (doc) =>
                Vehicle.fromMap(doc.data() as Map<String, dynamic>, id: doc.id),
          )
          .where((vehicle) {
            final make = vehicle.make.toLowerCase();
            final model = vehicle.model.toLowerCase();
            final color = vehicle.color.toLowerCase();
            final matchesMake = makeFilter.isEmpty || make.contains(makeFilter);
            final matchesModel =
                modelFilter.isEmpty || model.contains(modelFilter);
            final matchesColor =
                colorFilter.isEmpty || color.contains(colorFilter);
            return matchesMake && matchesModel && matchesColor;
          })
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Vehicles'),
        forceMaterialTransparency: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? const Center(child: Text('No vehicles found.'))
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final vehicle = _results[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: VehicleCard(vehicle: vehicle, disableHero: true),
                );
              },
            ),
    );
  }
}
