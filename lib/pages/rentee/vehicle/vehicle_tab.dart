import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meadowmiles/appstate.dart';
import 'package:meadowmiles/models/vehicle_model.dart';
import 'package:meadowmiles/pages/rentee/vehicle/add_vehicle.dart';
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

  void _viewVehicle(Vehicle vehicle) {
    // Implement view vehicle logic or navigation
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${vehicle.make} ${vehicle.model}'),
        content: Text('Plate: ${vehicle.plateNumber}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
                            onTap: () => _viewVehicle(vehicle),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                                right: 8.0,
                                bottom: 8.0,
                              ),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${vehicle.make} ${vehicle.model}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
                                            ),
                                            Text(
                                              'Plate: ${vehicle.plateNumber}\n'
                                              'Color: ${vehicle.color}\n'
                                              'Price per day: Php ${vehicle.pricePerDay.toStringAsFixed(2)}\n'
                                              'Year: ${vehicle.year}\n',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                            ),
                                            Text(
                                              vehicle.isAvailable
                                                  ? "Available"
                                                  : "Not Available",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: vehicle.isAvailable
                                                        ? const Color.fromARGB(
                                                            255,
                                                            57,
                                                            126,
                                                            58,
                                                          )
                                                        : const Color.fromARGB(
                                                            255,
                                                            155,
                                                            28,
                                                            19,
                                                          ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 100,
                                        height: 100,
                                        child: vehicle.imageUrl.isNotEmpty
                                            ? Image.network(
                                                vehicle.imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
                                                      color:
                                                          Colors.grey.shade300,
                                                      child: const Icon(
                                                        Icons.car_repair,
                                                      ),
                                                    ),
                                              )
                                            : Container(
                                                color: Colors.grey.shade300,
                                                child: const Icon(
                                                  Icons.car_repair,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
  }
}
