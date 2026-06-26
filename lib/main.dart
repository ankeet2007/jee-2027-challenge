import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const JEEApp());
}

// ── COLORS ──
const kBg = Color(0xFF0A0E1A);
const kSurface = Color(0xFF141929);
const kSurface2 = Color(0xFF1E2540);
const kAccent = Color(0xFF6366F1);
const kGold = Color(0xFFF59E0B);
const kGreen = Color(0xFF10B981);
const kRed = Color(0xFFEF4444);
const kBlue = Color(0xFF3B82F6);
const kText = Color(0xFFE2E8F0);
const kText2 = Color(0xFF94A3B8);
const kText3 = Color(0xFF475569);

// ── STATIC DATA ──
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

// ── DATA MODEL ──
class Chapter {
  String name;
  bool done;
  String priority; // 'high' | 'med' | 'low'
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
  Map<String, List<int>> studyMinutes; // date -> [phy, che, mat]
  Map<String, List<Chapter>> subjects;

  AppModel({
    this.name = 'JEE Aspirant',
    String? startDate,
    this.targetDate = '2027-05-25',
    Set<String>? completedDays,
    Map<String, List<Task>>? dailyTasks,
    Map<String, List<int>>? studyMinutes,
    Map<String, List<Chapter>>? subjects,
  })  : startDate = startDate ?? _dateStr(DateTime.now()),
        completedDays = completedDays ?? {},
        dailyTasks = dailyTasks ?? {},
        studyMinutes = studyMinutes ?? {},
        subjects = subjects ?? _defaultSubjects();

  static Map<String, List<Chapter>> _defaultSubjects() {
    return kSubjectChapters.map((s, chapters) => MapEntry(
      s, chapters.map((c) => Chapter(name: c)).toList(),
    ));
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String dateForDay(int i) {
    final d = DateTime.parse(startDate).add(Duration(days: i));
    return _dateStr(d);
  }

  int get currentDayIndex {
    final now = DateTime.now();
    final start = DateTime.parse(startDate);
    return now.difference(start).inDays;
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

  int get totalStudyMins => studyMinutes.values
      .fold(0, (a, v) => a + v.fold(0, (x, y) => x + y));

  Map<String, dynamic> toJson() => {
        'name': name,
        'startDate': startDate,
        'targetDate': targetDate,
        'completedDays': completedDays.toList(),
        'dailyTasks': dailyTasks.map((k, v) => MapEntry(k, v.map((t) => t.toJson()).toList())),
        'studyMinutes': studyMinutes,
        'subjects': subjects.map((k, v) => MapEntry(k, v.map((c) => c.toJson()).toList())),
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

// ── APP ──
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
      title: '180 Days JEE 2027',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(
          primary: kAccent,
          surface: kSurface,
          background: kBg,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: kSurface,
          selectedItemColor: kAccent,
          unselectedItemColor: kText3,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kAccent),
          ),
        ),
      ),
      home: _model == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator(color: kAccent)))
          : MainScreen(model: _model!, onChanged: _onChanged),
    );
  }
}

// ── MAIN SCREEN ──
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
      TasksScreen(model: widget.model, onChanged: widget.onChanged),
      SettingsScreen(model: widget.model, onChanged: widget.onChanged),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Tracker'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Subjects'),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt_rounded), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

