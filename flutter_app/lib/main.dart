import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/jio_colors.dart';
import 'models/chat_session.dart';
import 'models/chat_message.dart';
import 'models/app_settings.dart';
import 'services/rag_service.dart';
import 'services/groq_service.dart';
import 'services/storage_service.dart';
import 'theme/jio_theme.dart';
import 'widgets/jio_navbar.dart';
import 'widgets/category_tabs.dart';
import 'widgets/welcome_view.dart';
import 'widgets/message_bubble.dart';
import 'widgets/composer_bar.dart';
import 'widgets/jio_sidebar.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/clear_history_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JioGenieApp());
}

class JioGenieApp extends StatelessWidget {
  const JioGenieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JioGenie - Unofficial AI Assistance for Jio',
      debugShowCheckedModeBanner: false,
      theme: JioTheme.lightTheme,
      home: const JioGenieHomePage(),
    );
  }
}

class JioGenieHomePage extends StatefulWidget {
  const JioGenieHomePage({super.key});

  @override
  State<JioGenieHomePage> createState() => _JioGenieHomePageState();
}

class _JioGenieHomePageState extends State<JioGenieHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  final StorageService _storageService = StorageService();
  final RagService _ragService = RagService();
  final GroqService _groqService = GroqService();

  List<ChatSession> _chats = [];
  String? _activeChatId;
  String _activeCategory = 'all';
  AppSettings _settings = AppSettings();

  bool _isStreaming = false;
  StreamSubscription<String>? _streamSub;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    await _ragService.loadKnowledgeBase();
    final loadedSettings = await _storageService.loadSettings();
    final loadedChats = await _storageService.loadChats();
    final savedActiveId = await _storageService.loadActiveId();

    setState(() {
      _settings = loadedSettings;
      _chats = loadedChats;

      if (_chats.isNotEmpty) {
        if (savedActiveId != null && _chats.any((c) => c.id == savedActiveId)) {
          _activeChatId = savedActiveId;
        } else {
          _activeChatId = _chats.first.id;
        }
      } else {
        _createNewChat();
      }
    });
  }

  ChatSession? get _activeChat {
    if (_chats.isEmpty || _activeChatId == null) return null;
    return _chats.firstWhere(
      (c) => c.id == _activeChatId,
      orElse: () => _chats.first,
    );
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: JioColors.jioDeepNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _createNewChat() {
    if (_isStreaming) {
      _stopGenerating();
    }
    final fresh = ChatSession.create();
    setState(() {
      _chats.insert(0, fresh);
      _activeChatId = fresh.id;
    });
    _storageService.saveChats(_chats);
    _storageService.saveActiveId(fresh.id);
  }

  void _selectChat(String id) {
    if (_isStreaming) {
      _stopGenerating();
    }
    setState(() {
      _activeChatId = id;
    });
    _storageService.saveActiveId(id);
    _scrollToBottom();
  }

  void _renameChat(String id, String newTitle) {
    setState(() {
      final chat = _chats.firstWhere((c) => c.id == id);
      chat.title = newTitle;
      chat.updatedAt = DateTime.now();
    });
    _storageService.saveChats(_chats);
  }

  void _deleteChat(String id) {
    setState(() {
      _chats.removeWhere((c) => c.id == id);
      if (_activeChatId == id) {
        if (_chats.isNotEmpty) {
          _activeChatId = _chats.first.id;
        } else {
          _createNewChat();
        }
      }
    });
    _storageService.saveChats(_chats);
    _storageService.saveActiveId(_activeChatId);
    _showToast('Inquiry deleted');
  }

  void _clearAllHistory() {
    setState(() {
      _chats.clear();
      _createNewChat();
    });
    _storageService.clearAll();
    _showToast('All conversations cleared');
  }

  Future<void> _handleSendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isStreaming) return;

    if (_activeChatId == null || !_chats.any((c) => c.id == _activeChatId)) {
      _createNewChat();
    }

    final currentChat = _activeChat!;
    final isFirstMessage = currentChat.messages.isEmpty;

    final userMsg = ChatMessage(role: 'user', content: query);
    final botMsg = ChatMessage(role: 'assistant', content: '');

    setState(() {
      if (isFirstMessage) {
        currentChat.title = query.length > 35 ? '${query.substring(0, 35)}...' : query;
      }
      currentChat.updatedAt = DateTime.now();
      currentChat.messages.add(userMsg);
      currentChat.messages.add(botMsg);
      _isStreaming = true;
    });

    _scrollToBottom();

    // 1. Client-Side Okapi BM25 RAG Retrieval
    final matchedDocs = _ragService.retrieve(query, topK: 4);
    final citations = _ragService.getCitations(matchedDocs);
    final groundedPrompt = _ragService.buildGroundedPrompt(_settings.systemPrompt, matchedDocs);

    // 2. Stream completions from Groq or mock engine
    try {
      final stream = _groqService.streamChat(
        query: query,
        systemPrompt: groundedPrompt,
        settings: _settings,
      );

      _streamSub = stream.listen(
        (chunk) {
          setState(() {
            botMsg.content += chunk;
          });
          _scrollToBottom();
        },
        onError: (err) {
          setState(() {
            botMsg.content = '⚠️ **Error generating answer:** $err. Please check connection or API key in Settings ⚙️.';
            _isStreaming = false;
          });
          _storageService.saveChats(_chats);
        },
        onDone: () {
          setState(() {
            botMsg.citations = citations;
            _isStreaming = false;
          });
          _storageService.saveChats(_chats);
        },
        cancelOnError: true,
      );
    } catch (err) {
      setState(() {
        botMsg.content = '⚠️ **Error:** $err';
        _isStreaming = false;
      });
      _storageService.saveChats(_chats);
    }
  }

  void _stopGenerating() {
    _streamSub?.cancel();
    _groqService.cancel();
    setState(() {
      _isStreaming = false;
    });
    _storageService.saveChats(_chats);
    _showToast('Generation stopped');
  }

  void _exportMarkdown() {
    final chat = _activeChat;
    if (chat == null || chat.messages.isEmpty) {
      _showToast('No conversation to export');
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('# ${chat.title}');
    buffer.writeln('*Exported from JioGenie on ${DateTime.now().toLocal()}*\n');
    buffer.writeln('---\n');

    for (final m in chat.messages) {
      final sender = m.isUser ? '👤 User' : '⚡ JioGenie';
      buffer.writeln('### $sender (${m.timestamp.toLocal()})\n');
      buffer.writeln('${m.content}\n');

      if (m.citations.isNotEmpty) {
        buffer.writeln('*Sources from jio.com:*');
        for (final c in m.citations) {
          buffer.writeln('- [${c.title}](${c.url})');
        }
        buffer.writeln();
      }
      buffer.writeln('---\n');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    _showToast('Conversation copied to clipboard as Markdown');
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SettingsDialog(
        settings: _settings,
        onSave: (newSettings) {
          setState(() => _settings = newSettings);
          _storageService.saveSettings(newSettings);
          _showToast('Settings saved successfully');
        },
      ),
    );
  }

  void _openClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ClearHistoryDialog(
        onConfirmClear: _clearAllHistory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final activeChat = _activeChat;
    final hasMessages = activeChat != null && activeChat.messages.isNotEmpty;

    final sidebarWidget = JioSidebar(
      chats: _chats,
      activeChatId: _activeChatId,
      onSelectChat: _selectChat,
      onNewChat: _createNewChat,
      onRenameChat: _renameChat,
      onDeleteChat: _deleteChat,
      onOpenSettings: _openSettingsDialog,
      onClearAllHistory: _openClearHistoryDialog,
      onCloseDrawer: () => Navigator.of(context).maybePop(),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: JioColors.bgPrimary,
      drawer: Drawer(
        width: 280,
        child: sidebarWidget,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              children: [
                // Top Jio Navbar
                JioNavbar(
                  isMobile: isMobile,
                  onToggleSidebar: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  onNewInquiry: _createNewChat,
                  onExport: _exportMarkdown,
                ),

                // Category Navigation Tabs
                CategoryTabs(
                  activeCategoryId: _activeCategory,
                  onCategorySelected: (cat) => setState(() => _activeCategory = cat),
                ),

                // Chat Messages or Welcome Screen
                Expanded(
                  child: !hasMessages
                      ? WelcomeView(
                          activeCategory: _activeCategory,
                          onSelectPrompt: _handleSendMessage,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: activeChat.messages.length,
                          itemBuilder: (context, index) {
                            final msg = activeChat.messages[index];
                            final isCurrentStreaming =
                                _isStreaming && index == activeChat.messages.length - 1 && msg.isAssistant;

                            return MessageBubble(
                              message: msg,
                              isStreamingThis: isCurrentStreaming,
                              onShowToast: _showToast,
                              onRetry: () {
                                final lastUser = activeChat.messages.reversed
                                    .firstWhere((m) => m.isUser, orElse: () => msg);
                                _handleSendMessage(lastUser.content);
                              },
                            );
                          },
                        ),
                ),

                // Composer Input Bar
                ComposerBar(
                  isStreaming: _isStreaming,
                  onSendMessage: _handleSendMessage,
                  onStopGenerating: _stopGenerating,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
