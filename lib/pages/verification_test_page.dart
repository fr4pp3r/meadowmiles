import 'package:flutter/material.dart';
import 'package:meadowmiles/models/support_ticket_model.dart';
import 'package:meadowmiles/services/verification_service.dart';
import 'package:meadowmiles/components/support_ticket_card.dart';

class VerificationTestPage extends StatefulWidget {
  const VerificationTestPage({super.key});

  @override
  State<VerificationTestPage> createState() => _VerificationTestPageState();
}

class _VerificationTestPageState extends State<VerificationTestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification Test')),
      body: StreamBuilder<List<SupportTicket>>(
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
                  Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final tickets = snapshot.data ?? [];

          if (tickets.isEmpty) {
            return const Center(child: Text('No support tickets found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              return SupportTicketCard(
                ticket: tickets[index],
                onStatusChanged: () => setState(() {}),
              );
            },
          );
        },
      ),
    );
  }
}
