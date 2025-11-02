import 'package:flutter/material.dart';
import 'package:meadowmiles/models/owner_application_model.dart';
import 'package:meadowmiles/services/owner_application_service.dart';
import 'package:intl/intl.dart';

class AdminOwnerApplicationsPage extends StatefulWidget {
  const AdminOwnerApplicationsPage({super.key});

  @override
  State<AdminOwnerApplicationsPage> createState() =>
      _AdminOwnerApplicationsPageState();
}

class _AdminOwnerApplicationsPageState
    extends State<AdminOwnerApplicationsPage> {
  List<OwnerApplication> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    final applications =
        await OwnerApplicationService.getAllOwnerApplications();
    if (mounted) {
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
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

  Future<void> _updateApplicationStatus(
    OwnerApplication application,
    ApplicationStatus newStatus,
    String? response,
  ) async {
    final success = await OwnerApplicationService.updateApplicationStatus(
      applicationId: application.id,
      status: newStatus,
      adminResponse: response,
      adminId: 'admin', // In real app, get from current admin user
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Application ${newStatus.toString().split('.').last} successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadApplications(); // Reload
    }
  }

  void _showApplicationDetails(OwnerApplication application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Application Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Applicant', application.userName),
              _buildDetailRow('Email', application.userEmail),
              _buildDetailRow('Business', application.businessName),
              _buildDetailRow('Address', application.businessAddress),
              _buildDetailRow(
                'Emergency Contact',
                '${application.emergencyContactName} (${application.emergencyContactPhone})',
              ),
              _buildDetailRow('Reason', application.reasonForApplication),
              const SizedBox(height: 16),
              Text('Documents:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...application.documents.map(
                (doc) => ListTile(
                  dense: true,
                  leading: Icon(Icons.description),
                  title: Text(_getDocumentTypeName(doc.type)),
                  subtitle: Text(
                    'Uploaded: ${DateFormat('MMM dd, yyyy').format(doc.uploadedAt)}',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (application.status == ApplicationStatus.pending) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showRejectDialog(application);
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateApplicationStatus(
                  application,
                  ApplicationStatus.approved,
                  'Your application has been approved! You can now list your vehicles for rent.',
                );
              },
              child: const Text('Approve'),
            ),
          ],
        ],
      ),
    );
  }

  void _showRejectDialog(OwnerApplication application) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter rejection reason...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                _updateApplicationStatus(
                  application,
                  ApplicationStatus.rejected,
                  controller.text,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getDocumentTypeName(DocumentType type) {
    switch (type) {
      case DocumentType.orcr:
        return 'ORCR';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Applications'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No applications found'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadApplications,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _applications.length,
                itemBuilder: (context, index) {
                  final application = _applications[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(application.status),
                        child: Icon(
                          application.status == ApplicationStatus.approved
                              ? Icons.check
                              : application.status == ApplicationStatus.rejected
                              ? Icons.close
                              : Icons.hourglass_empty,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        application.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(application.userEmail),
                          Text(
                            'Status: ${application.status.toString().split('.').last.toUpperCase()}',
                            style: TextStyle(
                              color: _getStatusColor(application.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Submitted: ${DateFormat('MMM dd, yyyy').format(application.createdAt)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _showApplicationDetails(application),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
