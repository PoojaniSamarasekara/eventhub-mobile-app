import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Event>> getEvents() {
    return _firestore
        .collection('events')
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  Future<List<Event>> searchEvents(String query) async {
    // Basic client-side filtering for simplicity, or simple Firestore query
    // Firestore doesn't support easy full-text search without external tools,
    // but we can do a simple prefix search or just fetch all and filter.
    QuerySnapshot snapshot = await _firestore.collection('events').get();
    return snapshot.docs
        .map((doc) => Event.fromFirestore(doc))
        .where((event) => event.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Stream<List<Event>> getEventsByCategory(String category) {
    if (category == 'All') return getEvents();
    return _firestore
        .collection('events')
        .where('category', isEqualTo: category)
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }
}
