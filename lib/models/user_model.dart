import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  final String name;
  final String email;
  final String phoneNumber;
  final UserModelType userType;
  final DateTime? createdAt;
  final bool verifiedUser;
  final bool online;
  final bool markDelete;
  final DateTime? markDeleteAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.userType,
    this.createdAt,
    this.verifiedUser = false,
    this.online = false,
    this.markDelete = false,
    this.markDeleteAt,
  });

  // Firestore serialization
  factory UserModel.fromMap(Map<String, dynamic> map, {String? uid}) {
    return UserModel(
      uid: uid ?? map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      userType: UserModelType.values.firstWhere(
        // ignore: prefer_interpolation_to_compose_strings
        (e) => e.toString() == 'UserModelType.' + (map['userType'] ?? 'rentee'),
        orElse: () => UserModelType.rentee,
      ),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
                ? (map['createdAt'] as Timestamp).toDate()
                : DateTime.tryParse(map['createdAt'].toString()))
          : null,
      verifiedUser: map['verifiedUser'] ?? false,
      online: map['online'] ?? false,
      markDelete: map['markDelete'] ?? false,
      markDeleteAt: map['markDeleteAt'] != null
          ? (map['markDeleteAt'] is Timestamp
                ? (map['markDeleteAt'] as Timestamp).toDate()
                : DateTime.tryParse(map['markDeleteAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'userType': userType.toString().split('.').last,
      'createdAt': createdAt,
      'verifiedUser': verifiedUser,
      'online': online,
      'markDelete': markDelete,
      'markDeleteAt': markDeleteAt,
    };
  }

  // Helper to generate a user ID in the format USERYYMMDDHHMMSSMS
  static String generateUserId({DateTime? dateTime}) {
    final now = dateTime ?? DateTime.now();
    final yy = now.year % 100;
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final ms = (now.millisecond ~/ 10).toString().padLeft(
      2,
      '0',
    ); // 2 digits for millis
    return 'USER${yy.toString().padLeft(2, '0')}$mm$dd$hh$min$ss$ms';
  }
}

enum UserModelType { admin, renter, rentee }