// ── HOME SCREEN ──
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

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final today = _dateStr(DateTime.now());
    final dayNum = m.currentDayIndex + 1;
    final isDone = m.completedDays.contains(today);
    final quote = kQuotes[DateTime.now().day % kQuotes.length];
    final totalMins = m.totalStudyMins;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kSurface2, Color(0xFF0D1230)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Day ${dayNum.clamp(1, 180)}',
                    style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: kGold, height: 1),
                  ),
                  const SizedBox(height: 4),
                  const Text('of 180 Days', style: TextStyle(color: kText2, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    '${_fmt(DateTime.parse(m.startDate))} → ${_fmt(DateTime.parse(m.targetDate))}',
                    style: const TextStyle(color: kText3, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Countdown
            Row(children: [
              _cdBox(_remaining.inDays.toString(), 'Days to JEE'),
              const SizedBox(width: 8),
              _cdBox((_remaining.inHours % 24).toString(), 'Hours'),
              const SizedBox(width: 8),
              _cdBox((_remaining.inMinutes % 60).toString(), 'Minutes'),
            ]),
            const SizedBox(height: 8),

            // Stats row
            Row(children: [
              _statBox('🔥', m.streak.toString(), 'Streak'),
              const SizedBox(width: 8),
              _statBox('✅', m.totalDone.toString(), 'Days Done'),
              const SizedBox(width: 8),
              _statBox('⏱', '${totalMins ~/ 60}h', 'Study Time'),
            ]),
            const SizedBox(height: 12),

            // Quote
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1535), Color(0xFF0D1A2A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: const Border(left: BorderSide(color: kAccent, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"${quote[0]}"',
                      style: const TextStyle(color: kText, fontSize: 14, fontStyle: FontStyle.italic, height: 1.6)),
                  const SizedBox(height: 8),
                  Text('— ${quote[1]}',
                      style: const TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Mark Today Done button
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isDone ? kGreen : kAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                if (isDone) {
                  widget.model.completedDays.remove(today);
                } else {
                  widget.model.completedDays.add(today);
                }
                widget.onChanged();
              },
              child: Text(
                isDone ? '✓  Today Done! Tap to undo' : 'Mark Today as Done  ✓',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: .5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cdBox(String val, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(val, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kAccent)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 10, color: kText3, letterSpacing: .5)),
        ],
      ),
    ),
  );

  Widget _statBox(String icon, String val, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kGold)),
              Text(label, style: const TextStyle(fontSize: 10, color: kText3)),
            ],
          ),
        ],
      ),
    ),
  );

  String _fmt(DateTime d) =>
      '${d.day} ${['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month]} ${d.year}';
}

// ── TRACKER SCREEN ──
class TrackerScreen extends StatelessWidget {
  final AppModel model;
  final VoidCallback onChanged;
  const TrackerScreen({super.key, required this.model, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final today = _dateStr(DateTime.now());
    int done = 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('180 Day Grid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                _tStat(model.totalDone.toString(), 'Done', kGreen),
                const SizedBox(width: 8),
                _tStat((180 - model.totalDone).toString(), 'Left', kText3),
                const SizedBox(width: 8),
                _tStat('${(model.totalDone / 180 * 100).round()}%', '%', kGold),
              ],
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 500 ? 18 : 12,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 180,
              itemBuilder: (ctx, i) {
                final date = model.dateForDay(i);
                final isDone = model.completedDays.contains(date);
                final isToday = date == today;
                final isPast = date.compareTo(today) < 0;
                if (isDone) done++;

                Color bg;
                if (isDone) bg = kGreen;
                else if (isPast && !isDone) bg = const Color(0xFF7F1D1D);
                else bg = kSurface2;

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
                      borderRadius: BorderRadius.circular(4),
                      border: isToday ? Border.all(color: kGold, width: 2) : null,
                    ),
                    child: isToday
                        ? const Center(child: Text('●', style: TextStyle(color: kGold, fontSize: 8)))
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _legend(kGreen, 'Completed'),
                _legend(const Color(0xFF7F1D1D), 'Missed'),
                _legend(kSurface2, 'Pending'),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: kSurface2,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: kGold, width: 2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Today', style: TextStyle(fontSize: 12, color: kText2)),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tStat(String v, String l, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(10)),
    child: Column(
      children: [
        Text(v, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c)),
        Text(l, style: const TextStyle(fontSize: 10, color: kText3)),
      ],
    ),
  );

  Widget _legend(Color c, String l) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 16, height: 16, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(l, style: const TextStyle(fontSize: 12, color: kText2)),
    ],
  );
}

// ── SUBJECTS SCREEN ──
class SubjectsScreen extends StatelessWidget {
  final AppModel model;
  final VoidCallback onChanged;
  const SubjectsScreen({super.key, required this.model, required this.onChanged});

  static const _icons = ['⚛️', '🧪', '📐'];
  static const _colors = [kBlue, kGreen, kGold];

