import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meadowmiles/models/owner_application_model.dart';
import 'package:meadowmiles/services/owner_application_service.dart';
import 'package:meadowmiles/states/authstate.dart';
import 'package:intl/intl.dart';

class ApplicationStatusPage extends StatefulWidget {
  const ApplicationStatusPage({super.key});

  @override
  State<ApplicationStatusPage> createState() => _ApplicationStatusPageState();
}

class _ApplicationStatusPageState extends State<ApplicationStatusPage> {
  OwnerApplication? _application;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplicationStatus();
  }

  Future<void> _loadApplicationStatus() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    final user = authState.currentUser;

    if (user != null) {
      final application = await OwnerApplicationService.getUserOwnerApplication(
        user.uid,
      );

      if (mounted) {
        setState(() {
          _application = application;
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Colors.orange;
      case ApplicationStatus.underReview:
        return Colors.blue;
      case ApplicationStatus.approved:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.hourglass_empty;
      case ApplicationStatus.underReview:
        return Icons.search;
      case ApplicationStatus.approved:
        return Icons.check_circle;
      case ApplicationStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getStatusDescription(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Your application has been submitted and is waiting to be reviewed.';
      case ApplicationStatus.underReview:
        return 'Your application is currently being reviewed by our admin team.';
      case ApplicationStatus.approved:
        return 'Congratulations! Your application has been approved. You can now list vehicles for rent.';
      case ApplicationStatus.rejected:
        return 'Your application has been rejected. Please see the admin response below for more details.';
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Application Status'),
          centerTitle: true,
          forceMaterialTransparency: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_application == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Application Status'),
          centerTitle: true,
          forceMaterialTransparency: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No Application Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You haven\'t submitted an owner application yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Status'),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadApplicationStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getStatusColor(
                          _application!.status,
                        ).withValues(alpha: 0.1),
                        _getStatusColor(
                          _application!.status,
                        ).withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          _getStatusIcon(_application!.status),
                          size: 48,
                          color: _getStatusColor(_application!.status),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _application!.status
                              .toString()
                              .split('.')
                              .last
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(_application!.status),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getStatusDescription(_application!.status),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Application Details
              Text(
                'Application Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow('Application ID', _application!.id),
                      _buildInfoRow(
                        'Submitted On',
                        DateFormat(
                          'MMM dd, yyyy HH:mm',
                        ).format(_application!.createdAt),
                      ),
                      _buildInfoRow('Applicant Name', _application!.userName),
                      _buildInfoRow('Email', _application!.userEmail),
                      _buildInfoRow(
                        'Business Name',
                        _application!.businessName,
                      ),
                      _buildInfoRow(
                        'Business Address',
                        _application!.businessAddress,
                      ),
                      _buildInfoRow(
                        'Emergency Contact',
                        '${_application!.emergencyContactName} (${_application!.emergencyContactPhone})',
                      ),
                      if (_application!.updatedAt != null)
                        _buildInfoRow(
                          'Last Updated',
                          DateFormat(
                            'MMM dd, yyyy HH:mm',
                          ).format(_application!.updatedAt!),
                        ),
                      if (_application!.reviewedAt != null)
                        _buildInfoRow(
                          'Reviewed On',
                          DateFormat(
                            'MMM dd, yyyy HH:mm',
                          ).format(_application!.reviewedAt!),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Reason for Application
              Text(
                'Application Reason',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _application!.reasonForApplication,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Uploaded Documents
              Text(
                'Uploaded Documents',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ...(_application!.documents.map((document) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.description,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(_getDocumentTypeName(document.type)),
                    subtitle: Text(
                      'Uploaded: ${DateFormat('MMM dd, yyyy').format(document.uploadedAt)}',
                    ),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                );
              }).toList()),

              const SizedBox(height: 24),

              // Admin Response (if any)
              if (_application!.adminResponse != null) ...[
                Text(
                  'Admin Response',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _application!.status == ApplicationStatus.approved
                          ? Colors.green
                          : Colors.red,
                      width: 2,
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
                              _application!.status == ApplicationStatus.approved
                                  ? Icons.check_circle
                                  : Icons.info,
                              color:
                                  _application!.status ==
                                      ApplicationStatus.approved
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _application!.status == ApplicationStatus.approved
                                  ? 'Approved'
                                  : 'Response',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    _application!.status ==
                                        ApplicationStatus.approved
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _application!.adminResponse!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],

              // Action Buttons
              if (_application!.status == ApplicationStatus.approved) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed('/rentee_dashboard');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Go to Owner Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ] else if (_application!.status ==
                  ApplicationStatus.rejected) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed('/apply_for_owner');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Submit New Application',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
