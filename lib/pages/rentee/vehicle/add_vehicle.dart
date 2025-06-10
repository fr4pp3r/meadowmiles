import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meadowmiles/appstate.dart';
import 'package:meadowmiles/models/vehicle_model.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _pricePerDayController = TextEditingController();
  VehicleType _selectedType = VehicleType.car;
  bool _isAvailable = true;
  bool isLoading = false;
  XFile? pickedFile;
  String? imageUrl;

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _imageUrlController.dispose();
    _pricePerDayController.dispose();
    pickedFile = null; // Clear the picked file
    imageUrl = null; // Clear the image URL
    super.dispose();
  }

  Future<void> _submit(AppState appState) async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => isLoading = true);
      if (pickedFile != null) {
        final uploadedImageUrl = await appState.uploadVehicleImage(pickedFile!);
        if (uploadedImageUrl != null) {
          _imageUrlController.text = uploadedImageUrl;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image')),
            );
          }
          setState(() => isLoading = false);
          return;
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
        setState(() => isLoading = false);
        return;
      }
      final vehicle = Vehicle(
        id: Vehicle.generateVehicleId(),
        ownerId: appState.currentUser!.uid,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        plateNumber: _plateController.text.trim(),
        year: int.tryParse(_yearController.text.trim()) ?? 0,
        color: _colorController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        pricePerDay: double.tryParse(_pricePerDayController.text.trim()) ?? 0.0,
        isAvailable: _isAvailable,
        vehicleType: _selectedType,
      );
      try {
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(vehicle.id)
            .set(vehicle.toMap());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle added successfully!')),
        );
        Navigator.of(context).pop(vehicle);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add vehicle: $e')));
      }
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0, // Prevent color/elevation change on scroll
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _makeController,
                style: Theme.of(context).textTheme.bodySmall,
                decoration: InputDecoration(
                  labelText: 'Make/Brand',
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _modelController,
                style: Theme.of(context).textTheme.bodySmall,
                decoration: InputDecoration(
                  labelText: 'Model',
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _plateController,
                style: Theme.of(context).textTheme.bodySmall,
                decoration: InputDecoration(
                  labelText: 'Plate Number',
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _yearController,
                style: Theme.of(context).textTheme.bodySmall,
                decoration: InputDecoration(
                  labelText: 'Year',
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final year = int.tryParse(v);
                  if (year == null ||
                      year < 1900 ||
                      year > DateTime.now().year + 1) {
                    return 'Enter a valid year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _colorController,
                style: Theme.of(context).textTheme.bodySmall,
                decoration: InputDecoration(
                  labelText: 'Color',
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pricePerDayController,
                style: Theme.of(context).textTheme.bodySmall,
                decoration: InputDecoration(
                  labelText: 'Price Per Day',
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final price = double.tryParse(v);
                  if (price == null || price < 0) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<VehicleType>(
                value: _selectedType,
                items: VehicleType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          type.toString().split('.').last.toUpperCase(),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
                decoration: InputDecoration(
                  labelText: 'Vehicle Type',
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _isAvailable,
                onChanged: (val) => setState(() => _isAvailable = val),
                title: const Text('Available'),
              ),
              const SizedBox(height: 16),
              if (pickedFile != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Image.file(
                    File(pickedFile!.path),
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 160, // Set a fixed smaller width
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final tempPickedFile = await picker.pickImage(
                        source: ImageSource.gallery,
                      ); // Dismiss keyboard and reset insets
                      if (context.mounted && tempPickedFile != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Image added!')),
                        );
                      }
                      if (context.mounted) {
                        // Dismiss the keyboard if it is open
                        FocusManager.instance.primaryFocus?.unfocus();
                        // Optionally, unfocus any other focus nodes
                        // FocusManager.instance.primaryFocus?.unfocus();
                        FocusScope.of(context).unfocus();
                      }
                      setState(() {
                        pickedFile = tempPickedFile;
                      });
                    },
                    child: Text(
                      'Add Image',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 160, // Set a fixed smaller width
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: isLoading ? null : () => _submit(appState),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Add Vehicle',
                            style: Theme.of(context).textTheme.titleMedium
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
    );
  }
}
