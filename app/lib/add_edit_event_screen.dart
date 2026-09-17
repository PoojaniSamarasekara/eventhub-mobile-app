import 'package:flutter/material.dart';
import 'models/event.dart';
import 'services/organizer_service.dart';

class AddEditEventScreen extends StatefulWidget {
  final Event? event;

  const AddEditEventScreen({super.key, this.event});

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final OrganizerService _organizerService = OrganizerService();

  late TextEditingController _nameController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _totalSeatsController;

  String _selectedCategory = 'Music';
  DateTime _selectedDateTime = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;

  final List<String> _categories = ['Music', 'Sports', 'Education', 'Workshop', 'Tech', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event?.name ?? '');
    _imageUrlController = TextEditingController(text: widget.event?.imageUrl ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _locationController = TextEditingController(text: widget.event?.location ?? '');
    _priceController = TextEditingController(text: widget.event?.price.toString() ?? '0.0');
    _totalSeatsController = TextEditingController(text: widget.event?.totalSeats.toString() ?? '50');
    if (widget.event != null) {
      _selectedCategory = widget.event!.category;
      _selectedDateTime = widget.event!.dateTime;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _totalSeatsController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final eventData = {
      'name': _nameController.text.trim(),
      'imageUrl': _imageUrlController.text.trim().isEmpty ? 'https://placehold.co/600x400/png' : _imageUrlController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _selectedCategory,
      'dateTime': _selectedDateTime,
      'location': _locationController.text.trim(),
      'price': double.parse(_priceController.text),
      'totalSeats': int.parse(_totalSeatsController.text),
    };

    try {
      if (widget.event == null) {
        await _organizerService.addEvent(eventData);
      } else {
        await _organizerService.updateEvent(widget.event!.id, eventData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.event == null ? 'Event added successfully' : 'Event updated successfully'), backgroundColor: Colors.green),
        );
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
  Widget build(BuildContext context) {
    final isEdit = widget.event != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Event' : 'Add Event')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Event Name', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter event name' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v ?? 'Music'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: 'Image URL (Optional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 3,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter description' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter location' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(labelText: 'Price (\$)', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter price';
                              final p = double.tryParse(v);
                              if (p == null || p < 0) return 'Invalid price';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _totalSeatsController,
                            decoration: const InputDecoration(labelText: 'Total Seats', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter total seats';
                              final s = int.tryParse(v);
                              if (s == null || s <= 0) return 'Must be > 0';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      title: const Text('Event Date & Time'),
                      subtitle: Text(_selectedDateTime.toString().substring(0, 16)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickDateTime,
                      tileColor: Colors.blue.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveEvent,
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text(isEdit ? 'Save Changes' : 'Create Event', style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
