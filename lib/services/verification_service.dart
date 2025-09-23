import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meadowmiles/models/support_ticket_model.dart';
import 'package:meadowmiles/models/user_model.dart';

class VerificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Alternative Supabase client with service role key (if needed)
  static SupabaseClient? _serviceRoleClient;

  /// Upload an image to Supabase id-storage bucket
  static Future<String?> _uploadImage(XFile imageFile, String fileName) async {
    try {
      final file = File(imageFile.path);

      await _supabase.storage.from('id-storage').upload(fileName, file);

      // Get public URL (works if bucket is public)
      final publicUrl = _supabase.storage
          .from('id-storage')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Get a signed URL for viewing private images
  static Future<String?> getSignedImageUrl(String fileName) async {
    try {
      final signedUrl = await _supabase.storage
          .from('id-storage')
          .createSignedUrl(fileName, 60 * 60 * 24); // 24 hours expiry
      return signedUrl;
    } catch (e) {
      debugPrint('Error creating signed URL: $e');
      return null;
    }
  }

  /// Extract file name from URL
  static String? extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
    } catch (e) {
      debugPrint('Error extracting filename: $e');
    }
    return null;
  }

  /// Create a verification support ticket
  static Future<bool> createVerificationTicket({
    required UserModel user,
    required XFile idImage,
    required XFile selfieImage,
  }) async {
    try {
      // Generate unique file names
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final idFileName = 'id_${user.uid}_$timestamp.jpg';
      final selfieFileName = 'selfie_${user.uid}_$timestamp.jpg';

      // Upload images
      final idImageUrl = await _uploadImage(idImage, idFileName);
      final selfieImageUrl = await _uploadImage(selfieImage, selfieFileName);

      if (idImageUrl == null || selfieImageUrl == null) {
        throw Exception('Failed to upload images');
      }

      // Create support ticket
      final ticketId = _firestore.collection('support_tickets').doc().id;
      final ticket = SupportTicket(
        id: ticketId,
        userId: user.uid,
        userName: user.name,
        userEmail: user.email,
        type: SupportTicketType.verification,
        status: SupportTicketStatus.pending,
        title: 'User Verification Request',
        description:
            'User has submitted ID and selfie for account verification.',
        idImageUrl: idImageUrl,
        selfieImageUrl: selfieImageUrl,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('support_tickets')
          .doc(ticketId)
          .set(ticket.toMap());

      return true;
    } catch (e) {
      debugPrint('Error creating verification ticket: $e');
      return false;
    }
  }

  /// Get all support tickets for admin
  static Stream<List<SupportTicket>> getAllSupportTickets() {
    return _firestore
        .collection('support_tickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SupportTicket.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  /// Get support tickets by type
  static Stream<List<SupportTicket>> getSupportTicketsByType(
    SupportTicketType type,
  ) {
    return _firestore
        .collection('support_tickets')
        .where('type', isEqualTo: type.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SupportTicket.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  /// Update support ticket status
  static Future<bool> updateTicketStatus({
    required String ticketId,
    required SupportTicketStatus status,
    String? adminResponse,
    String? adminId,
  }) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (adminResponse != null) {
        updateData['adminResponse'] = adminResponse;
      }

      if (adminId != null) {
        updateData['adminId'] = adminId;
      }

      await _firestore
          .collection('support_tickets')
          .doc(ticketId)
          .update(updateData);

      return true;
    } catch (e) {
      debugPrint('Error updating ticket status: $e');
      return false;
    }
  }

  /// Approve user verification
  static Future<bool> approveUserVerification({
    required String ticketId,
    required String userId,
    String? adminId,
  }) async {
    try {
      // Update user verification status
      await _firestore.collection('users').doc(userId).update({
        'verifiedUser': true,
      });

      // Update support ticket
      await updateTicketStatus(
        ticketId: ticketId,
        status: SupportTicketStatus.resolved,
        adminResponse: 'User verification approved.',
        adminId: adminId,
      );

      return true;
    } catch (e) {
      debugPrint('Error approving user verification: $e');
      return false;
    }
  }

  /// Reject user verification
  static Future<bool> rejectUserVerification({
    required String ticketId,
    required String reason,
    String? adminId,
  }) async {
    try {
      await updateTicketStatus(
        ticketId: ticketId,
        status: SupportTicketStatus.rejected,
        adminResponse: 'Verification rejected: $reason',
        adminId: adminId,
      );

      return true;
    } catch (e) {
      debugPrint('Error rejecting user verification: $e');
      return false;
    }
  }

  /// Check if user has pending verification ticket
  static Future<bool> hasPendingVerificationTicket(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('support_tickets')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'verification')
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking pending verification: $e');
      return false;
    }
  }
}
