import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: kSurface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const JEEApp());
}

// ════════════════════════════════════════════════════════════
//  DESIGN SYSTEM
// ════════════════════════════════════════════════════════════
const kBg = Color(0xFF0A0B0F);
const kSurface = Color(0xFF141821);
const kSurfaceHi = Color(0xFF1C212C);
const kStroke = Color(0xFF262C38);
const kAccent = Color(0xFFFF6B4A); // warm coral
const kAccentDim = Color(0xFF3A2420);
const kGold = Color(0xFFFFB02E);
const kGreen = Color(0xFF2DD4A7);
const kRed = Color(0xFFFF5A6E);
const kBlue = Color(0xFF4F9DFF);
const kViolet = Color(0xFFA78BFA);
const kText = Color(0xFFF1F4F9);
const kText2 = Color(0xFF99A2B2);
const kText3 = Color(0xFF5A6478);

// Subject identity colors
const kPhysics = Color(0xFF4F9DFF);
const kChemistry = Color(0xFF2DD4A7);
const kMaths = Color(0xFFFFB02E);
const kSubjectColors = [kPhysics, kChemistry, kMaths];
const kSubjectIcons = [
  Icons.bolt_rounded,
  Icons.science_rounded,
  Icons.functions_rounded,
];

// ════════════════════════════════════════════════════════════
//  STATIC DATA
// ════════════════════════════════════════════════════════════
const Map<String, List<String>> kSubjectChapters = {
  'Physics': [
    'Kinematics', 'Laws of Motion', 'Work Energy Power', 'Rotational Motion',
    'Gravitation', 'Properties of Matter', 'Thermodynamics', 'Kinetic Theory',
    'Oscillations', 'Waves', 'Electrostatics', 'Current Electricity',
    'Magnetic Effects', 'Electromagnetic Induction', 'Alternating Current',
    'Optics', 'Modern Physics', 'Semiconductors',
  ],
  'Chemistry': [
    'Mole Concept', 'Atomic Structure', 'Periodic Table', 'Chemical Bonding',
    'States of Matter', 'Thermodynamics', 'Equilibrium', 'Redox Reactions',
    'Hydrogen', 's-Block Elements', 'p-Block Elements', 'd-Block Elements',
    'Coordination Compounds', 'Organic Basics', 'Hydrocarbons',
    'Halogen Derivatives', 'Alcohol Phenol Ether', 'Carbonyl Compounds',
    'Amines', 'Biomolecules', 'Polymers', 'Electrochemistry',
    'Chemical Kinetics', 'Surface Chemistry',
  ],
  'Maths': [
    'Sets Relations Functions', 'Complex Numbers', 'Quadratic Equations',
    'Sequences & Series', 'Permutations & Combinations', 'Binomial Theorem',
    'Matrices & Determinants', 'Straight Lines', 'Circles', 'Conic Sections',
    '3D Geometry', 'Vectors', 'Limits & Continuity', 'Differentiation',
    'Applications of Derivatives', 'Integration', 'Differential Equations',
    'Probability', 'Statistics', 'Trigonometry', 'Inverse Trig',
    'Mathematical Reasoning',
  ],
};

const List<List<String>> kQuotes = [
  ['The secret of getting ahead is getting started.', 'Mark Twain'],
  ['It does not matter how slowly you go as long as you do not stop.', 'Confucius'],
  ['Hard work beats talent when talent doesn\'t work hard.', 'Tim Notke'],
  ['Don\'t stop when you\'re tired. Stop when you\'re done.', 'Unknown'],
  ['One day or day one. You decide.', 'Unknown'],
  ['The harder you work for something, the greater you\'ll feel when you achieve it.', 'Unknown'],
  ['Success is the sum of small efforts repeated day in and day out.', 'Robert Collier'],
  ['A year from now you may wish you had started today.', 'Karen Lamb'],
  ['Push yourself, because no one else is going to do it for you.', 'Unknown'],
  ['Great things never come from comfort zones.', 'Unknown'],
  ['Be stronger than your excuses.', 'Unknown'],
  ['Doubt kills more dreams than failure ever will.', 'Suzy Kassem'],
  ['You don\'t get what you wish for. You get what you work for.', 'Unknown'],
  ['Sometimes later becomes never. Do it now.', 'Unknown'],
  ['Every champion was once a contender that refused to give up.', 'Unknown'],
];

