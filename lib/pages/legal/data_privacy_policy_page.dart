import 'package:flutter/material.dart';

class DataPrivacyPolicyPage extends StatelessWidget {
  const DataPrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Privacy Policy'),
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
                    Colors.blue.withAlpha((0.1 * 255).toInt()),
                    Colors.purple.withAlpha((0.05 * 255).toInt()),
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
                        Icons.privacy_tip,
                        color: Colors.blue.shade700,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Data Privacy Policy',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
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
              '1. Introduction',
              'MeadowMiles ("we," "our," or "us") is committed to protecting your privacy and personal information. This Privacy Policy explains how we collect, use, share, and protect your information when you use our vehicle rental platform.',
              Icons.info_outline,
              Colors.blue,
            ),

            _buildSection(
              context,
              '2. Information We Collect',
              '''We collect the following types of information:

Personal Information:
• Name, email address, and phone number
• Date of birth and government-issued ID details
• Driver's license information
• Emergency contact information
• Profile photos and selfie verification

Vehicle Information:
• Vehicle registration documents (ORCR)
• Vehicle photos and specifications
• Insurance documentation
• Maintenance records

Usage Information:
• Location data and GPS coordinates
• App usage patterns and preferences
• Communication logs and support interactions
• Transaction history and payment information

Device Information:
• Device type, operating system, and unique identifiers
• IP address and network information
• Camera and photo access for document verification''',
              Icons.data_usage,
              Colors.green,
            ),

            _buildSection(
              context,
              '3. How We Use Your Information',
              '''We use your information for:

Service Provision:
• Account creation and user authentication
• Identity and document verification
• Facilitating vehicle rentals and bookings
• Processing payments and transactions
• Providing customer support

Safety and Security:
• Preventing fraud and unauthorized access
• Ensuring platform safety and security
• Conducting background checks when necessary
• Monitoring for suspicious activities

Communication:
• Sending transaction confirmations and updates
• Providing important service announcements
• Responding to inquiries and support requests
• Marketing communications (with your consent)

Improvement and Analytics:
• Analyzing usage patterns to improve services
• Developing new features and functionality
• Conducting research and data analysis
• Personalizing user experience''',
              Icons.lightbulb_outline,
              Colors.orange,
            ),

            _buildSection(
              context,
              '4. Information Sharing',
              '''We may share your information with:

Service Partners:
• Payment processors for transaction handling
• Identity verification services
• Cloud storage and hosting providers
• Analytics and performance monitoring services

Legal Requirements:
• Law enforcement when required by law
• Government agencies for compliance purposes
• Courts and legal proceedings when necessary
• Regulatory bodies as required

Business Transfers:
• In case of merger, acquisition, or sale of assets
• With professional advisors during business transactions

We do NOT sell your personal information to third parties for marketing purposes.''',
              Icons.share,
              Colors.purple,
            ),

            _buildSection(
              context,
              '5. Data Security',
              '''We implement robust security measures including:

Technical Safeguards:
• End-to-end encryption for sensitive data
• Secure data transmission protocols (HTTPS/TLS)
• Regular security audits and penetration testing
• Multi-factor authentication for admin access

Physical Security:
• Secure data center facilities
• Restricted access to servers and equipment
• 24/7 monitoring and surveillance systems

Operational Security:
• Employee training on data protection
• Background checks for staff with data access
• Regular security policy updates and reviews
• Incident response and breach notification procedures''',
              Icons.security,
              Colors.red,
            ),

            _buildSection(
              context,
              '6. Your Rights and Choices',
              '''You have the following rights regarding your data:

Access Rights:
• Request copies of your personal information
• View how your data is being used
• Obtain information about data sharing

Control Rights:
• Update or correct your personal information
• Delete your account and associated data
• Opt-out of marketing communications
• Restrict certain data processing activities

Portability Rights:
• Export your data in a machine-readable format
• Transfer data to another service provider

To exercise these rights, contact us at privacy@meadowmiles.com''',
              Icons.person_outline,
              Colors.teal,
            ),

            _buildSection(
              context,
              '7. Data Retention',
              '''We retain your information for:

Active Accounts:
• Personal information: Duration of account plus 7 years
• Transaction records: 7 years after last transaction
• Support communications: 3 years after resolution

Inactive Accounts:
• Account deletion after 2 years of inactivity
• Essential data retained for legal/regulatory purposes
• Anonymous usage data may be retained indefinitely

Verification Documents:
• ID documents: Deleted within 30 days after verification
• Vehicle documents: Retained while vehicle is listed
• Backup copies: Securely deleted within 90 days''',
              Icons.schedule,
              Colors.indigo,
            ),

            _buildSection(
              context,
              '8. International Data Transfers',
              'Your information may be processed and stored in countries other than your residence. We ensure appropriate safeguards are in place for international transfers, including standard contractual clauses and adequacy decisions.',
              Icons.public,
              Colors.cyan,
            ),

            _buildSection(
              context,
              '9. Children\'s Privacy',
              'Our services are not intended for users under 18 years of age. We do not knowingly collect personal information from children. If we become aware that we have collected information from a child, we will promptly delete it.',
              Icons.child_care,
              Colors.pink,
            ),

            _buildSection(
              context,
              '10. Changes to This Policy',
              'We may update this Privacy Policy periodically. We will notify you of significant changes by email or through the app. Your continued use of our services after changes indicates acceptance of the updated policy.',
              Icons.update,
              Colors.amber,
            ),

            _buildSection(
              context,
              '11. Contact Information',
              '''For privacy-related questions or concerns:

Data Protection Officer:
Email: privacy@meadowmiles.com
Phone: +1 (555) 123-4567

Mailing Address:
MeadowMiles Privacy Team
123 MeadowMiles Lane
City, State, ZIP

Business Hours: Monday-Friday, 9:00 AM - 6:00 PM

We aim to respond to all privacy inquiries within 30 days.''',
              Icons.contact_support,
              Colors.brown,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha((0.05 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha((0.2 * 255).toInt())),
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