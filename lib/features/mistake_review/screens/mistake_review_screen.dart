import 'package:flutter/material.dart';

// Mock Model for Mistake
class MistakeItem {
  final String id;
  final String category;
  final String question;
  final String wrongAnswer;
  final String correctAnswer;

  MistakeItem({
    required this.id,
    required this.category,
    required this.question,
    required this.wrongAnswer,
    required this.correctAnswer,
  });
}

class MistakeReviewScreen extends StatefulWidget {
  const MistakeReviewScreen({super.key});

  @override
  State<MistakeReviewScreen> createState() => _MistakeReviewScreenState();
}

class _MistakeReviewScreenState extends State<MistakeReviewScreen> {
  // Design System Colors
  static const _ink = Color(0xFF08100E);
  static const _teal = Color(0xFF00BFAE);
  static const _yellow = Color(0xFFFFC928);
  static const _coral = Color(0xFFFF6B57);
  static const _green = Color(0xFF20A66A);
  static const _background = Color(0xFFF5F9F8);
  static const _muted = Color(0xFF66736F);
  static const _border = Color(0xFFDCE5E2);

  bool _loading = true;
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Grammar', 'Vocabulary', 'Listening', 'Speaking'];

  // Mock Data
  late List<MistakeItem> _mistakes;

  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }

  Future<void> _loadMistakes() async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate API/DB load
    if (!mounted) return;

    setState(() {
      _mistakes = [
        MistakeItem(
          id: '1',
          category: 'Grammar',
          question: 'I _____ learning English.',
          wrongAnswer: 'is',
          correctAnswer: 'am',
        ),
        MistakeItem(
          id: '2',
          category: 'Vocabulary',
          question: 'What is the synonym of "Happy"?',
          wrongAnswer: 'Sad',
          correctAnswer: 'Joyful',
        ),
        MistakeItem(
          id: '3',
          category: 'Listening',
          question: 'Audio: "Where are you from?"',
          wrongAnswer: 'What are you doing?',
          correctAnswer: 'Where are you from?',
        ),
      ];
      _loading = false;
    });
  }

  void _retryMistake(MistakeItem mistake) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mistake.category.toUpperCase(),
                    style: const TextStyle(color: _teal, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: _ink),
                )
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Retry this question:',
              style: TextStyle(color: _muted, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              mistake.question,
              style: const TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w900, height: 1.3),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _markAsCorrect(mistake);
                },
                child: const Text('I answered it correctly now', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _coral,
                  side: const BorderSide(color: _coral, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Still incorrect. Keep practicing!')),
                  );
                },
                child: const Text('I made a mistake again', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _markAsCorrect(MistakeItem mistake) {
    setState(() {
      _mistakes.removeWhere((item) => item.id == mistake.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Awesome! Mistake cleared from your review list.'),
        backgroundColor: _green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mistake Review',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : Column(
        children: [
          _buildCategoryFilters(),
          Expanded(
            child: _buildMistakesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: _ink,
              backgroundColor: Colors.white,
              side: BorderSide(color: isSelected ? _ink : _border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMistakesList() {
    final filteredMistakes = _selectedCategory == 'All'
        ? _mistakes
        : _mistakes.where((m) => m.category == _selectedCategory).toList();

    if (filteredMistakes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: filteredMistakes.length,
      itemBuilder: (context, index) {
        final mistake = filteredMistakes[index];
        return _buildMistakeCard(mistake);
      },
    );
  }

  Widget _buildMistakeCard(MistakeItem mistake) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0508100E),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  mistake.category,
                  style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              const Icon(Icons.history_rounded, color: _muted, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mistake.question,
            style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w900, height: 1.3),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.close_rounded, color: _coral, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mistake.wrongAnswer,
                        style: const TextStyle(color: _coral, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_rounded, color: _green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mistake.correctAnswer,
                        style: const TextStyle(color: _green, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _yellow,
                foregroundColor: _ink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _retryMistake(mistake),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.celebration_rounded, color: _green, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedCategory == 'All' ? 'No Mistakes to Review!' : 'No $_selectedCategory Mistakes!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have caught up on all your mistakes. Keep up the great work!',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 15, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}