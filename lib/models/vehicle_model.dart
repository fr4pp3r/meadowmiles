enum VehicleType { car, motorcycle, van, suv, other }

class Vehicle {
  final String id;
  final String ownerId;
  final String make;
  final String model;
  final String plateNumber;
  final int year;
  final String color;
  final String imageUrl;
  final double pricePerDay;
  final bool isAvailable;
  final VehicleType vehicleType;

  Vehicle({
    required this.id,
    required this.ownerId,
    required this.make,
    required this.model,
    required this.plateNumber,
    required this.year,
    required this.color,
    this.imageUrl = '',
    required this.pricePerDay,
    required this.isAvailable,
    required this.vehicleType,
  });

  factory Vehicle.fromMap(Map<String, dynamic> map, {String? id}) {
    return Vehicle(
      id: id ?? map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      plateNumber: map['plateNumber'] ?? '',
      year: map['year'] ?? 0,
      color: map['color'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      pricePerDay: (map['pricePerDay'] is int)
          ? (map['pricePerDay'] as int).toDouble()
          : (map['pricePerDay'] ?? 0.0),
      isAvailable: map['isAvailable'] ?? true,
      vehicleType: VehicleType.values.firstWhere(
        // ignore: prefer_interpolation_to_compose_strings
        (e) => e.toString() == 'VehicleType.' + (map['vehicleType'] ?? 'car'),
        orElse: () => VehicleType.car,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'make': make,
      'model': model,
      'plateNumber': plateNumber,
      'year': year,
      'color': color,
      'imageUrl': imageUrl,
      'pricePerDay': pricePerDay,
      'isAvailable': isAvailable,
      'vehicleType': vehicleType.toString().split('.').last,
    };
  }

  // Helper to generate a vehicle ID in the format VEHICLEYYMMDDHHMMSSMS
  static String generateVehicleId({DateTime? dateTime}) {
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
    return 'VEHICLE${yy.toString().padLeft(2, '0')}$mm$dd$hh$min$ss$ms';
  }
}
