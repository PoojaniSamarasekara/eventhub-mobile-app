import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../models/booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  final String _baseUrl = 'http://10.0.2.2:5001/eventhub-mobileapp/asia-east1/api';

  Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken() ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // GET /events
  Future<List<Event>> getEvents() async {
    final response = await http.get(Uri.parse('$_baseUrl/events'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => _parseEvent(item)).toList();
    } else {
      throw Exception('Failed to load events from REST API');
    }
  }

  // GET /events/:id
  Future<Event> getEventById(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/events/$id'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return _parseEvent(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load event details from REST API');
    }
  }

  // POST /events
  Future<void> createEvent(Map<String, dynamic> eventData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/events'),
      headers: await _getHeaders(),
      body: jsonEncode({
        ...eventData,
        'dateTime': (eventData['dateTime'] as DateTime).toIso8601String(),
      }),
    );
    if (response.statusCode != 201) {
      final errBody = jsonDecode(response.body);
      throw Exception(errBody['error'] ?? 'Failed to create event via REST API');
    }
  }

  // PUT /events/:id
  Future<void> updateEvent(String id, Map<String, dynamic> eventData) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/events/$id'),
      headers: await _getHeaders(),
      body: jsonEncode({
        ...eventData,
        'dateTime': (eventData['dateTime'] as DateTime).toIso8601String(),
      }),
    );
    if (response.statusCode != 200) {
      final errBody = jsonDecode(response.body);
      throw Exception(errBody['error'] ?? 'Failed to update event via REST API');
    }
  }

  // DELETE /events/:id
  Future<void> deleteEvent(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/events/$id'), headers: await _getHeaders());
    if (response.statusCode != 200) {
      final errBody = jsonDecode(response.body);
      throw Exception(errBody['error'] ?? 'Failed to delete event via REST API');
    }
  }

  // GET /bookings
  Future<List<Booking>> getBookings() async {
    final response = await http.get(Uri.parse('$_baseUrl/bookings'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => _parseBooking(item)).toList();
    } else {
      throw Exception('Failed to load bookings from REST API');
    }
  }

  // POST /bookings
  Future<void> createBooking(Map<String, dynamic> bookingData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/bookings'),
      headers: await _getHeaders(),
      body: jsonEncode({
        ...bookingData,
        'eventDateTime': (bookingData['eventDateTime'] as DateTime).toIso8601String(),
      }),
    );
    if (response.statusCode != 201) {
      final errBody = jsonDecode(response.body);
      throw Exception(errBody['error'] ?? 'Failed to record booking via REST API');
    }
  }

  // PUT /bookings/:id/cancel
  Future<void> cancelBooking(String id) async {
    final response = await http.put(Uri.parse('$_baseUrl/bookings/$id/cancel'), headers: await _getHeaders());
    if (response.statusCode != 200) {
      final errBody = jsonDecode(response.body);
      throw Exception(errBody['error'] ?? 'Failed to cancel booking via REST API');
    }
  }

  // Helper helper json parsers matching app serialization models parameters
  Event _parseEvent(Map<String, dynamic> item) {
    return Event(
      id: item['id'] ?? '',
      organizerId: item['organizerId'] ?? '',
      name: item['name'] ?? '',
      imageUrl: item['imageUrl'] ?? '',
      description: item['description'] ?? '',
      category: item['category'] ?? 'General',
      dateTime: _parseDate(item['dateTime']),
      location: item['location'] ?? '',
      price: (item['price'] ?? 0.0).toDouble(),
      totalSeats: item['totalSeats'] ?? 0,
      seatsAvailable: item['seatsAvailable'] ?? 0,
      createdAt: _parseDate(item['createdAt']),
    );
  }

  Booking _parseBooking(Map<String, dynamic> item) {
    return Booking(
      id: item['id'] ?? '',
      userId: item['userId'] ?? '',
      eventId: item['eventId'] ?? '',
      numberOfSeats: item['numberOfSeats'] ?? 0,
      status: item['status'] ?? 'confirmed',
      bookingDate: _parseDate(item['bookingDate']),
      attendeeName: item['attendeeName'] ?? '',
      attendeeContact: item['attendeeContact'] ?? '',
      bookingReference: item['bookingReference'] ?? '',
      eventName: item['eventName'] ?? '',
      eventDateTime: _parseDate(item['eventDateTime']),
      eventLocation: item['eventLocation'] ?? '',
      totalPrice: (item['totalPrice'] ?? 0.0).toDouble(),
    );
  }

  DateTime _parseDate(dynamic dateField) {
    if (dateField == null) return DateTime.now();
    if (dateField is Map && dateField['_seconds'] != null) {
      return Timestamp(dateField['_seconds'], dateField['_nanoseconds'] ?? 0).toDate();
    }
    return DateTime.parse(dateField.toString());
  }
}