// ════════════════════════════════════════════════════════════
//  DATA MODEL  (unchanged — preserves saved progress)
// ════════════════════════════════════════════════════════════
class Chapter {
  String name;
  bool done;
  String priority;
  Chapter({required this.name, this.done = false, this.priority = 'med'});
  Chapter.fromJson(Map<String, dynamic> j)
      : name = j['name'] ?? '',
        done = j['done'] ?? false,
        priority = j['priority'] ?? 'med';
  Map<String, dynamic> toJson() => {'name': name, 'done': done, 'priority': priority};
}

class Task {
  String text;
  bool done;
  Task({required this.text, this.done = false});
  Task.fromJson(Map<String, dynamic> j)
      : text = j['text'] ?? '',
        done = j['done'] ?? false;
  Map<String, dynamic> toJson() => {'text': text, 'done': done};
}

class AppModel {
  String name;
  String startDate;
  String targetDate;
  Set<String> completedDays;
  Map<String, List<Task>> dailyTasks;
  Map<String, List<int>> studyMinutes;
  Map<String, List<Chapter>> subjects;
  Map<String, Map<String, String>> monthlyPlans; // "YYYY-MM" -> {subject -> plan text}

  AppModel({
    this.name = 'JEE Aspirant',
    String? startDate,
    this.targetDate = '2027-05-25',
    Set<String>? completedDays,
    Map<String, List<Task>>? dailyTasks,
    Map<String, List<int>>? studyMinutes,
    Map<String, List<Chapter>>? subjects,
    Map<String, Map<String, String>>? monthlyPlans,
  })  : startDate = startDate ?? _dateStr(DateTime.now()),
        completedDays = completedDays ?? {},
        dailyTasks = dailyTasks ?? {},
        studyMinutes = studyMinutes ?? {},
        subjects = subjects ?? _defaultSubjects(),
        monthlyPlans = monthlyPlans ?? {};

  static Map<String, List<Chapter>> _defaultSubjects() {
    return kSubjectChapters.map((s, chapters) => MapEntry(
      s, chapters.map((c) => Chapter(name: c)).toList(),
    ));
  }

  String dateForDay(int i) {
    final d = DateTime.parse(startDate).add(Duration(days: i));
    return _dateStr(d);
  }

  int get currentDayIndex {
    final now = DateTime.now();
    final start = DateTime.parse(startDate);
    return now.difference(DateTime(start.year, start.month, start.day)).inDays;
  }

  int get totalDone => completedDays.length;

  int get streak {
    int s = 0;
    DateTime d = DateTime.now();
    while (true) {
      final k = _dateStr(d);
      if (completedDays.contains(k)) {
        s++;
        d = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return s;
  }

  int get totalStudyMins =>
      studyMinutes.values.fold(0, (a, v) => a + v.fold(0, (x, y) => x + y));

  int get totalChapters =>
      subjects.values.fold(0, (a, v) => a + v.length);
  int get doneChapters =>
      subjects.values.fold(0, (a, v) => a + v.where((c) => c.done).length);

  Map<String, dynamic> toJson() => {
        'name': name,
        'startDate': startDate,
        'targetDate': targetDate,
        'completedDays': completedDays.toList(),
        'dailyTasks': dailyTasks.map((k, v) => MapEntry(k, v.map((t) => t.toJson()).toList())),
        'studyMinutes': studyMinutes,
        'subjects': subjects.map((k, v) => MapEntry(k, v.map((c) => c.toJson()).toList())),
        'monthlyPlans': monthlyPlans,
      };

  factory AppModel.fromJson(Map<String, dynamic> j) {
    Map<String, List<Chapter>> subs = _defaultSubjects();
    if (j['subjects'] != null) {
      subs = (j['subjects'] as Map<String, dynamic>).map((k, v) => MapEntry(
        k,
        (v as List).map((e) => Chapter.fromJson(e as Map<String, dynamic>)).toList(),
      ));
    }
    return AppModel(
      name: j['name'] ?? 'JEE Aspirant',
      startDate: j['startDate'],
      targetDate: j['targetDate'] ?? '2027-05-25',
      completedDays: (j['completedDays'] as List?)?.map((e) => e as String).toSet() ?? {},
      dailyTasks: (j['dailyTasks'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(
        k, (v as List).map((e) => Task.fromJson(e as Map<String, dynamic>)).toList(),
      )) ?? {},
      studyMinutes: (j['studyMinutes'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(
        k, (v as List).cast<int>(),
      )) ?? {},
      subjects: subs,
      monthlyPlans: (j['monthlyPlans'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(
        k, (v as Map<String, dynamic>).map((sk, sv) => MapEntry(sk, sv as String)),
      )) ?? {},
    );
  }

  static Future<AppModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('jee_data');
    if (s == null) return AppModel();
    try {
      return AppModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return AppModel();
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jee_data', jsonEncode(toJson()));
  }
}

// ════════════════════════════════════════════════════════════
//  APP ROOT
// ════════════════════════════════════════════════════════════
class JEEApp extends StatefulWidget {
  const JEEApp({super.key});
  @override
  State<JEEApp> createState() => _JEEAppState();
}

class _JEEAppState extends State<JEEApp> {
  AppModel? _model;

  @override
  void initState() {
    super.initState();
    AppModel.load().then((m) => setState(() => _model = m));
  }

  void _onChanged() {
    _model!.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '180 Days · JEE 2027',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: kAccent,
          secondary: kGold,
          surface: kSurface,
        ),
        splashColor: kAccent.withOpacity(0.06),
        highlightColor: Colors.transparent,
      ),
      home: _model == null
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2)))
          : MainScreen(model: _model!, onChanged: _onChanged),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ════════════════════════════════════════════════════════════

/// Circular progress ring with a soft glow.
class ProgressRing extends StatelessWidget {
  final double progress; // 0..1
  final double size;
  final double stroke;
  final Color color;
  final Widget? child;
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 200,
    this.stroke = 13,
    this.color = kAccent,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: progress.clamp(0, 1), color: color, stroke: stroke),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double stroke;
  _RingPainter({required this.progress, required this.color, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final track = Paint()
      ..color = kStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress;
    const start = -math.pi / 2;

    // Glow
    final glow = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(rect, start, sweep, false, glow);

    // Arc
    final arc = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [color.withOpacity(0.55), color],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.stroke != stroke;
}

/// Standard surface card.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kStroke, width: 1),
      ),
      child: child,
    );
  }
}

