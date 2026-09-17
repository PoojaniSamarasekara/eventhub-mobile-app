import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/event.dart';
import 'models/booking.dart';
import 'services/organizer_service.dart';

class EventBookingsScreen extends StatelessWidget {
  final Event event;
  final OrganizerService _organizerService = OrganizerService();

  EventBookingsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bookings: ${event.name}')),
      body: StreamBuilder<List<Booking>>(
        stream: _organizerService.getEventBookings(event.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading bookings'));
          }

          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings recorded for this event.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ref: ${booking.bookingReference}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          Text(
                            booking.status.toUpperCase(),
                            style: TextStyle(
                              color: booking.status == 'confirmed' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text('Attendee: ${booking.attendeeName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Contact: ${booking.attendeeContact}'),
                      Text('Seats Reserved: ${booking.numberOfSeats}'),
                      Text('Booking Date: ${DateFormat('MMM d, yyyy • hh:mm a').format(booking.bookingDate)}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
