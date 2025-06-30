// Booking model for vehicle rental
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, onProcess, active, returned, cancelled }

class Booking {
  final String id;
  final String renterId; // User who made the booking
  final String vehicleId; // Chosen vehicle
  final String ownerId; // Owner of the vehicle
  final String transactionId; // Payment reference (transaction id, etc)
  final DateTime rentDate;
  final DateTime returnDate;
  final BookingStatus status;
  final String ratingRef; // Reference to a rating document (nullable)
  final String address; // Address for the booking (pickup/return location)
  final double rate; // Rating value (0-5)
  final String feedback; // Feedback text
  final double totalPrice; // Total price for the booking
  final String paymentproofUrl; // URL for proof of payment image

  Booking({
    required this.id,
    this.renterId = '',
    required this.vehicleId,
    this.ownerId = '',
    this.transactionId = '',
    required this.rentDate,
    required this.returnDate,
    this.status = BookingStatus.pending,
    this.ratingRef = '',
    this.address = '',
    this.rate = 0,
    this.feedback = '',
    this.totalPrice = 0,
    this.paymentproofUrl = '',
  });

  factory Booking.fromMap(Map<String, dynamic> map, {String? id}) {
    return Booking(
      id: id ?? map['id'] ?? '',
      renterId: map['renterId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      transactionId: map['transactionId'] ?? '',
      rentDate: (map['rentDate'] as Timestamp).toDate(),
      returnDate: (map['returnDate'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (map['status'] ?? 'pending'),
        orElse: () => BookingStatus.pending,
      ),
      ratingRef: map['ratingRef'] ?? '',
      address: map['address'] ?? '',
      rate: (map['rate'] is int)
          ? (map['rate'] as int).toDouble()
          : (map['rate'] ?? 0).toDouble(),
      feedback: map['feedback'] ?? '',
      totalPrice: (map['totalPrice'] is int)
          ? (map['totalPrice'] as int).toDouble()
          : (map['totalPrice'] ?? 0).toDouble(),
      paymentproofUrl: map['paymentproofUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'renterId': renterId,
      'vehicleId': vehicleId,
      'ownerId': ownerId,
      'transactionId': transactionId,
      'rentDate': Timestamp.fromDate(rentDate),
      'returnDate': Timestamp.fromDate(returnDate),
      'status': status.toString().split('.').last,
      'ratingRef': ratingRef,
      'address': address,
      'rate': rate,
      'feedback': feedback,
      'totalPrice': totalPrice,
      'proofUrl': paymentproofUrl,
    };
  }

  static String generateBookingId({DateTime? dateTime}) {
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
    return 'BOOK${yy.toString().padLeft(2, '0')}$mm$dd$hh$min$ss$ms';
  }
}
