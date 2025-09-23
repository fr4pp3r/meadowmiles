import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'dart:async';

class RenterGpsState extends ChangeNotifier {
  String? _connectedDeviceId;
  String? _connectedDeviceName;
  bool _isActive = false;
  bool _isDatabaseUpdateEnabled = false;
  StreamSubscription<LocationData>? _locationUpdateSubscription;

  // Getters
  String? get connectedDeviceId => _connectedDeviceId;
  String? get connectedDeviceName => _connectedDeviceName;
  bool get isActive => _isActive;
  bool get isDatabaseUpdateEnabled => _isDatabaseUpdateEnabled;
  bool get hasConnectedDevice => _connectedDeviceId != null;

  /// Start GPS state management for renter dashboard
  void startRenterGpsSession() {
    _isActive = true;
    _isDatabaseUpdateEnabled = true;
    notifyListeners();
    debugPrint('RenterGpsState: Session started');
  }

  /// Sync with existing location state connections when starting session
  void syncWithLocationState(String? deviceId, String? deviceName) {
    if (deviceId != null && deviceName != null && _isActive) {
      _connectedDeviceId = deviceId;
      _connectedDeviceName = deviceName;
      _updateDeviceActiveStatus(true);
      notifyListeners();
      debugPrint(
        'RenterGpsState: Synced with existing device - $deviceName ($deviceId)',
      );
    }
  }

  /// Stop GPS state management when leaving renter dashboard
  void stopRenterGpsSession() {
    _isActive = false;
    _isDatabaseUpdateEnabled = false;

    // Disconnect any connected device
    if (_connectedDeviceId != null) {
      _disconnectDeviceFromDatabase();
    }

    _clearDeviceInfo();
    _locationUpdateSubscription?.cancel();
    _locationUpdateSubscription = null;

    notifyListeners();
    debugPrint('RenterGpsState: Session stopped');
  }

  /// Set connected device info and start database updates
  void setConnectedDevice(String deviceId, String deviceName) {
    _connectedDeviceId = deviceId;
    _connectedDeviceName = deviceName;

    if (_isActive && _isDatabaseUpdateEnabled) {
      _updateDeviceActiveStatus(true);
    }

    notifyListeners();
    debugPrint('RenterGpsState: Device connected - $deviceName ($deviceId)');
  }

  /// Clear connected device info and stop database updates
  void clearConnectedDevice() {
    if (_connectedDeviceId != null && _isDatabaseUpdateEnabled) {
      _disconnectDeviceFromDatabase();
    }

    _clearDeviceInfo();
    notifyListeners();
    debugPrint('RenterGpsState: Device cleared');
  }

  /// Update device location in database
  Future<void> updateDeviceLocation(LocationData location) async {
    if (!_isDatabaseUpdateEnabled ||
        _connectedDeviceId == null ||
        location.latitude == null ||
        location.longitude == null) {
      return;
    }

    try {
      // Find the device document by deviceId and update its location
      final deviceQuery = await FirebaseFirestore.instance
          .collection('tracking_devices')
          .where('id', isEqualTo: _connectedDeviceId)
          .limit(1)
          .get();

      if (deviceQuery.docs.isNotEmpty) {
        final deviceDoc = deviceQuery.docs.first;
        await deviceDoc.reference.update({
          'lastLatitude': location.latitude,
          'lastLongitude': location.longitude,
          'lastLocationUpdate': Timestamp.now(),
        });

        debugPrint(
          'RenterGpsState: Location updated for device $_connectedDeviceId',
        );
      } else {
        debugPrint(
          'RenterGpsState: Device not found in database: $_connectedDeviceId',
        );
      }
    } catch (e) {
      debugPrint('RenterGpsState: Error updating device location: $e');
    }
  }

  /// Update device active status in database
  Future<void> _updateDeviceActiveStatus(bool isActive) async {
    if (_connectedDeviceId == null) return;

    try {
      final deviceQuery = await FirebaseFirestore.instance
          .collection('tracking_devices')
          .where('id', isEqualTo: _connectedDeviceId)
          .limit(1)
          .get();

      if (deviceQuery.docs.isNotEmpty) {
        await deviceQuery.docs.first.reference.update({'isActive': isActive});
        debugPrint(
          'RenterGpsState: Device active status updated to $isActive for $_connectedDeviceId',
        );
      }
    } catch (e) {
      debugPrint('RenterGpsState: Error updating device active status: $e');
    }
  }

  /// Disconnect device from database (set inactive)
  Future<void> _disconnectDeviceFromDatabase() async {
    if (_connectedDeviceId != null) {
      await _updateDeviceActiveStatus(false);
      debugPrint(
        'RenterGpsState: Device disconnected from database: $_connectedDeviceId',
      );
    }
  }

  /// Clear device info without database operations
  void _clearDeviceInfo() {
    _connectedDeviceId = null;
    _connectedDeviceName = null;
  }

  /// Check if there are any active GPS tracking devices in database
  Future<Map<String, dynamic>?> checkActiveDevice() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tracking_devices')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final deviceData = snapshot.docs.first.data();
        final deviceInfo = {
          'name': deviceData['name'],
          'id': deviceData['id'] ?? snapshot.docs.first.id,
        };

        debugPrint(
          'RenterGpsState: Active device found - ${deviceInfo['name']}',
        );
        return deviceInfo;
      }

      debugPrint('RenterGpsState: No active devices found');
      return null;
    } catch (e) {
      debugPrint('RenterGpsState: Error checking active device: $e');
      return null;
    }
  }

  @override
  void dispose() {
    // Ensure cleanup when state is disposed
    if (_isActive) {
      stopRenterGpsSession();
    }
    super.dispose();
  }
}
