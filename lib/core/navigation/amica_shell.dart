import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../constants/app_colors.dart';

import '../../features/emergency_contacts/screens/emergency_contacts_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/journey/screens/journeys_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

/// The app's persistent shell.
///
/// The old app had no bottom navigation: every feature was a push off the
/// home screen, and getting back always meant walking the stack. Worse,
/// Logout sat in the home app bar one tap from the SOS button.
///
/// Four tabs, always visible, state preserved between them:
/// **Home** (the SOS and the quick tools), **Journeys** (the active trip or
/// the form to start one), **Circle** (the people who get alerted) and
/// **You** (setup, discreet mode, and where Logout now lives).
class AmicaShell extends StatefulWidget {
  const AmicaShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AmicaShell> createState() => _AmicaShellState();
}

class _AmicaShellState extends State<AmicaShell> {
  late int _index = widget.initialIndex;

  /// [IndexedStack] rather than swapping children, so a half-filled journey
  /// form or a scrolled contact list survives a trip to another tab.
  static const List<Widget> _tabs = [
    HomeScreen(),
    JourneysScreen(),
    EmergencyContactsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final c = Theme.of(context).amica;
    const radius = BorderRadius.all(Radius.circular(30));

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      // A floating pill rather than an edge-to-edge bar, as in the
      // reference designs: it reads as part of the soft ground instead of
      // a hard slab across the bottom of every screen.
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: DecoratedBox(
            // Frosted glass pill: translucent over the pastel ground, with
            // a slightly denser fill than cards so the icons stay crisp.
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(c.glassHighlight, c.glassFill),
                  Color.lerp(c.glassFill, c.card, 0.35)!,
                ],
              ),
              borderRadius: radius,
              border: Border.all(color: c.glassBorder),
              boxShadow: c.shadow,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_rounded),
                    label: loc.navHome,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.route_outlined),
                    selectedIcon: const Icon(Icons.route_rounded),
                    label: loc.navJourneys,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.people_outline_rounded),
                    selectedIcon: const Icon(Icons.people_rounded),
                    label: loc.navCircle,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline_rounded),
                    selectedIcon: const Icon(Icons.person_rounded),
                    label: loc.navYou,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
