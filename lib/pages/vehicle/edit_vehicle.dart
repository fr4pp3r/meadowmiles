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
  late TextEditingController locationController;
  late TextEditingController descriptionController;
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
    locationController = TextEditingController(text: widget.vehicle.location);
    descriptionController = TextEditingController(
      text: widget.vehicle.description,
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
    locationController.dispose();
    descriptionController.dispose();
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
            'location': locationController.text.trim(),
            'description': descriptionController.text.trim(),
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

  Future<bool> _hasActiveBookings() async {
    final bookings = await FirebaseFirestore.instance
        .collection('bookings')
        .where('vehicleId', isEqualTo: widget.vehicle.id)
        .where('status', isNotEqualTo: 'cancelled')
        .get();
    return bookings.docs.isNotEmpty;
  }

  Future<void> _removeVehicle() async {
    setState(() => isLoading = true);
    final hasActive = await _hasActiveBookings();
    if (hasActive) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot remove vehicle with active bookings.'),
          ),
        );
      }
      return;
    }
    // Confirm removal
    bool? confirm = false;
    if (mounted) {
      confirm = await showDialog<bool>(
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
    }
    if (confirm != true) {
      setState(() => isLoading = false);
      return;
    }
    // Remove vehicle
    try {
      // Delete image from Supabase if it exists
      final imageUrl = widget.vehicle.imageUrl;
      if (imageUrl.isNotEmpty &&
          imageUrl.contains(
            'supabase.co/storage/v1/object/public/vehicle-img/',
          )) {
        final oldPath = _extractSupabasePathFromUrl(imageUrl);
        if (oldPath != null && oldPath.isNotEmpty) {
          await Supabase.instance.client.storage.from('vehicle-img').remove([
            oldPath,
          ]);
        }
      }
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle removed successfully!')),
        );
        Navigator.of(context).pop(true);
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
        forceMaterialTransparency: true,
        title: Text('Edit Vehicle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _currentImage != null
                        ? Image.file(
                            File(_currentImage!.path),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.car_repair, size: 60),
                                ),
                          )
                        : (widget.vehicle.imageUrl.isNotEmpty
                              ? Image.network(
                                  widget.vehicle.imageUrl,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.car_repair,
                                          size: 60,
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
                    onPressed: isLoading
                        ? null
                        : () async {
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
                                  const SnackBar(
                                    content: Text('Image selected!'),
                                  ),
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
              const SizedBox(height: 16),
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: makeController,
                          style: Theme.of(context).textTheme.bodySmall,
                          decoration: InputDecoration(
                            labelText: 'Make/Brand',
                            labelStyle: Theme.of(context).textTheme.bodySmall,
                            prefixIcon: const Icon(Icons.directions_car),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: modelController,
                          style: Theme.of(context).textTheme.bodySmall,
                          decoration: InputDecoration(
                            labelText: 'Model',
                            labelStyle: Theme.of(context).textTheme.bodySmall,
                            prefixIcon: const Icon(Icons.drive_eta),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: plateController,
                          style: Theme.of(context).textTheme.bodySmall,
                          decoration: InputDecoration(
                            labelText: 'Plate Number',
                            labelStyle: Theme.of(context).textTheme.bodySmall,
                            prefixIcon: const Icon(Icons.confirmation_number),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: yearController,
                          style: Theme.of(context).textTheme.bodySmall,
                          decoration: InputDecoration(
                            labelText: 'Year',
                            labelStyle: Theme.of(context).textTheme.bodySmall,
                            prefixIcon: const Icon(Icons.calendar_today),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: colorController,
                          style: Theme.of(context).textTheme.bodySmall,
                          decoration: InputDecoration(
                            labelText: 'Color',
                            labelStyle: Theme.of(context).textTheme.bodySmall,
                            prefixIcon: const Icon(Icons.color_lens),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: priceController,
                          style: Theme.of(context).textTheme.bodySmall,
                          decoration: InputDecoration(
                            labelText: 'Price per day',
                            labelStyle: Theme.of(context).textTheme.bodySmall,
                            prefixIcon: const Icon(Icons.attach_money),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: locationController,
                          style: Theme.of(context).textTheme.bodySmall,
                          decoration: InputDecoration(
                            labelText: 'Location',
                            labelStyle: Theme.of(context).textTheme.bodySmall,
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: descriptionController,
                          style: Theme.of(context).textTheme.bodySmall,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            labelStyle: Theme.of(context).textTheme.bodySmall,
                            prefixIcon: const Icon(Icons.description),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          maxLines: 3,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          textCapitalization: TextCapitalization.sentences,
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
                              onChanged: (val) =>
                                  setState(() => isAvailable = val),
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
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      await _updateVehicle();
                                      if (context.mounted) {
                                        Navigator.of(context).pop(true);
                                      }
                                    },
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Save Changes',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
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
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Remove Vehicle',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                          ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
