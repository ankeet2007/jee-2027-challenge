import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
const kVersion = '1.4.0';

const kBg = Color(0xFF0A0B0F);
const kSurface = Color(0xFF141821);
const kSurfaceHi = Color(0xFF1C212C);
const kStroke = Color(0xFF262C38);
const kAccent = Color(0xFFFF6B4A); // warm coral
const kAccent2 = Color(0xFFFF8A5B);
const kAccentDim = Color(0xFF3A2420);
const kGold = Color(0xFFFFB02E);
const kGreen = Color(0xFF2DD4A7);
const kRed = Color(0xFFFF5A6E);
const kBlue = Color(0xFF4F9DFF);
const kViolet = Color(0xFFA78BFA);
const kText = Color(0xFFF1F4F9);
const kText2 = Color(0xFF99A2B2);
const kText3 = Color(0xFF5A6478);

const kAccentGradient = LinearGradient(
  colors: [kAccent, kAccent2],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

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
//  DATA MODEL  (JSON shape unchanged — preserves saved progress + sync)
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
    return DateTime(now.year, now.month, now.day)
        .difference(DateTime(start.year, start.month, start.day))
        .inDays;
  }

  int get totalDone => completedDays.length;

  /// Current run of consecutive logged days. If today isn't logged yet we
  /// start counting from yesterday, so an active streak isn't shown as 0
  /// until the user checks in for the day.
  int get streak {
    int s = 0;
    DateTime d = DateTime.now();
    if (!completedDays.contains(_dateStr(d))) {
      d = d.subtract(const Duration(days: 1));
    }
    while (completedDays.contains(_dateStr(d))) {
      s++;
      d = d.subtract(const Duration(days: 1));
    }
    return s;
  }

  /// Longest run of consecutive logged days ever achieved.
  int get bestStreak {
    if (completedDays.isEmpty) return 0;
    final days = completedDays.map(DateTime.parse).toList()..sort();
    int best = 1, cur = 1;
    for (int i = 1; i < days.length; i++) {
      final gap = days[i].difference(days[i - 1]).inDays;
      if (gap == 1) {
        cur++;
        if (cur > best) best = cur;
      } else if (gap > 1) {
        cur = 1;
      }
    }
    return best;
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

  /// Overwrites every field from a decoded JSON map (used by Restore / sync).
  void applyJson(Map<String, dynamic> j) {
    final m = AppModel.fromJson(j);
    name = m.name;
    startDate = m.startDate;
    targetDate = m.targetDate;
    completedDays = m.completedDays;
    dailyTasks = m.dailyTasks;
    studyMinutes = m.studyMinutes;
    subjects = m.subjects;
    monthlyPlans = m.monthlyPlans;
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

  /// Writes only to the on-device cache. Used when applying a remote update so
  /// we refresh the offline copy without echoing a write back to the cloud.
  Future<void> saveLocalOnly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jee_data', jsonEncode(toJson()));
  }

  Future<void> save() async {
    final json = toJson();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jee_data', jsonEncode(json));
    // Mirror to the cloud so every signed-in device stays in sync.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'data': json,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Offline or transient error — Firestore queues the write and syncs later.
      }
    }
  }
}

// ════════════════════════════════════════════════════════════
//  CLOUD SYNC
// ════════════════════════════════════════════════════════════
class SyncService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  /// Loads the model for a signed-in user. Once a cloud copy exists it is the
  /// source of truth; otherwise we seed the cloud from this device's local data.
  static Future<AppModel> loadForUser(String uid) async {
    try {
      final snap = await _doc(uid).get();
      final data = snap.data();
      if (snap.exists && data != null && data['data'] != null) {
        final model = AppModel.fromJson(Map<String, dynamic>.from(data['data']));
        await model.save(); // refresh local cache
        return model;
      }
    } catch (_) {
      // Offline / error — fall back to the local cache.
      return AppModel.load();
    }
    // No cloud copy yet — seed it from whatever is stored on this device.
    final local = await AppModel.load();
    await local.save();
    return local;
  }

  /// Live updates pushed from other devices (ignores this device's own writes).
  static Stream<AppModel> watch(String uid) => _doc(uid)
      .snapshots()
      .where((s) =>
          !s.metadata.hasPendingWrites &&
          s.exists &&
          s.data()?['data'] != null)
      .map((s) => AppModel.fromJson(Map<String, dynamic>.from(s.data()!['data'])));

  static Future<void> signOut() => _auth.signOut();
}

// ════════════════════════════════════════════════════════════
//  APP ROOT
// ════════════════════════════════════════════════════════════
class JEEApp extends StatelessWidget {
  const JEEApp({super.key});

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
      home: const AuthGate(),
    );
  }
}

