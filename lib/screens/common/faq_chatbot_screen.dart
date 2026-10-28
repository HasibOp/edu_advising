import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/portal.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/faq_matcher.dart';
import '../../utils/pdf_export.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';

class _Message {
  const _Message(this.text, {required this.fromUser, this.faq});
  final String text;
  final bool fromUser;
  final Faq? faq;
}

/// FAQ-only assistant: rules, deadlines, fees, clearance, waitlist.
class FaqChatbotScreen extends StatefulWidget {
  const FaqChatbotScreen({super.key});

  @override
  State<FaqChatbotScreen> createState() => _FaqChatbotScreenState();
}

class _FaqChatbotScreenState extends State<FaqChatbotScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Message> _messages = [
    const _Message(
      'Hi! I am the EDU Advising assistant. Ask me about advising, clearance, fees, '
      'the waitlist, extra courses, routines or exams.',
      fromUser: false,
    ),
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _ask(List<Faq> faqs, String question) {
    final text = question.trim();
    if (text.isEmpty) return;
    final match = FaqMatcher.bestMatch(faqs, text);
    setState(() {
      _messages.add(_Message(text, fromUser: true));
      _messages.add(_Message(match?.answer ?? FaqMatcher.fallback, fromUser: false, faq: match));
    });
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 200,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EduAppBar(
        title: 'FAQ Chatbot',
        subtitle: 'Answers from the official FAQ',
        actions: [
          IconButton(
            tooltip: 'Download FAQ as PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => runWithFeedback(context, () async {
              final faqs = await context.read<ApiService>().fetchFaqs();
              await PdfExport.shareTable(
                title: 'Frequently Asked Questions',
                filename: 'faq.pdf',
                subtitle: ['${faqs.length} questions'],
                headers: ['Category', 'Question', 'Answer'],
                rows: [for (final f in faqs) [f.category, f.question, f.answer]],
                columnFlex: {0: 1, 1: 2.2, 2: 4},
              );
            }),
          ),
        ],
      ),
      body: FutureView<List<Faq>>(
        load: () => context.read<ApiService>().fetchFaqs(),
        builder: (context, faqs, _) => Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  for (final m in _messages) _Bubble(message: m),
                  if (_messages.length == 1) ...[
                    const SizedBox(height: 8),
                    const Text('Try asking:', style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final f in faqs.take(8))
                          ActionChip(
                            label: Text(f.question, style: const TextStyle(fontSize: 12.5)),
                            onPressed: () => _ask(faqs, f.question),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        style: const TextStyle(color: AppColors.text),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (v) => _ask(faqs, v),
                        decoration: const InputDecoration(
                          hintText: 'Type your question...',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      onPressed: () => _ask(faqs, _input.text),
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final user = message.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: user ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(user ? 16 : 4),
            bottomRight: Radius.circular(user ? 4 : 16),
          ),
          border: user ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.faq != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(message.faq!.question,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
              ),
            Text(message.text,
                style: TextStyle(color: user ? Colors.white : AppColors.text, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
