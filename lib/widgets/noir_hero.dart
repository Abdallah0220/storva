import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'store_widgets.dart';

/// Dark cinematic hero, the noir counterpoint to the light lookbook skin:
/// near-black panel, neon rim-light glow, oversized thin type and one
/// dramatic product photo.
class NoirHero extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onCta;

  const NoirHero({
    super.key,
    required this.imageUrl,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: AppTheme.noirBg,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 760;
            final content = _HeroCopy(onCta: onCta);
            final visual = _HeroVisual(imageUrl: imageUrl);
            return Stack(
              children: [
                // Warm and cool neon glows bleeding from the edges.
                Positioned(
                  left: -80,
                  top: -60,
                  child: _Glow(color: AppTheme.noirGlowWarm, size: 260),
                ),
                Positioned(
                  right: -60,
                  bottom: -80,
                  child: _Glow(color: AppTheme.noirGlowCool, size: 300),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 48 : 24,
                    vertical: wide ? 56 : 32,
                  ),
                  child: wide
                      ? Row(
                          children: [
                            Expanded(flex: 5, child: content),
                            const SizedBox(width: 32),
                            Expanded(flex: 4, child: visual),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            content,
                            const SizedBox(height: 28),
                            visual,
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.45),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final VoidCallback onCta;

  const _HeroCopy({required this.onCta});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE NOIR EDIT',
          style: AppTheme.eyebrow.copyWith(color: Colors.white54),
        ),
        const SizedBox(height: 14),
        const Text(
          'After dark,\nwe dress louder.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.5,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'A cinematic capsule of this season\'s sharpest pieces, '
          'shot in neon and shadow.',
          style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 26),
        ElevatedButton(
          onPressed: onCta,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.noirBg,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          ),
          child: const Text(
            'SHOP THE DROP',
            style: TextStyle(letterSpacing: 1.6, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _HeroVisual extends StatelessWidget {
  final String imageUrl;

  const _HeroVisual({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.noirGlowWarm.withValues(alpha: 0.35),
            blurRadius: 60,
            spreadRadius: -10,
            offset: const Offset(-14, 10),
          ),
          BoxShadow(
            color: AppTheme.noirGlowCool.withValues(alpha: 0.35),
            blurRadius: 60,
            spreadRadius: -10,
            offset: const Offset(14, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ProductImage(imageUrl: imageUrl),
      ),
    );
  }
}
