import 'package:flutter/material.dart';
import '../constants/jio_colors.dart';
import 'telecom_icon.dart';

class JioNavbar extends StatelessWidget {
  final VoidCallback onToggleSidebar;
  final VoidCallback onNewInquiry;
  final VoidCallback onExport;
  final bool isMobile;

  const JioNavbar({
    super.key,
    required this.onToggleSidebar,
    required this.onNewInquiry,
    required this.onExport,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: JioColors.bgSecondary,
        border: Border(
          bottom: BorderSide(color: JioColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Sidebar Drawer Toggle Button
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: JioColors.jioNavy, size: 24),
            tooltip: 'Conversations & Menu',
            splashRadius: 22,
            onPressed: onToggleSidebar,
          ),
          const SizedBox(width: 4),

          // Brand Logo & Title
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: JioColors.jioBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const TelecomIcon(size: 15, strokeWidth: 2.2),
                ),
                const SizedBox(width: 8),
                const Text(
                  'JioGenie',
                  style: TextStyle(
                    color: JioColors.jioNavy,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.4,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  const Text(
                    '•',
                    style: TextStyle(color: JioColors.textMuted, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'AI Telecom Assistant',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: JioColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Right Actions
          // New Inquiry Action
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: JioColors.jioBlue, size: 26),
              tooltip: 'New Inquiry',
              splashRadius: 22,
              onPressed: onNewInquiry,
            )
          else
            ElevatedButton.icon(
              onPressed: onNewInquiry,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('New Inquiry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: JioColors.jioBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),

          const SizedBox(width: 4),

          // Export Button
          IconButton(
            icon: const Icon(Icons.download_outlined, color: JioColors.textSecondary, size: 20),
            tooltip: 'Export Markdown',
            splashRadius: 20,
            onPressed: onExport,
          ),
        ],
      ),
    );
  }
}
