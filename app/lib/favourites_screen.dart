import 'package:flutter/material.dart';
import 'services/event_service.dart';
import 'services/favourites_service.dart';
import 'models/event.dart';
import 'widgets/event_card.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  final EventService _eventService = EventService();
  final FavouritesService _favouritesService = FavouritesService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Favourites')),
      body: FutureBuilder<List<String>>(
        future: _favouritesService.getFavourites(),
        builder: (context, favSnapshot) {
          if (favSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final favIds = favSnapshot.data ?? [];
          if (favIds.isEmpty) {
            return const Center(child: Text('No favourites yet'));
          }

          return StreamBuilder<List<Event>>(
            stream: _eventService.getEvents(),
            builder: (context, eventSnapshot) {
              if (eventSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final allEvents = eventSnapshot.data ?? [];
              final favEvents = allEvents.where((e) => favIds.contains(e.id)).toList();

              if (favEvents.isEmpty) {
                return const Center(child: Text('No favourites found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: favEvents.length,
                itemBuilder: (context, index) {
                  return EventCard(event: favEvents[index]);
                },
              );
            },
          );
        },
      ),
    );
  }
}
