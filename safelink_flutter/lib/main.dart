import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/debug_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SafeLinkApp());
}

class SafeLinkApp extends StatelessWidget {
  const SafeLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF534AB7),
          primary: const Color(0xFF534AB7),
        ),
        fontFamily: null, // use system default
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontWeight: FontWeight.w400),
          bodyLarge: TextStyle(fontWeight: FontWeight.w400),
          titleMedium: TextStyle(fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      home: const _RootNavigator(),
    );
  }
}

class _RootNavigator extends StatefulWidget {
  const _RootNavigator();

  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    MapScreen(),
    ContactsScreen(),
    SettingsScreen(),
    DebugScreen(),
  ];

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map_rounded),
      label: 'Map',
    ),
    NavigationDestination(
      icon: Icon(Icons.contacts_outlined),
      selectedIcon: Icon(Icons.contacts_rounded),
      label: 'Contacts',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Settings',
    ),
    NavigationDestination(
      icon: Icon(Icons.bug_report_outlined),
      selectedIcon: Icon(Icons.bug_report_rounded),
      label: 'Debug',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        indicatorColor: const Color(0xFF534AB7).withAlpha(40),
        destinations: _destinations,
      ),
    );
  }
}
