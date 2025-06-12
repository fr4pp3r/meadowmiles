import 'package:flutter/material.dart';
import 'package:meadowmiles/models/vehicle_model.dart';
import 'package:meadowmiles/components/vehicle_cards.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meadowmiles/pages/vehicle/view_vehicle.dart';

class HomeBrowsePage extends StatefulWidget {
  final VehicleType? vehicleType;
  final String? make;
  final String? model;
  final String? color;
  final DateTime? startDate;
  final DateTime? endDate;
  const HomeBrowsePage({
    super.key,
    this.vehicleType,
    this.make,
    this.model,
    this.color,
    this.startDate,
    this.endDate,
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
    final vehicleSnapshot = await query.get();
    final makeFilter = (widget.make ?? '').trim().toLowerCase();
    final modelFilter = (widget.model ?? '').trim().toLowerCase();
    final colorFilter = (widget.color ?? '').trim().toLowerCase();

    // Date range filtering
    DateTime? startDate = widget.startDate;
    DateTime? endDate = widget.endDate;

    List<Vehicle> filteredVehicles = vehicleSnapshot.docs
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

    // If date range is selected, filter out vehicles that are booked in that range
    if (startDate != null && endDate != null) {
      List<Vehicle> availableVehicles = [];
      for (final vehicle in filteredVehicles) {
        final bookingsSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('vehicleId', isEqualTo: vehicle.id)
            .where('status', whereIn: ['pending', 'onProcess', 'active'])
            .get();
        bool isAvailable = true;
        for (final doc in bookingsSnapshot.docs) {
          final data = doc.data();
          final bookingStart = (data['rentDate'] as Timestamp).toDate();
          final bookingEnd = (data['returnDate'] as Timestamp).toDate();
          // Check for overlap
          if (!(endDate.isBefore(bookingStart) ||
              startDate.isAfter(bookingEnd))) {
            isAvailable = false;
            break;
          }
        }
        if (isAvailable) {
          availableVehicles.add(vehicle);
        }
      }
      filteredVehicles = availableVehicles;
    }

    setState(() {
      _results = filteredVehicles;
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
                  child: VehicleCard(
                    vehicle: vehicle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ViewVehiclePage(vehicle: vehicle),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
