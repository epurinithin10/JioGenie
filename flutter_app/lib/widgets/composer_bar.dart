import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/jio_colors.dart';

class ComposerBar extends StatefulWidget {
  final bool isStreaming;
  final ValueChanged<String> onSendMessage;
  final VoidCallback onStopGenerating;

  const ComposerBar({
    super.key,
    required this.isStreaming,
    required this.onSendMessage,
    required this.onStopGenerating,
  });

  @override
  State<ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends State<ComposerBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final can = _textController.text.trim().isNotEmpty;
    if (can != _canSend) {
      setState(() => _canSend = can);
    }
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty || widget.isStreaming) return;
    _textController.clear();
    widget.onSendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: JioColors.bgPrimary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stop Generating Button
              if (widget.isStreaming)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    onPressed: widget.onStopGenerating,
                    icon: const Icon(Icons.stop_rounded, size: 16),
                    label: const Text('Stop generating'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: JioColors.jioNavy,
                      backgroundColor: JioColors.bgSecondary,
                      side: const BorderSide(color: JioColors.borderDefault),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ),

              // Pill Box
              Container(
                decoration: BoxDecoration(
                  color: JioColors.bgSecondary,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _focusNode.hasFocus ? JioColors.jioBlue : JioColors.borderDefault,
                    width: _focusNode.hasFocus ? 1.5 : 1,
                  ),
                  boxShadow: JioColors.shadowMd,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Text Input
                    Expanded(
                      child: CallbackShortcuts(
                        bindings: {
                          const SingleActivator(LogicalKeyboardKey.enter): _submit,
                        },
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          minLines: 1,
                          maxLines: 5,
                          style: const TextStyle(
                            fontSize: 14,
                            color: JioColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Ask anything about Jio...',
                            hintStyle: TextStyle(color: JioColors.textMuted, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          ),
                        ),
                      ),
                    ),

                    // Mic Button
                    IconButton(
                      icon: const Icon(Icons.mic_none_rounded, color: JioColors.textSecondary, size: 20),
                      tooltip: 'Voice Dictation',
                      splashRadius: 20,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Voice dictation is active in web & mobile systems'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),

                    // Send Button
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      child: Material(
                        color: (_canSend && !widget.isStreaming)
                            ? JioColors.jioBlue
                            : JioColors.borderSubtle,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: (_canSend && !widget.isStreaming) ? _submit : null,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 18,
                              color: (_canSend && !widget.isStreaming)
                                  ? Colors.white
                                  : JioColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Disclaimer
              const Text(
                'Unofficial AI Assistance for Jio. Not affiliated with, sponsored by, or endorsed by Reliance Jio Infocomm Ltd. Grounded in verified data from www.jio.com.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: JioColors.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
