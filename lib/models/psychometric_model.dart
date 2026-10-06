/// Psychometric assessment model for ConGrowing onboarding.
///
/// Maps 7 questions to personality traits and computes an initial
/// CRI (Character Rating Index) score so new users never start at 0.
library;

class PsychometricOption {
  final String label;
  final int weight; // 1–5

  const PsychometricOption({required this.label, required this.weight});
}

enum TraitCategory {
  openness,
  conscientiousness,
  extraversion,
  agreeableness,
  emotionalStability,
  communicationStyle, // ConGrowing-specific
  growthMindset, // ConGrowing-specific
}

class PsychometricQuestion {
  final String question;
  final String subtitle;
  final TraitCategory trait;
  final List<PsychometricOption> options;

  const PsychometricQuestion({
    required this.question,
    required this.subtitle,
    required this.trait,
    required this.options,
  });
}

/// Result of the psychometric assessment.
class PsychometricResult {
  final String personalityType;
  final String personalityEmoji;
  final String personalityDescription;
  final int initialCriScore;
  final Map<TraitCategory, int> traitScores;

  const PsychometricResult({
    required this.personalityType,
    required this.personalityEmoji,
    required this.personalityDescription,
    required this.initialCriScore,
    required this.traitScores,
  });
}

/// Static data & scoring logic for the 7-question psychometric test.
class PsychometricTest {
  PsychometricTest._();

  static const List<PsychometricQuestion> questions = [
    // ── 1. Openness ─────────────────────────────────────────────
    PsychometricQuestion(
      question:
          'When faced with a new idea that contradicts your beliefs, you typically…',
      subtitle: 'How open are you to new perspectives?',
      trait: TraitCategory.openness,
      options: [
        PsychometricOption(
            label: 'Dismiss it — my views are well-formed', weight: 1),
        PsychometricOption(
            label: 'Feel uncomfortable but ignore it', weight: 2),
        PsychometricOption(label: 'Think about it later on my own', weight: 3),
        PsychometricOption(
            label: 'Explore it curiously and ask questions', weight: 4),
        PsychometricOption(
            label: 'Get excited — I love challenging my thinking', weight: 5),
      ],
    ),

    // ── 2. Conscientiousness ────────────────────────────────────
    PsychometricQuestion(
      question:
          'When you commit to helping someone, how often do you follow through?',
      subtitle: 'Your reliability and dedication',
      trait: TraitCategory.conscientiousness,
      options: [
        PsychometricOption(label: 'Rarely — things come up', weight: 1),
        PsychometricOption(label: 'Sometimes, if it\'s convenient', weight: 2),
        PsychometricOption(label: 'Most of the time', weight: 3),
        PsychometricOption(
            label: 'Almost always — I take commitments seriously', weight: 4),
        PsychometricOption(label: 'Always — my word is my bond', weight: 5),
      ],
    ),

    // ── 3. Extraversion ─────────────────────────────────────────
    PsychometricQuestion(
      question: 'In a group conversation with strangers, you usually…',
      subtitle: 'How you engage in social settings',
      trait: TraitCategory.extraversion,
      options: [
        PsychometricOption(label: 'Stay quiet and observe', weight: 1),
        PsychometricOption(label: 'Speak only when spoken to', weight: 2),
        PsychometricOption(label: 'Join in after warming up', weight: 3),
        PsychometricOption(
            label: 'Actively participate and share stories', weight: 4),
        PsychometricOption(label: 'Lead the conversation naturally', weight: 5),
      ],
    ),

    // ── 4. Agreeableness ────────────────────────────────────────
    PsychometricQuestion(
      question:
          'When someone shares a problem with you, your first instinct is to…',
      subtitle: 'Your empathy and support style',
      trait: TraitCategory.agreeableness,
      options: [
        PsychometricOption(label: 'Tell them to toughen up', weight: 1),
        PsychometricOption(
            label: 'Offer a quick solution and move on', weight: 2),
        PsychometricOption(
            label: 'Listen and offer practical advice', weight: 3),
        PsychometricOption(
            label: 'Listen deeply and validate their feelings', weight: 4),
        PsychometricOption(
            label: 'Drop everything to be fully present for them', weight: 5),
      ],
    ),

    // ── 5. Emotional Stability ──────────────────────────────────
    PsychometricQuestion(
      question: 'When someone criticizes you unfairly, you tend to…',
      subtitle: 'How you handle emotional pressure',
      trait: TraitCategory.emotionalStability,
      options: [
        PsychometricOption(label: 'Get angry and confront them', weight: 1),
        PsychometricOption(
            label: 'Feel hurt and dwell on it for days', weight: 2),
        PsychometricOption(
            label: 'Feel upset but move on within hours', weight: 3),
        PsychometricOption(
            label: 'Reflect calmly and consider if there\'s truth to it',
            weight: 4),
        PsychometricOption(
            label: 'Stay composed — I don\'t let others define me', weight: 5),
      ],
    ),

    // ── 6. Communication Style (CG-specific) ────────────────────
    PsychometricQuestion(
      question: 'During a disagreement, you prefer to…',
      subtitle: 'Your communication approach in conflict',
      trait: TraitCategory.communicationStyle,
      options: [
        PsychometricOption(label: 'Win the argument at all costs', weight: 1),
        PsychometricOption(label: 'Avoid the conversation entirely', weight: 2),
        PsychometricOption(label: 'Compromise to keep the peace', weight: 3),
        PsychometricOption(
            label: 'Understand their perspective before sharing yours',
            weight: 4),
        PsychometricOption(
            label: 'Seek a solution that works for everyone', weight: 5),
      ],
    ),

    // ── 7. Growth Mindset (CG-specific) ─────────────────────────
    PsychometricQuestion(
      question: 'When you fail at something important, you believe…',
      subtitle: 'Your relationship with failure and growth',
      trait: TraitCategory.growthMindset,
      options: [
        PsychometricOption(label: 'I\'m just not talented enough', weight: 1),
        PsychometricOption(label: 'Some people are just luckier', weight: 2),
        PsychometricOption(label: 'I can improve if I try harder', weight: 3),
        PsychometricOption(
            label: 'Failure is a stepping stone to success', weight: 4),
        PsychometricOption(
            label: 'Every failure teaches me something invaluable', weight: 5),
      ],
    ),
  ];

