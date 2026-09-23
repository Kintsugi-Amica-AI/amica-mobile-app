import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../widgets/glass_card.dart';
import '../widgets/motion.dart';

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

  /// Mirrors [_index] so a tab can react when it is actually shown — the
  /// tab stack builds every tab up front.
  late final ValueNotifier<int> _currentTab = ValueNotifier(_index);

  void _select(int i) {
    setState(() => _index = i);
    _currentTab.value = i;
  }

  @override
  void dispose() {
    _currentTab.dispose();
    super.dispose();
  }

  /// [AnimatedTabStack] rather than swapping children, so a half-filled journey
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
    const radius = BorderRadius.all(Radius.circular(30));

    return Scaffold(
      // The tabs run underneath the floating glass pill (and the system
      // navigation bar), so a map fills the whole screen instead of ending
      // in a strip of background under the pill. Scaffold adds the pill's
      // height to each tab's bottom padding, so content stays reachable.
      extendBody: true,
      body: AmicaShellScope(
        selectTab: _select,
        currentTab: _currentTab,
        // Tabs cross-fade with a gentle rise instead of cutting.
        child: AnimatedTabStack(index: _index, children: _tabs),
      ),
      // A floating pill rather than an edge-to-edge bar, as in the
      // reference designs: it reads as part of the soft ground instead of
      // a hard slab across the bottom of every screen.
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          // The same glass as the cards (e.g. "Your location"): a milky
          // white fill with a top-left sheen and a light-catching rim — plus
          // a live blur, since this pill floats over maps and scrolling
          // content rather than a flat panel.
          child: AmicaGlass(
            borderRadius: radius,
            blur: 20,
            opacity: Theme.of(context).brightness == Brightness.dark
                ? 0.8
                : 0.72,
            child: NavigationBar(
                backgroundColor: Colors.transparent,
                // The selection pill slides and stretches between tabs.
                animationDuration: const Duration(milliseconds: 420),
                selectedIndex: _index,
                onDestinationSelected: _select,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const _PopIcon(Icons.home_rounded),
                    label: loc.navHome,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.route_outlined),
                    selectedIcon: const _PopIcon(Icons.route_rounded),
                    label: loc.navJourneys,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.people_outline_rounded),
                    selectedIcon: const _PopIcon(Icons.people_rounded),
                    label: loc.navCircle,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline_rounded),
                    selectedIcon: const _PopIcon(Icons.person_rounded),
                    label: loc.navYou,
                  ),
                ],
              ),
          ),
        ),
      ),
    );
  }
}

/// Lets a tab jump to another tab — e.g. Home's "Walk with me" tile opens
/// the Journeys tab itself instead of pushing a second copy of the same
/// screen on top of Home.
class AmicaShellScope extends InheritedWidget {
  const AmicaShellScope({
    required this.selectTab,
    required this.currentTab,
    required super.child,
    super.key,
  });

  static const int homeTab = 0;
  static const int journeysTab = 1;
  static const int circleTab = 2;
  static const int youTab = 3;

  final void Function(int index) selectTab;

  /// The tab on screen right now.
  final ValueListenable<int> currentTab;

  static AmicaShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AmicaShellScope>();

  @override
  bool updateShouldNotify(AmicaShellScope oldWidget) => false;
}

/// The selected tab's icon arrives with a small springy pop.
class _PopIcon extends StatelessWidget {
  const _PopIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (AmicaMotion.reduced(context)) return Icon(icon);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1),
      duration: AmicaMotion.slow,
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Icon(icon),
    );
  }
}
