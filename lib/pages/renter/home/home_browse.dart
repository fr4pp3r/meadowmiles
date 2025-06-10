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
    Query query = FirebaseFirestore.instance
        .collection('vehicles')
        .where('isAvailable', isEqualTo: true);
    if (widget.vehicleType != null) {
      query = query.where(
        'vehicleType',
        isEqualTo: widget.vehicleType!.toString().split('.').last,
      );
    }
    if (widget.make != null && widget.make!.trim().isNotEmpty) {
      query = query.where(
        'make',
        isGreaterThanOrEqualTo: widget.make,
        isLessThanOrEqualTo: widget.make! + '\uf8ff',
      );
    }
    if (widget.model != null && widget.model!.trim().isNotEmpty) {
      query = query.where(
        'model',
        isGreaterThanOrEqualTo: widget.model,
        isLessThanOrEqualTo: widget.model! + '\uf8ff',
      );
    }
    if (widget.color != null && widget.color!.trim().isNotEmpty) {
      query = query.where(
        'color',
        isGreaterThanOrEqualTo: widget.color,
        isLessThanOrEqualTo: widget.color! + '\uf8ff',
      );
    }
    final snapshot = await query.get();
    setState(() {
      _results = snapshot.docs
          .map(
            (doc) =>
                Vehicle.fromMap(doc.data() as Map<String, dynamic>, id: doc.id),
          )
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
