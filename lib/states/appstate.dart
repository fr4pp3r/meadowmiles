import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class AppState extends ChangeNotifier {
  // Future<void> loadCurrentUserModel() async {
  //   if (currentUser == null) {
  //     _userModel = null;
  //     notifyListeners();
  //     return;
  //   }
  //   final doc = await FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(currentUser!.uid)
  //       .get();
  //   if (!doc.exists) {
  //     _userModel = null;
  //   } else {
  //     _userModel = UserModel.fromMap(doc.data()!, uid: doc.id);
  //   }
  //   notifyListeners();
  // }

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
