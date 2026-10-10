import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hamyon/core/utils/formatters.dart';
import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';

class WalletCardTile extends StatelessWidget {
  const WalletCardTile({required this.card, super.key});

  final WalletCard card;

  @override
  Widget build(BuildContext context) {
    final base = Color(card.colorValue);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: AspectRatio(
        aspectRatio: 1.58,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [base, Color.lerp(base, const Color(0xFF246BFE), 0.55)!],
            ),
            boxShadow: [
              BoxShadow(
                color: base.withOpacity(0.26),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -54,
                top: -72,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                ),
              ),
              Positioned(
                right: -78,
                bottom: -112,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.055),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
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
                              colors: [Color(0xFFFFE7A0), Color(0xFFC89D3C)],
                            ),
                          ),
                          child: Transform.rotate(
                            angle: math.pi / 2,
                            child: const Icon(
                              Icons.wifi_rounded,
                              color: Color(0xFF6F551C),
                              size: 20,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          card.type.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      AppFormatters.maskedCard(card.number),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 1.9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 17),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.70),
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppFormatters.money(card.balance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.contactless_rounded,
                          color: Colors.white70,
                          size: 30,
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
    );
  }
}
