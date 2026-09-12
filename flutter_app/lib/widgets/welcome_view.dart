import 'package:flutter/material.dart';
import '../constants/jio_colors.dart';
import '../constants/categories.dart';
import 'telecom_icon.dart';

class WelcomeView extends StatelessWidget {
  final String activeCategory;
  final ValueChanged<String> onSelectPrompt;

  const WelcomeView({
    super.key,
    required this.activeCategory,
    required this.onSelectPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final promptList = Categories.prompts[activeCategory] ?? Categories.prompts['all']!;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Telecom Hero Emblem
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: JioColors.jioBlue,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: JioColors.jioBlue.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: const TelecomIcon(size: 30, strokeWidth: 2.2),
              ),
              const SizedBox(height: 14),

              // Tagline Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: JioColors.jioBlueLight,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: JioColors.jioBlue.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.radio_outlined, size: 13, color: JioColors.jioBlue),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Unofficial AI Assistance for Jio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: JioColors.jioBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Title
              const Text(
                'How can JioGenie help you?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: JioColors.jioNavy,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: const Text(
                  'Grounded in verified data from https://www.jio.com/ for Prepaid, True 5G, JioFiber, AirFiber, and eSIM with official citations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: JioColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Cards List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: promptList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final p = promptList[idx];
                  return _PromptCard(
                    prompt: p,
                    onTap: () => onSelectPrompt(p.prompt),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptCard extends StatefulWidget {
  final CategoryPrompt prompt;
  final VoidCallback onTap;

  const _PromptCard({required this.prompt, required this.onTap});

  @override
  State<_PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends State<_PromptCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: JioColors.bgSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isHovered ? JioColors.jioBlue : JioColors.borderSubtle,
                width: _isHovered ? 1.5 : 1,
              ),
              boxShadow: _isHovered ? JioColors.shadowMd : JioColors.shadowSm,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _isHovered ? JioColors.jioBlueLight : JioColors.bgTertiary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.prompt.icon,
                    size: 20,
                    color: _isHovered ? JioColors.jioBlue : JioColors.jioNavy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.prompt.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: JioColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.prompt.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: JioColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: _isHovered ? JioColors.jioBlue : JioColors.borderDefault,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
