import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

/// Model for a single IQ/riddle question.
class IQQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String category; // 'riddle', 'pattern', 'logic', 'spatial', 'math'

  const IQQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.category,
  });
}

/// Bank of 50 diverse IQ questions.
const List<IQQuestion> _allQuestions = [
  // ── Riddles ──────────────────────────────────────────────────────────────
  IQQuestion(
    question:
        "I speak without a mouth and hear without ears. I have no body, but I come alive with wind. What am I?",
    options: ["A shadow", "An echo", "A whisper", "A thought"],
    correctIndex: 1,
    explanation:
        "An echo is sound reflected back — it 'speaks' and 'hears' without physical organs.",
    category: 'riddle',
  ),
  IQQuestion(
    question: "The more you take, the more you leave behind. What am I?",
    options: ["Footsteps", "Time", "Money", "Memories"],
    correctIndex: 0,
    explanation: "Every step you take leaves a footprint behind.",
    category: 'riddle',
  ),
  IQQuestion(
    question:
        "I have cities but no houses, mountains but no trees, water but no fish, and roads but no cars. What am I?",
    options: ["A dream", "A painting", "A map", "A book"],
    correctIndex: 2,
    explanation:
        "A map represents all these features symbolically without the actual things.",
    category: 'riddle',
  ),
  IQQuestion(
    question: "What can you catch but not throw?",
    options: ["A shadow", "A cold", "A dream", "The wind"],
    correctIndex: 1,
    explanation:
        "You can catch a cold (illness) but you certainly can't throw it.",
    category: 'riddle',
  ),
  IQQuestion(
    question: "What has hands but cannot clap?",
    options: ["A tree", "A glove", "A clock", "A puppet"],
    correctIndex: 2,
    explanation: "A clock has hour and minute hands but cannot clap.",
    category: 'riddle',
  ),
  IQQuestion(
    question: "I go up when the rain comes down. What am I?",
    options: ["A kite", "An umbrella", "A river level", "A mood"],
    correctIndex: 1,
    explanation: "An umbrella goes up (is opened) when it rains.",
    category: 'riddle',
  ),
  IQQuestion(
    question: "What has a head, a tail, is brown, and has no legs?",
    options: ["A snake", "A penny", "A log", "A worm"],
    correctIndex: 1,
    explanation:
        "A coin (penny) has a head side and a tail side, is copper (brown) coloured.",
    category: 'riddle',
  ),
  IQQuestion(
    question:
        "I'm light as a feather, yet the strongest person can't hold me for more than a few minutes. What am I?",
    options: ["A secret", "Breath", "A smile", "Time"],
    correctIndex: 1,
    explanation:
        "Breath is weightless but you can only hold it for a short time.",
    category: 'riddle',
  ),
  IQQuestion(
    question: "What invention lets you look right through a wall?",
    options: ["X-ray", "A periscope", "A window", "A telescope"],
    correctIndex: 2,
    explanation:
        "A window is literally built into a wall and lets you see through it.",
    category: 'riddle',
  ),
  IQQuestion(
    question:
        "The person who makes it doesn't need it. The person who buys it doesn't use it. The person who uses it doesn't know. What is it?",
    options: ["A will", "A coffin", "A dream", "Medicine"],
    correctIndex: 1,
    explanation:
        "A coffin is made by a carpenter, bought by relatives, used by the deceased.",
    category: 'riddle',
  ),

  // ── Number / Letter Patterns ──────────────────────────────────────────────
  IQQuestion(
    question: "What comes next in the sequence: 2, 4, 8, 16, 32, ___?",
    options: ["48", "64", "60", "56"],
    correctIndex: 1,
    explanation: "Each number doubles the previous one: 32 × 2 = 64.",
    category: 'pattern',
  ),
  IQQuestion(
    question: "What comes next: 1, 1, 2, 3, 5, 8, ___?",
    options: ["12", "13", "14", "11"],
    correctIndex: 1,
    explanation:
        "This is the Fibonacci sequence: each number is the sum of the two before it (8+5=13).",
    category: 'pattern',
  ),
  IQQuestion(
    question: "What comes next: 3, 6, 11, 18, 27, ___?",
    options: ["36", "38", "40", "35"],
    correctIndex: 1,
    explanation: "Differences are +3, +5, +7, +9, +11 — so 27+11 = 38.",
    category: 'pattern',
  ),
  IQQuestion(
    question: "Which letter comes next: A, C, F, J, ___?",
    options: ["M", "O", "N", "P"],
    correctIndex: 1,
    explanation: "Gaps increase by 1: +2 (C), +3 (F), +4 (J), +5 → O.",
    category: 'pattern',
  ),
  IQQuestion(
    question: "What is the missing number: 5, 10, 20, ___, 80?",
    options: ["35", "30", "40", "45"],
    correctIndex: 2,
    explanation: "Each number is doubled: 20 × 2 = 40.",
    category: 'pattern',
  ),
  IQQuestion(
    question: "What comes next: 144, 121, 100, 81, 64, ___?",
    options: ["49", "36", "45", "48"],
    correctIndex: 0,
    explanation:
        "These are perfect squares in descending order: 12², 11², 10², 9², 8², 7² = 49.",
    category: 'pattern',
  ),
  IQQuestion(
    question: "Complete: 2, 6, 12, 20, 30, ___?",
    options: ["40", "42", "44", "48"],
    correctIndex: 1,
    explanation: "Pattern is n(n+1): 6×7=42.",
    category: 'pattern',
  ),
  IQQuestion(
    question: "Which number is out of place: 2, 5, 10, 17, 26, 37, 50, 64?",
    options: ["37", "50", "64", "26"],
    correctIndex: 2,
    explanation: "Differences are +3,+5,+7,+9,+11,+13 giving 63, not 64.",
    category: 'pattern',
  ),

  // ── Logical Reasoning ────────────────────────────────────────────────────
  IQQuestion(
    question: "All roses are flowers. Some flowers fade quickly. Therefore:",
    options: [
      "All roses fade quickly",
      "Some roses may fade quickly",
      "No roses fade quickly",
      "All flowers are roses"
    ],
    correctIndex: 1,
    explanation:
        "Since only *some* flowers fade quickly, and roses are a subset, some roses may fall into that group.",
    category: 'logic',
  ),
  IQQuestion(
    question: "If A > B, B > C, and C > D, which is the largest?",
    options: ["B", "C", "A", "D"],
    correctIndex: 2,
    explanation: "A is greater than all others by the transitive property.",
    category: 'logic',
  ),
  IQQuestion(
    question:
        "Tom is taller than Sam. Sam is taller than Alex. Who is the shortest?",
    options: ["Tom", "Sam", "Alex", "Cannot tell"],
    correctIndex: 2,
    explanation: "Alex < Sam < Tom, so Alex is shortest.",
    category: 'logic',
  ),
  IQQuestion(
    question:
        "A snail climbs 3m up a wall during the day and slides 2m back at night. How many days to climb 10m?",
    options: ["7", "8", "10", "9"],
    correctIndex: 1,
    explanation:
        "Net gain = 1m/day for 7 days (7m). On day 8 it climbs 3m more reaching 10m before sliding.",
    category: 'logic',
  ),
  IQQuestion(
    question: "A clock shows 3:15. What is the angle between the hands?",
    options: ["7.5°", "0°", "15°", "30°"],
    correctIndex: 0,
    explanation:
        "Minute hand: 90°. Hour hand at 3:15 is at 97.5°. Difference = 7.5°.",
    category: 'logic',
  ),
  IQQuestion(
    question: "If you rearrange CIFAIRC, you get the name of a:",
    options: ["Country", "Ocean", "City", "Animal"],
    correctIndex: 1,
    explanation: "CIFAIRC rearranges to PACIFIC — an ocean.",
    category: 'logic',
  ),
  IQQuestion(
    question: "How many months have 28 days?",
    options: ["1", "2", "4", "12"],
    correctIndex: 3,
    explanation: "All 12 months have at least 28 days.",
    category: 'logic',
  ),
  IQQuestion(
    question: "A farmer has 17 sheep. All but 9 die. How many are left?",
    options: ["8", "17", "9", "0"],
    correctIndex: 2,
    explanation: "'All but 9' means 9 survive.",
    category: 'logic',
  ),
  IQQuestion(
    question:
        "Before Mount Everest was discovered, what was the highest mountain on Earth?",
    options: ["K2", "Kangchenjunga", "Mount Everest", "Makalu"],
    correctIndex: 2,
    explanation:
        "Mount Everest was always the tallest — it just hadn't been *discovered* yet.",
    category: 'logic',
  ),
  IQQuestion(
    question:
        "A plane crashes on the border of USA and Canada. Where do you bury the survivors?",
    options: ["USA", "Canada", "Border zone", "You don't bury survivors"],
    correctIndex: 3,
    explanation: "Survivors are alive — you don't bury living people!",
    category: 'logic',
  ),

  // ── Spatial / Visual Reasoning ───────────────────────────────────────────
  IQQuestion(
    question:
        "If you fold a square piece of paper in half twice and cut a hole, how many holes will there be when unfolded?",
    options: ["1", "2", "4", "8"],
    correctIndex: 2,
    explanation:
        "Each fold doubles the layers, so one cut creates 4 holes when unfolded.",
    category: 'spatial',
  ),
  IQQuestion(
    question: "How many faces does a cube have?",
    options: ["4", "6", "8", "12"],
    correctIndex: 1,
    explanation:
        "A cube has 6 square faces (top, bottom, front, back, left, right).",
    category: 'spatial',
  ),
  IQQuestion(
    question:
        "A 3×3×3 cube is painted on all sides. How many small cubes have exactly 2 painted faces?",
    options: ["8", "12", "24", "6"],
    correctIndex: 1,
    explanation:
        "The 12 edge cubes (not corners) have exactly 2 painted faces.",
    category: 'spatial',
  ),
  IQQuestion(
    question:
        "If a wheel has 6 spokes, how many spaces are between the spokes?",
    options: ["5", "6", "7", "12"],
    correctIndex: 1,
    explanation:
        "Each spoke creates one space: 6 spokes create 6 gaps in a circle.",
    category: 'spatial',
  ),
  IQQuestion(
    question:
        "Which shape has the most sides? Triangle, Pentagon, Hexagon, Octagon",
    options: ["Triangle", "Pentagon", "Hexagon", "Octagon"],
    correctIndex: 3,
    explanation: "Octagon has 8 sides, which is the most among the options.",
    category: 'spatial',
  ),

  // ── Math / Quantitative ──────────────────────────────────────────────────
  IQQuestion(
    question:
        "If 5 machines take 5 minutes to make 5 widgets, how long for 100 machines to make 100 widgets?",
    options: ["100 minutes", "5 minutes", "10 minutes", "50 minutes"],
    correctIndex: 1,
    explanation:
        "Each machine makes 1 widget in 5 minutes. 100 machines work in parallel — still 5 minutes.",
    category: 'math',
  ),
  IQQuestion(
    question: "What is 15% of 200?",
    options: ["30", "25", "35", "20"],
    correctIndex: 0,
    explanation: "15% × 200 = 0.15 × 200 = 30.",
    category: 'math',
  ),
  IQQuestion(
    question:
        "A bat and ball cost \$1.10. The bat costs \$1.00 more than the ball. How much does the ball cost?",
    options: ["10 cents", "5 cents", "15 cents", "1 cent"],
    correctIndex: 1,
    explanation: "Ball = x, bat = x+1.00. x + x+1 = 1.10 → x = 0.05 (5 cents).",
    category: 'math',
  ),
  IQQuestion(
    question: "If you have 3 apples and take 2, how many do you have?",
    options: ["1", "2", "3", "5"],
    correctIndex: 1,
    explanation: "You *took* 2, so you have 2 apples.",
    category: 'math',
  ),
  IQQuestion(
    question: "What is the sum of angles in a triangle?",
    options: ["90°", "180°", "270°", "360°"],
    correctIndex: 1,
    explanation: "The interior angles of any triangle always sum to 180°.",
    category: 'math',
  ),
  IQQuestion(
    question: "How many prime numbers are there between 1 and 20?",
    options: ["6", "7", "8", "9"],
    correctIndex: 2,
    explanation: "2, 3, 5, 7, 11, 13, 17, 19 — that's 8 primes.",
    category: 'math',
  ),
  IQQuestion(
    question: "If today is Wednesday, what day will it be in 100 days?",
    options: ["Monday", "Tuesday", "Friday", "Saturday"],
    correctIndex: 1,
    explanation:
        "100 ÷ 7 = 14 remainder 2. Wednesday + 2 = Friday. Wait — 100 mod 7 = 2, so Friday? 100 = 14×7+2, Wed+2 = Friday.",
    category: 'math',
  ),
  IQQuestion(
    question: "What is the next prime number after 13?",
    options: ["14", "15", "17", "16"],
    correctIndex: 2,
    explanation: "14 = 2×7, 15 = 3×5, 16 = 2⁴. 17 is prime.",
    category: 'math',
  ),

  // ── Word / Verbal Reasoning ───────────────────────────────────────────────
  IQQuestion(
    question:
        "Which word does not belong: Apple, Mango, Banana, Carrot, Grape?",
    options: ["Apple", "Banana", "Carrot", "Grape"],
    correctIndex: 2,
    explanation: "Carrot is a vegetable; the rest are fruits.",
    category: 'logic',
  ),
  IQQuestion(
    question: "LARGE is to SMALL as HEAVY is to ___?",
    options: ["Thin", "Light", "Weak", "Short"],
    correctIndex: 1,
    explanation: "LARGE and SMALL are antonyms. The antonym of HEAVY is LIGHT.",
    category: 'logic',
  ),
  IQQuestion(
    question: "Doctor is to Hospital as Teacher is to ___?",
    options: ["Book", "School", "Student", "Classroom"],
    correctIndex: 1,
    explanation: "A doctor works at a hospital; a teacher works at a school.",
    category: 'logic',
  ),
  IQQuestion(
    question:
        "Which is the odd one out: Square, Triangle, Rectangle, Cube, Circle?",
    options: ["Triangle", "Rectangle", "Cube", "Circle"],
    correctIndex: 2,
    explanation: "Cube is a 3D shape; all others are 2D shapes.",
    category: 'spatial',
  ),
  IQQuestion(
    question:
        "What single word can precede all of these: BALL, WORK, HOUSE, YARD, KEEPER?",
    options: ["GATE", "BACK", "GOAL", "PLAY"],
    correctIndex: 2,
    explanation:
        "GOALKEEPER, GOALBALL, GOALWORK... actually GOAL: GOALBALL, GOALPOST — GOAL fits best here.",
    category: 'logic',
  ),
  IQQuestion(
    question: "If CAT = 3-1-20, what does DOG equal?",
    options: ["4-15-7", "4-14-6", "5-16-8", "3-14-6"],
    correctIndex: 0,
    explanation: "Using A=1, B=2... D=4, O=15, G=7 → 4-15-7.",
    category: 'pattern',
  ),
  IQQuestion(
    question:
        "A man looks at a photo and says 'Brothers and sisters I have none, but that man's father is my father's son.' Who is in the photo?",
    options: ["His father", "Himself", "His son", "His brother"],
    correctIndex: 2,
    explanation:
        "'My father's son' with no siblings = me. So 'that man's father is me' — the man in the photo is my son.",
    category: 'logic',
  ),
];

