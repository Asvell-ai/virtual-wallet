import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hamyon/core/utils/formatters.dart';
import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';

class WalletCardTile extends StatelessWidget {
  const WalletCardTile({
    required this.card,
    this.onTap,
    this.revealSensitive = false,
    super.key,
  });

  final WalletCard card;
  final VoidCallback? onTap;
  final bool revealSensitive;

  @override
  Widget build(BuildContext context) {
    final base = Color(card.colorValue);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: AspectRatio(
        aspectRatio: 1.58,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  base,
                  Color.lerp(base, const Color(0xFF2E6CB7), 0.65)!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: base.withValues(alpha: 0.24),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(26),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  children: [
                    Positioned(
                      top: -70,
                      right: 52,
                      child: Transform.rotate(
                        angle: -0.34,
                        child: Container(
                          width: 80,
                          height: 260,
                          color: Colors.white.withValues(alpha: 0.045),
                        ),
                      ),
                    ),
                    ...List.generate(
                      3,
                      (index) => Positioned(
                        top: -28.0 + (index.isOdd ? 18 : 0),
                        right: -12.0 + index * 34,
                        child: Container(
                          width: 22,
                          height: 132 + index * 18,
                          decoration: BoxDecoration(
                            color: index.isEven
                                ? const Color(
                                    0xFF25C7C9,
                                  ).withValues(alpha: 0.64)
                                : const Color(
                                    0xFF5794E8,
                                  ).withValues(alpha: 0.55),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(11),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFE7A0),
                                      Color(0xFFC89D3C),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.sim_card_rounded,
                                  color: Color(0xFF87671E),
                                  size: 23,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Transform.rotate(
                                angle: math.pi / 2,
                                child: const Icon(
                                  Icons.wifi_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(width: 10),
                              ColorFiltered(
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                                child: Image.asset(
                                  'assets/images/uzcard_logo.png',
                                  width: 42,
                                  height: 56,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppFormatters.money(card.balance),
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            revealSensitive
                                ? AppFormatters.cardNumber(card.number)
                                : AppFormatters.maskedCard(card.number),
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              letterSpacing: 2.1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _CardCaption(
                                  label: 'CARDHOLDER NAME',
                                  value: card.name.toUpperCase(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              _CardCaption(
                                label: 'VALID THRU',
                                value: revealSensitive
                                    ? card.expiryLabel
                                    : '** / **',
                              ),
                            ],
                          ),
                        ],
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

class _CardCaption extends StatelessWidget {
  const _CardCaption({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.62),
          fontSize: 8,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
