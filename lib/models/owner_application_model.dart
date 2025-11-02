import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus { pending, underReview, approved, rejected }

enum DocumentType {
  orcr, // Official Receipt and Certificate of Registration
  driversLicense,
  validId,
  proofOfIncome,
  other,
}

class VehicleDocument {
  final String id;
  final DocumentType type;
  final String fileName;
  final String fileUrl;
  final DateTime uploadedAt;
  final String description;

  VehicleDocument({
    required this.id,
    required this.type,
    required this.fileName,
    required this.fileUrl,
    required this.uploadedAt,
    this.description = '',
  });

  factory VehicleDocument.fromMap(Map<String, dynamic> map, {String? id}) {
    return VehicleDocument(
      id: id ?? map['id'] ?? '',
      type: DocumentType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['type'] ?? 'other'),
        orElse: () => DocumentType.other,
      ),
      fileName: map['fileName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      uploadedAt: map['uploadedAt'] is Timestamp
          ? (map['uploadedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['uploadedAt'].toString()) ?? DateTime.now(),
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'uploadedAt': uploadedAt,
      'description': description,
    };
  }
}

class OwnerApplication {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String phoneNumber;
  final ApplicationStatus status;
  final List<VehicleDocument> documents;
  final String businessName;
  final String businessAddress;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String reasonForApplication;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminResponse;
  final String? adminId;
  final DateTime? reviewedAt;

  OwnerApplication({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.phoneNumber,
    this.status = ApplicationStatus.pending,
    this.documents = const [],
    this.businessName = '',
    this.businessAddress = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.reasonForApplication = '',
    required this.createdAt,
    this.updatedAt,
    this.adminResponse,
    this.adminId,
    this.reviewedAt,
  });

  factory OwnerApplication.fromMap(Map<String, dynamic> map, {String? id}) {
    return OwnerApplication(
      id: id ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      status: ApplicationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (map['status'] ?? 'pending'),
        orElse: () => ApplicationStatus.pending,
      ),
      documents:
          (map['documents'] as List<dynamic>?)
              ?.map(
                (doc) => VehicleDocument.fromMap(doc as Map<String, dynamic>),
              )
              .toList() ??
          [],
      businessName: map['businessName'] ?? '',
      businessAddress: map['businessAddress'] ?? '',
      emergencyContactName: map['emergencyContactName'] ?? '',
      emergencyContactPhone: map['emergencyContactPhone'] ?? '',
      reasonForApplication: map['reasonForApplication'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
                ? (map['updatedAt'] as Timestamp).toDate()
                : DateTime.tryParse(map['updatedAt'].toString()))
          : null,
      adminResponse: map['adminResponse'],
      adminId: map['adminId'],
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] is Timestamp
                ? (map['reviewedAt'] as Timestamp).toDate()
                : DateTime.tryParse(map['reviewedAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'phoneNumber': phoneNumber,
      'status': status.toString().split('.').last,
      'documents': documents.map((doc) => doc.toMap()).toList(),
      'businessName': businessName,
      'businessAddress': businessAddress,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'reasonForApplication': reasonForApplication,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'adminResponse': adminResponse,
      'adminId': adminId,
      'reviewedAt': reviewedAt,
    };
  }

  static String generateApplicationId({DateTime? dateTime}) {
    final now = dateTime ?? DateTime.now();
    final yy = now.year % 100;
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final ms = (now.millisecond ~/ 10).toString().padLeft(2, '0');
    return 'OWN${yy.toString().padLeft(2, '0')}$mm$dd$hh$min$ss$ms';
  }
}
