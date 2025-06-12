import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meadowmiles/states/appstate.dart';
import 'package:meadowmiles/models/vehicle_model.dart';
import 'package:meadowmiles/states/authstate.dart';
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
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
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
    _locationController.dispose();
    _descriptionController.dispose();
    pickedFile = null; // Clear the picked file
    imageUrl = null; // Clear the image URL
    super.dispose();
  }

  Future<void> _submit(AuthState authState, AppState appState) async {
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
        ownerId: authState.currentUser!.uid,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        plateNumber: _plateController.text.trim(),
        year: int.tryParse(_yearController.text.trim()) ?? 0,
        color: _colorController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        pricePerDay: double.tryParse(_pricePerDayController.text.trim()) ?? 0.0,
        isAvailable: _isAvailable,
        vehicleType: _selectedType,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
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
    var authState = context.watch<AuthState>();
    var appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle'),
        forceMaterialTransparency: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _makeController,
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
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _modelController,
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
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _plateController,
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
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _yearController,
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
                        prefixIcon: const Icon(Icons.color_lens),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pricePerDayController,
                      style: Theme.of(context).textTheme.bodySmall,
                      decoration: InputDecoration(
                        labelText: 'Price Per Day',
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
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final price = double.tryParse(v);
                        if (price == null || price < 0)
                          return 'Enter a valid price';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
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
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
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
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: pickedFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(pickedFile!.path),
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: 180,
                                ),
                              )
                            : Container(
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.image,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(
                            Icons.add_a_photo,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Add Image',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                          ),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final tempPickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (context.mounted && tempPickedFile != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Image added!')),
                              );
                            }
                            if (context.mounted) {
                              FocusManager.instance.primaryFocus?.unfocus();
                              FocusScope.of(context).unfocus();
                            }
                            setState(() {
                              pickedFile = tempPickedFile;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 180,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: isLoading
                              ? null
                              : () => _submit(authState, appState),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Add Vehicle',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
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
        },
      ),
    );
  }
}
