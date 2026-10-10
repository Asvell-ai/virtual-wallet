import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/theme/app_theme.dart';
import 'package:hamyon/core/widgets/fade_slide_in.dart';
import 'package:hamyon/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hamyon/features/auth/presentation/cubit/auth_state.dart';
import 'package:hamyon/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:hamyon/features/settings/presentation/cubit/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocListener<AuthCubit, AuthState>(
    listenWhen: (previous, current) =>
        previous.message != current.message && current.message != null,
    listener: (context, state) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.message!)));
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A1D45), Color(0xFF173B57)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: AppTheme.mint,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hamyon himoyalangan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AES-256-GCM • PIN • HMAC',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.66),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.verified_rounded, color: AppTheme.mint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: SwitchListTile(
                value: state.themeMode == ThemeMode.dark,
                onChanged: context.read<SettingsCubit>().darkModeChanged,
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark mode'),
                subtitle: const Text('Qorong‘i mavzuni yoqish'),
              ),
            ),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, auth) => Card(
                child: SwitchListTile(
                  value: auth.biometricEnabled,
                  onChanged: !auth.biometricAvailable
                      ? null
                      : (enabled) async {
                          if (!enabled) {
                            await context
                                .read<AuthCubit>()
                                .biometricSettingChanged(enabled: false);
                            return;
                          }
                          final pin = await _askForPin(context);
                          if (pin != null && context.mounted) {
                            await context
                                .read<AuthCubit>()
                                .biometricSettingChanged(
                                  enabled: true,
                                  pin: pin,
                                );
                          }
                        },
                  secondary: const Icon(Icons.fingerprint_rounded),
                  title: const Text('Barmoq izi / Face ID'),
                  subtitle: Text(
                    auth.biometricAvailable
                        ? 'Hamyonni biometrik tasdiq bilan ochish'
                        : 'Qurilmada biometrik himoya mavjud emas',
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                onTap: context.read<AuthCubit>().lock,
                leading: const Icon(Icons.lock_rounded),
                title: const Text('Ilovani qulflash'),
                subtitle: const Text('Qayta kirishda PIN so‘raladi'),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Hamyon — lokal demo ilova. Undagi kartalar va pullar haqiqiy emas.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<String?> _askForPin(BuildContext context) async {
    final controller = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('PIN-kodni tasdiqlang'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: '4 xonali PIN',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Davom etish'),
          ),
        ],
      ),
    );
    controller.dispose();
    return pin;
  }
}
