import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String organizerId;
  final String name;
  final String imageUrl;
  final String description;
  final String category;
  final DateTime dateTime;
  final String location;
  final double price;
  final int totalSeats;
  final int seatsAvailable;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.organizerId,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.dateTime,
    required this.location,
    required this.price,
    required this.totalSeats,
    required this.seatsAvailable,
    required this.createdAt,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      organizerId: data['organizerId'] ?? '',
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      totalSeats: data['totalSeats'] ?? 0,
      seatsAvailable: data['seatsAvailable'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'organizerId': organizerId,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'category': category,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'price': price,
      'totalSeats': totalSeats,
      'seatsAvailable': seatsAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