Widget sectionLabel(String text) => Padding(
  padding: const EdgeInsets.only(left: 4, bottom: 10),
  child: Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700, color: kText3, letterSpacing: 1.5),
  ),
);

// ════════════════════════════════════════════════════════════
//  MAIN SCREEN  (nav shell)
// ════════════════════════════════════════════════════════════
class MainScreen extends StatefulWidget {
  final AppModel model;
  final VoidCallback onChanged;
  const MainScreen({super.key, required this.model, required this.onChanged});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(model: widget.model, onChanged: widget.onChanged),
      TrackerScreen(model: widget.model, onChanged: widget.onChanged),
      SubjectsScreen(model: widget.model, onChanged: widget.onChanged),
      PlannerScreen(model: widget.model, onChanged: widget.onChanged),
      SettingsScreen(model: widget.model, onChanged: widget.onChanged),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kSurface,
          border: Border(top: BorderSide(color: kStroke, width: 1)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: kAccentDim,
            labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: s.contains(WidgetState.selected) ? kAccent : kText3,
            )),
            iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 24,
              color: s.contains(WidgetState.selected) ? kAccent : kText3,
            )),
          ),
          child: NavigationBar(
            height: 66,
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.calendar_view_month_outlined), selectedIcon: Icon(Icons.calendar_view_month_rounded), label: 'Tracker'),
              NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Subjects'),
              NavigationDestination(icon: Icon(Icons.edit_calendar_outlined), selectedIcon: Icon(Icons.edit_calendar_rounded), label: 'Planner'),
              NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune_rounded), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  HOME
