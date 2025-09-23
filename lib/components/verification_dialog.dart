import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meadowmiles/models/user_model.dart';
import 'package:meadowmiles/services/verification_service.dart';
import 'dart:io';

class VerificationDialog extends StatefulWidget {
  final UserModel user;

  const VerificationDialog({super.key, required this.user});

  @override
  State<VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<VerificationDialog> {
  int _currentStep = 0;
  bool _privacyAccepted = false;
  XFile? _idImage;
  XFile? _selfieImage;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Account Verification',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stepper
            Expanded(
              child: Stepper(
                currentStep: _currentStep,
                controlsBuilder: (context, details) => const SizedBox.shrink(),
                steps: [
                  Step(
                    title: const Text('Privacy Policy'),
                    content: _buildPrivacyStep(),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0
                        ? StepState.complete
                        : _currentStep == 0
                        ? StepState.indexed
                        : StepState.disabled,
                  ),
                  Step(
                    title: const Text('Upload ID'),
                    content: _buildIdUploadStep(),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1
                        ? StepState.complete
                        : _currentStep == 1
                        ? StepState.indexed
                        : StepState.disabled,
                  ),
                  Step(
                    title: const Text('Take Selfie'),
                    content: _buildSelfieStep(),
                    isActive: _currentStep >= 2,
                    state: _currentStep > 2
                        ? StepState.complete
                        : _currentStep == 2
                        ? StepState.indexed
                        : StepState.disabled,
                  ),
                  Step(
                    title: const Text('Submit'),
                    content: _buildSubmitStep(),
                    isActive: _currentStep >= 3,
                    state: _currentStep == 3
                        ? StepState.indexed
                        : StepState.disabled,
                  ),
                ],
              ),
            ),

            // Navigation buttons
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() => _currentStep--),
                    child: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _getNextButtonAction(),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_getNextButtonText()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Notice',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'To verify your account, we need to collect and process the following information:\n\n'
                '• A photo of your government-issued ID\n'
                '• A selfie photograph for identity verification\n\n'
                'This information will be:\n'
                '• Stored securely in our encrypted storage system\n'
                '• Used only for identity verification purposes\n'
                '• Reviewed by our verification team\n'
                '• Deleted within 30 days after verification is complete\n\n'
                'By proceeding, you consent to this data collection and processing.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _privacyAccepted,
          onChanged: (value) =>
              setState(() => _privacyAccepted = value ?? false),
          title: const Text(
            'I agree to the privacy policy and consent to data processing',
            style: TextStyle(fontSize: 14),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildIdUploadStep() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _idImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(_idImage!.path), fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload your ID',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Government-issued ID (License, Passport, etc.)',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.camera, isId: true),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Camera'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.gallery, isId: true),
          icon: const Icon(Icons.photo_library),
          label: const Text('Gallery'),
        ),
      ],
    );
  }

  Widget _buildSelfieStep() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _selfieImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_selfieImage!.path),
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.face, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Take a selfie',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please take a clear photo of your face',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.camera, isId: false),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Camera'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.gallery, isId: false),
          icon: const Icon(Icons.photo_library),
          label: const Text('Gallery'),
        ),
      ],
    );
  }

  Widget _buildSubmitStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 12),
              Text(
                'Ready to Submit',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your verification request will be submitted to our team for review. You will be notified once the verification is complete.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_idImage != null && _selfieImage != null)
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(File(_idImage!.path), fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(
                      File(_selfieImage!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source, {required bool isId}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (isId) {
            _idImage = image;
          } else {
            _selfieImage = image;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  VoidCallback? _getNextButtonAction() {
    if (_isSubmitting) return null;

    switch (_currentStep) {
      case 0:
        return _privacyAccepted ? () => setState(() => _currentStep++) : null;
      case 1:
        return _idImage != null ? () => setState(() => _currentStep++) : null;
      case 2:
        return _selfieImage != null
            ? () => setState(() => _currentStep++)
            : null;
      case 3:
        return _canSubmit() ? _submitVerification : null;
      default:
        return null;
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Accept & Continue';
      case 1:
        return 'Continue';
      case 2:
        return 'Continue';
      case 3:
        return 'Submit';
      default:
        return 'Next';
    }
  }

  bool _canSubmit() {
    return _privacyAccepted && _idImage != null && _selfieImage != null;
  }

  Future<void> _submitVerification() async {
    if (!_canSubmit()) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await VerificationService.createVerificationTicket(
        user: widget.user,
        idImage: _idImage!,
        selfieImage: _selfieImage!,
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to submit verification request. Please try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
