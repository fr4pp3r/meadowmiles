import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingDevice {
  final String id;
  final String name;
  final String userUid;
  final DateTime registeredAt;
  final bool isActive;
  final double? lastLatitude;
  final double? lastLongitude;
  final DateTime? lastLocationUpdate;
  final String? vehicleId;

  TrackingDevice({
    required this.id,
    required this.name,
    required this.userUid,
    required this.registeredAt,
    this.isActive = false,
    this.lastLatitude,
    this.lastLongitude,
    this.lastLocationUpdate,
    this.vehicleId,
  });

  factory TrackingDevice.fromMap(Map<String, dynamic> map, {String? id}) {
    return TrackingDevice(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      userUid: map['userUid'] ?? '',
      registeredAt: map['registeredAt'] != null
          ? (map['registeredAt'] is Timestamp
                ? (map['registeredAt'] as Timestamp).toDate()
                : DateTime.tryParse(map['registeredAt'].toString()) ??
                      DateTime.now())
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
      lastLatitude: map['lastLatitude']?.toDouble(),
      lastLongitude: map['lastLongitude']?.toDouble(),
      lastLocationUpdate: map['lastLocationUpdate'] != null
          ? (map['lastLocationUpdate'] is Timestamp
                ? (map['lastLocationUpdate'] as Timestamp).toDate()
                : DateTime.tryParse(map['lastLocationUpdate'].toString()))
          : null,
      vehicleId: map['vehicleId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'userUid': userUid,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'isActive': isActive,
      'lastLatitude': lastLatitude,
      'lastLongitude': lastLongitude,
      'lastLocationUpdate': lastLocationUpdate != null
          ? Timestamp.fromDate(lastLocationUpdate!)
          : null,
      'vehicleId': vehicleId,
    };
  }

  TrackingDevice copyWith({
    String? id,
    String? name,
    String? userUid,
    DateTime? registeredAt,
    bool? isActive,
    double? lastLatitude,
    double? lastLongitude,
    DateTime? lastLocationUpdate,
    String? vehicleId,
  }) {
    return TrackingDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      userUid: userUid ?? this.userUid,
      registeredAt: registeredAt ?? this.registeredAt,
      isActive: isActive ?? this.isActive,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      vehicleId: vehicleId ?? this.vehicleId,
    );
  }
}
