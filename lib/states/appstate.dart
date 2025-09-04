import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class AppState extends ChangeNotifier {
  String _activeDashboard = 'renter';

  String get activeDashboard => _activeDashboard;

  void setActiveDashboard(String dashboard) {
    if (_activeDashboard != dashboard) {
      _activeDashboard = dashboard;
      notifyListeners();
    }
  }

  Future<String?> uploadProfileImage(XFile pickedFile) async {
    final file = File(pickedFile.path);
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final storageResponse = await Supabase.instance.client.storage
        .from('profile-img') // your bucket name
        .upload(fileName, file);

    if (storageResponse.isEmpty) return null;

    // Get the public URL
    final publicUrl = Supabase.instance.client.storage
        .from('profile-img')
        .getPublicUrl(fileName);

    return publicUrl;
  }

  Future<String?> uploadVehicleImage(XFile pickedFile) async {
    final file = File(pickedFile.path);
    final fileName = 'vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final storageResponse = await Supabase.instance.client.storage
        .from('vehicle-img') // your bucket name
        .upload(fileName, file);

    if (storageResponse.isEmpty) return null;

    // Get the public URL
    final publicUrl = Supabase.instance.client.storage
        .from('vehicle-img')
        .getPublicUrl(fileName);

    return publicUrl;
  }
}