  /// Evaluate the user's answers and return a [PsychometricResult].
  ///
  /// [answers] is a map of question index → selected option index.
  static PsychometricResult evaluate(Map<int, int> answers) {
    assert(
        answers.length == questions.length, 'All 7 questions must be answered');

    // Collect trait scores
    final traitScores = <TraitCategory, int>{};
    double totalWeighted = 0;

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final selectedIdx = answers[i] ?? 2; // default to middle
      final weight = q.options[selectedIdx].weight;
      traitScores[q.trait] = weight;
      totalWeighted += weight;
    }

    // Raw average (1.0 – 5.0)
    final rawAvg = totalWeighted / questions.length;

    // Map to CRI:  300 + (rawAvg * 90)  →  range 390–750
    final initialCri = (300 + (rawAvg * 90)).round().clamp(390, 750);

    // Determine dominant trait → personality type
    final dominantTrait = _dominantTrait(traitScores);
    final personality = _classifyPersonality(dominantTrait);

    return PsychometricResult(
      personalityType: personality['type']!,
      personalityEmoji: personality['emoji']!,
      personalityDescription: personality['desc']!,
      initialCriScore: initialCri,
      traitScores: traitScores,
    );
  }

  static TraitCategory _dominantTrait(Map<TraitCategory, int> scores) {
    TraitCategory dominant = TraitCategory.openness;
    int highest = 0;
    for (final entry in scores.entries) {
      if (entry.value > highest) {
        highest = entry.value;
        dominant = entry.key;
      }
    }
    return dominant;
  }

  static Map<String, String> _classifyPersonality(TraitCategory dominant) {
    switch (dominant) {
      case TraitCategory.openness:
        return {
          'type': 'Explorer',
          'emoji': '🌍',
          'desc':
              'You thrive on new ideas and diverse perspectives. Your curiosity makes conversations with you exciting and enriching.',
        };
      case TraitCategory.conscientiousness:
        return {
          'type': 'Guardian',
          'emoji': '🛡️',
          'desc':
              'Reliable and dedicated, people can always count on you. Your commitment builds deep, lasting trust.',
        };
      case TraitCategory.extraversion:
        return {
          'type': 'Connector',
          'emoji': '⚡',
          'desc':
              'You light up every room you enter. Your natural social energy brings people together effortlessly.',
        };
      case TraitCategory.agreeableness:
        return {
          'type': 'Diplomat',
          'emoji': '🤝',
          'desc':
              'Empathetic and understanding, you have a gift for making others feel heard and valued.',
        };
      case TraitCategory.emotionalStability:
        return {
          'type': 'Anchor',
          'emoji': '⚓',
          'desc':
              'Calm under pressure, you\'re the steady presence everyone needs. Your composure inspires confidence.',
        };
      case TraitCategory.communicationStyle:
        return {
          'type': 'Mediator',
          'emoji': '🕊️',
          'desc':
              'You navigate conflict with grace. Your balanced approach helps find solutions that work for everyone.',
        };
      case TraitCategory.growthMindset:
        return {
          'type': 'Visionary',
          'emoji': '🚀',
          'desc':
              'You see potential where others see failure. Your growth mindset inspires those around you to aim higher.',
        };
    }
  }
}
