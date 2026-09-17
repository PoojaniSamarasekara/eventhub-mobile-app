import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/organizer_service.dart';
import 'models/event.dart';
import 'add_edit_event_screen.dart';
import 'event_bookings_screen.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() => _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  final OrganizerService _organizerService = OrganizerService();
  String _organizerName = 'Organizer';

  @override
  void initState() {
    super.initState();
    _loadOrganizerName();
  }

  Future<void> _loadOrganizerName() async {
    final name = await _organizerService.getOrganizerName();
    if (mounted) {
      setState(() {
        _organizerName = name;
      });
    }
  }

  void _confirmDelete(String eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _organizerService.deleteEvent(eventId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully'), backgroundColor: Colors.green),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organizer Dashboard')),
      body: StreamBuilder<List<Event>>(
        stream: _organizerService.getOrganizerEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading events'));
          }

          final events = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, $_organizerName',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text('Total Events Created: ${events.length}'),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddEditEventScreen()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Event'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'My Events',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: events.isEmpty
                    ? const Center(child: Text('No events created yet. Tap Add Event to start.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Category: ${event.category} | Price: \$${event.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
                                  Text('Date: ${DateFormat('MMM d, yyyy • hh:mm a').format(event.dateTime)}', style: const TextStyle(color: Colors.grey)),
                                  Text('Seats: ${event.seatsAvailable} available / ${event.totalSeats} total', style: const TextStyle(fontWeight: FontWeight.w500)),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.list_alt, size: 18),
                                        label: const Text('Bookings'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => EventBookingsScreen(event: event)),
                                          );
                                        },
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const Text('Edit'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => AddEditEventScreen(event: event)),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _confirmDelete(event.id),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
