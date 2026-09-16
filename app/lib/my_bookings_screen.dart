import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/booking.dart';
import 'services/booking_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _cancelBooking(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _bookingService.cancelBooking(booking);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: StreamBuilder<List<Booking>>(
        stream: _bookingService.getUserBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading bookings'));
          }

          final bookings = snapshot.data ?? [];
          final now = DateTime.now();

          final upcoming = bookings.where((b) => b.status == 'confirmed' && b.eventDateTime.isAfter(now)).toList();
          final past = bookings.where((b) => b.status == 'confirmed' && b.eventDateTime.isBefore(now)).toList();
          final cancelled = bookings.where((b) => b.status == 'cancelled').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(upcoming, isUpcoming: true),
              _buildBookingList(past),
              _buildBookingList(cancelled),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(List<Booking> list, {bool isUpcoming = false}) {
    if (list.isEmpty) {
      return const Center(child: Text('No bookings found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final booking = list[index];
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: booking.status == 'confirmed' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        booking.status.toUpperCase(),
                        style: TextStyle(color: booking.status == 'confirmed' ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(booking.eventName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(DateFormat('MMM d, yyyy • hh:mm a').format(booking.eventDateTime), style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.chair, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${booking.numberOfSeats} seat(s)', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: \$${booking.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (isUpcoming)
                      TextButton.icon(
                        onPressed: () => _cancelBooking(booking),
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
