import 'package:shared_preferences/shared_preferences.dart';

class FavouritesService {
  static const String _key = 'favourite_events';

  Future<void> toggleFavourite(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favourites = prefs.getStringList(_key) ?? [];
    if (favourites.contains(eventId)) {
      favourites.remove(eventId);
    } else {
      favourites.add(eventId);
    }
    await prefs.setStringList(_key, favourites);
  }

  Future<bool> isFavourite(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favourites = prefs.getStringList(_key) ?? [];
    return favourites.contains(eventId);
  }

  Future<List<String>> getFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }
}
