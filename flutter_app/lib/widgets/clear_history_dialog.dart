import 'package:flutter/material.dart';
import '../constants/jio_colors.dart';

class ClearHistoryDialog extends StatelessWidget {
  final VoidCallback onConfirmClear;

  const ClearHistoryDialog({super.key, required this.onConfirmClear});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Clear All History?',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: JioColors.jioNavy,
        ),
      ),
      content: const Text(
        'This will permanently delete all saved conversations from local storage.',
        style: TextStyle(
          fontSize: 13.5,
          color: JioColors.textSecondary,
          height: 1.4,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Cancel', style: TextStyle(color: JioColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirmClear();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: JioColors.jioRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Delete All', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
