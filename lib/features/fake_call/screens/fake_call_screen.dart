import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/services/user_profile_service.dart';
import '../services/fake_call_service.dart';
import 'fake_call_active_screen.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({
    super.key,
    this.userProfileService = const UserProfileService(),
    this.fakeCallService = const FakeCallService(),
  });

  final UserProfileService userProfileService;
  final FakeCallService fakeCallService;

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  late Future<Map<String, dynamic>> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = widget.userProfileService.getSafetySettings();
  }

  void _acceptCall(Map<String, dynamic> settings) {
    final session = widget.fakeCallService.buildFakeCallSession(
      callerName: settings['fakeCallContactName'] as String?,
      callerNumber: settings['fakeCallPhoneNumber'] as String?,
      status: 'active',
    );

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.fakeCallActive,
      arguments: FakeCallActiveArguments(
        callerName: session.callerName,
        callerNumber: session.callerNumber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _settingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadingView(message: 'Preparing fake call'),
          );
        }

        final settings = snapshot.data ?? const <String, dynamic>{};
        final callerName = settings['fakeCallContactName'] as String? ??
            widget.fakeCallService.getDefaultCallerName();
        final callerNumber = settings['fakeCallPhoneNumber'] as String? ??
            widget.fakeCallService.getDefaultCallerNumber();

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'Fake Call',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white12,
                    child: Text(
                      callerName.isEmpty ? 'A' : callerName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    callerName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    callerNumber,
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Incoming call',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallActionButton(
                        label: 'Decline',
                        icon: Icons.call_end,
                        color: Colors.red,
                        onPressed: () => Navigator.pop(context),
                      ),
                      _CallActionButton(
                        label: 'Accept',
                        icon: Icons.call,
                        color: Colors.green,
                        onPressed: () => _acceptCall(settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: label,
          backgroundColor: color,
          onPressed: onPressed,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
