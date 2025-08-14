import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:meadowmiles/states/authstate.dart';

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

  @override
  void initState() {
    super.initState();
    _checkDeviceStatus();
  }

  Future<void> _checkDeviceStatus() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    final userUid = authState.currentUser?.uid;

    if (userUid == null) return;

    try {
      // Check if user has any connected GPS devices
      final snapshot = await FirebaseFirestore.instance
          .collection('gps_connections')
          .where('userUid', isEqualTo: userUid)
          .where('isConnected', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        final deviceData = snapshot.docs.first.data();
        setState(() {
          _isConnected = true;
          _deviceName = deviceData['deviceName'];
          _deviceId = deviceData['deviceId'];
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
    setState(() {
      _isConnecting = true;
    });

    // Simulate BLE connection process
    await Future.delayed(const Duration(seconds: 2));

    final authState = Provider.of<AuthState>(context, listen: false);
    final userUid = authState.currentUser?.uid;

    if (userUid == null) {
      setState(() {
        _isConnecting = false;
      });
      return;
    }

    try {
      // Create a mock device connection record
      final deviceData = {
        'userUid': userUid,
        'deviceName': 'ESP32 GPS Tracker',
        'deviceId': 'ESP32_${DateTime.now().millisecondsSinceEpoch}',
        'isConnected': true,
        'lastConnectionTime': Timestamp.now(),
        'connectionType': 'BLE',
        'firmwareVersion': '1.0.0',
        'batteryLevel': 85,
      };

      await FirebaseFirestore.instance
          .collection('gps_connections')
          .add(deviceData);

      if (mounted) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
          _deviceName = deviceData['deviceName'] as String;
          _deviceId = deviceData['deviceId'] as String;
          _lastConnectionTime = DateTime.now();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS device connected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnectDevice() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    final userUid = authState.currentUser?.uid;

    if (userUid == null) return;

    try {
      // Update all connected devices for this user to disconnected
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('gps_connections')
          .where('userUid', isEqualTo: userUid)
          .where('isConnected', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isConnected': false,
          'disconnectionTime': Timestamp.now(),
        });
      }

      await batch.commit();

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
            const Text('2. Make sure Bluetooth is enabled on your phone'),
            const SizedBox(height: 8),
            const Text('3. Tap "Connect Device" to start pairing'),
            const SizedBox(height: 8),
            const Text('4. Once connected, GPS data will be sent to Firebase'),
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
                      'Note: This is a demo interface. ESP32 BLE functionality will be implemented in a future update.',
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
