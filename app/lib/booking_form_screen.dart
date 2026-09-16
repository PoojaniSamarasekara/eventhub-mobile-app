import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/event.dart';
import 'services/booking_service.dart';

class BookingFormScreen extends StatefulWidget {
  final Event event;

  const BookingFormScreen({super.key, required this.event});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final BookingService _bookingService = BookingService();

  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  int _seatsSelected = 1;
  bool _isLoading = false;

  void _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    // Show summary dialog before confirming
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event: ${widget.event.name}'),
            Text('Seats: $_seatsSelected'),
            Text('Total Price: \$${(widget.event.price * _seatsSelected).toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Attendee: ${_nameController.text.trim()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _bookingService.createBooking(
        eventId: widget.event.id,
        eventName: widget.event.name,
        eventDateTime: widget.event.dateTime,
        eventLocation: widget.event.location,
        eventPrice: widget.event.price,
        seatsToBook: _seatsSelected,
        attendeeName: _nameController.text.trim(),
        attendeeContact: _contactController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking Confirmed Successfully!'), backgroundColor: Colors.green),
        );
        // Pop back to Event Details
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.event.price * _seatsSelected;

    return Scaffold(
      appBar: AppBar(title: const Text('Book Event')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.event.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(DateFormat('MMM d, yyyy • hh:mm a').format(widget.event.dateTime)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(widget.event.location),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Select Seats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        const Text('Number of Seats: ', style: TextStyle(fontSize: 16)),
                        const Spacer(),
                        DropdownButton<int>(
                          value: _seatsSelected,
                          items: List.generate(
                            widget.event.seatsAvailable > 5 ? 5 : widget.event.seatsAvailable,
                            (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1}')),
                          ),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _seatsSelected = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    const Text('Attendee Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter full name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter contact number' : null,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Price:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(totalPrice == 0 ? 'FREE' : '\$${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitBooking,
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Proceed to Confirm', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
