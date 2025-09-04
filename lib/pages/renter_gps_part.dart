import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:meadowmiles/states/location_state.dart';
import 'package:meadowmiles/states/renter_gps_state.dart';
import 'package:meadowmiles/states/appstate.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
  BluetoothDevice? _connectedBleDevice; // Track the actual BLE device

  // Reconnection management
  bool _autoReconnectEnabled = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  Timer? _reconnectTimer;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  @override
  void initState() {
    super.initState();
    _checkDeviceStatus();
    _setupDashboardListener();
  }

  void _setupDashboardListener() {
    // Listen for dashboard changes and disconnect device if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final appState = Provider.of<AppState>(context, listen: false);
      appState.addListener(_onDashboardChange);
    });
  }

  void _onDashboardChange() {
    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);

    // If dashboard is no longer renter, disconnect device
    if (appState.activeDashboard != 'renter' && _isConnected) {
      _disconnectDevice();
    }
  }

  @override
  void dispose() {
    // Cancel reconnection timer
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // Cancel connection state subscription
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;

    // Disconnect BLE device if connected
    if (_connectedBleDevice != null) {
      _connectedBleDevice!.disconnect().catchError((e) {
        print('Error disconnecting BLE device during dispose: $e');
      });
    }

    try {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.removeListener(_onDashboardChange);
      }
    } catch (e) {
      // Handle potential provider access issues during dispose
      print('Error removing listeners: $e');
    }
    super.dispose();
  }

  Future<void> _checkDeviceStatus() async {
    try {
      final renterGpsState = Provider.of<RenterGpsState>(
        context,
        listen: false,
      );
      final activeDevice = await renterGpsState.checkActiveDevice();

      if (activeDevice != null && mounted) {
        // Check if we have a real BLE connection
        if (_connectedBleDevice != null) {
          final connectionState =
              await _connectedBleDevice!.connectionState.first;
          if (connectionState == BluetoothConnectionState.connected) {
            setState(() {
              _isConnected = true;
              _deviceName = activeDevice['name'];
              _deviceId = activeDevice['id'];
              _lastConnectionTime = DateTime.now();
            });
          } else {
            // Device is marked as active but not actually connected
            _handleDisconnectedDevice();
          }
        } else {
          // Device is marked as active but we have no BLE reference
          setState(() {
            _isConnected = false;
            _deviceName = null;
            _deviceId = null;
            _lastConnectionTime = null;
          });
          // Clear the active status since there's no real connection
          renterGpsState.clearConnectedDevice();
        }
      }
    } catch (e) {
      print('Error checking device status: $e');
    }
  }

  void _handleDisconnectedDevice() {
    setState(() {
      _isConnected = false;
      _deviceName = null;
      _deviceId = null;
      _lastConnectionTime = null;
      _connectedBleDevice = null;
    });

    // Clear device from states
    final renterGpsState = Provider.of<RenterGpsState>(context, listen: false);
    final locationState = Provider.of<LocationState>(context, listen: false);
    renterGpsState.clearConnectedDevice();
    locationState.clearConnectedDevice();
  }

  void _handleUnexpectedDisconnection() {
    print('Handling unexpected BLE disconnection...');

    // Update UI immediately
    setState(() {
      _isConnected = false;
    });

    // Show notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'GPS device disconnected. ${_autoReconnectEnabled ? "Attempting to reconnect..." : ""}',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }

    // Attempt automatic reconnection if enabled
    if (_autoReconnectEnabled && _reconnectAttempts < _maxReconnectAttempts) {
      _attemptReconnection();
    } else {
      // Give up reconnecting and clear everything
      _handleDisconnectedDevice();
      _reconnectAttempts = 0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to reconnect to GPS device. Please reconnect manually.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _attemptReconnection() async {
    if (_connectedBleDevice == null || !mounted) return;

    _reconnectAttempts++;
    print('Reconnection attempt $_reconnectAttempts/$_maxReconnectAttempts');

    setState(() {
      _isConnecting = true;
    });

    try {
      // Wait a bit before attempting reconnection
      await Future.delayed(Duration(seconds: 2));

      if (!mounted) return;

      // Try to reconnect
      await _connectedBleDevice!.connect();

      // If successful, reset attempts and update UI
      _reconnectAttempts = 0;
      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _lastConnectionTime = DateTime.now();
      });

      // Restore device states
      final locationState = Provider.of<LocationState>(context, listen: false);
      final renterGpsState = Provider.of<RenterGpsState>(
        context,
        listen: false,
      );

      if (_deviceId != null && _deviceName != null) {
        locationState.setConnectedDevice(_deviceId!, _deviceName!);
        renterGpsState.setConnectedDevice(_deviceId!, _deviceName!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS device reconnected successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Reconnection attempt failed: $e');
      setState(() {
        _isConnecting = false;
      });

      if (_reconnectAttempts < _maxReconnectAttempts) {
        // Schedule next attempt
        _reconnectTimer = Timer(Duration(seconds: 5), () {
          if (mounted && _autoReconnectEnabled) {
            _attemptReconnection();
          }
        });
      } else {
        // All attempts failed
        _handleDisconnectedDevice();
        _reconnectAttempts = 0;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to reconnect to GPS device after multiple attempts.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _connectDevice() async {
    // Show BLE device scanning dialog
    _showBleDeviceDialog();
  }

  Future<void> _disconnectDevice() async {
    try {
      // Disable auto-reconnection for manual disconnection
      _autoReconnectEnabled = false;
      _reconnectAttempts = 0;

      // Cancel any pending reconnection attempts
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      // Cancel connection state subscription
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;

      final renterGpsState = Provider.of<RenterGpsState>(
        context,
        listen: false,
      );
      final locationState = Provider.of<LocationState>(context, listen: false);

      // Disconnect the actual BLE device if connected
      if (_connectedBleDevice != null) {
        try {
          await _connectedBleDevice!.disconnect();
          _connectedBleDevice = null;
        } catch (e) {
          print('Error disconnecting BLE device: $e');
        }
      }

      // Clear device from both states
      renterGpsState.clearConnectedDevice();
      locationState.clearConnectedDevice();

      if (mounted) {
        setState(() {
          _isConnected = false;
          _deviceName = null;
          _deviceId = null;
          _lastConnectionTime = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS device disconnected'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Re-enable auto-reconnection for future connections
      _autoReconnectEnabled = true;
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

  void _showBleDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          BleDeviceDialog(onDeviceConnected: _onDeviceConnected),
    );
  }

  Future<void> _onDeviceConnected(
    String deviceId,
    String deviceName,
    BluetoothDevice? bleDevice,
  ) async {
    try {
      // Look for existing device in tracking_devices collection by deviceID only
      final deviceQuery = await FirebaseFirestore.instance
          .collection('tracking_devices')
          .where('id', isEqualTo: deviceId)
          .limit(1)
          .get();

      if (deviceQuery.docs.isNotEmpty) {
        if (mounted) {
          // Reset reconnection state for new connection
          _reconnectAttempts = 0;
          _autoReconnectEnabled = true;

          setState(() {
            _isConnected = true;
            _deviceName = deviceName;
            _deviceId = deviceId;
            _lastConnectionTime = DateTime.now();
            _connectedBleDevice = bleDevice; // Store the BLE device reference
          });

          // Set up connection state listener for the BLE device
          if (bleDevice != null) {
            _connectionStateSubscription
                ?.cancel(); // Cancel any existing subscription
            _connectionStateSubscription = bleDevice.connectionState.listen((
              BluetoothConnectionState state,
            ) {
              if (state == BluetoothConnectionState.disconnected &&
                  mounted &&
                  _isConnected) {
                print('BLE device disconnected unexpectedly');
                _handleUnexpectedDisconnection();
              }
            });
          }

          // Set connected device in both states
          final locationState = Provider.of<LocationState>(
            context,
            listen: false,
          );
          final renterGpsState = Provider.of<RenterGpsState>(
            context,
            listen: false,
          );

          locationState.setConnectedDevice(deviceId, deviceName);
          renterGpsState.setConnectedDevice(deviceId, deviceName);

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
              Consumer<LocationState>(
                builder: (context, locationState, child) {
                  if (_isConnected && locationState.currentLocation != null) {
                    return Column(
                      children: [
                        _buildLocationCard(),
                        const SizedBox(height: 24),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

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
                    : _isConnecting
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
              ),
              child: _isConnecting
                  ? const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : Icon(
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
              _isConnected
                  ? 'Device Connected'
                  : _isConnecting
                  ? (_reconnectAttempts > 0
                        ? 'Reconnecting...'
                        : 'Connecting...')
                  : 'No Device Connected',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isConnected
                    ? Colors.green
                    : _isConnecting
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              _isConnected
                  ? 'Your ESP32 GPS tracker is connected and ready'
                  : _isConnecting
                  ? (_reconnectAttempts > 0
                        ? 'Attempting to reconnect to your GPS tracker...'
                        : 'Connecting to your ESP32 GPS tracker...')
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
              'Session Started',
              _lastConnectionTime != null
                  ? _formatDateTime(_lastConnectionTime!)
                  : 'Unknown',
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Connection Type', 'Bluetooth LE'),
            const SizedBox(height: 8),
            Consumer<LocationState>(
              builder: (context, locationState, child) {
                return Row(
                  children: [
                    Text(
                      'Location Tracking',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          locationState.isLocationTracking
                              ? Icons.location_on
                              : Icons.location_off,
                          size: 16,
                          color: locationState.isLocationTracking
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          locationState.isLocationTracking
                              ? 'Active'
                              : 'Inactive',
                          style: TextStyle(
                            color: locationState.isLocationTracking
                                ? Colors.green
                                : Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: locationState.isLocationTracking
                              ? locationState.stopLocationTracking
                              : locationState.startLocationTracking,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(60, 30),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          child: Text(
                            locationState.isLocationTracking ? 'Stop' : 'Start',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            // Auto-reconnect setting
            Row(
              children: [
                Text(
                  'Auto-reconnect',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      _autoReconnectEnabled
                          ? Icons.autorenew
                          : Icons.sync_disabled,
                      size: 16,
                      color: _autoReconnectEnabled ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _autoReconnectEnabled ? 'Enabled' : 'Disabled',
                      style: TextStyle(
                        color: _autoReconnectEnabled
                            ? Colors.green
                            : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _autoReconnectEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _autoReconnectEnabled = value;
                        });
                      },
                      activeColor: Colors.green,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

            Consumer<LocationState>(
              builder: (context, locationState, child) {
                final currentLocation = locationState.currentLocation;
                return Column(
                  children: [
                    _buildInfoRow(
                      'Latitude',
                      currentLocation?.latitude?.toStringAsFixed(6) ?? '--',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Longitude',
                      currentLocation?.longitude?.toStringAsFixed(6) ?? '--',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Last Update',
                      currentLocation != null
                          ? _formatDateTime(DateTime.now())
                          : 'No data received',
                    ),
                  ],
                );
              },
            ),
            Consumer<LocationState>(
              builder: (context, locationState, child) {
                final currentLocation = locationState.currentLocation;
                if (currentLocation != null) {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Accuracy',
                        currentLocation.accuracy != null
                            ? '${currentLocation.accuracy!.toStringAsFixed(1)}m'
                            : '--',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Altitude',
                        currentLocation.altitude != null
                            ? '${currentLocation.altitude!.toStringAsFixed(1)}m'
                            : '--',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Speed',
                        currentLocation.speed != null
                            ? '${(currentLocation.speed! * 3.6).toStringAsFixed(1)} km/h'
                            : '--',
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionButton() {
    String buttonText;
    IconData buttonIcon;
    Color backgroundColor;

    if (_isConnecting) {
      buttonText = _reconnectAttempts > 0
          ? 'Reconnecting... (${_reconnectAttempts}/$_maxReconnectAttempts)'
          : 'Connecting...';
      buttonIcon = Icons.bluetooth_searching;
      backgroundColor = Colors.orange;
    } else if (_isConnected) {
      buttonText = 'Disconnect Device';
      buttonIcon = Icons.bluetooth_disabled;
      backgroundColor = Colors.red;
    } else {
      buttonText = 'Connect Device';
      buttonIcon = Icons.bluetooth;
      backgroundColor = Colors.blue;
    }

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
            : Icon(buttonIcon),
        label: Text(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
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
  final Function(String deviceId, String deviceName, BluetoothDevice? bleDevice)
  onDeviceConnected;

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
      // Pass the device ID obtained from ESP32, display name, and BLE device
      widget.onDeviceConnected(
        _deviceId!,
        _deviceDisplayName ?? 'ESP32 GPS Tracker',
        _selectedDevice, // Pass the actual BLE device
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