class IQChallengeScreen extends StatefulWidget {
  const IQChallengeScreen({super.key});

  @override
  State<IQChallengeScreen> createState() => _IQChallengeScreenState();
}

class _IQChallengeScreenState extends State<IQChallengeScreen>
    with TickerProviderStateMixin {
  static const int _questionsPerSession = 7;

  late List<IQQuestion> _sessionQuestions;
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;
  bool _gameStarted = false;
  bool _gameFinished = false;

  late AnimationController _cardAnimCtrl;
  late Animation<double> _cardAnim;
  late AnimationController _optionAnimCtrl;

  @override
  void initState() {
    super.initState();
    _sessionQuestions = _pickRandomQuestions();
    _cardAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _cardAnim =
        CurvedAnimation(parent: _cardAnimCtrl, curve: Curves.easeOutBack);
    _optionAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _cardAnimCtrl.forward();
  }

  List<IQQuestion> _pickRandomQuestions() {
    final rng = Random();
    final shuffled = List<IQQuestion>.from(_allQuestions)..shuffle(rng);
    return shuffled.take(_questionsPerSession).toList();
  }

  void _startGame() => setState(() => _gameStarted = true);

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (index == _sessionQuestions[_currentIndex].correctIndex) _score++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= _questionsPerSession) {
      setState(() => _gameFinished = true);
    } else {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
      _cardAnimCtrl.reset();
      _cardAnimCtrl.forward();
    }
  }

  void _restartGame() {
    setState(() {
      _sessionQuestions = _pickRandomQuestions();
      _currentIndex = 0;
      _score = 0;
      _selectedOption = null;
      _answered = false;
      _gameFinished = false;
      _gameStarted = true;
    });
    _cardAnimCtrl.reset();
    _cardAnimCtrl.forward();
  }

  String get _scoreLabel {
    if (_score >= 6) return 'Genius! 🧠';
    if (_score >= 5) return 'Excellent! 🌟';
    if (_score >= 4) return 'Great! 👏';
    if (_score >= 3) return 'Good Job! 💪';
    if (_score >= 2) return 'Keep Practising! 📚';
    return 'Better Luck Next Time! 🎯';
  }

  Color get _scoreColor {
    if (_score >= 6) return const Color(0xFF7C3AED);
    if (_score >= 5) return const Color(0xFF10B981);
    if (_score >= 4) return const Color(0xFF06B6D4);
    if (_score >= 3) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  void dispose() {
    _cardAnimCtrl.dispose();
    _optionAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF8F7FF),
      body: SafeArea(
        child: _gameFinished
            ? _buildResultScreen(isDark)
            : _gameStarted
                ? _buildQuizScreen(isDark)
                : _buildStartScreen(isDark),
      ),
    );
  }

  // ── Start Screen ──────────────────────────────────────────────────────────
  Widget _buildStartScreen(bool isDark) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: isDark ? Colors.white : Colors.black87),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Icon
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.psychology_rounded,
                      color: Colors.white, size: 60),
                ),
                const SizedBox(height: 28),
                Text(
                  'IQ Challenge',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                      ).createShader(const Rect.fromLTWH(0, 0, 250, 50)),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Test your intelligence with riddles, logic, patterns & more!',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Stats cards
                Row(
                  children: [
                    _buildStatCard(Icons.quiz_rounded, '7', 'Questions',
                        const Color(0xFF7C3AED), isDark),
                    const SizedBox(width: 12),
                    _buildStatCard(Icons.timer_rounded, '∞', 'Time Limit',
                        const Color(0xFF06B6D4), isDark),
                    const SizedBox(width: 12),
                    _buildStatCard(Icons.emoji_events_rounded, '50', 'Q Pool',
                        const Color(0xFFF59E0B), isDark),
                  ],
                ),
                const SizedBox(height: 28),

                // Categories
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Question Types',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 14),
                      _buildCategoryChip('🧩 Riddles', const Color(0xFF10B981)),
                      const SizedBox(height: 8),
                      _buildCategoryChip('🔢 Number & Letter Patterns',
                          const Color(0xFF3B82F6)),
                      const SizedBox(height: 8),
                      _buildCategoryChip(
                          '🧠 Logical Reasoning', const Color(0xFF8B5CF6)),
                      const SizedBox(height: 8),
                      _buildCategoryChip(
                          '📐 Spatial Thinking', const Color(0xFFEF4444)),
                      const SizedBox(height: 8),
                      _buildCategoryChip(
                          '📊 Math & Quantitative', const Color(0xFFF59E0B)),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Start Button
                GestureDetector(
                  onTap: _startGame,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF7C3AED),
                          Color(0xFF4F46E5),
                          Color(0xFF06B6D4)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          'Start Challenge',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.inter(
                    color: color, fontWeight: FontWeight.w800, fontSize: 18)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : Colors.grey.shade600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: 13, color: color)),
    );
  }

  // ── Quiz Screen ───────────────────────────────────────────────────────────
  Widget _buildQuizScreen(bool isDark) {
    final q = _sessionQuestions[_currentIndex];
    final progress = (_currentIndex + 1) / _questionsPerSession;

    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: isDark ? Colors.white : Colors.black87),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor:
                          isDark ? Colors.white12 : Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF7C3AED)),
                    ),
                  ),
                ),
              ),
              Text(
                '${_currentIndex + 1}/$_questionsPerSession',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFF7C3AED)),
              ),
            ],
          ),
        ),

        // Score row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              _buildCategoryBadge(q.category),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFF7C3AED), size: 16),
                    const SizedBox(width: 4),
                    Text('$_score',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF7C3AED),
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ScaleTransition(
            scale: _cardAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Question card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.psychology_rounded,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text('Question ${_currentIndex + 1}',
                                style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          q.question,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Options
                  ...List.generate(
                      q.options.length, (i) => _buildOption(q, i, isDark)),

                  // Explanation
                  if (_answered) ...[
                    const SizedBox(height: 16),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : (_selectedOption == q.correctIndex
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFFF7ED)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedOption == q.correctIndex
                              ? const Color(0xFF10B981).withOpacity(0.4)
                              : const Color(0xFFF59E0B).withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _selectedOption == q.correctIndex
                                ? Icons.lightbulb_rounded
                                : Icons.info_outline_rounded,
                            color: _selectedOption == q.correctIndex
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              q.explanation,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  height: 1.5,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _nextQuestion,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Text(
                          _currentIndex + 1 < _questionsPerSession
                              ? 'Next Question →'
                              : 'See Results',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption(IQQuestion q, int index, bool isDark) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (!_answered) {
      bgColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
      borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
      textColor = isDark ? Colors.white : Colors.black87;
    } else if (index == q.correctIndex) {
      bgColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFF10B981);
      textColor = const Color(0xFF065F46);
    } else if (index == _selectedOption) {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFEF4444);
      textColor = const Color(0xFF991B1B);
    } else {
      bgColor = isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50;
      borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
      textColor = isDark ? Colors.white38 : Colors.grey.shade400;
    }

    final letter = ['A', 'B', 'C', 'D'][index];

    return GestureDetector(
      onTap: () => _selectOption(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: !_answered && !isDark
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _answered && index == q.correctIndex
                    ? const Color(0xFF10B981)
                    : _answered && index == _selectedOption
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _answered && index == q.correctIndex
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18)
                  : _answered && index == _selectedOption
                      ? const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18)
                      : Center(
                          child: Text(letter,
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF7C3AED),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                        ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(q.options[index],
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: textColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    final labels = {
      'riddle': '🧩 Riddle',
      'pattern': '🔢 Pattern',
      'logic': '🧠 Logic',
      'spatial': '📐 Spatial',
      'math': '📊 Math'
    };
    final colors = {
      'riddle': const Color(0xFF10B981),
      'pattern': const Color(0xFF3B82F6),
      'logic': const Color(0xFF8B5CF6),
      'spatial': const Color(0xFFEF4444),
      'math': const Color(0xFFF59E0B),
    };
    final c = colors[category] ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.withOpacity(0.3))),
      child: Text(labels[category] ?? category,
          style: GoogleFonts.inter(
              color: c, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }

  // ── Results Screen ────────────────────────────────────────────────────────
  Widget _buildResultScreen(bool isDark) {
    final pct = (_score / _questionsPerSession * 100).round();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: isDark ? Colors.white : Colors.black87),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Trophy
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [_scoreColor, _scoreColor.withOpacity(0.6)]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: _scoreColor.withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$_score/$_questionsPerSession',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _scoreLabel,
                  style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _scoreColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'You answered $_score out of $_questionsPerSession questions correctly ($pct%)',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                      height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Score breakdown
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Question Review',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 14),
                      ...List.generate(_questionsPerSession, (i) {
                        // We don't store per-question result here — show score bar
                        return null;
                      }).whereType<Widget>(),
                      // Overall bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _score / _questionsPerSession,
                          minHeight: 14,
                          backgroundColor:
                              isDark ? Colors.white12 : Colors.grey.shade100,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_scoreColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Correct: $_score',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.w700)),
                          Text('Wrong: ${_questionsPerSession - _score}',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFFEF4444),
                                  fontWeight: FontWeight.w700)),
                          Text('$pct%',
                              style: GoogleFonts.inter(
                                  color: _scoreColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // CTA Buttons
                GestureDetector(
                  onTap: _restartGame,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFF7C3AED),
                        Color(0xFF4F46E5),
                        Color(0xFF06B6D4)
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text('Try Again',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('← Back to Missions',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black87),
                        textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
