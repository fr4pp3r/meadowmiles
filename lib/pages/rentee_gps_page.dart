import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:meadowmiles/models/tracking_device_model.dart';
import 'package:meadowmiles/states/authstate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class RenteeGpsPage extends StatefulWidget {
  const RenteeGpsPage({super.key});

  @override
  State<RenteeGpsPage> createState() => _RenteeGpsPageState();
}

class _RenteeGpsPageState extends State<RenteeGpsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LocationData? _currentLocation;
  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    // Refresh device markers when switching to map tab
    if (_tabController.index == 0) {
      _loadDeviceMarkers();
    }
  }

  Future<void> _initializeLocation() async {
    try {
      await _requestLocationPermission();
      _startLocationTracking();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      Location location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          throw Exception('Location service is not enabled');
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          throw Exception('Location permission not granted');
        }
      }
    } catch (e) {
      print('Error requesting location permission: $e');
      rethrow;
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      Location location = Location();

      _locationSubscription = location.onLocationChanged.listen(
        (LocationData currentLocation) {
          if (mounted) {
            setState(() {
              _currentLocation = currentLocation;
              _updateMarkers();
            });
          }
        },
        onError: (error) {
          print('Location tracking error: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location tracking error: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      print('Error starting location tracking: $e');
      rethrow;
    }
  }

  void _updateMarkers() {
    _markers.clear();

    // Add current location marker
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          ),
          infoWindow: const InfoWindow(
            title: 'Your Current Location',
            snippet: 'Real-time GPS position',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Load and add device markers
    _loadDeviceMarkers();
  }

  Future<void> _loadDeviceMarkers() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    final userUid = authState.currentUser?.uid;

    if (userUid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tracking_devices')
          .where('userUid', isEqualTo: userUid)
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        final device = TrackingDevice.fromMap(doc.data(), id: doc.id);

        // Only add marker if device has location data
        if (device.lastLatitude != null && device.lastLongitude != null) {
          _markers.add(
            Marker(
              markerId: MarkerId('device_${device.id}'),
              position: LatLng(device.lastLatitude!, device.lastLongitude!),
              infoWindow: InfoWindow(
                title: device.name,
                snippet: device.lastLocationUpdate != null
                    ? 'Last update: ${_formatDateTime(device.lastLocationUpdate!)}'
                    : 'No recent updates',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading device markers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0, // Remove title area completely
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Live Map'),
            Tab(icon: Icon(Icons.devices), text: 'Devices'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: [_buildMapTab(), _buildDevicesTab()],
      ),
    );
  }

  Widget _buildMapTab() {
    return Stack(
      children: [
        Column(
          children: [
            // Info and Refresh Bar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Blue: Your location, Red: Device locations',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadDeviceMarkers,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh device locations',
                    iconSize: 20,
                  ),
                ],
              ),
            ),

            // Map Container
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation != null
                          ? LatLng(
                              _currentLocation!.latitude!,
                              _currentLocation!.longitude!,
                            )
                          : const LatLng(
                              37.7749,
                              -122.4194,
                            ), // Default to San Francisco
                      zoom: 15.0,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapType: MapType.normal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location Info (commented out for now)
            // Container(...),
          ],
        ),
      ],
    );
  }

  Widget _buildDevicesTab() {
    final authState = Provider.of<AuthState>(context);
    final userUid = authState.currentUser?.uid;

    if (userUid == null) {
      return const Center(
        child: Text('Please log in to view tracking devices'),
      );
    }

    return Column(
      children: [
        // Add Device Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddDeviceDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Register New Device'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ),

        // Devices List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tracking_devices')
                .where('userUid', isEqualTo: userUid)
                .orderBy('registeredAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.devices,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tracking devices registered',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Register your first device to start tracking',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final device = TrackingDevice.fromMap(
                    docs[index].data() as Map<String, dynamic>,
                    id: docs[index].id,
                  );
                  return _buildDeviceCard(device);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(TrackingDevice device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: device.isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.gps_fixed,
                    color: device.isActive ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Device ID: ${device.id}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleDeviceAction(value, device),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: device.isActive ? 'deactivate' : 'activate',
                      child: Row(
                        children: [
                          Icon(
                            device.isActive ? Icons.pause : Icons.play_arrow,
                          ),
                          const SizedBox(width: 8),
                          Text(device.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  device.isActive ? Icons.circle : Icons.circle_outlined,
                  size: 12,
                  color: device.isActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  device.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: device.isActive ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'Registered: ${_formatDate(device.registeredAt)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (device.lastLocationUpdate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last location update: ${_formatDate(device.lastLocationUpdate!)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleDeviceAction(String action, TrackingDevice device) async {
    switch (action) {
      case 'edit':
        _showEditDeviceDialog(device);
        break;
      case 'activate':
      case 'deactivate':
        await _toggleDeviceStatus(device);
        break;
      case 'delete':
        _showDeleteDeviceDialog(device);
        break;
    }
  }

  void _showAddDeviceDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register New Device'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Device Name',
            hintText: 'e.g., My Car Tracker',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _registerDevice(nameController.text),
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  void _showEditDeviceDialog(TrackingDevice device) {
    final nameController = TextEditingController(text: device.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Device'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Device Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateDevice(device, nameController.text),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDeviceDialog(TrackingDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text(
          'Are you sure you want to delete "${device.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _deleteDevice(device),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _registerDevice(String name) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a device name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authState = Provider.of<AuthState>(context, listen: false);
    final userUid = authState.currentUser?.uid;

    if (userUid == null) return;

    try {
      final device = TrackingDevice(
        id: '', // Firestore will generate this
        name: name.trim(),
        userUid: userUid,
        registeredAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('tracking_devices')
          .add(device.toMap());

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Device "${device.name}" registered successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error registering device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateDevice(TrackingDevice device, String name) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a device name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('tracking_devices')
          .doc(device.id)
          .update({'name': name.trim()});

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleDeviceStatus(TrackingDevice device) async {
    try {
      await FirebaseFirestore.instance
          .collection('tracking_devices')
          .doc(device.id)
          .update({'isActive': !device.isActive});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Device ${!device.isActive ? 'activated' : 'deactivated'}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating device status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDevice(TrackingDevice device) async {
    try {
      await FirebaseFirestore.instance
          .collection('tracking_devices')
          .doc(device.id)
          .delete();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Device "${device.name}" deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
