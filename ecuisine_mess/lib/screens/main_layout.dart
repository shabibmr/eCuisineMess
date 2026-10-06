import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecuisine_mess/navigation/app_destinations.dart';
import 'package:ecuisine_mess/providers/auth_provider.dart';
import 'package:ecuisine_mess/widgets/server_settings_dialog.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.restaurant_menu, color: Colors.amber, size: 24),
            SizedBox(width: 12),
            Text(
              'eCuisine Mess Billing & Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final name = auth.user?.displayName ?? '';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Server Connection Settings',
            onPressed: () => showServerSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            backgroundColor: const Color(0xFF0F172A),
            selectedIconTheme: const IconThemeData(color: Colors.amber),
            unselectedIconTheme: const IconThemeData(color: Colors.white70),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white70, fontSize: 12),
            destinations: [
              for (final dest in kAppDestinations)
                NavigationRailDestination(
                  icon: Icon(dest.icon),
                  label: Text(dest.label),
                ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: kAppDestinations[_selectedIndex].builder()),
        ],
      ),
    );
  }
}
