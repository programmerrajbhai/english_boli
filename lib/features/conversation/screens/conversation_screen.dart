
import 'package:flutter/material.dart';
import '../../../core/services/audio_service.dart';
import '../../../data/models/level_model.dart';
import '../../../data/repositories/level_progress_repository.dart';

// Dummy models for Conversation
class ChatMessage {
  final String text;
  final String? translation;
  final bool isUser;
  ChatMessage({required this.text, this.translation, required this.isUser});
}

class ConversationTurn {
  final String characterText;
  final String characterTranslation;
  final List<String> userOptions;
  ConversationTurn({
    required this.characterText,
    required this.characterTranslation,
    required this.userOptions,
  });
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.level,
    this.audioService,
    this.progressRepository,
  });

  final LevelModel level;
  final AudioService? audioService;
  final LevelProgressRepository? progressRepository;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  // Design System Colors
  static const _ink = Color(0xFF08100E);
  static const _teal = Color(0xFF00BFAE);
  static const _yellow = Color(0xFFFFC928);
  static const _coral = Color(0xFFFF6B57);
  static const _background = Color(0xFFF5F9F8);
  static const _muted = Color(0xFF66736F);
  static const _border = Color(0xFFDCE5E2);

  late final AudioService _audioService;
  late final LevelProgressRepository _progressRepository;
  final ScrollController _scrollController = ScrollController();

  // States
  bool _loading = true;
  bool _finishing = false;
  bool _allowPop = false;
  int _currentTurnIndex = 0;
  final List<ChatMessage> _chatHistory = [];
  bool _isWaitingForReply = false;

  // Mocking 5-turn Conversation
  final List<ConversationTurn> _conversationTurns = [
    ConversationTurn(
      characterText: "Hello! Welcome to the cafe. What would you like to order?",
      characterTranslation: "হ্যালো! ক্যাফেতে স্বাগতম। আপনি কী অর্ডার করতে চান?",
      userOptions: ["I would like a coffee, please.", "Do you have tea?"],
    ),
    ConversationTurn(
      characterText: "Yes, we have both. Would you like it hot or iced?",
      characterTranslation: "হ্যাঁ, আমাদের দুটোই আছে। আপনি কি গরম নাকি বরফ দেওয়া চান?",
      userOptions: ["Hot, please.", "Iced coffee sounds good."],
    ),
    ConversationTurn(
      characterText: "Great choice. Any snacks with that?",
      characterTranslation: "চমৎকার পছন্দ। এর সাথে কি কোনো স্ন্যাকস লাগবে?",
      userOptions: ["No, just the drink.", "Yes, a chocolate muffin."],
    ),
    ConversationTurn(
      characterText: "Sure. That will be 5 dollars.",
      characterTranslation: "অবশ্যই। মোট ৫ ডলার হয়েছে।",
      userOptions: ["Here you go.", "Can I pay by card?"],
    ),
    ConversationTurn(
      characterText: "Thank you! Please wait a moment for your order.",
      characterTranslation: "ধন্যবাদ! আপনার অর্ডারের জন্য একটু অপেক্ষা করুন।",
      userOptions: ["Thank you!", "Okay, no problem."],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _audioService = widget.audioService ?? AudioService();
    _progressRepository = widget.progressRepository ?? LevelProgressRepository();
    _initialize();
  }

  Future<void> _initialize() async {
    await _audioService.initialize();
    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    _triggerNextCharacterTurn();
  }

  @override
  void dispose() {
    _audioService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _triggerNextCharacterTurn() async {
    if (_currentTurnIndex >= _conversationTurns.length) {
      _showCompletionSummary();
      return;
    }

    final turn = _conversationTurns[_currentTurnIndex];

    // Add character message to history
    setState(() {
      _chatHistory.add(ChatMessage(
        text: turn.characterText,
        translation: turn.characterTranslation,
        isUser: false,
      ));
    });
    _scrollToBottom();

    // Play TTS
    await _audioService.speak(turn.characterText);

    if (!mounted) return;
    setState(() {
      _isWaitingForReply = true;
    });
    _scrollToBottom();
  }

  Future<void> _handleUserReply(String reply) async {
    setState(() {
      _isWaitingForReply = false;
      _chatHistory.add(ChatMessage(
        text: reply,
        isUser: true,
      ));
    });
    _scrollToBottom();

    // Optional: play user reply TTS or just proceed
    _currentTurnIndex++;

    // Small delay for natural conversational feel
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) _triggerNextCharacterTurn();
  }

  void _showCompletionSummary() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildSummarySheet(),
    );
  }

  Future<void> _finishConversation() async {
    setState(() => _finishing = true);
    try {
      await _progressRepository.completeStage(
        levelId: widget.level.id,
        totalPractices: widget.level.totalPractices,
        minimumCompletedPractices: widget.level.totalPractices, // Completed all
        nextStage: 5, // Move to Level Test
      );

      if (!mounted) return;
      setState(() => _allowPop = true);

      // Pop bottom sheet and screen
      Navigator.of(context).pop();
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save progress.')),
      );
    }
  }

  Future<void> _confirmClose() async {
    if (_allowPop) {
      Navigator.of(context).pop();
      return;
    }

    await _audioService.stop();
    if (!mounted) return;

    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave Conversation?', style: TextStyle(fontWeight: FontWeight.w900)),
          content: const Text('You will lose your current progress in this chat.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _coral, foregroundColor: Colors.white),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (shouldClose == true && mounted) {
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmClose();
      },
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _buildTopBar(),
              _buildEnvironmentHeader(),
              Expanded(child: _buildChatArea()),
              if (_isWaitingForReply) _buildReplyOptions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final progressValue = _loading ? 0.0 : (_currentTurnIndex) / _conversationTurns.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 18, 10),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: _confirmClose,
            icon: const Icon(Icons.close_rounded, color: _ink, size: 28),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 11,
                backgroundColor: const Color(0xFFE0E8E6),
                color: _teal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: _yellow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _yellow.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded, color: _yellow, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'At the Cafe',
                  style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Order food and drinks',
                  style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _teal));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _chatHistory.length,
      itemBuilder: (context, index) {
        final message = _chatHistory[index];
        return _buildChatBubble(message);
      },
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 18,
              backgroundColor: _teal,
              child: Icon(Icons.face_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? _teal : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
                border: isUser ? null : Border.all(color: _border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A08100E),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (message.translation != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      message.translation!,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 14,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 18,
              backgroundColor: _yellow,
              child: Icon(Icons.person_rounded, color: _ink, size: 24),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildReplyOptions() {
    final options = _conversationTurns[_currentTurnIndex].userOptions;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Your Reply:',
            style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...options.map((option) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                side: const BorderSide(color: _teal, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _handleUserReply(option),
              child: Text(
                option,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSummarySheet() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.forum_rounded, color: _teal, size: 56),
          const SizedBox(height: 16),
          const Text(
            'Great Conversation!',
            style: TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'You successfully ordered at the cafe and completed all conversation turns.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _finishing ? null : _finishConversation,
              child: _finishing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Complete Practice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          )
        ],
      ),
    );
  }
}