// ════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  final AppModel model;
  final VoidCallback onChanged;
  const HomeScreen({super.key, required this.model, required this.onChanged});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  void _tick() {
    final target = DateTime.parse(widget.model.targetDate);
    setState(() => _remaining = target.difference(DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final today = _dateStr(DateTime.now());
    final dayNum = (m.currentDayIndex + 1).clamp(1, 180);
    final isDone = m.completedDays.contains(today);
    final quote = kQuotes[DateTime.now().day % kQuotes.length];
    final progress = m.totalDone / 180;
    final firstLetter = (m.name.isNotEmpty ? m.name[0] : 'J').toUpperCase();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // ── Greeting row ──
          Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [kAccent, kGold]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(firstLetter,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting, style: const TextStyle(fontSize: 13, color: kText3)),
                    Text(m.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
                  ],
                ),
              ),
              _flameChip(m.streak),
            ],
          ),
          const SizedBox(height: 22),

          // ── Hero ring ──
          Center(
            child: ProgressRing(
              progress: progress,
              size: 230,
              stroke: 15,
              color: kAccent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('DAY', style: TextStyle(fontSize: 12, color: kText3, letterSpacing: 4, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('$dayNum',
                      style: const TextStyle(fontSize: 68, fontWeight: FontWeight.w800, color: kText, height: 1)),
                  Text('of 180',
                      style: TextStyle(fontSize: 14, color: kText2, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: kAccentDim,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('${(progress * 100).round()}% complete',
                        style: const TextStyle(fontSize: 12, color: kAccent, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Countdown strip ──
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: kAccentDim, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.flag_rounded, color: kAccent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('JEE 2027 countdown',
                          style: TextStyle(fontSize: 12, color: kText3, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          _cdUnit('${_remaining.inDays}', 'd'),
                          const SizedBox(width: 8),
                          _cdUnit('${_remaining.inHours % 24}', 'h'),
                          const SizedBox(width: 8),
                          _cdUnit('${_remaining.inMinutes % 60}', 'm'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Stat chips ──
          Row(
            children: [
              _statTile(Icons.local_fire_department_rounded, kAccent, '${m.streak}', 'Streak'),
              const SizedBox(width: 12),
              _statTile(Icons.task_alt_rounded, kGreen, '${m.totalDone}', 'Days done'),
              const SizedBox(width: 12),
              _statTile(Icons.menu_book_rounded, kBlue, '${m.doneChapters}', 'Chapters'),
            ],
          ),
          const SizedBox(height: 22),

          // ── Quote ──
          sectionLabel('Daily fuel'),
          Panel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote_rounded, color: kAccent.withOpacity(0.7), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(quote[0],
                          style: const TextStyle(fontSize: 15, color: kText, height: 1.5, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text('— ${quote[1]}',
                          style: const TextStyle(fontSize: 12, color: kText3, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── CTA ──
          _ctaButton(isDone, today),
        ],
      ),
    );
  }

  Widget _flameChip(int streak) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: kSurfaceHi,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: kStroke),
    ),
    child: Row(
      children: [
        const Icon(Icons.local_fire_department_rounded, color: kAccent, size: 18),
        const SizedBox(width: 5),
        Text('$streak', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText)),
      ],
    ),
  );

  Widget _cdUnit(String v, String u) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(v, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kText, fontFeatures: [FontFeature.tabularFigures()])),
      Text(u, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText3)),
    ],
  );

  Widget _statTile(IconData icon, Color c, String v, String l) => Expanded(
    child: Panel(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: c, size: 24),
          const SizedBox(height: 8),
          Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText)),
          Text(l, style: const TextStyle(fontSize: 11, color: kText3, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );

  Widget _ctaButton(bool isDone, String today) => GestureDetector(
    onTap: () {
      if (isDone) {
        widget.model.completedDays.remove(today);
      } else {
        widget.model.completedDays.add(today);
      }
      widget.onChanged();
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: isDone ? null : const LinearGradient(colors: [kAccent, Color(0xFFFF8A5B)]),
        color: isDone ? kSurfaceHi : null,
        borderRadius: BorderRadius.circular(18),
        border: isDone ? Border.all(color: kGreen, width: 1.5) : null,
        boxShadow: isDone ? null : [BoxShadow(color: kAccent.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isDone ? kGreen : Colors.white, size: 22),
          const SizedBox(width: 10),
          Text(
            isDone ? 'Completed today — tap to undo' : 'Mark today complete',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: isDone ? kGreen : Colors.white),
          ),
        ],
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  TRACKER
// ════════════════════════════════════════════════════════════
class TrackerScreen extends StatelessWidget {
  final AppModel model;
  final VoidCallback onChanged;
  const TrackerScreen({super.key, required this.model, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final today = _dateStr(DateTime.now());
    final done = model.totalDone;
    final pct = done / 180;
    final cols = MediaQuery.of(context).size.width > 500 ? 20 : 12;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Your 180 days',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 4),
          Text('Tap any day up to today to log it',
              style: TextStyle(fontSize: 13, color: kText3)),
          const SizedBox(height: 18),

          // Progress header
          Panel(
            child: Column(
              children: [
                Row(
                  children: [
                    _miniStat('$done', 'Done', kGreen),
                    Container(width: 1, height: 34, color: kStroke),
                    _miniStat('${180 - done}', 'Remaining', kText2),
                    Container(width: 1, height: 34, color: kStroke),
                    _miniStat('${(pct * 100).round()}%', 'Progress', kAccent),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct, minHeight: 8,
                    backgroundColor: kStroke,
                    valueColor: const AlwaysStoppedAnimation(kAccent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Grid
          Panel(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
              ),
              itemCount: 180,
              itemBuilder: (ctx, i) {
                final date = model.dateForDay(i);
                final isDone = model.completedDays.contains(date);
                final isToday = date == today;
                final isPast = date.compareTo(today) < 0;

                Color bg;
                if (isDone) {
                  bg = kGreen;
                } else if (isPast) {
                  bg = kRed.withOpacity(0.18);
                } else {
                  bg = kSurfaceHi;
                }

                return GestureDetector(
                  onTap: () {
                    if (date.compareTo(today) > 0) return;
                    if (isDone) {
                      model.completedDays.remove(date);
                    } else {
                      model.completedDays.add(date);
                    }
                    onChanged();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(6),
                      border: isToday ? Border.all(color: kGold, width: 2) : null,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isDone ? Colors.white.withOpacity(0.85) : kText3,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Legend
          Wrap(
            spacing: 18, runSpacing: 10,
            children: [
              _legend(kGreen, 'Completed'),
              _legend(kRed.withOpacity(0.18), 'Missed'),
              _legend(kSurfaceHi, 'Upcoming'),
              _legendToday(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String v, String l, Color c) => Expanded(
    child: Column(
      children: [
        Text(v, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c)),
        const SizedBox(height: 2),
        Text(l, style: const TextStyle(fontSize: 11, color: kText3, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _legend(Color c, String l) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 14, height: 14, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 7),
      Text(l, style: const TextStyle(fontSize: 12, color: kText2)),
    ],
  );

  Widget _legendToday() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14, height: 14,
        decoration: BoxDecoration(
          color: kSurfaceHi, borderRadius: BorderRadius.circular(4),
          border: Border.all(color: kGold, width: 2),
        ),
      ),
      const SizedBox(width: 7),
      const Text('Today', style: TextStyle(fontSize: 12, color: kText2)),
    ],
  );
}

// ════════════════════════════════════════════════════════════
//  SUBJECTS
// ════════════════════════════════════════════════════════════
class SubjectsScreen extends StatefulWidget {
  final AppModel model;
  final VoidCallback onChanged;
  const SubjectsScreen({super.key, required this.model, required this.onChanged});
  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final Set<int> _expanded = {0};

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final subjectNames = m.subjects.keys.toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Syllabus',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 4),
          Text('${m.doneChapters} of ${m.totalChapters} chapters mastered',
              style: const TextStyle(fontSize: 13, color: kText3)),
          const SizedBox(height: 18),

          // Three rings overview
          Panel(
            child: Row(
              children: List.generate(subjectNames.length, (i) {
                final chapters = m.subjects[subjectNames[i]]!;
                final done = chapters.where((c) => c.done).length;
                final p = chapters.isEmpty ? 0.0 : done / chapters.length;
                return Expanded(
                  child: Column(
                    children: [
                      ProgressRing(
                        progress: p, size: 70, stroke: 7, color: kSubjectColors[i],
                        child: Text('${(p * 100).round()}',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kText)),
                      ),
                      const SizedBox(height: 8),
                      Text(subjectNames[i],
                          style: const TextStyle(fontSize: 12, color: kText2, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 18),

          ...List.generate(subjectNames.length, (si) => _subjectCard(si, subjectNames[si])),
        ],
      ),
    );
  }

  Widget _subjectCard(int si, String name) {
    final chapters = widget.model.subjects[name]!;
    final done = chapters.where((c) => c.done).length;
    final pct = chapters.isEmpty ? 0.0 : done / chapters.length;
    final color = kSubjectColors[si];
    final isOpen = _expanded.contains(si);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        children: [
          // Header (tap to expand)
          GestureDetector(
            onTap: () => setState(() => isOpen ? _expanded.remove(si) : _expanded.add(si)),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(kSubjectIcons[si], color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kText)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: pct, minHeight: 6,
                                  backgroundColor: kStroke,
                                  valueColor: AlwaysStoppedAnimation(color),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('$done/${chapters.length}',
                                style: const TextStyle(fontSize: 12, color: kText3, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: kText3),
                  ),
                ],
              ),
            ),
          ),
          // Chapter list
          if (isOpen) ...[
            const Divider(height: 1, color: kStroke),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Column(
                children: [
                  ...chapters.asMap().entries.map((e) => _chapterRow(chapters, e.key, e.value, color)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _addChapter(context, name, chapters),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, size: 18, color: color),
                          const SizedBox(width: 6),
                          Text('Add chapter',
                              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chapterRow(List<Chapter> chapters, int idx, Chapter ch, Color subjColor) {
    final pColor = ch.priority == 'high' ? kRed : ch.priority == 'low' ? kGreen : kGold;
    void remove() {
      setState(() => chapters.remove(ch));
      widget.onChanged();
    }
    return Dismissible(
      key: ObjectKey(ch),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => remove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: kRed.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline_rounded, color: kRed, size: 20),
      ),
      child: GestureDetector(
        onTap: () { setState(() => ch.done = !ch.done); widget.onChanged(); },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: ch.done ? subjColor : Colors.transparent,
                  border: Border.all(color: ch.done ? subjColor : kText3, width: 2),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: ch.done ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(ch.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: ch.done ? kText3 : kText,
                      decoration: ch.done ? TextDecoration.lineThrough : null,
                      decorationColor: kText3,
                    )),
              ),
              Container(width: 7, height: 7, decoration: BoxDecoration(color: pColor, shape: BoxShape.circle)),
              GestureDetector(
                onTap: remove,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Icon(Icons.close_rounded, size: 18, color: kText3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addChapter(BuildContext ctx, String subject, List<Chapter> chapters) {
    final ctrl = TextEditingController();
    String priority = 'med';
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx2).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 38, height: 4, decoration: BoxDecoration(color: kStroke, borderRadius: BorderRadius.circular(99))),
              ),
              const SizedBox(height: 20),
              Text('Add chapter to $subject',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kText)),
              const SizedBox(height: 16),
              _sheetField(ctrl, 'Chapter name'),
              const SizedBox(height: 14),
              const Text('Priority', style: TextStyle(fontSize: 12, color: kText3, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _prioChip('High', 'high', priority, kRed, (v) => setS(() => priority = v)),
                  const SizedBox(width: 8),
                  _prioChip('Medium', 'med', priority, kGold, (v) => setS(() => priority = v)),
                  const SizedBox(width: 8),
                  _prioChip('Low', 'low', priority, kGreen, (v) => setS(() => priority = v)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final n = ctrl.text.trim();
                    if (n.isEmpty) return;
                    chapters.add(Chapter(name: n, priority: priority));
                    widget.onChanged();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add chapter', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _prioChip(String label, String val, String sel, Color c, ValueChanged<String> onTap) => Expanded(
    child: GestureDetector(
      onTap: () => onTap(val),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: sel == val ? c.withOpacity(0.16) : kSurfaceHi,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel == val ? c : kStroke, width: 1.5),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel == val ? c : kText2)),
        ),
      ),
    ),
  );
}

Widget _sheetField(TextEditingController ctrl, String hint) => TextField(
  controller: ctrl,
  autofocus: true,
  style: const TextStyle(color: kText, fontSize: 15),
  cursorColor: kAccent,
  decoration: InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: kText3),
    filled: true,
    fillColor: kSurfaceHi,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kStroke)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kAccent, width: 1.5)),
  ),
);

// ════════════════════════════════════════════════════════════
//  FOCUS / TASKS
// ════════════════════════════════════════════════════════════
class PlannerScreen extends StatefulWidget {
  final AppModel model;
  final VoidCallback onChanged;
  const PlannerScreen({super.key, required this.model, required this.onChanged});
  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final _ctrl = TextEditingController();
  final Map<String, TextEditingController> _planCtrls = {};
  final Set<String> _openMonths = {};

  static const _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  String get _today => _dateStr(DateTime.now());

  List<DateTime> _months() {
    final start = DateTime.parse(widget.model.startDate);
    final target = DateTime.parse(widget.model.targetDate);
    final months = <DateTime>[];
    var d = DateTime(start.year, start.month);
    final end = DateTime(target.year, target.month);
    while (!d.isAfter(end)) {
      months.add(d);
      d = DateTime(d.year, d.month + 1);
    }
    return months;
  }

  String _monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  TextEditingController _planCtrl(String monthKey, String subject) {
    return _planCtrls.putIfAbsent('$monthKey|$subject',
        () => TextEditingController(text: widget.model.monthlyPlans[monthKey]?[subject] ?? ''));
  }

  void _savePlan(String monthKey, String subject, String text) {
    widget.model.monthlyPlans.putIfAbsent(monthKey, () => {});
    widget.model.monthlyPlans[monthKey]![subject] = text;
    widget.model.save();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _openMonths.add('${now.year}-${now.month.toString().padLeft(2, '0')}');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    for (final c in _planCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.model.dailyTasks[_today] ?? [];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Planner',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 4),
          const Text('Plan each month and your day',
              style: TextStyle(fontSize: 13, color: kText3)),
          const SizedBox(height: 20),

          // Tasks
          Row(
            children: [
              sectionLabel('Today\'s tasks'),
              const Spacer(),
              if (tasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, right: 4),
                  child: Text('${tasks.where((t) => t.done).length}/${tasks.length}',
                      style: const TextStyle(fontSize: 12, color: kText3, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: kText, fontSize: 15),
                  cursorColor: kAccent,
                  decoration: InputDecoration(
                    hintText: 'Add a task…',
                    hintStyle: const TextStyle(color: kText3),
                    filled: true, fillColor: kSurface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kStroke)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kAccent, width: 1.5)),
                  ),
                  onSubmitted: (_) => _addTask(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addTask,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Icon(Icons.checklist_rounded, size: 40, color: kText3.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  const Text('No tasks yet', style: TextStyle(color: kText3, fontSize: 14)),
                ],
              ),
            )
          else
            ...tasks.asMap().entries.map((e) => _taskRow(e.key, e.value)),

          const SizedBox(height: 26),
          sectionLabel('Monthly planner'),
          ..._months().map(_monthCard),
        ],
      ),
    );
  }

  Widget _monthCard(DateTime month) {
    final key = _monthKey(month);
    final isOpen = _openMonths.contains(key);
    final subjects = widget.model.subjects.keys.toList();
    final filled = widget.model.monthlyPlans[key]?.values.where((v) => v.trim().isNotEmpty).length ?? 0;
    final isCurrent = key == '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isCurrent ? kAccent.withOpacity(0.5) : kStroke),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => isOpen ? _openMonths.remove(key) : _openMonths.add(key)),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: kAccentDim, borderRadius: BorderRadius.circular(13)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(month.month.toString().padLeft(2, '0'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kAccent, height: 1)),
                        Text("'${month.year % 100}",
                            style: const TextStyle(fontSize: 10, color: kAccent, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('${_monthNames[month.month]} ${month.year}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: kAccentDim, borderRadius: BorderRadius.circular(99)),
                                child: const Text('NOW',
                                    style: TextStyle(fontSize: 9, color: kAccent, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(filled == 0 ? 'No plan yet' : '$filled of ${subjects.length} subjects planned',
                            style: const TextStyle(fontSize: 12, color: kText3, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: kText3),
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) ...[
            const Divider(height: 1, color: kStroke),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: List.generate(subjects.length, (i) {
                  final subject = subjects[i];
                  final c = kSubjectColors[i % kSubjectColors.length];
                  return Padding(
                    padding: EdgeInsets.only(bottom: i < subjects.length - 1 ? 14 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(kSubjectIcons[i % kSubjectIcons.length], size: 16, color: c),
                            const SizedBox(width: 7),
                            Text(subject,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
                          ],
                        ),
                        const SizedBox(height: 7),
                        TextField(
                          controller: _planCtrl(key, subject),
                          onChanged: (v) => _savePlan(key, subject, v),
                          minLines: 2,
                          maxLines: 6,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(color: kText, fontSize: 14, height: 1.4),
                          cursorColor: c,
                          decoration: InputDecoration(
                            hintText: 'What will you cover in $subject this month?',
                            hintStyle: const TextStyle(color: kText3, fontSize: 13),
                            filled: true,
                            fillColor: kSurfaceHi,
                            contentPadding: const EdgeInsets.all(13),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kStroke)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _taskRow(int idx, Task t) => Dismissible(
    key: Key('task-$idx-${t.text}'),
    direction: DismissDirection.endToStart,
    onDismissed: (_) {
      widget.model.dailyTasks[_today]!.removeAt(idx);
      widget.onChanged();
    },
    background: Container(
      margin: const EdgeInsets.only(bottom: 10),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(color: kRed.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
      child: const Icon(Icons.delete_outline_rounded, color: kRed),
    ),
    child: GestureDetector(
      onTap: () { setState(() => t.done = !t.done); widget.onChanged(); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: kSurface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kStroke),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: t.done ? kGreen : Colors.transparent,
                border: Border.all(color: t.done ? kGreen : kText3, width: 2),
                borderRadius: BorderRadius.circular(7),
              ),
              child: t.done ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(t.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: t.done ? kText3 : kText,
                    decoration: t.done ? TextDecoration.lineThrough : null,
                    decorationColor: kText3,
                  )),
            ),
          ],
        ),
      ),
    ),
  );

  void _addTask() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.model.dailyTasks.putIfAbsent(_today, () => []);
    widget.model.dailyTasks[_today]!.add(Task(text: text));
    _ctrl.clear();
    widget.onChanged();
  }
}

// ════════════════════════════════════════════════════════════
//  SETTINGS
// ════════════════════════════════════════════════════════════
class SettingsScreen extends StatefulWidget {
  final AppModel model;
  final VoidCallback onChanged;
  const SettingsScreen({super.key, required this.model, required this.onChanged});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  late DateTime _startDate;
  late DateTime _targetDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.model.name);
    _startDate = DateTime.parse(widget.model.startDate);
    _targetDate = DateTime.parse(widget.model.targetDate);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.model;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 18),

          sectionLabel('Challenge setup'),
          Panel(
            child: Column(
              children: [
                _fieldRow('Your name', TextField(
                  controller: _nameCtrl,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: kText, fontWeight: FontWeight.w600),
                  cursorColor: kAccent,
                  decoration: const InputDecoration(
                    border: InputBorder.none, isDense: true,
                    hintText: 'Name', hintStyle: TextStyle(color: kText3),
                  ),
                )),
                const Divider(height: 24, color: kStroke),
                _dateRow('Start date', _startDate, (d) => setState(() => _startDate = d)),
                const Divider(height: 24, color: kStroke),
                _dateRow('JEE target date', _targetDate, (d) => setState(() => _targetDate = d)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                m.name = _nameCtrl.text.trim().isEmpty ? 'JEE Aspirant' : _nameCtrl.text.trim();
                m.startDate = _dateStr(_startDate);
                m.targetDate = _dateStr(_targetDate);
                widget.onChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Settings saved'),
                    backgroundColor: kGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: kAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 24),

          sectionLabel('Your stats'),
          Panel(
            child: Column(
              children: [
                _statRow(Icons.task_alt_rounded, kGreen, 'Days completed', '${m.totalDone}'),
                const Divider(height: 22, color: kStroke),
                _statRow(Icons.local_fire_department_rounded, kAccent, 'Current streak', '${m.streak} days'),
                const Divider(height: 22, color: kStroke),
                _statRow(Icons.menu_book_rounded, kViolet, 'Chapters done', '${m.doneChapters}/${m.totalChapters}'),
                const Divider(height: 22, color: kStroke),
                _statRow(Icons.trending_up_rounded, kGold, 'Overall progress', '${(m.totalDone / 180 * 100).round()}%'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: () => _confirmReset(context),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            label: const Text('Reset all data', style: TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: kRed,
              side: const BorderSide(color: kRed, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('180 Days · JEE 2027  ·  v1.1',
                style: TextStyle(fontSize: 12, color: kText3)),
          ),
        ],
      ),
    );
  }

  Widget _fieldRow(String label, Widget field) => Row(
    children: [
      Text(label, style: const TextStyle(fontSize: 15, color: kText2)),
      const Spacer(),
      SizedBox(width: 170, child: field),
    ],
  );

  Widget _dateRow(String label, DateTime value, ValueChanged<DateTime> onPick) => Row(
    children: [
      Text(label, style: const TextStyle(fontSize: 15, color: kText2)),
      const Spacer(),
      GestureDetector(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2024),
            lastDate: DateTime(2030),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.dark(primary: kAccent, surface: kSurface, onSurface: kText),
                dialogBackgroundColor: kSurface,
              ),
              child: child!,
            ),
          );
          if (d != null) onPick(d);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: kSurfaceHi, borderRadius: BorderRadius.circular(10), border: Border.all(color: kStroke)),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: kAccent),
              const SizedBox(width: 7),
              Text(_fmtDate(value), style: const TextStyle(color: kText, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _statRow(IconData icon, Color c, String label, String value) => Row(
    children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: c.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: c, size: 19),
      ),
      const SizedBox(width: 13),
      Text(label, style: const TextStyle(fontSize: 14, color: kText)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 15, color: c, fontWeight: FontWeight.w800)),
    ],
  );

  String _fmtDate(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  void _confirmReset(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset all data?', style: TextStyle(color: kText, fontWeight: FontWeight.w700)),
        content: const Text('This deletes all your progress, tasks and study time. This cannot be undone.',
            style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: kText2))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kRed),
            onPressed: () {
              final m = widget.model;
              m.completedDays.clear();
              m.dailyTasks.clear();
              m.studyMinutes.clear();
              for (final chapters in m.subjects.values) {
                for (final c in chapters) c.done = false;
              }
              widget.onChanged();
              Navigator.pop(ctx);
            },
            child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  UTIL
// ════════════════════════════════════════════════════════════
String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
