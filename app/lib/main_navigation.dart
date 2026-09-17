import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'favourites_screen.dart';
import 'my_bookings_screen.dart';
import 'organizer_dashboard_screen.dart';
import 'services/organizer_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final OrganizerService _organizerService = OrganizerService();

  final List<Widget> _baseScreens = [
    const HomeScreen(),
    const FavouritesScreen(),
    const MyBookingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: _organizerService.getUserRole(),
      builder: (context, roleSnapshot) {
        final role = roleSnapshot.data ?? 'user';
        final isOrganizer = role == 'organizer';

        // Dynamic screens list based on authorization role
        final screens = List<Widget>.from(_baseScreens);
        if (isOrganizer) {
          screens.add(const OrganizerDashboardScreen());
        }

        // Adjust index if an organic fallback scenario happens
        if (_selectedIndex >= screens.length) {
          _selectedIndex = 0;
        }

        return Scaffold(
          body: screens[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.favorite_outline),
                selectedIcon: Icon(Icons.favorite),
                label: 'Favourites',
              ),
              const NavigationDestination(
                icon: Icon(Icons.confirmation_number_outlined),
                selectedIcon: Icon(Icons.confirmation_number),
                label: 'Bookings',
              ),
              if (isOrganizer)
                const NavigationDestination(
                  icon: Icon(Icons.dashboard_customize_outlined),
                  selectedIcon: Icon(Icons.dashboard_customize),
                  label: 'Manage',
                ),
            ],
          ),
        );
      },
    );
  }
}
