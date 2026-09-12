import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import '../constants/jio_colors.dart';
import '../models/chat_message.dart';
import 'telecom_icon.dart';
import 'synthesizing_indicator.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreamingThis;
  final VoidCallback? onRetry;
  final ValueChanged<String>? onShowToast;

  const MessageBubble({
    super.key,
    required this.message,
    this.isStreamingThis = false,
    this.onRetry,
    this.onShowToast,
  });

  Future<void> _openUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserBubble(context);
    } else {
      return _buildAssistantBubble(context);
    }
  }

  Widget _buildUserBubble(BuildContext context) {
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.84;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: JioColors.jioBlue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: JioColors.jioBlue.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context) {
    final showSynthesizing = isStreamingThis && message.content.isEmpty;
    final containsTable = message.content.contains('|');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: JioColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: JioColors.borderSubtle),
          boxShadow: JioColors.shadowSm,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header (Avatar + Name + Status + Time)
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: JioColors.jioBlue,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: JioColors.jioBlue.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const TelecomIcon(size: 14, strokeWidth: 2.2),
                ),
                const SizedBox(width: 8),
                const Text(
                  'JioGenie',
                  style: TextStyle(
                    color: JioColors.jioNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: JioColors.jioGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Verified AI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00875A),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: JioColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: JioColors.borderSubtle),
            const SizedBox(height: 12),

            // Content
            if (showSynthesizing)
              const SynthesizingIndicator()
            else ...[
              // Optional table scroll hint if table is detected
              if (containsTable)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 14, color: JioColors.jioBlue),
                      const SizedBox(width: 4),
                      Text(
                        'Swipe horizontally to view full table',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: JioColors.jioBlue,
                        ),
                      ),
                    ],
                  ),
                ),

              // Full Markdown Body with Horizontal Scrollable Tables
              MarkdownBody(
                data: message.content + (isStreamingThis ? ' ▍' : ''),
                extensionSet: md.ExtensionSet.gitHubFlavored,
                selectable: true,
                onTapLink: (text, href, title) {
                  if (href != null) _openUrl(href);
                },
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: JioColors.textPrimary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                  h1: const TextStyle(
                    color: JioColors.jioNavy,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                  h2: const TextStyle(
                    color: JioColors.jioNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  h3: const TextStyle(
                    color: JioColors.jioNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                  strong: const TextStyle(
                    color: JioColors.jioDeepNavy,
                    fontWeight: FontWeight.w700,
                  ),
                  listBullet: const TextStyle(
                    color: JioColors.jioBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  code: const TextStyle(
                    color: JioColors.jioNavy,
                    backgroundColor: JioColors.bgTertiary,
                    fontSize: 12.5,
                    fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  // Table Configuration for Mobile:
                  // IntrinsicColumnWidth forces each column to fit its natural text
                  // and triggers flutter_markdown's horizontal scroll controller!
                  tableColumnWidth: const IntrinsicColumnWidth(),
                  tableScrollbarThumbVisibility: true,
                  tablePadding: const EdgeInsets.symmetric(vertical: 8),
                  tableCellsPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  tableHead: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: JioColors.jioNavy,
                    fontSize: 13,
                  ),
                  tableBody: const TextStyle(
                    fontSize: 13,
                    color: JioColors.textPrimary,
                    height: 1.45,
                  ),
                  tableBorder: TableBorder(
                    horizontalInside: const BorderSide(color: JioColors.borderSubtle, width: 1),
                    verticalInside: BorderSide(color: JioColors.borderSubtle.withValues(alpha: 0.6), width: 1),
                    top: const BorderSide(color: JioColors.borderDefault, width: 1),
                    bottom: const BorderSide(color: JioColors.borderDefault, width: 1),
                    left: const BorderSide(color: JioColors.borderDefault, width: 1),
                    right: const BorderSide(color: JioColors.borderDefault, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tableCellsDecoration: BoxDecoration(
                    color: JioColors.bgPrimary,
                  ),
                ),
              ),
              if (isStreamingThis) const LiveStreamRibbon(),
            ],

            // Official Sources Section
            if (message.citations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: JioColors.bgTertiary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: JioColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.menu_book_rounded, size: 13, color: JioColors.jioNavy),
                        SizedBox(width: 5),
                        Text(
                          'Verified Sources from Jio.com:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: JioColors.jioNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: message.citations.map((cite) {
                        return InkWell(
                          onTap: () => _openUrl(cite.url),
                          borderRadius: BorderRadius.circular(9999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: JioColors.bgSecondary,
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(color: JioColors.borderDefault),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.open_in_new_rounded, size: 11, color: JioColors.jioBlue),
                                const SizedBox(width: 4),
                                Text(
                                  cite.title,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: JioColors.jioBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // Action Bar (Copy, Thumbs Up, Retry)
            if (!isStreamingThis && message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.content));
                      onShowToast?.call('Response copied to clipboard');
                    },
                  ),
                  const SizedBox(width: 6),
                  _ActionButton(
                    icon: Icons.thumb_up_alt_outlined,
                    label: '',
                    onTap: () {
                      onShowToast?.call('Thank you for your feedback!');
                    },
                  ),
                  const SizedBox(width: 6),
                  if (onRetry != null)
                    _ActionButton(
                      icon: Icons.refresh_rounded,
                      label: 'Retry',
                      onTap: onRetry!,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: JioColors.textSecondary),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: JioColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
