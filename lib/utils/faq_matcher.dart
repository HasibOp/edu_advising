import '../models/portal.dart';

/// Offline FAQ bot, step 1 of the plan: keyword and word-overlap matching.
/// Only FAQ text is searched; no personal data is ever used.
class FaqMatcher {
  FaqMatcher._();

  static const String fallback =
      'Sorry, I could not find that in the FAQ. Please contact the Accounts or '
      'Academic office.';

  static const Set<String> _stopWords = {
    'a', 'an', 'the', 'i', 'my', 'me', 'is', 'are', 'do', 'does', 'can', 'to', 'of', 'in',
    'on', 'for', 'and', 'or', 'it', 'what', 'how', 'when', 'where', 'why', 'which', 'with',
    'be', 'am', 'we', 'you', 'your', 'this', 'that', 'there', 'please',
  };

  static List<String> _words(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9' ]"), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 1 && !_stopWords.contains(w))
      .toList();

  static int score(Faq faq, String question) {
    final q = question.toLowerCase();
    var score = 0;
    for (final k in faq.keywords) {
      if (q.contains(k.toLowerCase())) score += k.contains(' ') ? 4 : 3;
    }
    final faqWords = _words('${faq.question} ${faq.category}').toSet();
    for (final w in _words(question)) {
      if (faqWords.contains(w)) score += 1;
    }
    return score;
  }

  /// Best FAQ for [question], or null when nothing is close enough.
  static Faq? bestMatch(List<Faq> faqs, String question) {
    Faq? best;
    var bestScore = 0;
    for (final f in faqs) {
      final s = score(f, question);
      if (s > bestScore) {
        best = f;
        bestScore = s;
      }
    }
    return bestScore >= 2 ? best : null;
  }
}
