import 'package:flutter/material.dart';
import 'package:meadowmiles/models/support_ticket_model.dart';
import 'package:meadowmiles/models/owner_application_model.dart';
import 'package:meadowmiles/services/verification_service.dart';
import 'package:meadowmiles/services/owner_application_service.dart';
import 'package:meadowmiles/components/support_ticket_card.dart';
import 'package:intl/intl.dart';

class AdminSupportTab extends StatefulWidget {
  const AdminSupportTab({super.key});

  @override
  State<AdminSupportTab> createState() => _AdminSupportTabState();
}

class _AdminSupportTabState extends State<AdminSupportTab>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.verified_user), text: 'Verification'),
              Tab(icon: Icon(Icons.support_agent), text: 'All Tickets'),
              Tab(icon: Icon(Icons.business), text: 'Owner Apps'),
            ],
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
            indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildVerificationTab(),
              _buildAllTicketsTab(),
              _buildOwnerApplicationsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationTab() {
    return StreamBuilder<List<SupportTicket>>(
      stream: VerificationService.getSupportTicketsByType(
        SupportTicketType.verification,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading verification tickets',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final tickets = snapshot.data ?? [];

        if (tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Verification Requests',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'User verification requests will appear here',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            return SupportTicketCard(
              ticket: tickets[index],
              onStatusChanged: () {
                // Refresh the list when status changes
                setState(() {});
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAllTicketsTab() {
    return StreamBuilder<List<SupportTicket>>(
      stream: VerificationService.getAllSupportTickets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading support tickets',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final tickets = snapshot.data ?? [];

        if (tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.support_agent,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Support Tickets',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'User support tickets will appear here',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            return SupportTicketCard(
              ticket: tickets[index],
              onStatusChanged: () {
                // Refresh the list when status changes
                setState(() {});
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOwnerApplicationsTab() {
    return FutureBuilder<List<OwnerApplication>>(
      future: OwnerApplicationService.getAllOwnerApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading owner applications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final applications = snapshot.data ?? [];

        if (applications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No Owner Applications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Owner applications will appear here',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              return _buildOwnerApplicationCard(application);
            },
          ),
        );
      },
    );
  }

  Widget _buildOwnerApplicationCard(OwnerApplication application) {
    Color statusColor = _getApplicationStatusColor(application.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(
            application.status == ApplicationStatus.approved
                ? Icons.check
                : application.status == ApplicationStatus.rejected
                ? Icons.close
                : application.status == ApplicationStatus.underReview
                ? Icons.reviews_outlined
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
            Text(application.businessName),
            const SizedBox(height: 4),
            Text(
              'Status: ${application.status.toString().split('.').last.toUpperCase()}',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              'Submitted: ${DateFormat('MMM dd, yyyy').format(application.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showOwnerApplicationDetails(application),
      ),
    );
  }

  Color _getApplicationStatusColor(ApplicationStatus status) {
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

  void _showOwnerApplicationDetails(OwnerApplication application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Owner Application Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildApplicationDetailRow('Applicant', application.userName),
                _buildApplicationDetailRow('Email', application.userEmail),
                _buildApplicationDetailRow(
                  'Business',
                  application.businessName,
                ),
                _buildApplicationDetailRow(
                  'Address',
                  application.businessAddress,
                ),
                _buildApplicationDetailRow(
                  'Emergency Contact',
                  '${application.emergencyContactName} (${application.emergencyContactPhone})',
                ),
                _buildApplicationDetailRow(
                  'Reason',
                  application.reasonForApplication,
                ),
                const SizedBox(height: 16),
                Text(
                  'Documents:',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...application.documents.map(
                  (doc) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: () => _viewDocument(doc),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getDocumentIcon(doc.type),
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getDocumentTypeName(doc.type),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    doc.fileName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Uploaded: ${DateFormat('MMM dd, yyyy').format(doc.uploadedAt)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.visibility,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                _showRejectApplicationDialog(application);
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateOwnerApplicationStatus(
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

  Widget _buildApplicationDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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

  void _showRejectApplicationDialog(OwnerApplication application) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Owner Application'),
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
                _updateOwnerApplicationStatus(
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

  Future<void> _updateOwnerApplicationStatus(
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
          backgroundColor: newStatus == ApplicationStatus.approved
              ? Colors.green
              : Colors.orange,
        ),
      );
      setState(() {}); // Trigger rebuild to refresh the list
    }
  }

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.orcr:
        return Icons.directions_car;
      case DocumentType.driversLicense:
        return Icons.credit_card;
      case DocumentType.validId:
        return Icons.badge;
      case DocumentType.proofOfIncome:
        return Icons.receipt_long;
      case DocumentType.other:
        return Icons.description;
    }
  }

  void _viewDocument(VehicleDocument document) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getDocumentIcon(document.type),
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDocumentTypeName(document.type),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          document.fileName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Document viewer
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: _isImageFile(document.fileName)
                    ? InteractiveViewer(
                        child: Image.network(
                          document.fileUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  SizedBox(height: 8),
                                  Text('Failed to load image'),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Document Preview',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cannot preview this file type.\nTap "Open" to download or view externally.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _openDocumentExternally(document.fileUrl),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open Document'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            // Footer with info and actions
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Uploaded: ${DateFormat('MMM dd, yyyy HH:mm').format(document.uploadedAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (document.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            document.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  // if (_isImageFile(document.fileName))
                  //   ElevatedButton.icon(
                  //     onPressed: () => _openDocumentExternally(document.fileUrl),
                  //     icon: const Icon(Icons.download),
                  //     label: const Text('Download'),
                  //   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isImageFile(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  Future<void> _openDocumentExternally(String url) async {
    // In a real app, you would use url_launcher package to open the URL
    // For now, we'll just show a snackbar with the URL
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document URL: $url'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // In a real app, copy to clipboard
          },
        ),
      ),
    );
  }
}
