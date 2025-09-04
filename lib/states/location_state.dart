import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'dart:async';

class LocationState extends ChangeNotifier {
  Location? _location;
  StreamSubscription<LocationData>? _locationSubscription;
  LocationData? _currentLocation;
  bool _isLocationTracking = false;
  bool _isLocationInitialized = false;
  
  // BLE connection info
  String? _connectedDeviceId;
  String? _connectedDeviceName;

  // Getters
  LocationData? get currentLocation => _currentLocation;
  bool get isLocationTracking => _isLocationTracking;
  bool get isLocationInitialized => _isLocationInitialized;
  String? get connectedDeviceId => _connectedDeviceId;
  String? get connectedDeviceName => _connectedDeviceName;
  bool get hasConnectedDevice => _connectedDeviceId != null;

  // Initialize location services
  Future<void> initializeLocation() async {
    if (_isLocationInitialized) return;

    try {
      _location = Location();
      await _requestLocationPermission();
      _isLocationInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing location: $e');
      rethrow;
    }
  }

  // Request location permissions
  Future<void> _requestLocationPermission() async {
    if (_location == null) return;

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

  // Start location tracking
  Future<void> startLocationTracking() async {
    if (_location == null || _isLocationTracking) return;

    try {
      _isLocationTracking = true;
      notifyListeners();

      _locationSubscription = _location!.onLocationChanged.listen(
        (LocationData currentLocation) {
          _currentLocation = currentLocation;
          notifyListeners();
        },
        onError: (error) {
          print('Location tracking error: $error');
          _isLocationTracking = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('Error starting location tracking: $e');
      _isLocationTracking = false;
      notifyListeners();
    }
  }

  // Stop location tracking
  Future<void> stopLocationTracking() async {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isLocationTracking = false;
    notifyListeners();
  }

  // Set connected device info (call when BLE device connects)
  void setConnectedDevice(String deviceId, String deviceName) {
    _connectedDeviceId = deviceId;
    _connectedDeviceName = deviceName;
    notifyListeners();
    
    // Start tracking if not already started
    if (!_isLocationTracking) {
      startLocationTracking();
    }
  }

  // Clear connected device info (call when BLE device disconnects)
  void clearConnectedDevice() {
    _connectedDeviceId = null;
    _connectedDeviceName = null;
    notifyListeners();
    
    // Optionally stop tracking when no device is connected
    // stopLocationTracking();
  }

  // Manual location update (for testing or force update)
  Future<void> forceLocationUpdate() async {
    if (_location == null) return;

    try {
      final locationData = await _location!.getLocation();
      _currentLocation = locationData;
      notifyListeners();
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
