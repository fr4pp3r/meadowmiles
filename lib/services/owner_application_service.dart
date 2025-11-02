import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meadowmiles/models/owner_application_model.dart';
import 'package:meadowmiles/models/user_model.dart';

class OwnerApplicationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload a document to Supabase owner-documents bucket
  static Future<String?> _uploadDocument(
    XFile documentFile,
    String fileName,
  ) async {
    try {
      final file = File(documentFile.path);

      await _supabase.storage.from('owner-documents').upload(fileName, file);

      // Get public URL (works if bucket is public)
      final publicUrl = _supabase.storage
          .from('owner-documents')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading document: $e');
      return null;
    }
  }

  /// Get a signed URL for viewing private documents
  static Future<String?> getSignedDocumentUrl(String fileName) async {
    try {
      final signedUrl = await _supabase.storage
          .from('owner-documents')
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

  /// Submit owner application with documents
  static Future<bool> submitOwnerApplication({
    required UserModel user,
    required List<VehicleDocument> documents,
    required String businessName,
    required String businessAddress,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String reasonForApplication,
  }) async {
    try {
      final application = OwnerApplication(
        id: OwnerApplication.generateApplicationId(),
        userId: user.uid,
        userName: user.name,
        userEmail: user.email,
        phoneNumber: user.phoneNumber,
        status: ApplicationStatus.pending,
        documents: documents,
        businessName: businessName,
        businessAddress: businessAddress,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        reasonForApplication: reasonForApplication,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore.collection('owner_applications').doc(application.id).set(
        {...application.toMap(), 'createdAt': FieldValue.serverTimestamp()},
      );

      return true;
    } catch (e) {
      debugPrint('Error submitting owner application: $e');
      return false;
    }
  }

  /// Upload a document file and create VehicleDocument object
  static Future<VehicleDocument?> uploadVehicleDocument({
    required XFile documentFile,
    required DocumentType type,
    required String userId,
    String description = '',
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          '${userId}_${type.toString().split('.').last}_$timestamp.${documentFile.path.split('.').last}';

      final uploadedUrl = await _uploadDocument(documentFile, fileName);

      if (uploadedUrl != null) {
        return VehicleDocument(
          id: 'doc_$timestamp',
          type: type,
          fileName: fileName,
          fileUrl: uploadedUrl,
          uploadedAt: DateTime.now(),
          description: description,
        );
      }
    } catch (e) {
      debugPrint('Error uploading vehicle document: $e');
    }
    return null;
  }

  /// Check if user has a pending owner application
  static Future<bool> hasPendingOwnerApplication(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('owner_applications')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'underReview'])
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking pending application: $e');
      return false;
    }
  }

  /// Get user's owner application status
  static Future<OwnerApplication?> getUserOwnerApplication(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('owner_applications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return OwnerApplication.fromMap(doc.data(), id: doc.id);
      }
    } catch (e) {
      debugPrint('Error getting user application: $e');
    }
    return null;
  }

  /// Get all owner applications (for admin)
  static Future<List<OwnerApplication>> getAllOwnerApplications() async {
    try {
      final querySnapshot = await _firestore
          .collection('owner_applications')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => OwnerApplication.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting all applications: $e');
      return [];
    }
  }

  /// Update application status (for admin)
  static Future<bool> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
    String? adminResponse,
    String? adminId,
  }) async {
    try {
      await _firestore
          .collection('owner_applications')
          .doc(applicationId)
          .update({
            'status': status.toString().split('.').last,
            'adminResponse': adminResponse,
            'adminId': adminId,
            'reviewedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // If approved, update user type to rentee
      if (status == ApplicationStatus.approved) {
        final appDoc = await _firestore
            .collection('owner_applications')
            .doc(applicationId)
            .get();

        if (appDoc.exists) {
          final userId = appDoc.data()?['userId'];
          if (userId != null) {
            await _firestore.collection('users').doc(userId).update({
              'userType': 'rentee',
            });
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error updating application status: $e');
      return false;
    }
  }

  /// Delete a document from storage
  static Future<bool> deleteDocument(String fileName) async {
    try {
      await _supabase.storage.from('owner-documents').remove([fileName]);
      return true;
    } catch (e) {
      debugPrint('Error deleting document: $e');
      return false;
    }
  }
}
