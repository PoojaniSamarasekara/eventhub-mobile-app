import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../models/booking.dart';

class OrganizerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUid => _auth.currentUser?.uid ?? '';

  // Future to get organizer name
  Future<String> getOrganizerName() async {
    final uid = _currentUid;
    if (uid.isEmpty) return 'Organizer';
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['name'] ?? 'Organizer';
    } catch (_) {
      return 'Organizer';
    }
  }

  // Stream user role from Firestore
  Stream<String> getUserRole() {
    final uid = _currentUid;
    if (uid.isEmpty) return Stream.value('user');
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data()?['role'] ?? 'user';
      }
      return 'user';
    });
  }

  // Get only events owned by this organizer
  Stream<List<Event>> getOrganizerEvents() {
    final uid = _currentUid;
    return _firestore
        .collection('events')
        .where('organizerId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
          list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return list;
        });
  }

  // Add a new event
  Future<void> addEvent(Map<String, dynamic> eventData) async {
    final uid = _currentUid;
    if (uid.isEmpty) throw Exception('User not authenticated');

    await _firestore.collection('events').add({
      ...eventData,
      'organizerId': uid,
      'seatsAvailable': eventData['totalSeats'],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update an existing event with dynamic seatsAvailable handling
  Future<void> updateEvent(String eventId, Map<String, dynamic> eventData) async {
    final uid = _currentUid;
    final DocumentReference eventRef = _firestore.collection('events').doc(eventId);

    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(eventRef);
      if (!snapshot.exists) throw Exception('Event not found');
      if (snapshot['organizerId'] != uid) throw Exception('Unauthorized to edit this event');

      int oldTotal = snapshot['totalSeats'] ?? 0;
      int oldAvailable = snapshot['seatsAvailable'] ?? 0;
      int bookedSeats = oldTotal - oldAvailable;

      int newTotal = eventData['totalSeats'];
      if (newTotal < bookedSeats) {
        throw Exception('Cannot reduce total seats below already booked seats ($bookedSeats)');
      }

      int newAvailable = newTotal - bookedSeats;

      transaction.update(eventRef, {
        ...eventData,
        'seatsAvailable': newAvailable,
      });
    });
  }

  // Delete event safely using transaction
  Future<void> deleteEvent(String eventId) async {
    final uid = _currentUid;
    final DocumentReference eventRef = _firestore.collection('events').doc(eventId);

    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(eventRef);
      if (!snapshot.exists) throw Exception('Event not found');
      if (snapshot['organizerId'] != uid) throw Exception('Unauthorized to delete this event');

      transaction.delete(eventRef);
    });
  }

  // Retrieve bookings for a specific event
  Stream<List<Booking>> getEventBookings(String eventId) {
    return _firestore
        .collection('bookings')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }
}
