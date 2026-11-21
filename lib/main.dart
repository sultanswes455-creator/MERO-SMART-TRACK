
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

const neon = Color(0xFF00F58A);
const dark = Color(0xFF080D0A);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SnakApp());
}

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(primary: neon),
      ),
      home: const TrainingOverlay(),
    ),
  );
}

class SnakApp extends StatelessWidget {
  const SnakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: dark,
        colorScheme: const ColorScheme.dark(primary: neon),
      ),
      home: const ActivationPage(),
    );
  }
}

class ActivationPage extends StatefulWidget {
  const ActivationPage({super.key});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final code = TextEditingController();
  String error = '';

  void activate() {
    if (code.text.trim() == '3111') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      setState(() => error = 'كود التفعيل غير صحيح');
    }
  }

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_esports, color: neon, size: 75),
              const SizedBox(height: 20),
              const Text(
                'SNAK TRAINING',
                style: TextStyle(
                  color: neon,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: code,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'أدخل كود التفعيل',
                  errorText: error.isEmpty ? null : error,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onSubmitted: (_) => activate(),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: activate,
                  style: FilledButton.styleFrom(
                    backgroundColor: neon,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('دخول'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String status = 'جاهز للتشغيل';

  Future<void> start() async {
    try {
      bool allowed =
          await FlutterOverlayWindow.isPermissionGranted();

      if (!allowed) {
        allowed =
            await FlutterOverlayWindow.requestPermission() ?? false;
      }

      if (!allowed) {
        setState(() => status = 'امنح إذن الظهور فوق التطبيقات');
        return;
      }

      await FlutterOverlayWindow.showOverlay(
        height: 560,
        width: 320,
        enableDrag: true,
        overlayTitle: 'SNAK TRAINING',
        overlayContent: 'مساعد تدريب 8 Ball Pool',
      );

      setState(() => status = 'تم تشغيل النافذة العائمة');
    } catch (e) {
      setState(() => status = 'تعذر تشغيل النافذة: $e');
    }
  }

  Future<void> stop() async {
    await FlutterOverlayWindow.closeOverlay();
    setState(() => status = 'تم إيقاف النافذة');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SNAK TRAINING',
            style: TextStyle(color: neon)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_esports, color: neon, size: 75),
            const SizedBox(height: 20),
            const Text(
              'مساعد تدريب 8 Ball Pool',
              style: TextStyle(fontSize: 21),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: start,
                icon: const Icon(Icons.play_arrow),
                label: const Text('تشغيل النافذة العائمة'),
                style: FilledButton.styleFrom(
                  backgroundColor: neon,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: stop,
              icon: const Icon(Icons.close),
              label: const Text('إيقاف النافذة'),
            ),
            const SizedBox(height: 20),
            Text(status, style: const TextStyle(color: neon)),
          ],
        ),
      ),
    );
  }
}

class TrainingOverlay extends StatefulWidget {
  const TrainingOverlay({super.key});

  @override
  State<TrainingOverlay> createState() => _TrainingOverlayState();
}

class _TrainingOverlayState extends State<TrainingOverlay> {
  double angle = 45;
  double power = 65;
  Offset spin = Offset.zero;
  bool expanded = true;
  bool showLines = true;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xF20A120D),
            border: Border.all(color: neon, width: 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle, color: neon, size: 12),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'SNAK TRAINING',
                        style: TextStyle(
                          color: neon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => expanded = !expanded),
                      icon: Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          FlutterOverlayWindow.closeOverlay(),
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
                if (expanded) ...[
                  const Divider(color: neon),
                  Text('زاوية التصويب: ${angle.round()}°'),
                  Slider(
                    value: angle,
                    min: 0,
                    max: 360,
                    activeColor: neon,
                    onChanged: (v) => setState(() => angle = v),
                  ),
                  Text('قوة الضربة: ${power.round()}%'),
                  Slider(
                    value: power,
                    min: 1,
                    max: 100,
                    activeColor: neon,
                    onChanged: (v) => setState(() => power = v),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'مؤشر السبين',
                    style: TextStyle(color: neon),
                  ),
                  GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        spin = Offset(
                          (spin.dx + details.delta.dx / 45)
                              .clamp(-1.0, 1.0),
                          (spin.dy + details.delta.dy / 45)
                              .clamp(-1.0, 1.0),
                        );
                      });
                    },
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: Colors.black26,
                            ),
                          ),
                          Positioned(
                            left: 49 + spin.dx * 40 - 6,
                            top: 49 + spin.dy * 40 - 6,
                            child: const CircleAvatar(
                              radius: 7,
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'X: ${spin.dx.toStringAsFixed(2)}   '
                    'Y: ${spin.dy.toStringAsFixed(2)}',
                    style: const TextStyle(color: neon, fontSize: 12),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('إظهار خطوط المسار'),
                    value: showLines,
                    activeColor: neon,
                    onChanged: (v) =>
                        setState(() => showLines = v),
                  ),
                  if (showLines)
                    CustomPaint(
                      size: const Size(250, 95),
                      painter: PathPainter(angle, power, spin),
                    ),
                  const Text(
                    '  ،  تتبعاً تلقائياً للكرات.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final double angle;
  final double power;
  final Offset spin;

  PathPainter(this.angle, this.power, this.spin);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radians = angle * math.pi / 180;
    final length = power * 0.85;

    final direction = Offset(
      math.cos(radians),
      -math.sin(radians),
    );

    final paint = Paint()
      ..color = neon
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      center + direction * length,
      paint,
    );

    final spinPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2;

    canvas.drawLine(
      center + direction * length,
      center + direction * length +
          Offset(spin.dx * 15, spin.dy * 15),
      spinPaint,
    );

    canvas.drawCircle(
      center,
      5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant PathPainter old) {
    return old.angle != angle ||
        old.power != power ||
        old.spin != spin;
  }
}