  @override
  Widget build(BuildContext context) {
    final subjects = model.subjects;
    final subjectNames = subjects.keys.toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: List.generate(3, (i) {
              final name = subjectNames[i];
              final chapters = subjects[name]!;
              final done = chapters.where((c) => c.done).length;
              final pct = chapters.isEmpty ? 0 : (done / chapters.length * 100).round();
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text('$pct%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _colors[i])),
                      const SizedBox(height: 3),
                      Text(name, style: const TextStyle(fontSize: 11, color: kText3)),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          ...List.generate(subjectNames.length, (si) {
            final name = subjectNames[si];
            final chapters = subjects[name]!;
            final done = chapters.where((c) => c.done).length;
            final pct = chapters.isEmpty ? 0.0 : done / chapters.length;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${_icons[si]} $name',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _colors[si])),
                      const Spacer(),
                      Text('$done/${chapters.length}', style: const TextStyle(color: kText2, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: kSurface2,
                      color: _colors[si],
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...chapters.asMap().entries.map((e) {
                    final ch = e.value;
                    final tagColor = _tagColor(ch.priority);
                    return GestureDetector(
                      onTap: () { ch.done = !ch.done; onChanged(); },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: ch.done ? kGreen : Colors.transparent,
                                border: Border.all(color: ch.done ? kGreen : kText3, width: 2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: ch.done
                                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(ch.name,
                                  style: TextStyle(
                                    fontSize: 13, color: ch.done ? kText3 : kText,
                                    decoration: ch.done ? TextDecoration.lineThrough : null,
                                  )),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: tagColor[0],
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(_tagLabel(ch.priority),
                                  style: TextStyle(fontSize: 10, color: tagColor[1], fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _addChapterDialog(context, name, chapters),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: kText3, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('+ Add Chapter',
                          textAlign: TextAlign.center, style: TextStyle(color: kText2, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Color> _tagColor(String p) {
    switch (p) {
      case 'high': return [const Color(0xFF7F1D1D), const Color(0xFFFCA5A5)];
      case 'low': return [const Color(0xFF14532D), const Color(0xFF86EFAC)];
      default: return [const Color(0xFF78350F), const Color(0xFFFCD34D)];
    }
  }

  String _tagLabel(String p) => p == 'high' ? 'High' : p == 'low' ? 'Low' : 'Med';

  void _addChapterDialog(BuildContext ctx, String subject, List<Chapter> chapters) {
    final ctrl = TextEditingController();
    String priority = 'med';
    showModalBottomSheet(
      context: ctx,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx2).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Chapter to $subject',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(color: kText),
                decoration: const InputDecoration(hintText: 'Chapter name...', hintStyle: TextStyle(color: kText3)),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'high', label: Text('High')),
                  ButtonSegment(value: 'med', label: Text('Medium')),
                  ButtonSegment(value: 'low', label: Text('Low')),
                ],
                selected: {priority},
                onSelectionChanged: (s) => setS(() => priority = s.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected) ? kAccent : kSurface2),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final name = ctrl.text.trim();
                        if (name.isEmpty) return;
                        chapters.add(Chapter(name: name, priority: priority));
                        onChanged();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── TASKS SCREEN ──
class TasksScreen extends StatefulWidget {
  final AppModel model;
  final VoidCallback onChanged;
  const TasksScreen({super.key, required this.model, required this.onChanged});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _ctrl = TextEditingController();
  int _selectedSub = 0;
  int _timerSecs = 0;
  bool _running = false;
  Timer? _timer;

  static const _subNames = ['Physics', 'Chemistry', 'Maths'];
  static const _subIcons = ['⚛️', '🧪', '📐'];
  static const _subColors = [kBlue, kGreen, kGold];

  String get _today => _dateStr(DateTime.now());

  List<Task> get _tasks => widget.model.dailyTasks[_today] ?? [];
  List<int> get _studyToday => widget.model.studyMinutes[_today] ?? [0, 0, 0];

  void _startTimer() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _timerSecs++);
      if (_timerSecs % 60 == 0) {
        final today = _dateStr(DateTime.now());
        widget.model.studyMinutes.putIfAbsent(today, () => [0, 0, 0]);
        widget.model.studyMinutes[today]![_selectedSub]++;
        widget.onChanged();
      }
    });
    setState(() {});
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() => _timerSecs = 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.model.dailyTasks[_today] ?? [];
    final study = _studyToday;
    final h = _timerSecs ~/ 3600;
    final m = (_timerSecs % 3600) ~/ 60;
    final s = _timerSecs % 60;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _fmtDate(DateTime.now()),
            style: const TextStyle(fontSize: 14, color: kText2, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),

          // Subject selector
          Row(
            children: List.generate(3, (i) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSub = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedSub == i ? kSurface2 : kSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedSub == i ? kAccent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(_subIcons[i], style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(_subNames[i],
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _subColors[i])),
                      const SizedBox(height: 2),
                      Text(_fmtMins(study.length > i ? study[i] : 0),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kGold)),
                    ],
                  ),
                ),
              ),
            )),
          ),
          const SizedBox(height: 10),

          // Timer display
          Center(
            child: Text(
              '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontSize: 48, fontWeight: FontWeight.w900, color: kGold,
                  fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
          const SizedBox(height: 8),

          // Timer buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _running ? null : _startTimer,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start'),
                  style: FilledButton.styleFrom(backgroundColor: kGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _running ? _pauseTimer : null,
                  icon: const Icon(Icons.pause_rounded),
                  label: const Text('Pause'),
                  style: FilledButton.styleFrom(backgroundColor: kRed,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset'),
                  style: FilledButton.styleFrom(backgroundColor: kSurface2,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Task section
          const Text('Today\'s Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: kText),
                  decoration: const InputDecoration(
                    hintText: 'Add a task...',
                    hintStyle: TextStyle(color: kText3),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  onSubmitted: (_) => _addTask(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _addTask,
                style: FilledButton.styleFrom(
                  backgroundColor: kAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.add, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (tasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              child: const Column(
                children: [
                  Text('📝', style: TextStyle(fontSize: 36)),
                  SizedBox(height: 8),
                  Text('No tasks yet. Add one above!', style: TextStyle(color: kText3)),
                ],
              ),
            )
          else
            ...tasks.asMap().entries.map((e) {
              final t = e.value;
              return Dismissible(
                key: Key('task-${e.key}-${t.text}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  widget.model.dailyTasks[_today]!.removeAt(e.key);
                  widget.onChanged();
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: kRed.withOpacity(.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_rounded, color: kRed),
                ),
                child: GestureDetector(
                  onTap: () { t.done = !t.done; widget.onChanged(); },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: t.done ? kGreen : Colors.transparent,
                            border: Border.all(color: t.done ? kGreen : kText3, width: 2),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: t.done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: t.done ? kText3 : kText,
                              decoration: t.done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _addTask() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.model.dailyTasks.putIfAbsent(_today, () => []);
    widget.model.dailyTasks[_today]!.add(Task(text: text));
    _ctrl.clear();
    widget.onChanged();
  }

  String _fmtDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month]} ${d.year}';
  }

  String _fmtMins(int m) => '${m ~/ 60}h ${m % 60}m';
}

// ── SETTINGS SCREEN ──
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
    final totalMins = m.totalStudyMins;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _card('Challenge Setup', [
            _field('Your Name', _nameCtrl),
            _datePicker('Start Date', _startDate, (d) => setState(() => _startDate = d)),
            _datePicker('JEE Target Date', _targetDate, (d) => setState(() => _targetDate = d)),
          ]),
          const SizedBox(height: 4),
          FilledButton(
            onPressed: () {
              m.name = _nameCtrl.text.trim().isEmpty ? 'JEE Aspirant' : _nameCtrl.text.trim();
              m.startDate = _dateStr(_startDate);
              m.targetDate = _dateStr(_targetDate);
              widget.onChanged();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved!'), backgroundColor: kGreen),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: kAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Save Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
          _card('Your Stats', [
            _statRow('Days Completed', '${m.totalDone}', kGreen),
            _statRow('Current Streak', '${m.streak} days', kGold),
            _statRow('Total Study Hours', '${totalMins ~/ 60}h ${totalMins % 60}m', kAccent),
            _statRow('Challenge Progress', '${(m.totalDone / 180 * 100).round()}%', kBlue),
            _statRow('App Version', '1.0.0', kText3),
          ]),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _confirmReset(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: kRed,
              side: const BorderSide(color: kRed),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('⚠  Reset All Data', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: kText3, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );

  Widget _field(String label, TextEditingController ctrl) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: kText2)),
        const SizedBox(height: 6),
        TextField(controller: ctrl, style: const TextStyle(color: kText),
            decoration: InputDecoration(hintStyle: const TextStyle(color: kText3),
                hintText: label)),
      ],
    ),
  );

  Widget _datePicker(String label, DateTime value, ValueChanged<DateTime> onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: kText))),
          TextButton(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(primary: kAccent, surface: kSurface),
                  ),
                  child: child!,
                ),
              );
              if (d != null) onPick(d);
            },
            child: Text(_fmtDate(value),
                style: const TextStyle(color: kAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: kText)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, color: c, fontWeight: FontWeight.w700)),
      ],
    ),
  );

  String _fmtDate(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  void _confirmReset(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Reset All Data?'),
        content: const Text('This will delete all your progress. This cannot be undone.',
            style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kRed),
            onPressed: () {
              final m = widget.model;
              m.completedDays.clear();
              m.dailyTasks.clear();
              m.studyMinutes.clear();
              m.subjects.forEach((_, chapters) {
                for (final c in chapters) c.done = false;
              });
              widget.onChanged();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('All data reset.'), backgroundColor: kRed),
              );
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }
}

// ── UTILITIES ──
String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
