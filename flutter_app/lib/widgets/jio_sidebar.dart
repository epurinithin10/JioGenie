import 'package:flutter/material.dart';
import '../constants/jio_colors.dart';
import '../models/chat_session.dart';
import 'telecom_icon.dart';

class JioSidebar extends StatefulWidget {
  final List<ChatSession> chats;
  final String? activeChatId;
  final ValueChanged<String> onSelectChat;
  final VoidCallback onNewChat;
  final Function(String id, String newTitle) onRenameChat;
  final ValueChanged<String> onDeleteChat;
  final VoidCallback onOpenSettings;
  final VoidCallback onClearAllHistory;
  final VoidCallback? onCloseDrawer;

  const JioSidebar({
    super.key,
    required this.chats,
    required this.activeChatId,
    required this.onSelectChat,
    required this.onNewChat,
    required this.onRenameChat,
    required this.onDeleteChat,
    required this.onOpenSettings,
    required this.onClearAllHistory,
    this.onCloseDrawer,
  });

  @override
  State<JioSidebar> createState() => _JioSidebarState();
}

class _JioSidebarState extends State<JioSidebar> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<ChatSession>> _getGroupedChats() {
    final filtered = widget.chats.where((c) {
      if (_searchQuery.isEmpty) return true;
      if (c.title.toLowerCase().contains(_searchQuery)) return true;
      return c.messages.any((m) => m.content.toLowerCase().contains(_searchQuery));
    }).toList();

    final groups = <String, List<ChatSession>>{
      'Today': [],
      'Yesterday': [],
      'Previous 7 Days': [],
      'Older': [],
    };

    final now = DateTime.now();

    for (final chat in filtered) {
      final date = chat.updatedAt;
      final diffDays = now.difference(date).inDays;

      if (diffDays == 0 && now.day == date.day) {
        groups['Today']!.add(chat);
      } else if (diffDays <= 1) {
        groups['Yesterday']!.add(chat);
      } else if (diffDays <= 7) {
        groups['Previous 7 Days']!.add(chat);
      } else {
        groups['Older']!.add(chat);
      }
    }

    return groups;
  }

  void _showRenameDialog(ChatSession chat) {
    final controller = TextEditingController(text: chat.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Inquiry', style: TextStyle(color: JioColors.jioNavy, fontSize: 17)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter inquiry title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: JioColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: JioColors.jioBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                widget.onRenameChat(chat.id, val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _getGroupedChats();

    return Container(
      width: 280,
      height: double.infinity,
      color: JioColors.bgSecondary,
      child: Column(
        children: [
          // Sidebar Header
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: JioColors.borderSubtle)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: JioColors.jioBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const TelecomIcon(size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'JioGenie',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: JioColors.jioNavy,
                  ),
                ),
                const Spacer(),
                if (widget.onCloseDrawer != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: JioColors.textSecondary),
                    onPressed: widget.onCloseDrawer,
                  ),
              ],
            ),
          ),

          // New Inquiry Pill Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Material(
              color: JioColors.jioBlue,
              borderRadius: BorderRadius.circular(9999),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(9999),
                onTap: widget.onNewChat,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: const [
                      Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'New Inquiry',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Ctrl K',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: JioColors.bgTertiary,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: JioColors.borderSubtle),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13, color: JioColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: JioColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: JioColors.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: JioColors.textMuted),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
          ),

          // Grouped Chats List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: grouped.entries.expand((entry) {
                final groupName = entry.key;
                final items = entry.value;
                if (items.isEmpty) return <Widget>[];

                return [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
                    child: Text(
                      groupName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: JioColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...items.map((chat) {
                    final isActive = chat.id == widget.activeChatId;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? JioColors.jioBlueLight : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        title: Text(
                          chat.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? JioColors.jioBlue : JioColors.textPrimary,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 14, color: JioColors.textMuted),
                              tooltip: 'Rename',
                              splashRadius: 14,
                              onPressed: () => _showRenameDialog(chat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 15, color: JioColors.jioRed),
                              tooltip: 'Delete',
                              splashRadius: 14,
                              onPressed: () => widget.onDeleteChat(chat.id),
                            ),
                          ],
                        ),
                        onTap: () {
                          widget.onSelectChat(chat.id);
                          widget.onCloseDrawer?.call();
                        },
                      ),
                    );
                  }),
                ];
              }).toList(),
            ),
          ),

          // Sidebar Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: JioColors.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: widget.onOpenSettings,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: const [
                          Icon(Icons.settings_outlined, size: 18, color: JioColors.textSecondary),
                          SizedBox(width: 8),
                          Text(
                            'Settings',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: JioColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: widget.onClearAllHistory,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.delete_sweep_outlined, size: 18, color: JioColors.jioRed),
                        SizedBox(width: 6),
                        Text(
                          'Clear',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: JioColors.jioRed),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
