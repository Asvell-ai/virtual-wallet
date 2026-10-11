import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/widgets/pin_confirmation_sheet.dart';
import 'package:hamyon/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hamyon/features/auth/presentation/cubit/auth_state.dart';
import 'package:hamyon/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:hamyon/features/settings/presentation/cubit/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sozlamalar')),
    body: BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
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
          const SizedBox(height: 10),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, auth) => Card(
              child: ListTile(
                leading: const Icon(Icons.fingerprint_rounded),
                title: const Text('Barmoq izi / Face ID'),
                subtitle: Text(
                  auth.biometricAvailable
                      ? 'Hamyonni biometrik tasdiq bilan ochish'
                      : 'Qurilmada biometrik himoya mavjud emas',
                ),
                trailing: auth.isBiometricSettingInProgress
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Switch(
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
                                await _showBiometricPinConfirmation(context);
                              },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
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
        ],
      ),
    ),
  );

  Future<void> _showBiometricPinConfirmation(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    var pin = '';
    String? message;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      isDismissible: false,
      showDragHandle: false,
      builder: (_) => BlocProvider.value(
        value: authCubit,
        child: StatefulBuilder(
          builder: (context, setSheetState) => BlocBuilder<AuthCubit, AuthState>(
            builder: (context, auth) => FractionallySizedBox(
              heightFactor: 1,
              child: PinConfirmationSheet(
                title: 'PIN-kodni tasdiqlang',
                subtitle:
                    'Biometrik kirishni yoqish uchun 4 xonali PIN-kodingizni kiriting',
                pinLength: pin.length,
                submitting: auth.isBiometricSettingInProgress,
                message: message,
                onDigit: (digit) async {
                  if (pin.length >= 4 || auth.isBiometricSettingInProgress) {
                    return false;
                  }
                  setSheetState(() {
                    pin = '$pin$digit';
                    message = null;
                  });
                  if (pin.length < 4) return false;
                  final enabled = await authCubit.biometricSettingChanged(
                    enabled: true,
                    pin: pin,
                  );
                  if (!enabled && context.mounted) {
                    setSheetState(() {
                      pin = '';
                      message = authCubit.state.message;
                    });
                  }
                  return enabled;
                },
                onBackspace: () {
                  if (pin.isEmpty) return;
                  setSheetState(() {
                    pin = pin.substring(0, pin.length - 1);
                    message = null;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
