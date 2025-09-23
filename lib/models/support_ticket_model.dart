import 'package:cloud_firestore/cloud_firestore.dart';

enum SupportTicketType { verification, general, technical, complaint }

enum SupportTicketStatus { pending, inReview, resolved, rejected }

class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final SupportTicketType type;
  final SupportTicketStatus status;
  final String title;
  final String description;
  final List<String> attachmentUrls;
  final String? idImageUrl;
  final String? selfieImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminResponse;
  final String? adminId;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    this.attachmentUrls = const [],
    this.idImageUrl,
    this.selfieImageUrl,
    required this.createdAt,
    this.updatedAt,
    this.adminResponse,
    this.adminId,
  });

  factory SupportTicket.fromMap(Map<String, dynamic> map, {String? id}) {
    return SupportTicket(
      id: id ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      type: SupportTicketType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['type'] ?? 'general'),
        orElse: () => SupportTicketType.general,
      ),
      status: SupportTicketStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (map['status'] ?? 'pending'),
        orElse: () => SupportTicketStatus.pending,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      idImageUrl: map['idImageUrl'],
      selfieImageUrl: map['selfieImageUrl'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
                ? (map['createdAt'] as Timestamp).toDate()
                : DateTime.tryParse(map['createdAt'].toString()) ??
                      DateTime.now())
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
                ? (map['updatedAt'] as Timestamp).toDate()
                : DateTime.tryParse(map['updatedAt'].toString()))
          : null,
      adminResponse: map['adminResponse'],
      adminId: map['adminId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'title': title,
      'description': description,
      'attachmentUrls': attachmentUrls,
      'idImageUrl': idImageUrl,
      'selfieImageUrl': selfieImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'adminResponse': adminResponse,
      'adminId': adminId,
    };
  }

  SupportTicket copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    SupportTicketType? type,
    SupportTicketStatus? status,
    String? title,
    String? description,
    List<String>? attachmentUrls,
    String? idImageUrl,
    String? selfieImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminResponse,
    String? adminId,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      idImageUrl: idImageUrl ?? this.idImageUrl,
      selfieImageUrl: selfieImageUrl ?? this.selfieImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminResponse: adminResponse ?? this.adminResponse,
      adminId: adminId ?? this.adminId,
    );
  }
}
