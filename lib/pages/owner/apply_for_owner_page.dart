import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meadowmiles/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:meadowmiles/models/owner_application_model.dart';
import 'package:meadowmiles/services/owner_application_service.dart';
import 'package:meadowmiles/states/authstate.dart';

class ApplyForOwnerPage extends StatefulWidget {
  const ApplyForOwnerPage({super.key});

  @override
  State<ApplyForOwnerPage> createState() => _ApplyForOwnerPageState();
}

class _ApplyForOwnerPageState extends State<ApplyForOwnerPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _reasonController = TextEditingController();
  UserModel? _userModel;

  final Map<DocumentType, XFile?> _uploadedDocuments = {};
  final Map<DocumentType, VehicleDocument?> _processedDocuments = {};

  bool _isSubmitting = false;
  bool _agreedToTerms = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkExistingApplication();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    final userModel = await authState.fetchCurrentUserModelSilent();
    if (mounted) {
      setState(() {
        _userModel = userModel;
      });
    }
  }

  Future<void> _checkExistingApplication() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    final user = authState.currentUser;

    if (user != null) {
      final hasPending =
          await OwnerApplicationService.hasPendingOwnerApplication(user.uid);
      final existingApp = await OwnerApplicationService.getUserOwnerApplication(
        user.uid,
      );

      if (hasPending && mounted) {
        _showExistingApplicationDialog(existingApp);
      } else if (existingApp != null &&
          existingApp.status == ApplicationStatus.rejected &&
          mounted) {
        _showRejectedApplicationDialog(existingApp);
      }
    }
  }

  void _showExistingApplicationDialog(OwnerApplication? application) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Application Already Exists'),
        content: Text(
          application != null
              ? 'You already have a ${application.status.toString().split('.').last} owner application. Please wait for the review process to complete.'
              : 'You already have a pending owner application.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRejectedApplicationDialog(OwnerApplication application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Previous Application Rejected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your previous application was rejected.'),
            if (application.adminResponse != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Reason:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(application.adminResponse!),
            ],
            const SizedBox(height: 8),
            const Text(
              'You can submit a new application addressing the issues mentioned above.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDocument(DocumentType type) async {
    try {
      final XFile? document = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (document != null) {
        setState(() {
          _uploadedDocuments[type] = document;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_getDocumentTypeName(type)} selected successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeDocument(DocumentType type) async {
    setState(() {
      _uploadedDocuments.remove(type);
      _processedDocuments.remove(type);
    });
  }

  String _getDocumentTypeName(DocumentType type) {
    switch (type) {
      case DocumentType.orcr:
        return 'ORCR (Official Receipt & Certificate of Registration)';
      case DocumentType.driversLicense:
        return "Driver's License";
      case DocumentType.validId:
        return 'Valid ID';
      case DocumentType.proofOfIncome:
        return 'Proof of Income';
      case DocumentType.other:
        return 'Other Document';
    }
  }

  String _getDocumentDescription(DocumentType type) {
    switch (type) {
      case DocumentType.orcr:
        return 'Required: Official Receipt and Certificate of Registration of your vehicle(s)';
      case DocumentType.driversLicense:
        return 'Required: Valid driver\'s license';
      case DocumentType.validId:
        return 'Required: Government-issued ID (Passport, National ID, etc.)';
      case DocumentType.proofOfIncome:
        return 'Optional: ITR, COE, or other proof of income documents';
      case DocumentType.other:
        return 'Optional: Any other supporting documents';
    }
  }

  bool _isDocumentRequired(DocumentType type) {
    return [
      DocumentType.orcr,
      DocumentType.driversLicense,
      DocumentType.validId,
    ].contains(type);
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if required documents are uploaded
    final requiredTypes = [
      DocumentType.orcr,
      DocumentType.driversLicense,
      DocumentType.validId,
    ];
    for (final type in requiredTypes) {
      if (!_uploadedDocuments.containsKey(type) ||
          _uploadedDocuments[type] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please upload ${_getDocumentTypeName(type)}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final user = _userModel;
      if (user == null) {
        throw Exception('User not found');
      }

      // Upload all documents
      final List<VehicleDocument> uploadedDocuments = [];

      for (final entry in _uploadedDocuments.entries) {
        if (entry.value != null) {
          final document = await OwnerApplicationService.uploadVehicleDocument(
            documentFile: entry.value!,
            type: entry.key,
            userId: user.uid,
            description: _getDocumentTypeName(entry.key),
          );

          if (document != null) {
            uploadedDocuments.add(document);
          }
        }
      }

      if (uploadedDocuments.length != _uploadedDocuments.length) {
        throw Exception('Failed to upload some documents');
      }

      // Submit application
      final success = await OwnerApplicationService.submitOwnerApplication(
        user: user,
        documents: uploadedDocuments,
        businessName: _businessNameController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
        emergencyContactName: _emergencyContactNameController.text.trim(),
        emergencyContactPhone: _emergencyContactPhoneController.text.trim(),
        reasonForApplication: _reasonController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Owner application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      } else {
        throw Exception('Failed to submit application');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply to Become an Owner'),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Information
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.business,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Owner Application',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Complete this form to apply for vehicle owner status. You\'ll need to upload vehicle documents including ORCR as proof of legal ownership.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Business Information
              Text(
                'Business Information',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _businessNameController,
                decoration: InputDecoration(
                  labelText: 'Business/Individual Name *',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Enter your business name or full name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Business name is required';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _businessAddressController,
                decoration: InputDecoration(
                  labelText: 'Business Address *',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Enter complete business address',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Business address is required';
                  }
                  return null;
                },
                maxLines: 2,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 24),

              // Emergency Contact
              Text(
                'Emergency Contact',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emergencyContactNameController,
                decoration: InputDecoration(
                  labelText: 'Emergency Contact Name *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Enter emergency contact name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Emergency contact name is required';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _emergencyContactPhoneController,
                decoration: InputDecoration(
                  labelText: 'Emergency Contact Phone *',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Enter emergency contact phone number',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Emergency contact phone is required';
                  }
                  return null;
                },
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              // Reason for Application
              Text(
                'Application Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for Application *',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText:
                      'Explain why you want to become a vehicle owner on our platform',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide a reason for your application';
                  }
                  if (value.length < 20) {
                    return 'Please provide a more detailed explanation (at least 20 characters)';
                  }
                  return null;
                },
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 24),

              // Document Upload Section
              Text(
                'Required Documents',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload clear, readable photos of the following documents:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              // Required Documents
              ...DocumentType.values.map((type) {
                final isRequired = _isDocumentRequired(type);
                final hasDocument =
                    _uploadedDocuments.containsKey(type) &&
                    _uploadedDocuments[type] != null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Card(
                    elevation: hasDocument ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: hasDocument
                            ? Colors.green
                            : (isRequired
                                  ? Colors.red.shade300
                                  : Colors.grey.shade300),
                        width: hasDocument ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                hasDocument
                                    ? Icons.check_circle
                                    : Icons.upload_file,
                                color: hasDocument
                                    ? Colors.green
                                    : (isRequired ? Colors.red : Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getDocumentTypeName(type),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: hasDocument
                                            ? Colors.green[700]
                                            : null,
                                      ),
                                ),
                              ),
                              if (isRequired)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'REQUIRED',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getDocumentDescription(type),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 12),

                          if (hasDocument) ...[
                            // Show uploaded document
                            Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade100,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_uploadedDocuments[type]!.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _pickDocument(type),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Replace'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade50,
                                      foregroundColor: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _removeDocument(type),
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Remove'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade50,
                                      foregroundColor: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Upload button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _pickDocument(type),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Upload Document'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Terms and Conditions
              CheckboxListTile(
                value: _agreedToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreedToTerms = value ?? false;
                  });
                },
                title: const Text(
                  'I agree to the terms and conditions and consent to document verification',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  'By checking this, you agree that the documents provided are authentic and accurate.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Submitting Application...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Submit Owner Application',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your application will be reviewed by our admin team. You will receive a notification once the review is complete.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
