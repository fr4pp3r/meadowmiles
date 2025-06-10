import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meadowmiles/appstate.dart';
import 'package:meadowmiles/components/vehicle_cards.dart';
import 'package:meadowmiles/models/vehicle_model.dart';
import 'package:meadowmiles/pages/rentee/vehicle/add_vehicle.dart';
import 'package:meadowmiles/pages/rentee/vehicle/view_vehicle.dart';
import 'package:provider/provider.dart';

class VehicleTab extends StatefulWidget {
  const VehicleTab({super.key});

  @override
  State<VehicleTab> createState() => _VehicleTabState();
}

class _VehicleTabState extends State<VehicleTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Vehicle> vehicles = [];
  List<Vehicle> filteredVehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchVehicles() async {
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final uid = appState.currentUser?.uid;
    if (uid == null) {
      setState(() {
        vehicles = [];
        filteredVehicles = [];
        _isLoading = false;
      });
      return;
    }
    final query = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('ownerId', isEqualTo: uid)
        .get();
    vehicles = query.docs
        .map((doc) => Vehicle.fromMap(doc.data(), id: doc.id))
        .toList();
    filteredVehicles = vehicles;
    setState(() => _isLoading = false);
  }

  void _onSearchChanged() {
    setState(() {
      filteredVehicles = vehicles
          .where(
            (vehicle) =>
                vehicle.make.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                vehicle.model.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                vehicle.plateNumber.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
          )
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: Theme.of(context).textTheme.bodySmall,
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search vehicles...',
                          hintStyle: Theme.of(context).textTheme.bodySmall,
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(360),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddVehiclePage(),
                          ),
                        );
                        if (result != null) {
                          // A vehicle was added, reload the list
                          await _fetchVehicles();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredVehicles.isEmpty
                    ? const Center(child: Text('No vehicles found.'))
                    : ListView.builder(
                        itemCount: filteredVehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = filteredVehicles[index];
                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ViewVehiclePage(vehicle: vehicle),
                                ),
                              );
                              setState(() {
                                _isLoading = true;
                              });
                              await _fetchVehicles();
                            },
                            child: VehicleCard(vehicle: vehicle),
                          );
                        },
                      ),
              ),
            ],
          );
  }
}
