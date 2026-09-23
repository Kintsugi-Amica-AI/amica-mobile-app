import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/emergency_action_service.dart';
import '../../auth/services/user_profile_service.dart';
import '../services/fake_call_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'fake_call_active_screen.dart';

class FakeCallArguments {
  const FakeCallArguments({this.immediate = false});

  /// Whether to ring straight away instead of offering the scheduler.
  ///
  /// True when the call was already triggered — the volume-up shortcut, or a
  /// schedule that just came due — and false when the user opened Fake Call
  /// from the home dashboard to arm one.
  final bool immediate;
}

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({
    super.key,
    this.arguments,
    this.userProfileService = const UserProfileService(),
    this.fakeCallService = const FakeCallService(),
    this.emergencyActionService = const EmergencyActionService(),
  });

  final FakeCallArguments? arguments;
  final UserProfileService userProfileService;
  final FakeCallService fakeCallService;
  final EmergencyActionService emergencyActionService;

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  Timer? _countdownTimer;
  Map<String, dynamic> _settings = const <String, dynamic>{};
  Duration _selectedDelay = FakeCallService.scheduleDelayOptions[1];
  Duration _scheduledRemaining = Duration.zero;
  bool _isLoading = true;
  bool _isBusy = false;

  bool get _isImmediate => widget.arguments?.immediate ?? false;

  bool get _hasSchedule => _scheduledRemaining > Duration.zero;

  String get _callerName =>
      _settings['fakeCallContactName'] as String? ??
      widget.fakeCallService.getDefaultCallerName();

  String get _callerNumber =>
      _settings['fakeCallPhoneNumber'] as String? ??
      widget.fakeCallService.getDefaultCallerNumber();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    Map<String, dynamic> settings = const <String, dynamic>{};
    try {
      settings = await widget.userProfileService.getSafetySettings();
    } catch (_) {
      // Fall back to the built-in caller identity so Fake Call still works
      // offline or before a profile document exists.
    }

    final remaining = _isImmediate
        ? Duration.zero
        : await _readScheduledRemaining();

    if (!mounted) {
      return;
    }

    setState(() {
      _settings = settings;
      _scheduledRemaining = remaining;
      _isLoading = false;
    });

    if (remaining > Duration.zero) {
      _startCountdown();
    }
  }

  Future<Duration> _readScheduledRemaining() async {
    try {
      return await widget.emergencyActionService.scheduledFakeCallRemaining();
    } catch (_) {
      return Duration.zero;
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final next = _scheduledRemaining - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        timer.cancel();
        // The native scheduler opens the call screen itself; this only clears
        // the arming UI so it does not show a stale countdown.
        setState(() => _scheduledRemaining = Duration.zero);
        return;
      }

      setState(() => _scheduledRemaining = next);
    });
  }

  void _ringNow() {
    final session = widget.fakeCallService.buildFakeCallSession(
      callerName: _callerName,
      callerNumber: _callerNumber,
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

  Future<void> _scheduleCall() async {
    setState(() => _isBusy = true);
    try {
      await widget.emergencyActionService.scheduleFakeCall(
        delay: _selectedDelay,
        callerName: _callerName,
      );

      if (!mounted) {
        return;
      }
      setState(() => _scheduledRemaining = _selectedDelay);
      _startCountdown();
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.fakeCallScheduledSnackbar(
              _callerName,
              widget.fakeCallService.formatScheduleDelay(_selectedDelay),
            ),
          ),
        ),
      );
    } on EmergencyActionException catch (error) {
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context).fakeCallCouldNotSchedule);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _cancelSchedule() async {
    setState(() => _isBusy = true);
    try {
      await widget.emergencyActionService.cancelScheduledFakeCall();
      _countdownTimer?.cancel();

      if (!mounted) {
        return;
      }
      setState(() => _scheduledRemaining = Duration.zero);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).fakeCallScheduleCancelled),
        ),
      );
    } on EmergencyActionException catch (error) {
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context).fakeCallCouldNotCancel);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: LoadingView(
          message: AppLocalizations.of(context).fakeCallPreparingCall,
        ),
      );
    }

    return _isImmediate ? _buildIncomingCall(context) : _buildScheduler(context);
  }

  // ---------------------------------------------------------------------
  // Arming a deterrent call
  // ---------------------------------------------------------------------

  Widget _buildScheduler(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(loc.fakeCallAppBarTitle)),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                loc.fakeCallHeroTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(loc.fakeCallHeroSubtitle),
              const SizedBox(height: 22),
              _buildCallerCard(context),
              const SizedBox(height: 20),
              if (_hasSchedule)
                _buildArmedCard(context)
              else
                _buildDelayPicker(context),
              const SizedBox(height: 24),
              if (_hasSchedule) ...[
                PrimaryButton(
                  label: loc.fakeCallRingNowInstead,
                  icon: Icons.phone_in_talk_rounded,
                  onPressed: _isBusy ? null : _ringNow,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : _cancelSchedule,
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(loc.fakeCallCancelScheduled),
                ),
              ] else ...[
                PrimaryButton(
                  label: _isBusy
                      ? loc.fakeCallScheduling
                      : loc.fakeCallScheduleIn(
                          widget.fakeCallService
                              .formatScheduleDelay(_selectedDelay),
                        ),
                  icon: Icons.schedule_rounded,
                  onPressed: _isBusy ? null : _scheduleCall,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : _ringNow,
                  icon: const Icon(Icons.phone_in_talk_outlined),
                  label: Text(loc.fakeCallRingNow),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                loc.fakeCallDisclaimer,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallerCard(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Theme.of(context).amica.shell,
            child: Text(
              _callerName.isEmpty ? 'A' : _callerName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _callerName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  _callerNumber,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).fakeCallEditCallerTooltip,
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.settings);
              await _load();
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildDelayPicker(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).fakeCallMeIn,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: FakeCallService.scheduleDelayOptions.map((delay) {
              final isSelected = delay == _selectedDelay;
              return ChoiceChip(
                selected: isSelected,
                label: Text(
                  widget.fakeCallService.formatScheduleDelay(delay),
                ),
                onSelected: _isBusy
                    ? null
                    : (_) => setState(() => _selectedDelay = delay),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildArmedCard(BuildContext context) {
    return GlassCard(
      borderColor: Theme.of(context).amica.gold,
      child: Column(
        children: [
          Icon(
            Icons.phone_forwarded_rounded,
            color: Theme.of(context).amica.gold,
            size: 26,
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context).fakeCallCallingIn,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.4,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            DateTimeUtils.formatDuration(_scheduledRemaining),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 44,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).fakeCallKeepNotificationVisible,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Incoming call
  // ---------------------------------------------------------------------

  Widget _buildIncomingCall(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).fakeCallIncoming,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const Spacer(),
              CircleAvatar(
                radius: 52,
                backgroundColor: Colors.white12,
                child: Text(
                  _callerName.isEmpty ? 'A' : _callerName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _callerName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _callerNumber,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).fakeCallMobile,
                style: const TextStyle(color: Colors.white54),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallActionButton(
                    label: AppLocalizations.of(context).fakeCallDecline,
                    icon: Icons.call_end,
                    color: Colors.red,
                    onPressed: () => Navigator.pop(context),
                  ),
                  _CallActionButton(
                    label: AppLocalizations.of(context).fakeCallAccept,
                    icon: Icons.call,
                    color: Colors.green,
                    onPressed: _ringNow,
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
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