/// Shows the sign-in screen until the user is authenticated, then the app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold();
        }
        final user = snap.data;
        if (user == null) return const AuthScreen();
        return SyncedRoot(uid: user.uid);
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2)),
      );
}

/// Loads the signed-in user's data from the cloud and keeps it live-synced.
class SyncedRoot extends StatefulWidget {
  final String uid;
  const SyncedRoot({super.key, required this.uid});
  @override
  State<SyncedRoot> createState() => _SyncedRootState();
}

class _SyncedRootState extends State<SyncedRoot> {
  AppModel? _model;
  StreamSubscription<AppModel>? _sub;
  // Bumped only when the model is wholesale-replaced (remote sync / restore /
  // reset) so controller-caching screens rebuild from the fresh data.
  int _rev = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final model = await SyncService.loadForUser(widget.uid);
    if (!mounted) return;
    setState(() => _model = model);
    // Mirror changes made on other devices in real time.
    _sub = SyncService.watch(widget.uid).listen((remote) {
      if (!mounted) return;
      remote.saveLocalOnly(); // keep the offline cache fresh (no cloud echo)
      setState(() {
        _model = remote;
        _rev++;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Normal edits: persist + repaint, keeping screen state intact.
  void _onChanged() {
    _model!.save();
    setState(() {});
  }

  // Wholesale data replacement (restore / reset): force caching screens to rebuild.
  void _onReplaced() {
    _model!.save();
    setState(() => _rev++);
  }

  @override
  Widget build(BuildContext context) {
    if (_model == null) return const _LoadingScaffold();
    return MainScreen(
      model: _model!,
      rev: _rev,
      onChanged: _onChanged,
      onReplaced: _onReplaced,
    );
  }
}

// ════════════════════════════════════════════════════════════
//  AUTH SCREEN  (sign in / sign up — same account syncs every device)
// ════════════════════════════════════════════════════════════
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      if (_isSignUp) {
        await auth.createUserWithEmailAndPassword(email: email, password: pass);
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: pass);
      }
      // AuthGate reacts to the auth state change and shows the app.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } catch (_) {
      setState(() => _error = 'Something went wrong. Check your connection.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Sign in instead.';
      case 'weak-password':
        return 'Choose a stronger password (6+ characters).';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Could not continue. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: kAccentGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: kAccent.withOpacity(0.35), blurRadius: 22, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 20),
                  const Text('180 Days · JEE 2027',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText)),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUp
                        ? 'Create an account to sync your progress across devices.'
                        : 'Sign in to sync your progress across devices.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13.5, color: kText2, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _input(
                          controller: _emailCtrl,
                          hint: 'Email',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _input(
                          controller: _passCtrl,
                          hint: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          onSubmitted: (_) => _busy ? null : _submit(),
                          suffix: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: kText3, size: 20,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: kRed, size: 17),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(_error!,
                                    style: const TextStyle(color: kRed, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: kAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(_isSignUp ? 'Create account' : 'Sign in',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _error = null;
                            }),
                    child: Text.rich(
                      TextSpan(
                        text: _isSignUp ? 'Already have an account?  ' : "Don't have an account?  ",
                        style: const TextStyle(color: kText2, fontSize: 13.5),
                        children: [
                          TextSpan(
                            text: _isSignUp ? 'Sign in' : 'Sign up',
                            style: const TextStyle(color: kAccent, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: kText, fontWeight: FontWeight.w600),
      cursorColor: kAccent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kText3),
        prefixIcon: Icon(icon, color: kText3, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: kSurfaceHi,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kAccent, width: 1.4),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ════════════════════════════════════════════════════════════

/// Circular progress ring with a soft glow. Animates to its value on change.
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
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, value, ringChild) => CustomPaint(
          painter: _RingPainter(progress: value, color: color, stroke: stroke),
          child: Center(child: ringChild),
        ),
        child: child,
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

/// Animated, rounded linear progress bar.
class AnimatedBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;
  const AnimatedBar({super.key, required this.value, required this.color, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: kStroke,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
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

/// Big screen title with a subtitle, used at the top of each tab.
Widget screenHeader(String title, String subtitle) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kText)),
    const SizedBox(height: 4),
    Text(subtitle, style: const TextStyle(fontSize: 13, color: kText3)),
  ],
);

/// One floating snackbar style used everywhere.
void showSnack(BuildContext ctx, String msg, {Color color = kGreen, IconData? icon}) {
  final messenger = ScaffoldMessenger.of(ctx);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 10)],
          Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  MAIN SCREEN  (nav shell)
// ════════════════════════════════════════════════════════════
class MainScreen extends StatefulWidget {
  final AppModel model;
  final int rev;
  final VoidCallback onChanged;
  final VoidCallback onReplaced;
  const MainScreen({
    super.key,
    required this.model,
    required this.rev,
    required this.onChanged,
    required this.onReplaced,
  });
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  void _go(int i) {
    if (_tab == i) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rev;
    // Screens are keyed by `rev` so the ones that cache controllers
    // (Planner, Settings) rebuild cleanly after a remote sync / restore / reset.
    final screens = [
      HomeScreen(key: ValueKey('home$r'), model: widget.model, onChanged: widget.onChanged, onNavigate: _go),
      TrackerScreen(key: ValueKey('track$r'), model: widget.model, onChanged: widget.onChanged),
      SubjectsScreen(key: ValueKey('subj$r'), model: widget.model, onChanged: widget.onChanged),
      PlannerScreen(key: ValueKey('plan$r'), model: widget.model, onChanged: widget.onChanged),
      SettingsScreen(
        key: ValueKey('set$r'),
        model: widget.model,
        onChanged: widget.onChanged,
        onReplaced: widget.onReplaced,
      ),
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
            onDestinationSelected: _go,
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
  final ValueChanged<int>? onNavigate;
  const HomeScreen({super.key, required this.model, required this.onChanged, this.onNavigate});
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
    final diff = target.difference(DateTime.now());
    if (mounted) setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
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
    final progress = (m.totalDone / 180).clamp(0.0, 1.0);
    final firstLetter = (m.name.trim().isNotEmpty ? m.name.trim()[0] : 'J').toUpperCase();
    final todayTasks = m.dailyTasks[today] ?? const <Task>[];

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
                  gradient: kAccentGradient,
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                // soft radial glow behind the ring
                Container(
                  width: 210, height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [kAccent.withOpacity(0.13), Colors.transparent],
                    ),
                  ),
                ),
                ProgressRing(
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
                      const Text('of 180',
                          style: TextStyle(fontSize: 14, color: kText2, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
                        decoration: BoxDecoration(
                          color: kAccentDim,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text('${m.totalDone} done · ${(progress * 100).round()}%',
                            style: const TextStyle(fontSize: 12, color: kAccent, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
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

          // ── Stat chips (tap to jump to the relevant tab) ──
          Row(
            children: [
              _statTile(Icons.local_fire_department_rounded, kAccent, '${m.streak}', 'Streak', () => widget.onNavigate?.call(1)),
              const SizedBox(width: 12),
              _statTile(Icons.task_alt_rounded, kGreen, '${m.totalDone}', 'Days done', () => widget.onNavigate?.call(1)),
              const SizedBox(width: 12),
              _statTile(Icons.menu_book_rounded, kBlue, '${m.doneChapters}', 'Chapters', () => widget.onNavigate?.call(2)),
            ],
          ),
          const SizedBox(height: 12),

          // ── Today's tasks summary → Planner ──
          _todayTasksCard(todayTasks),
          const SizedBox(height: 22),

          // ── Quote ──
          sectionLabel('Daily fuel'),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kSurfaceHi, kSurface],
              ),
              borderRadius: BorderRadius.circular(20),
              border: const Border(left: BorderSide(color: kAccent, width: 3)),
            ),
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
          _ctaButton(isDone, today, dayNum),
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

  Widget _statTile(IconData icon, Color c, String v, String l, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      behavior: HitTestBehavior.opaque,
      child: Panel(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Column(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: c.withOpacity(0.14), borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: c, size: 21),
            ),
            const SizedBox(height: 8),
            Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText)),
            Text(l, style: const TextStyle(fontSize: 11, color: kText3, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ),
  );

  Widget _todayTasksCard(List<Task> tasks) {
    final done = tasks.where((t) => t.done).length;
    final hasTasks = tasks.isNotEmpty;
    final allDone = hasTasks && done == tasks.length;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); widget.onNavigate?.call(3); },
      behavior: HitTestBehavior.opaque,
      child: Panel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: (allDone ? kGreen : kViolet).withOpacity(0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(allDone ? Icons.check_circle_rounded : Icons.checklist_rounded,
                  color: allDone ? kGreen : kViolet, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's tasks",
                      style: TextStyle(fontSize: 14, color: kText, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    hasTasks
                        ? (allDone ? 'All $done done — nice work!' : '$done of ${tasks.length} done')
                        : 'Tap to plan your day',
                    style: const TextStyle(fontSize: 12, color: kText2),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: kText3, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _ctaButton(bool isDone, String today, int dayNum) => GestureDetector(
    onTap: () {
      final nowComplete = !isDone;
      HapticFeedback.mediumImpact();
      if (nowComplete) {
        widget.model.completedDays.add(today);
      } else {
        widget.model.completedDays.remove(today);
      }
      widget.onChanged();
      if (nowComplete) {
        showSnack(context, 'Day $dayNum logged — keep the streak alive!',
            color: kGreen, icon: Icons.check_circle_rounded);
      }
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: isDone ? null : kAccentGradient,
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
    final pct = (done / 180).clamp(0.0, 1.0);
    final cols = MediaQuery.of(context).size.width > 500 ? 20 : 12;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          screenHeader('Your 180 days', 'Tap any day up to today to log it'),
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
                AnimatedBar(value: pct, color: kAccent),
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
                    HapticFeedback.selectionClick();
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
          screenHeader('Syllabus', '${m.doneChapters} of ${m.totalChapters} chapters mastered'),
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
                        progress: p, size: 70, stroke: 7,
                        color: kSubjectColors[i % kSubjectColors.length],
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
    final color = kSubjectColors[si % kSubjectColors.length];
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
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => isOpen ? _expanded.remove(si) : _expanded.add(si));
            },
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
                    child: Icon(kSubjectIcons[si % kSubjectIcons.length], color: color, size: 24),
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
                            Expanded(child: AnimatedBar(value: pct, color: color, height: 6)),
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
                  ...chapters.map((ch) => _chapterRow(chapters, ch, color)),
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

  Widget _chapterRow(List<Chapter> chapters, Chapter ch, Color subjColor) {
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
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => ch.done = !ch.done);
          widget.onChanged();
        },
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
//  PLANNER  (today's tasks + monthly plan)
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
  Timer? _planSaveTimer;
  bool _planDirty = false;

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

  // Update the in-memory model immediately, but debounce the (cloud) write so
  // we don't fire a Firestore write on every keystroke.
  void _onPlanChanged(String monthKey, String subject, String text) {
    widget.model.monthlyPlans.putIfAbsent(monthKey, () => {});
    widget.model.monthlyPlans[monthKey]![subject] = text;
    _planDirty = true;
    _planSaveTimer?.cancel();
    _planSaveTimer = Timer(const Duration(milliseconds: 800), () {
      widget.model.save();
      _planDirty = false;
    });
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _openMonths.add('${now.year}-${now.month.toString().padLeft(2, '0')}');
  }

  @override
  void dispose() {
    _planSaveTimer?.cancel();
    if (_planDirty) widget.model.save(); // flush any pending plan edit
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
          screenHeader('Planner', 'Plan each month and your day'),
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
                  textCapitalization: TextCapitalization.sentences,
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
                  decoration: BoxDecoration(gradient: kAccentGradient, borderRadius: BorderRadius.circular(14)),
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
            ...tasks.map(_taskRow),

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
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => isOpen ? _openMonths.remove(key) : _openMonths.add(key));
            },
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
                          onChanged: (v) => _onPlanChanged(key, subject, v),
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

  Widget _taskRow(Task t) => Dismissible(
    key: ObjectKey(t),
    direction: DismissDirection.endToStart,
    onDismissed: (_) {
      widget.model.dailyTasks[_today]?.remove(t);
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
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => t.done = !t.done);
        widget.onChanged();
      },
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
    HapticFeedback.selectionClick();
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
  final VoidCallback onReplaced;
  const SettingsScreen({
    super.key,
    required this.model,
    required this.onChanged,
    required this.onReplaced,
  });
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
                  textCapitalization: TextCapitalization.words,
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
                if (_targetDate.isBefore(_startDate)) {
                  showSnack(context, 'Target date must be after the start date',
                      color: kRed, icon: Icons.error_outline_rounded);
                  return;
                }
                m.name = _nameCtrl.text.trim().isEmpty ? 'JEE Aspirant' : _nameCtrl.text.trim();
                m.startDate = _dateStr(_startDate);
                m.targetDate = _dateStr(_targetDate);
                FocusScope.of(context).unfocus();
                widget.onChanged();
                showSnack(context, 'Settings saved', color: kGreen, icon: Icons.check_circle_rounded);
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
                _statRow(Icons.emoji_events_rounded, kGold, 'Longest streak', '${m.bestStreak} days'),
                const Divider(height: 22, color: kStroke),
                _statRow(Icons.menu_book_rounded, kViolet, 'Chapters done', '${m.doneChapters}/${m.totalChapters}'),
                const Divider(height: 22, color: kStroke),
                _statRow(Icons.trending_up_rounded, kBlue, 'Overall progress', '${(m.totalDone / 180 * 100).clamp(0, 100).round()}%'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          sectionLabel('Backup & restore'),
          Panel(
            child: Column(
              children: [
                _actionRow(
                  Icons.ios_share_rounded, kBlue, 'Export data',
                  'Copy a backup of everything to the clipboard',
                  () => _exportData(context),
                ),
                const Divider(height: 24, color: kStroke),
                _actionRow(
                  Icons.download_rounded, kGreen, 'Restore data',
                  'Paste a backup to replace your current data',
                  () => _importData(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          sectionLabel('Account'),
          Panel(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: kBlue.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_done_rounded, color: kBlue, size: 19),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Synced', style: TextStyle(fontSize: 14, color: kText)),
                          const SizedBox(height: 2),
                          Text(
                            FirebaseAuth.instance.currentUser?.email ?? '',
                            style: const TextStyle(fontSize: 12.5, color: kText2),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: kStroke),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _confirmSignOut(context),
                    icon: const Icon(Icons.logout_rounded, size: 19, color: kText2),
                    label: const Text('Sign out',
                        style: TextStyle(color: kText2, fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                  ),
                ),
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
          Center(
            child: Text('180 Days · JEE 2027  ·  v$kVersion',
                style: const TextStyle(fontSize: 12, color: kText3)),
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

  Widget _actionRow(IconData icon, Color c, String title, String sub, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: c.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: c, size: 19),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: kText, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(fontSize: 12, color: kText2)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: kText3, size: 22),
          ],
        ),
      );

  void _exportData(BuildContext ctx) {
    final data = jsonEncode(widget.model.toJson());
    Clipboard.setData(ClipboardData(text: data));
    showSnack(ctx, 'Backup copied to clipboard', color: kGreen, icon: Icons.check_circle_rounded);
  }

  void _importData(BuildContext ctx) {
    final ctrl = TextEditingController();
    // Capture a stable messenger up front: applying a restore bumps `rev`,
    // which rebuilds this screen and would invalidate `ctx` for a later lookup.
    final messenger = ScaffoldMessenger.of(ctx);
    showDialog(
      context: ctx,
      builder: (dctx) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restore data', style: TextStyle(color: kText, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste a backup below. This replaces all your current data on this account.',
                style: TextStyle(color: kText2, fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              maxLines: 6,
              style: const TextStyle(color: kText, fontSize: 12),
              cursorColor: kAccent,
              decoration: InputDecoration(
                hintText: 'Paste backup here…',
                hintStyle: const TextStyle(color: kText3),
                filled: true,
                fillColor: kSurfaceHi,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kStroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kAccent, width: 1.4),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancel', style: TextStyle(color: kText2))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kGreen),
            onPressed: () {
              try {
                final parsed = jsonDecode(ctrl.text.trim()) as Map<String, dynamic>;
                widget.model.applyJson(parsed);
                Navigator.pop(dctx);
                widget.onReplaced(); // persist + rebuild every screen from fresh data
                _snack(messenger, 'Data restored', kGreen);
              } catch (_) {
                _snack(messenger, "That doesn't look like a valid backup", kRed);
              }
            },
            child: const Text('Restore', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // Snackbar via a pre-captured messenger (safe across a `rev` rebuild).
  void _snack(ScaffoldMessengerState messenger, String msg, Color color) {
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _confirmSignOut(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dctx) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?', style: TextStyle(color: kText, fontWeight: FontWeight.w700)),
        content: const Text(
            'Your data stays safe in the cloud. Sign back in on any device to access it.',
            style: TextStyle(color: kText2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancel', style: TextStyle(color: kText2))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kAccent),
            onPressed: () {
              Navigator.pop(dctx);
              SyncService.signOut();
            },
            child: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext ctx) {
    final messenger = ScaffoldMessenger.of(ctx);
    showDialog(
      context: ctx,
      builder: (dctx) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset all data?', style: TextStyle(color: kText, fontWeight: FontWeight.w700)),
        content: const Text('This deletes all your progress, tasks, plans and study time. This cannot be undone.',
            style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancel', style: TextStyle(color: kText2))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kRed),
            onPressed: () {
              final m = widget.model;
              m.completedDays.clear();
              m.dailyTasks.clear();
              m.studyMinutes.clear();
              m.monthlyPlans.clear();
              for (final chapters in m.subjects.values) {
                for (final c in chapters) {
                  c.done = false;
                }
              }
              Navigator.pop(dctx);
              widget.onReplaced(); // persist + rebuild every screen from fresh data
              _snack(messenger, 'All data reset', kRed);
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
