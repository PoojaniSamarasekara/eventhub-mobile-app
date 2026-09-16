import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String eventId;
  final int numberOfSeats;
  final String status; // confirmed, cancelled
  final DateTime bookingDate;
  final String attendeeName;
  final String attendeeContact;
  final String bookingReference;

  // Extra fields helper to avoid multiple reads
  final String eventName;
  final DateTime eventDateTime;
  final String eventLocation;
  final double totalPrice;

  Booking({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.numberOfSeats,
    required this.status,
    required this.bookingDate,
    required this.attendeeName,
    required this.attendeeContact,
    required this.bookingReference,
    required this.eventName,
    required this.eventDateTime,
    required this.eventLocation,
    required this.totalPrice,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      eventId: data['eventId'] ?? '',
      numberOfSeats: data['numberOfSeats'] ?? 0,
      status: data['status'] ?? 'confirmed',
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      attendeeName: data['attendeeName'] ?? '',
      attendeeContact: data['attendeeContact'] ?? '',
      bookingReference: data['bookingReference'] ?? '',
      eventName: data['eventName'] ?? '',
      eventDateTime: (data['eventDateTime'] as Timestamp).toDate(),
      eventLocation: data['eventLocation'] ?? '',
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'eventId': eventId,
      'numberOfSeats': numberOfSeats,
      'status': status,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'attendeeName': attendeeName,
      'attendeeContact': attendeeContact,
      'bookingReference': bookingReference,
      'eventName': eventName,
      'eventDateTime': Timestamp.fromDate(eventDateTime),
      'eventLocation': eventLocation,
      'totalPrice': totalPrice,
    };
  }
}
