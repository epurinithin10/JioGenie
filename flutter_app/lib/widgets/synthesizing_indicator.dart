import 'package:flutter/material.dart';
import '../constants/jio_colors.dart';

class SynthesizingIndicator extends StatefulWidget {
  const SynthesizingIndicator({super.key});

  @override
  State<SynthesizingIndicator> createState() => _SynthesizingIndicatorState();
}

class _SynthesizingIndicatorState extends State<SynthesizingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JioColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JioColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 4 Animated Signal Bars
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final val = _controller.value;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(4, (i) {
                      final phase = (val + (i * 0.22)) % 1.0;
                      final h = 6.0 + 12.0 * (0.5 + 0.5 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2));
                      return Container(
                        margin: const EdgeInsets.only(right: 3),
                        width: 4,
                        height: h,
                        decoration: BoxDecoration(
                          color: JioColors.jioBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(width: 12),

              // Status Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '✦ JioGenie is synthesizing answer',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: JioColors.jioNavy,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Querying Jio.com verified knowledge context...',
                      style: TextStyle(
                        fontSize: 12,
                        color: JioColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Linear Indeterminate Shimmer Track
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: JioColors.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(JioColors.jioBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveStreamRibbon extends StatelessWidget {
  const LiveStreamRibbon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: JioColors.jioBlueLight,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: JioColors.jioBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: JioColors.jioGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'JioGenie Live Stream • Verified AI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: JioColors.jioNavy,
            ),
          ),
        ],
      ),
    );
  }
}
