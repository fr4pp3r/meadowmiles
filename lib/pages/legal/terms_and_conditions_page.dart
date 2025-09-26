import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        forceMaterialTransparency: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                    Theme.of(context).colorScheme.secondary.withAlpha((0.05 * 255).toInt()),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.article,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Terms and Conditions',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: September 26, 2025',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Content
            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By accessing and using the MeadowMiles platform, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. If you do not agree to these terms, you must not use our services.',
            ),

            _buildSection(
              context,
              '2. Service Description',
              'MeadowMiles is a vehicle rental platform that connects vehicle owners with renters. Our platform facilitates the rental process but does not own or operate the vehicles listed on the platform.',
            ),

            _buildSection(
              context,
              '3. User Responsibilities',
              '''As a user of MeadowMiles, you agree to:

• Provide accurate and truthful information during registration and application processes
• Maintain the confidentiality of your account credentials
• Use the platform only for lawful purposes
• Comply with all applicable local, state, and federal laws
• Treat other users with respect and professionalism
• Report any suspicious or fraudulent activity immediately''',
            ),

            _buildSection(
              context,
              '4. Owner Obligations',
              '''Vehicle owners who list their vehicles on MeadowMiles must:

• Provide accurate vehicle information and documentation
• Ensure vehicles are properly maintained and roadworthy
• Carry adequate insurance coverage as required by law
• Respond promptly to rental requests and communications
• Provide vehicles in clean and acceptable condition
• Comply with all safety and legal requirements''',
            ),

            _buildSection(
              context,
              '5. Renter Obligations',
              '''Vehicle renters must:

• Possess a valid driver's license appropriate for the vehicle type
• Use vehicles responsibly and according to their intended purpose
• Return vehicles in the same condition as received
• Pay all applicable fees and charges on time
• Report any damage or issues immediately
• Comply with all traffic laws and regulations''',
            ),

            _buildSection(
              context,
              '6. Application Process',
              '''The owner application process includes:

• Submission of required documentation including ORCR, driver's license, and valid ID
• Verification of identity and vehicle ownership
• Review by our admin team
• Approval or rejection notification
• Right to reapply if initially rejected

Applications may be rejected for incomplete documentation, fraudulent information, or failure to meet our standards.''',
            ),

            _buildSection(
              context,
              '7. Fees and Payments',
              '''MeadowMiles may charge fees for:

• Platform usage and transaction processing
• Premium features and services
• Administrative services
• Late payment penalties

All fees are clearly disclosed before charges are incurred. Payment methods and terms are specified during the transaction process.''',
            ),

            _buildSection(
              context,
              '8. Insurance and Liability',
              '''Users acknowledge that:

• MeadowMiles is not an insurance provider
• Vehicle owners must maintain appropriate insurance coverage
• Users are responsible for verifying insurance coverage before transactions
• MeadowMiles is not liable for damages, accidents, or losses during vehicle use
• Users agree to indemnify MeadowMiles against claims arising from their use of the platform''',
            ),

            _buildSection(
              context,
              '9. Dispute Resolution',
              '''In case of disputes:

• Users should first attempt to resolve issues directly with each other
• MeadowMiles may provide mediation services at its discretion
• Serious disputes may require legal resolution through appropriate courts
• Users agree to binding arbitration for platform-related disputes as specified by applicable law''',
            ),

            _buildSection(
              context,
              '10. Termination',
              '''MeadowMiles reserves the right to:

• Suspend or terminate user accounts for violation of these terms
• Refuse service to any user at its discretion
• Modify or discontinue services with appropriate notice
• Remove listings that violate platform policies

Users may terminate their accounts at any time by contacting customer support.''',
            ),

            _buildSection(
              context,
              '11. Modifications',
              'MeadowMiles reserves the right to modify these Terms and Conditions at any time. Users will be notified of significant changes, and continued use of the platform constitutes acceptance of the modified terms.',
            ),

            _buildSection(
              context,
              '12. Governing Law',
              'These Terms and Conditions are governed by the laws of the jurisdiction where MeadowMiles operates. Any disputes will be resolved in the courts of competent jurisdiction in that area.',
            ),

            _buildSection(
              context,
              '13. Contact Information',
              '''For questions about these Terms and Conditions, contact us at:

Email: legal@meadowmiles.com
Phone: +1 (555) 123-4567
Address: 123 MeadowMiles Lane, City, State, ZIP

Business hours: Monday-Friday, 9:00 AM - 6:00 PM''',
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}