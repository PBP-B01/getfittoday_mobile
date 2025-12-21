import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../models/fitness_spot.dart';
import 'package:getfittoday_mobile/constants.dart';

class EventFormPage extends StatefulWidget {
  final String? eventId;
  const EventFormPage({super.key, this.eventId});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}


class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();


  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool isLoading = false;

  List<FitnessSpot> _locations = [];
  final Set<String> _selectedPlaceIds = {};

  bool _isLoadingLocations = true;
  String _locationSearchQuery = '';

  final ScrollController _locationsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchLocations();

      if (widget.eventId != null) {
        await _loadEventData();
      }
    });
  }


  @override
  void dispose() {
    _locationsScrollController.dispose();
    _nameController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }


  Future<void> _fetchLocations() async {
    final request = context.read<CookieRequest>();

    try {
      final response =
      await request.get('$djangoBaseUrl/api/fitness-spots/');


      final dynamic rawSpots =
      response is Map ? response['spots'] : response;

      if (rawSpots is! List) {
        throw Exception('Invalid fitness spots response format');
      }

      setState(() {
        _locations =
            rawSpots.map((e) => FitnessSpot.fromJson(e)).toList();
        _isLoadingLocations = false;
      });
    } catch (e) {
      _isLoadingLocations = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load locations: $e')),
        );
      }
    }
  }

  Future<void> _loadEventData() async {
    if (widget.eventId == null) return;

    setState(() {
      isLoading = true;
    });

    final request = context.read<CookieRequest>();

    final response = await request.get(
      '$djangoBaseUrl/blognevent/api/events/${widget.eventId}/',
    );

    // BASIC FIELDS
    _nameController.text = response['name'] ?? '';
    _descriptionController.text = response['description'] ?? '';
    _imageController.text = response['image'] ?? '';

    // DATES
    _startDate = DateTime.parse(response['starting_date']);
    _endDate = DateTime.parse(response['ending_date']);

    // LOCATIONS (IMPORTANT)
    final List locations = response['locations'] ?? [];

    _selectedPlaceIds
      ..clear()
      ..addAll(
        locations.map<String>((l) => l['place_id'].toString()),
      );

    setState(() {
      isLoading = false;
    });
  }


  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    if (_selectedPlaceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one location')),
      );
      return;
    }

    final request = context.read<CookieRequest>();

    if (!request.loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in')),
      );
      return;
    }

    try {
      final url = widget.eventId == null
          ? '$djangoBaseUrl/blognevent/api/event/create/'
          : '$djangoBaseUrl/blognevent/api/events/${widget.eventId}/edit/';

      final response = await request.post(
        url,
        {
          'name': _nameController.text,
          'image': _imageController.text,
          'description': _descriptionController.text,
          'starting_date': _startDate!.toIso8601String(),
          'ending_date': _endDate!.toIso8601String(),
          'locations': jsonEncode(_selectedPlaceIds.toList()),
        },
      );


      if (response['error'] != null) {
        throw Exception(response['error']);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: $e')),
        );
      }
    }
  }
  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year.toString().substring(2)} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredLocations = _locations
        .where((spot) =>
        spot.name.toLowerCase().contains(_locationSearchQuery))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventId == null ? 'Create Event' : 'Edit Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Event Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _imageController,
                decoration:
                const InputDecoration(labelText: 'Image URL (optional)'),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 20),
              const Text('Locations',
                  style: TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 8),

              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search locations...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) =>
                    setState(() => _locationSearchQuery = v.toLowerCase()),
              ),

              const SizedBox(height: 8),

              Container(
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoadingLocations
                    ? const Center(child: CircularProgressIndicator())
                    : Scrollbar(
                  controller: _locationsScrollController,
                  thumbVisibility: true,
                  interactive: true,
                  child: ListView.builder(
                    controller: _locationsScrollController,
                    itemCount: filteredLocations.length,
                    itemBuilder: (_, i) {
                      final spot = filteredLocations[i];
                      return CheckboxListTile(
                        dense: true,
                        value: _selectedPlaceIds.contains(spot.placeId),
                        title: Text(
                          spot.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          spot.address,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onChanged: (checked) {
                          setState(() {
                            checked == true
                                ? _selectedPlaceIds.add(spot.placeId)
                                : _selectedPlaceIds.remove(spot.placeId);
                          });
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ListTile(
                title: Text(
                  _startDate == null
                      ? 'Pick start date'
                      : 'Start: ${_formatDate(_startDate!.toLocal())}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(true),
              ),

              ListTile(
                title: Text(
                  _endDate == null
                      ? 'Pick end date'
                      : 'End: ${_formatDate(_endDate!.toLocal())}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(false),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit,
                child: Text(widget.eventId == null ? 'Create Event' : 'Update Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
