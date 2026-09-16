import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _generateReference() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> createBooking({
    required String eventId,
    required String eventName,
    required DateTime eventDateTime,
    required String eventLocation,
    required double eventPrice,
    required int seatsToBook,
    required String attendeeName,
    required String attendeeContact,
  }) async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final DocumentReference eventRef = _firestore.collection('events').doc(eventId);
    final DocumentReference bookingRef = _firestore.collection('bookings').doc();

    final String reference = _generateReference();
    final double totalPrice = eventPrice * seatsToBook;

    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot eventSnapshot = await transaction.get(eventRef);
      if (!eventSnapshot.exists) {
        throw Exception('Event does not exist');
      }

      int currentAvailable = eventSnapshot['seatsAvailable'] ?? 0;
      if (currentAvailable < seatsToBook) {
        throw Exception('Not enough available seats left');
      }

      // Update available seats
      transaction.update(eventRef, {
        'seatsAvailable': currentAvailable - seatsToBook,
      });

      // Write booking details
      transaction.set(bookingRef, {
        'userId': userId,
        'eventId': eventId,
        'numberOfSeats': seatsToBook,
        'status': 'confirmed',
        'bookingDate': FieldValue.serverTimestamp(),
        'attendeeName': attendeeName,
        'attendeeContact': attendeeContact,
        'bookingReference': reference,
        'eventName': eventName,
        'eventDateTime': Timestamp.fromDate(eventDateTime),
        'eventLocation': eventLocation,
        'totalPrice': totalPrice,
      });
    });
  }

  Future<void> cancelBooking(Booking booking) async {
    final DocumentReference eventRef = _firestore.collection('events').doc(booking.eventId);
    final DocumentReference bookingRef = _firestore.collection('bookings').doc(booking.id);

    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot eventSnapshot = await transaction.get(eventRef);
      DocumentSnapshot bookingSnapshot = await transaction.get(bookingRef);

      if (!bookingSnapshot.exists) throw Exception('Booking not found');
      if (bookingSnapshot['status'] == 'cancelled') throw Exception('Booking already cancelled');

      // Return seats to total available if event exists
      if (eventSnapshot.exists) {
        int currentAvailable = eventSnapshot['seatsAvailable'] ?? 0;
        transaction.update(eventRef, {
          'seatsAvailable': currentAvailable + booking.numberOfSeats,
        });
      }

      // Mark booking status as cancelled
      transaction.update(bookingRef, {
        'status': 'cancelled',
      });
    });
  }

  Stream<List<Booking>> getUserBookings() {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList()
              ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate)));
  }
}
