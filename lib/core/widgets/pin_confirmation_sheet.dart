import 'package:flutter/material.dart';

class PinConfirmationSheet extends StatelessWidget {
  const PinConfirmationSheet({
    required this.title,
    required this.subtitle,
    required this.pinLength,
    required this.submitting,
    required this.onDigit,
    required this.onBackspace,
    this.message,
    super.key,
  });

  final String title;
  final String subtitle;
  final int pinLength;
  final bool submitting;
  final String? message;
  final Future<bool> Function(String digit) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Yopish',
                        onPressed: submitting
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: scheme.primary,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 22,
                      child: submitting
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                4,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeOutCubic,
                                  width: index < pinLength ? 17 : 13,
                                  height: index < pinLength ? 17 : 13,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index < pinLength
                                        ? scheme.primary
                                        : scheme.surfaceContainerHighest,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    SizedBox(
                      height: 54,
                      child: message == null
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(
                                message!,
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
                            return _PinKey(
                              onTap: submitting ? null : onBackspace,
                              child: const Icon(Icons.backspace_outlined),
                            );
                          }
                          final digit = index == 10 ? '0' : '${index + 1}';
                          return _PinKey(
                            onTap: submitting
                                ? null
                                : () async {
                                    final success = await onDigit(digit);
                                    if (success && context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                            child: Text(
                              digit,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Center(child: child),
    ),
  );
}
