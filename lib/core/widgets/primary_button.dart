import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 58,
        child: FilledButton.icon(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon ?? Icons.arrow_forward_rounded),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
}
