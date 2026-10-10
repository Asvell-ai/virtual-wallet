import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/theme/app_theme.dart';
import 'package:hamyon/core/widgets/fade_slide_in.dart';
import 'package:hamyon/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hamyon/features/auth/presentation/cubit/auth_state.dart';

class PinPage extends StatelessWidget {
  const PinPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: -150,
              right: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.08),
                ),
              ),
            ),
            SafeArea(
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final setup = state.status == AuthStatus.setupRequired;
                  final blocked = state.status == AuthStatus.blocked;
                  final scheme = Theme.of(context).colorScheme;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 20),
                    child: Column(
                      children: [
                        FadeSlideIn(
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppTheme.primary, AppTheme.navy],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.25),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          setup
                              ? state.isConfirmingSetup
                                  ? 'PIN-kodni tasdiqlang'
                                  : 'Xavfsiz PIN yarating'
                              : blocked
                                  ? 'Vaqtincha bloklandi'
                                  : 'Xush kelibsiz',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.6,
                                  ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          blocked
                              ? '${state.remainingSeconds} soniyadan keyin qayta urinishingiz mumkin'
                              : setup
                                  ? '4 xonali PIN-kod hamyoningizni himoya qiladi'
                                  : 'Hamyonni ochish uchun PIN-kodni kiriting',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            4,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutBack,
                              width: index < state.pinInput.length ? 17 : 13,
                              height: index < state.pinInput.length ? 17 : 13,
                              margin: const EdgeInsets.symmetric(horizontal: 9),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index < state.pinInput.length
                                    ? scheme.primary
                                    : scheme.surfaceContainerHighest,
                                boxShadow: index < state.pinInput.length
                                    ? [
                                        BoxShadow(
                                          color: scheme.primary.withOpacity(0.25),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: state.message == null
                              ? const SizedBox(height: 38)
                              : Padding(
                                  key: ValueKey(state.message),
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Text(
                                    state.message!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: scheme.error),
                                  ),
                                ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 276,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.45,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 14,
                            ),
                            itemCount: 12,
                            itemBuilder: (context, index) {
                              if (index == 9) return const SizedBox.shrink();
                              if (index == 11) {
                                return Material(
                                  color: scheme.surface,
                                  borderRadius: BorderRadius.circular(22),
                                  child: InkWell(
                                    onTap: blocked
                                        ? null
                                        : context.read<AuthCubit>().removeDigit,
                                    borderRadius: BorderRadius.circular(22),
                                    child: const Icon(Icons.backspace_outlined),
                                  ),
                                );
                              }
                              final digit = index == 10 ? '0' : '${index + 1}';
                              return Material(
                                color: scheme.surface,
                                borderRadius: BorderRadius.circular(22),
                                child: InkWell(
                                  onTap: blocked
                                      ? null
                                      : () => context
                                          .read<AuthCubit>()
                                          .addDigit(digit),
                                  borderRadius: BorderRadius.circular(22),
                                  child: Center(
                                    child: Text(
                                      digit,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed:
                                state.status == AuthStatus.loading || blocked
                                    ? null
                                    : context.read<AuthCubit>().submit,
                            child: state.status == AuthStatus.loading
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.lock_open_rounded,
                                          size: 20),
                                      const SizedBox(width: 9),
                                      Text(setup ? 'PINni saqlash' : 'Kirish'),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
}
