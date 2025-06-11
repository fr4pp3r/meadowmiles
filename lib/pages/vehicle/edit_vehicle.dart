import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meadowmiles/models/vehicle_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditVehiclePage extends StatefulWidget {
  final Vehicle vehicle;
  const EditVehiclePage({super.key, required this.vehicle});

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  XFile? _currentImage;

  late TextEditingController makeController;
  late TextEditingController modelController;
  late TextEditingController plateController;
  late TextEditingController colorController;
  late TextEditingController yearController;
  late TextEditingController priceController;
  bool isAvailable = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    makeController = TextEditingController(text: widget.vehicle.make);
    modelController = TextEditingController(text: widget.vehicle.model);
    plateController = TextEditingController(text: widget.vehicle.plateNumber);
    colorController = TextEditingController(text: widget.vehicle.color);
    yearController = TextEditingController(
      text: widget.vehicle.year.toString(),
    );
    priceController = TextEditingController(
      text: widget.vehicle.pricePerDay.toStringAsFixed(2),
    );
    isAvailable = widget.vehicle.isAvailable;
  }

  @override
  void dispose() {
    makeController.dispose();
    modelController.dispose();
    plateController.dispose();
    colorController.dispose();
    yearController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> _updateVehicle() async {
    setState(() => isLoading = true);
    String? oldImageUrl = widget.vehicle.imageUrl;
    String? newImageUrl = oldImageUrl;
    // If a new image is picked, upload it and delete the old one
    if (_currentImage != null) {
      try {
        // Delete old image from Supabase if it exists and is a Supabase URL
        if (oldImageUrl.isNotEmpty &&
            oldImageUrl.contains(
              'supabase.co/storage/v1/object/public/vehicle-img/',
            )) {
          final oldPath = _extractSupabasePathFromUrl(oldImageUrl);
          debugPrint('Supabase delete path: $oldPath');
          if (oldPath != null && oldPath.isNotEmpty) {
            await Supabase.instance.client.storage.from('vehicle-img').remove([
              oldPath,
            ]);
          }
        }
        // Upload new image
        final file = File(_currentImage!.path);
        final fileName = 'vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploadRes = await Supabase.instance.client.storage
            .from('vehicle-img')
            .upload(fileName, file);
        if (uploadRes.isNotEmpty) {
          newImageUrl = Supabase.instance.client.storage
              .from('vehicle-img')
              .getPublicUrl(fileName);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload/delete failed: $e')),
          );
        }
        setState(() => isLoading = false);
        return;
      }
    }
    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id)
          .update({
            'make': makeController.text.trim(),
            'model': modelController.text.trim(),
            'plateNumber': plateController.text.trim(),
            'color': colorController.text.trim(),
            'year': int.tryParse(yearController.text.trim()) ?? 0,
            'pricePerDay': double.tryParse(priceController.text.trim()) ?? 0.0,
            'isAvailable': isAvailable,
            'imageUrl': newImageUrl,
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update vehicle: $e')));
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> _removeVehicle() async {
    final confirm = await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Vehicle'),
        content: const Text(
          'Are you sure you want to remove this vehicle? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => isLoading = true);
    try {
      // Delete image from Supabase if it exists
      final imageUrl = widget.vehicle.imageUrl;
      if (imageUrl.isNotEmpty &&
          imageUrl.contains(
            'supabase.co/storage/v1/object/public/vehicle-img/',
          )) {
        final oldPath = _extractSupabasePathFromUrl(imageUrl);
        debugPrint('Supabase delete path: $oldPath');
        if (oldPath != null && oldPath.isNotEmpty) {
          await Supabase.instance.client.storage.from('vehicle-img').remove([
            oldPath,
          ]);
        }
      }
      // Delete vehicle from Firestore
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle removed successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove vehicle: $e')));
      }
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle.make} ${widget.vehicle.model}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: 'vehicle-image-${widget.vehicle.id}',
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _currentImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_currentImage!.path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.car_repair, size: 60),
                                ),
                          ),
                        )
                      : (widget.vehicle.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  widget.vehicle.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.car_repair,
                                          size: 60,
                                        ),
                                      ),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.car_repair, size: 60),
                              )),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 160,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(360),
                    ),
                  ),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      setState(() {
                        _currentImage = picked;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Image selected!')),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Change Image',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: makeController,
              decoration: const InputDecoration(labelText: 'Make'),
              textCapitalization: TextCapitalization.words,
            ),
            TextFormField(
              controller: modelController,
              decoration: const InputDecoration(labelText: 'Model'),
              textCapitalization: TextCapitalization.words,
            ),
            TextFormField(
              controller: plateController,
              decoration: const InputDecoration(labelText: 'Plate Number'),
              textCapitalization: TextCapitalization.characters,
            ),
            TextFormField(
              controller: colorController,
              decoration: const InputDecoration(labelText: 'Color'),
              textCapitalization: TextCapitalization.words,
            ),
            TextFormField(
              controller: yearController,
              decoration: const InputDecoration(labelText: 'Year'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price per day'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  isAvailable ? 'Available' : 'Not Available',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isAvailable
                        ? const Color.fromARGB(255, 57, 126, 58)
                        : const Color.fromARGB(255, 155, 28, 19),
                  ),
                ),
                Switch(
                  value: isAvailable,
                  onChanged: (val) => setState(() => isAvailable = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 160,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(360),
                    ),
                  ),
                  onPressed: isLoading ? null : _updateVehicle,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Save Changes',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 200,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(360),
                    ),
                  ),
                  onPressed: isLoading ? null : _removeVehicle,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Remove Vehicle',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to extract Supabase storage path from public URL
  String? _extractSupabasePathFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    // Extract the last part after the last '/' in the URL
    if (segments.isNotEmpty) {
      return segments.last;
    }
    return null;
  }
}
