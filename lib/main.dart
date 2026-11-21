import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

const Color neon = Color(0xFF00F58A);
const Color dark = Color(0xFF07100B);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SnakApp());
}

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TrainingOverlay(),
  ));
}

class SnakApp extends StatelessWidget {
  const SnakApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: dark,
          colorScheme: const ColorScheme.dark(primary: neon),
        ),
        home: const ActivationPage(),
      );
}

class ActivationPage extends StatefulWidget {
  const ActivationPage({super.key});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final TextEditingController code = TextEditingController();
  String error = '';

  void enter() {
    if (code.text.trim() == '3111') {
      Navigator.of(context).pushReplacement(
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
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_esports, color: neon, size: 72),
                const SizedBox(height: 16),
                const Text(
                  'SNAK TRAINING',
                  style: TextStyle(
                    color: neon,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: code,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'أدخل كود التفعيل',
                    errorText: error.isEmpty ? null : error,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => enter(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: enter,
                    child: const Text('دخول'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String status = 'جاهز';

  Future<void> startOverlay() async {
    try {
      bool permitted =
          await FlutterOverlayWindow.isPermissionGranted();

      if (!permitted) {
        permitted =
            await FlutterOverlayWindow.requestPermission() ?? false;
      }

      if (!permitted) {
        setState(() =>
            status = 'لم يتم منح إذن الظهور فوق التطبيقات');
        return;
      }

      await FlutterOverlayWindow.showOverlay(
        height: 470,
        width: 310,
        enableDrag: true,
        overlayTitle: 'SNAK TRAINING',
        overlayContent: 'أدوات تدريب يدوية',
      );

      setState(() => status = 'تم طلب تشغيل النافذة العائمة');
    } catch (e) {
      setState(() => status = 'خطأ: $e');
    }
  }

  Future<void> stopOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
    if (mounted) {
      setState(() => status = 'تم إيقاف النافذة');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('SNAK TRAINING')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sports_esports,
                  color: neon,
                  size: 70,
                ),
                const SizedBox(height: 18),
                const Text(
                  'مساعد تدريب 8 Ball Pool',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: startOverlay,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('تشغيل النافذة العائمة'),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: stopOverlay,
                  icon: const Icon(Icons.close),
                  label: const Text('إيقاف النافذة'),
                ),
                const SizedBox(height: 18),
                Text(status, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
}

class TrainingOverlay extends StatefulWidget {
  const TrainingOverlay({super.key});

  @override
  State<TrainingOverlay> createState() =>
      _TrainingOverlayState();
}

class _TrainingOverlayState extends State<TrainingOverlay> {
  double angle = 45;
  double power = 60;
  Offset spin = Offset.zero;
  bool expanded = true;

  Future<void> toggleSize() async {
    setState(() => expanded = !expanded);

    await FlutterOverlayWindow.resizeOverlay(
      310,
      expanded ? 470 : 76,
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.all(5),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xF20A120D),
            border: Border.all(color: neon, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.sports_esports,
                    color: neon,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
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
                    visualDensity: VisualDensity.compact,
                    onPressed: toggleSize,
                    icon: Icon(
                      expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        FlutterOverlayWindow.closeOverlay(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              if (expanded) ...[
                const Divider(color: neon, height: 8),
                Text('زاوية التصويب: ${angle.round()}°'),
                Slider(
                  value: angle,
                  min: 0,
                  max: 360,
                  activeColor: neon,
                  onChanged: (v) =>
                      setState(() => angle = v),
                ),
                Text('قوة الضربة: ${power.round()}%'),
                Slider(
                  value: power,
                  min: 1,
                  max: 100,
                  activeColor: neon,
                  onChanged: (v) =>
                      setState(() => power = v),
                ),
                const Text(
                  'تحكم السبين اليدوي',
                  style: TextStyle(color: neon),
                ),
                GestureDetector(
                  onPanUpdate: (d) => setState(() {
                    spin = Offset(
                      (spin.dx + d.delta.dx / 45)
                          .clamp(-1.0, 1.0)
                          .toDouble(),
                      (spin.dy + d.delta.dy / 45)
                          .clamp(-1.0, 1.0)
                          .toDouble(),
                    );
                  }),
                  child: SizedBox(
                    width: 104,
                    height: 104,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
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
                            left: 45 + spin.dx * 38,
                            top: 45 + spin.dy * 38,
                            child: const CircleAvatar(
                              radius: 7,
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'X ${spin.dx.toStringAsFixed(2)}   '
                  'Y ${spin.dy.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: neon,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                CustomPaint(
                  size: const Size(260, 70),
                  painter: AimPainter(angle, power, spin),
                ),
                const Text(
                  'مؤشر تدريبي يدوي — لا يتتبع كرات اللعبة تلقائياً',
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
    );
  }
}

class AimPainter extends CustomPainter {
  final double angle;
  final double power;
  final Offset spin;

  AimPainter(this.angle, this.power, this.spin);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radians = angle * math.pi / 180;

    final direction = Offset(
      math.cos(radians),
      -math.sin(radians),
    );

    final end = center + direction * (power * 0.55);

    canvas.drawLine(
      center,
      end,
      Paint()
        ..color = neon
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawLine(
      end,
      end + Offset(spin.dx * 12, spin.dy * 12),
      Paint()
        ..color = Colors.orange
        ..strokeWidth = 2,
    );

    canvas.drawCircle(
      center,
      5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant AimPainter oldDelegate) =>
      oldDelegate.angle != angle ||
      oldDelegate.power != power ||
      oldDelegate.spin != spin;
}