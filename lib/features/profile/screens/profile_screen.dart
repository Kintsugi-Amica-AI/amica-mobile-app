import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/models/app_user.dart';
import '../../auth/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.authService = const AuthService(),
  });

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Profile')),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(
          child: FutureBuilder<AppUser?>(
            future: authService.currentUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView(message: 'Loading profile');
              }

              final user = snapshot.data;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.auraGradient,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initial(user),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      user?.name ?? 'Amica User',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Center(
                    child: Text(
                      user?.email ?? 'Not signed in',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Column(
                      children: [
                        _ProfileRow(
                          icon: Icons.call_outlined,
                          label: 'Phone',
                          value: (user?.phone.isNotEmpty ?? false)
                              ? user!.phone
                              : 'Not set',
                        ),
                        const Divider(height: 24),
                        _ProfileRow(
                          icon: Icons.shield_outlined,
                          label: 'Account status',
                          value: (user?.status ?? 'active').toUpperCase(),
                        ),
                        const Divider(height: 24),
                        _ProfileRow(
                          icon: Icons.record_voice_over_outlined,
                          label: 'Stealth secret phrase',
                          value: (user?.secretPhrase?.isNotEmpty ?? false)
                              ? user!.secretPhrase!
                              : 'Not set',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(Icons.settings_outlined,
                          color: AppColors.secondary),
                      title: const Text('Safety Settings'),
                      subtitle: const Text(
                        'Fake call, stealth voice SOS, and secret phrase.',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.settings),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _initial(AppUser? user) {
    final name = user?.name.trim() ?? '';
    return name.isEmpty ? 'A' : name[0].toUpperCase();
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
