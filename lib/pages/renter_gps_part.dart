import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:meadowmiles/states/authstate.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'dart:convert';

class RenterGpsPage extends StatefulWidget {
  const RenterGpsPage({super.key});

  @override
  State<RenterGpsPage> createState() => _RenterGpsPageState();
}

class _RenterGpsPageState extends State<RenterGpsPage> {
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _deviceName;
  String? _deviceId;
  DateTime? _lastConnectionTime;
  double? _lastLatitude;
  double? _lastLongitude;
  DateTime? _lastLocationUpdate;

  // Location tracking variables
  Location? _location;
  StreamSubscription<LocationData>? _locationSubscription;
  bool _isLocationTracking = false;
  LocationData? _currentLocation;

  @override
  void initState() {
    super.initState();
    _checkDeviceStatus();
    _initializeLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkDeviceStatus() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    final userUid = authState.currentUser?.uid;

    if (userUid == null) return;

    try {
      // Check if user has any active GPS tracking devices
      final snapshot = await FirebaseFirestore.instance
          .collection('tracking_devices')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        final deviceData = snapshot.docs.first.data();
        setState(() {
          _isConnected = true;
          _deviceName = deviceData['name'];
          _deviceId = deviceData['id'] ?? snapshot.docs.first.id;
          _lastConnectionTime = deviceData['lastConnectionTime'] != null
              ? (deviceData['lastConnectionTime'] as Timestamp).toDate()
              : null;
          _lastLatitude = deviceData['lastLatitude']?.toDouble();
          _lastLongitude = deviceData['lastLongitude']?.toDouble();
          _lastLocationUpdate = deviceData['lastLocationUpdate'] != null
              ? (deviceData['lastLocationUpdate'] as Timestamp).toDate()
              : null;
        });
      }
    } catch (e) {
      print('Error checking device status: $e');
    }
  }

  Future<void> _connectDevice() async {
    // Show BLE device scanning dialog
    _showBleDeviceDialog();
  }

  Future<void> _disconnectDevice() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    final userUid = authState.currentUser?.uid;

    if (userUid == null) return;

    try {
      // Update all active devices for this user to inactive
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('tracking_devices')
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'disconnectionTime': Timestamp.now(),
        });
      }

      await batch.commit();

      // Stop location tracking when disconnecting
      _stopLocationTracking();

      if (mounted) {
        setState(() {
          _isConnected = false;
          _deviceName = null;
          _deviceId = null;
          _lastConnectionTime = null;
          _lastLatitude = null;
          _lastLongitude = null;
          _lastLocationUpdate = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS device disconnected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disconnect device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initializeLocation() async {
    try {
      _location = Location();
      await _requestLocationPermission();
    } catch (e) {
      print('Error initializing location: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await _location!.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location!.requestService();
        if (!serviceEnabled) {
          throw Exception('Location service is not enabled');
        }
      }

      PermissionStatus permissionGranted = await _location!.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location!.requestPermission();
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
    if (_location == null || !_isConnected || _deviceId == null) return;

    try {
      setState(() {
        _isLocationTracking = true;
      });

      _locationSubscription = _location!.onLocationChanged.listen(
        (LocationData currentLocation) {
          if (mounted) {
            setState(() {
              _currentLocation = currentLocation;
              _lastLatitude = currentLocation.latitude;
              _lastLongitude = currentLocation.longitude;
              _lastLocationUpdate = DateTime.now();
            });
            _updateDeviceLocation(currentLocation);
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
      if (mounted) {
        setState(() {
          _isLocationTracking = false;
        });
      }
    }
  }

  Future<void> _stopLocationTracking() async {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    setState(() {
      _isLocationTracking = false;
    });
  }

  Future<void> _updateDeviceLocation(LocationData location) async {
    if (_deviceId == null ||
        location.latitude == null ||
        location.longitude == null)
      return;

    final authState = Provider.of<AuthState>(context, listen: false);
    final userUid = authState.currentUser?.uid;

    if (userUid == null) return;

    try {
      // Find the device document and update its location
      final deviceQuery = await FirebaseFirestore.instance
          .collection('tracking_devices')
          .where('userUid', isEqualTo: userUid)
          .where('id', isEqualTo: _deviceId)
          .limit(1)
          .get();

      if (deviceQuery.docs.isNotEmpty) {
        final deviceDoc = deviceQuery.docs.first;
        await deviceDoc.reference.update({
          'lastLatitude': location.latitude,
          'lastLongitude': location.longitude,
          'lastLocationUpdate': Timestamp.now(),
          'accuracy': location.accuracy,
          'altitude': location.altitude,
          'speed': location.speed,
        });
      }
    } catch (e) {
      print('Error updating device location: $e');
    }
  }

  void _showBleDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          BleDeviceDialog(onDeviceConnected: _onDeviceConnected),
    );
  }

  Future<void> _onDeviceConnected(String deviceId, String deviceName) async {
    final authState = Provider.of<AuthState>(context, listen: false);
    final userUid = authState.currentUser?.uid;

    if (userUid == null) return;

    try {
      // Look for existing device in tracking_devices collection
      final deviceQuery = await FirebaseFirestore.instance
          .collection('tracking_devices')
          .where('userUid', isEqualTo: userUid)
          .where('id', isEqualTo: deviceId)
          .limit(1)
          .get();

      if (deviceQuery.docs.isNotEmpty) {
        // Device exists, update its connection status and last connection time
        final deviceDoc = deviceQuery.docs.first;
        await deviceDoc.reference.update({
          'isActive': true,
          'lastConnectionTime': Timestamp.now(),
          'connectionType': 'BLE',
          'firmwareVersion': '1.0.0',
          'batteryLevel': 85,
        });

        if (mounted) {
          setState(() {
            _isConnected = true;
            _deviceName = deviceName;
            _deviceId = deviceId;
            _lastConnectionTime = DateTime.now();
          });

          // Start location tracking after device is connected
          _startLocationTracking();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Device "$deviceName" connected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Device doesn't exist, show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Device not found. Please register the device first in the Devices tab.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with refresh button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GPS Device Status',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _checkDeviceStatus,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Status',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Card
              _buildStatusCard(),
              const SizedBox(height: 24),

              // Device Info Card (if connected)
              if (_isConnected) ...[
                _buildDeviceInfoCard(),
                const SizedBox(height: 24),
              ],

              // Location Data Card (if available)
              if (_isConnected &&
                  _lastLatitude != null &&
                  _lastLongitude != null) ...[
                _buildLocationCard(),
                const SizedBox(height: 24),
              ],

              // Connection Button
              _buildConnectionButton(),

              const SizedBox(height: 24),

              // Instructions Card
              _buildInstructionsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Status Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isConnected
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
              ),
              child: Icon(
                _isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                size: 48,
                color: _isConnected ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),

            // Status Text
            Text(
              _isConnected ? 'Device Connected' : 'No Device Connected',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isConnected ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              _isConnected
                  ? 'Your ESP32 GPS tracker is connected and ready'
                  : 'Connect your ESP32 GPS tracker to start tracking',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text(
                  'Device Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow('Device Name', _deviceName ?? 'Unknown'),
            const SizedBox(height: 8),
            _buildInfoRow('Device ID', _deviceId ?? 'Unknown'),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Connected At',
              _lastConnectionTime != null
                  ? _formatDateTime(_lastConnectionTime!)
                  : 'Unknown',
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Connection Type', 'Bluetooth LE'),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Location Tracking',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      _isLocationTracking
                          ? Icons.location_on
                          : Icons.location_off,
                      size: 16,
                      color: _isLocationTracking ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isLocationTracking ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: _isLocationTracking ? Colors.green : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLocationTracking
                          ? _stopLocationTracking
                          : _startLocationTracking,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(60, 30),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: Text(
                        _isLocationTracking ? 'Stop' : 'Start',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                Text(
                  'Latest Location Data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              'Latitude',
              _lastLatitude?.toStringAsFixed(6) ?? '--',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Longitude',
              _lastLongitude?.toStringAsFixed(6) ?? '--',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Last Update',
              _lastLocationUpdate != null
                  ? _formatDateTime(_lastLocationUpdate!)
                  : 'No data received',
            ),
            if (_currentLocation != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                'Accuracy',
                _currentLocation!.accuracy != null
                    ? '${_currentLocation!.accuracy!.toStringAsFixed(1)}m'
                    : '--',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Altitude',
                _currentLocation!.altitude != null
                    ? '${_currentLocation!.altitude!.toStringAsFixed(1)}m'
                    : '--',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Speed',
                _currentLocation!.speed != null
                    ? '${(_currentLocation!.speed! * 3.6).toStringAsFixed(1)} km/h'
                    : '--',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isConnecting
            ? null
            : (_isConnected ? _disconnectDevice : _connectDevice),
        icon: _isConnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_isConnected ? Icons.bluetooth_disabled : Icons.bluetooth),
        label: Text(
          _isConnecting
              ? 'Connecting...'
              : (_isConnected ? 'Disconnect Device' : 'Connect Device'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isConnected ? Colors.red : Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline),
                const SizedBox(width: 8),
                Text(
                  'How to Connect',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text('1. Turn on your ESP32 GPS tracker'),
            const SizedBox(height: 8),
            const Text(
              '2. Make sure Bluetooth and Location are enabled on your phone',
            ),
            const SizedBox(height: 8),
            const Text('3. Tap "Connect Device" to scan for available devices'),
            const SizedBox(height: 8),
            const Text('4. Select your ESP32 GPS tracker from the list'),
            const SizedBox(height: 8),
            const Text(
              '5. Once connected, location tracking will start automatically',
            ),
            const SizedBox(height: 8),
            const Text(
              '6. Your phone\'s GPS will update the device location in real-time',
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: Location tracking uses your phone\'s GPS to update the device position in Firebase. Make sure to grant location permissions.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class BleDeviceDialog extends StatefulWidget {
  final Function(String deviceId, String deviceName) onDeviceConnected;

  const BleDeviceDialog({Key? key, required this.onDeviceConnected})
    : super(key: key);

  @override
  _BleDeviceDialogState createState() => _BleDeviceDialogState();
}

class _BleDeviceDialogState extends State<BleDeviceDialog> {
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothDevice? _selectedDevice;
  BluetoothCharacteristic? _characteristic;
  String? _deviceId;
  String? _deviceDisplayName;
  bool _isConnecting = false;

  // UUIDs from ESP32 code
  static const String SERVICE_UUID = "12345678-1234-1234-1234-123456789abc";
  static const String CHARACTERISTIC_UUID =
      "87654321-4321-4321-4321-cba987654321";

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    FlutterBluePlus.stopScan();
    _selectedDevice?.disconnect();
    super.dispose();
  }

  void _startScanning() {
    if (!mounted) return;

    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;

      for (ScanResult result in results) {
        // Filter for ESP32 GPS tracker devices
        if (result.device.platformName.contains('GPSTRACK') ||
            result.advertisementData.localName.contains('GPSTRACK')) {
          if (!_devices.contains(result.device)) {
            if (mounted) {
              setState(() {
                _devices.add(result.device);
              });
            }
          }
        }
      }
    });

    FlutterBluePlus.startScan(timeout: Duration(seconds: 15));

    Timer(Duration(seconds: 15), () {
      if (mounted) {
        _stopScanning();
      }
    });
  }

  void _stopScanning() {
    FlutterBluePlus.stopScan();
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
    _scanSubscription?.cancel();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (!mounted) return;

    setState(() {
      _isConnecting = true;
      _selectedDevice = device;
    });

    try {
      await device.connect();

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() ==
            SERVICE_UUID.toLowerCase()) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() ==
                CHARACTERISTIC_UUID.toLowerCase()) {
              _characteristic = characteristic;
              break;
            }
          }
          break;
        }
      }

      if (_characteristic != null) {
        // Request device ID
        await _characteristic!.write(utf8.encode('GET_ID'));

        // Read the response
        List<int> value = await _characteristic!.read();
        _deviceId = utf8.decode(value);
        _deviceDisplayName = _selectedDevice!.platformName.isNotEmpty
            ? _selectedDevice!.platformName
            : 'ESP32 GPS Tracker';

        if (mounted) {
          setState(() {
            _isConnecting = false;
          });

          _showConnectDialog();
        }
      } else {
        throw Exception('Could not find required characteristic');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device Found:'),
            SizedBox(height: 8),
            Text(
              _deviceDisplayName ?? 'Unknown Device',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Do you want to connect to this device?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _connectDevice();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _connectDevice() {
    if (_deviceId != null && _selectedDevice != null) {
      // Use the callback function passed from the parent
      // Pass the device ID obtained from ESP32 and display name
      widget.onDeviceConnected(
        _deviceId!,
        _deviceDisplayName ?? 'ESP32 GPS Tracker',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.bluetooth_searching),
          SizedBox(width: 8),
          Text('Scan for GPS Trackers'),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: [
            if (_isScanning)
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Scanning for devices...'),
                  ],
                ),
              ),
            Expanded(
              child: _devices.isEmpty && !_isScanning
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth_disabled,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text('No GPS trackers found'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _startScanning,
                            child: Text('Scan Again'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.gps_fixed),
                            title: Text(
                              device.platformName.isNotEmpty
                                  ? device.platformName
                                  : 'Unknown Device',
                            ),
                            subtitle: Text(device.remoteId.toString()),
                            trailing: _isConnecting && _selectedDevice == device
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.arrow_forward_ios),
                            onTap: _isConnecting
                                ? null
                                : () => _connectToDevice(device),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        if (!_isScanning && _devices.isNotEmpty)
          ElevatedButton(onPressed: _startScanning, child: Text('Refresh')),
      ],
    );
  }
}
